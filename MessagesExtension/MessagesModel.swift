import Foundation
import Messages
import Observation
import UIKit

/// State and actions behind the iMessage extension's SwiftUI screens.
///
/// `MessagesViewController` owns it, forwards the Messages lifecycle, and fills in the hooks
/// (presentation changes, the active conversation, dismissing, opening links). Everything runs
/// on the main actor; Messages' background completion handlers hop back with
/// `Task { @MainActor in … }`.
@Observable
final class MessagesModel {
    /// Which screen the root view shows.
    nonisolated enum Screen: Equatable, Sendable {
        case signIn
        case consent
        case compact
        case expanded
    }

    let engine = ChatEngine(surface: .messages)
    let session = NimbusSession.shared
    let recents = RecentAnswersStore()
    let cards = CardSender()

    // MARK: Presentation

    private(set) var presentationStyle: MSMessagesAppPresentationStyle = .compact
    /// Set when the composer should take focus; `ExpandedView` focuses it and clears this.
    var wantsComposerFocus = false
    /// The person asked to sign in (or to give consent) while reading a received card.
    var wantsSignIn = false

    // MARK: Composer

    var draft = ""
    var composerStyle: ChatStyle = .default
    /// Summarize was picked without pasted text: the next typed message is what to summarize.
    private(set) var pendingSummarize = false
    /// Conversation text from the Paste button, sent as `context`.
    private(set) var pastedContext: String?

    // MARK: Received card

    private(set) var receivedCard: ReceivedCard?

    // MARK: Feedback

    private(set) var toast: ExtensionToast?
    /// The answer whose Report dialog is showing.
    var reportTarget: ThreadMessage?
    /// Firm tap when Send or Card is pressed.
    private(set) var sendTick = 0
    /// Selection tick when a chat is pasted.
    private(set) var pasteTick = 0
    /// A send or insert is on its way (buttons are disabled meanwhile).
    private(set) var isDelivering = false
    /// The answer whose card is being made after the tap (spinner on the Card button).
    private(set) var cardInFlight: UUID?

    // MARK: Hooks set by MessagesViewController

    @ObservationIgnored var requestPresentation: (@MainActor (MSMessagesAppPresentationStyle) -> Void)?
    @ObservationIgnored var dismissExtension: (@MainActor () -> Void)?
    @ObservationIgnored var openURLHandler: (@MainActor (URL) -> Void)?
    @ObservationIgnored var conversationProvider: (@MainActor () -> MSConversation?)?

    @ObservationIgnored private var focusAfterExpand = false
    @ObservationIgnored private var pendingCardMessage: MSMessage?
    @ObservationIgnored private var toastTask: Task<Void, Never>?
    @ObservationIgnored private var fullCardTask: Task<Void, Never>?

    private static let noConversationText = "Open a conversation in Messages first."

    init() {
        cards.onPrepared = { [weak self] answerID, card in
            self?.recents.attachCard(card, to: answerID)
        }
    }

    // MARK: - Derived state

    var screen: Screen {
        let expanded = presentationStyle == .expanded
        if receivedCard != nil, expanded, !wantsSignIn {
            return .expanded
        }
        guard session.isSignedIn else { return .signIn }
        guard hasConsent else { return .consent }
        return expanded ? .expanded : .compact
    }

    var isExpanded: Bool { presentationStyle == .expanded }

    /// Consent to send questions to Claude was given (App Review guideline 5.1.2(i)).
    var hasConsent: Bool { session.credential?.consentedAt != nil }

    var canAsk: Bool { session.isSignedIn && hasConsent }

    var isLoadingCard: Bool { receivedCard?.loadState == .loading }

    /// Drives the Report confirmation dialog.
    var isReporting: Bool {
        get { reportTarget != nil }
        set {
            if !newValue {
                reportTarget = nil
            }
        }
    }

    /// The finished answer the action bar acts on: the last message, when nothing is streaming.
    var actionableAnswer: ThreadMessage? {
        guard !engine.isBusy, let last = engine.messages.last, last.isCompletedAnswer else { return nil }
        return last
    }

    /// The last answer failed because today's answers are used up.
    var isAtDailyLimit: Bool {
        guard let last = engine.messages.last, last.state.isFailed else { return false }
        if case .dailyLimit(_)? = engine.lastError {
            return true
        }
        return false
    }

    /// Whether "Try again" makes sense on the failed last answer.
    var canRetryLast: Bool {
        engine.lastError?.isRetryable ?? true
    }

    var placeholder: String {
        if pendingSummarize, pastedContext == nil {
            return "Paste the conversation to summarize…"
        }
        if pastedContext == nil, engine.messages.isEmpty {
            switch composerStyle {
            case .reply: return "What did they say? Paste or type it…"
            case .explain: return "What should Nimbus explain?"
            case .factcheck: return "What claim should Nimbus check?"
            case .default, .short, .funny, .formal: break
            }
        }
        return engine.messages.isEmpty ? "Ask anything…" : "Ask a follow-up…"
    }

    // MARK: - Lifecycle (from MessagesViewController)

    func becomeActive(selectedMessageURL: URL?, style: MSMessagesAppPresentationStyle) {
        presentationStyle = style
        session.reload()
        // Tapping a bubble opens the extension expanded with `selectedMessage` set; from the
        // drawer it opens compact and any stale selection is ignored.
        if style == .expanded, let selectedMessageURL {
            openCard(from: selectedMessageURL)
        }
        let session = self.session
        Task {
            await session.refreshUsage()
        }
    }

    func resignActive() {
        engine.cancel()
        reportTarget = nil
        wantsComposerFocus = false
        focusAfterExpand = false
        endDelivery()
        dismissToast()
    }

    func willTransition(to style: MSMessagesAppPresentationStyle) {
        presentationStyle = style
    }

    func didTransition(to style: MSMessagesAppPresentationStyle) {
        presentationStyle = style
        guard style == .expanded else {
            focusAfterExpand = false
            return
        }
        if focusAfterExpand || (engine.messages.isEmpty && receivedCard == nil && canAsk) {
            wantsComposerFocus = true
        }
        focusAfterExpand = false
    }

    /// The person tapped Send on something staged in the message field (or a direct send began).
    func didStartSending() {
        dismissToast()
    }

    // MARK: - Presentation

    /// Asks Messages for the expanded view (compact mode has no keyboard).
    func expand(focusComposer: Bool) {
        if presentationStyle == .expanded {
            if focusComposer {
                wantsComposerFocus = true
            }
            return
        }
        focusAfterExpand = focusComposer
        requestPresentation?(.expanded)
    }

    func collapse() {
        guard presentationStyle == .expanded else { return }
        requestPresentation?(.compact)
    }

    func close() {
        dismissExtension?()
    }

    func open(_ url: URL) {
        openURLHandler?(url)
    }

    // MARK: - Compact actions

    /// The compact prompt bar: expand and bring up the keyboard.
    func startTyping() {
        pendingSummarize = false
        expand(focusComposer: true)
    }

    /// A quick-action chip. With a pasted chat it runs right away and expands to show the
    /// answer streaming; without one it expands with the style picked and the keyboard up.
    func run(_ action: QuickAction) {
        guard canAsk else {
            wantsSignIn = true
            return
        }
        if let context = pastedContext {
            fullCardTask?.cancel()
            receivedCard = nil
            engine.reset()
            composerStyle = action.style
            pendingSummarize = false
            engine.ask(action.prompt, style: action.style, context: context)
            expand(focusComposer: false)
        } else {
            composerStyle = action.style
            pendingSummarize = action == .summarize
            expand(focusComposer: true)
        }
    }

    /// Text from the Paste button (no paste-permission alert).
    func receivePaste(_ strings: [String]) {
        let text = strings.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            showToast("Nothing to paste. Copy some messages first.", systemImage: "doc.on.clipboard")
            return
        }
        // The latest messages matter most for a reply, so a very long chat keeps its end.
        pastedContext = Self.keepingEnd(text, maxUTF16: TextLimit.chatContent)
        pasteTick += 1
        if text.utf16.count > TextLimit.chatContent {
            showToast("That's a long chat. Nimbus will read the most recent part.", systemImage: "scissors")
        }
    }

    func clearPastedContext() {
        pastedContext = nil
        // Detach it from the current thread too, keeping the messages.
        if engine.context != nil, !engine.isBusy {
            engine.load(engine.messages, style: engine.style, context: nil)
        }
    }

    func openRecent(_ recent: RecentAnswer) {
        fullCardTask?.cancel()
        receivedCard = nil
        pendingSummarize = false
        draft = ""
        composerStyle = .default
        engine.load(Self.thread(question: recent.question, answer: recent.answer, answerID: recent.id, date: recent.date))
        if let cardID = recent.cardID, let host = recent.cardHost {
            cards.seed(PreparedCard(id: cardID, host: host), for: recent.id)
        } else if canAsk {
            cards.prefetch(answerID: recent.id, question: recent.question, answer: recent.answer)
        }
        expand(focusComposer: false)
    }

    // MARK: - Composer

    func submitDraft() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard canAsk else {
            wantsSignIn = true
            return
        }
        if pendingSummarize, pastedContext == nil {
            // What they typed is the conversation to summarize.
            engine.ask(QuickAction.summarize.prompt, style: QuickAction.summarize.style, context: text)
        } else {
            engine.ask(text, style: composerStyle, context: pastedContext)
        }
        pendingSummarize = false
        draft = ""
    }

    func newChat() {
        fullCardTask?.cancel()
        engine.reset()
        receivedCard = nil
        pastedContext = nil
        pendingSummarize = false
        draft = ""
        composerStyle = .default
        wantsSignIn = false
        if canAsk {
            wantsComposerFocus = true
        }
    }

    /// Called when an answer finishes streaming: remember it and get its card ready.
    func answerDidFinish() {
        guard let answer = engine.messages.last, answer.isCompletedAnswer else { return }
        let question = askedQuestion(for: answer)
        recents.add(RecentAnswer(id: answer.id, question: question, answer: answer.text))
        if session.isSignedIn {
            cards.prefetch(answerID: answer.id, question: question, answer: answer.text)
        }
    }

    // MARK: - Thread actions

    func copy(_ message: ThreadMessage) {
        UIPasteboard.general.string = message.text
        showToast("Copied", systemImage: "doc.on.doc")
    }

    func retry(_ message: ThreadMessage) {
        guard engine.messages.last?.id == message.id else { return }
        engine.retry()
    }

    func regenerate() {
        engine.regenerate()
    }

    func rewrite(_ kind: RewriteKind) {
        engine.rewrite(kind)
    }

    func requestReport(_ message: ThreadMessage) {
        reportTarget = message
    }

    func report(_ message: ThreadMessage, reason: ReportReason) {
        reportTarget = nil
        guard session.isSignedIn else {
            showToast("Sign in to Nimbus to report answers.", systemImage: "person.crop.circle.badge.exclamationmark")
            return
        }
        Task {
            do {
                try await self.engine.report(message, reason: reason)
                self.showToast("Thanks for reporting. Reports are reviewed within 24 hours.", systemImage: "checkmark.shield")
            } catch {
                let text = NimbusError.from(error)?.errorDescription ?? "Couldn't send the report. Try again?"
                self.showToast(text, systemImage: "exclamationmark.triangle")
            }
        }
    }

    // MARK: - Send / Card / Insert

    /// Send as a normal text bubble. Called straight from the tap, because iOS only allows a
    /// direct send right after a touch; falls back to `insertText` when iOS refuses.
    func send(_ answer: ThreadMessage) {
        guard !isDelivering else { return }
        guard let conversation = conversationProvider?() else {
            showToast(Self.noConversationText, systemImage: "exclamationmark.triangle")
            return
        }
        sendTick += 1
        isDelivering = true
        let text = answer.text
        conversation.sendText(text) { @Sendable (error: (any Error)?) in
            Task { @MainActor in
                await self.textSendFinished(text, error: error, note: nil)
            }
        }
    }

    /// Put the answer in the message field to edit, then collapse.
    func insert(_ answer: ThreadMessage) {
        guard !isDelivering else { return }
        guard let conversation = conversationProvider?() else {
            showToast(Self.noConversationText, systemImage: "exclamationmark.triangle")
            return
        }
        isDelivering = true
        conversation.insertText(answer.text) { @Sendable (error: (any Error)?) in
            Task { @MainActor in
                self.insertFinished(error: error)
            }
        }
    }

    /// Send as a card bubble. Instant when the card was prefetched; otherwise the card is made
    /// first (and Messages may then stage it instead of sending). Falls back to a text when no
    /// card can be made.
    func sendCard(_ answer: ThreadMessage) {
        guard !isDelivering else { return }
        let question = askedQuestion(for: answer)
        let text = answer.text
        sendTick += 1
        isDelivering = true

        if case .ready(let card)? = cards.status(for: answer.id),
           let message = cards.makeMessage(card: card, question: question, answer: text),
           let conversation = conversationProvider?() {
            pendingCardMessage = message
            conversation.send(message) { @Sendable (error: (any Error)?) in
                Task { @MainActor in
                    await self.cardSendFinished(error: error, fallbackText: text)
                }
            }
            return
        }

        cardInFlight = answer.id
        let answerID = answer.id
        Task {
            await self.prepareAndDeliverCard(answerID: answerID, question: question, answer: text)
        }
    }

    private func textSendFinished(_ text: String, error: (any Error)?, note: String?) async {
        guard error != nil else {
            endDelivery()
            if let note {
                showToast(note, systemImage: "text.bubble")
            }
            collapse()
            return
        }
        await insertTextFallback(text, note: note)
        endDelivery()
    }

    private func insertFinished(error: (any Error)?) {
        endDelivery()
        if error == nil {
            showToast("Added to your message. Edit it, then tap ↑ to send.", systemImage: "pencil")
            collapse()
        } else {
            showToast("Couldn't add that to the message field. Try Copy instead.", systemImage: "exclamationmark.triangle")
        }
    }

    private func cardSendFinished(error: (any Error)?, fallbackText: String) async {
        guard error != nil else {
            endDelivery()
            collapse()
            return
        }
        if let message = pendingCardMessage {
            await insertCard(message, fallbackText: fallbackText)
        } else {
            await sendTextInstead(fallbackText, lead: "Couldn't send the card")
        }
        endDelivery()
    }

    private func prepareAndDeliverCard(answerID: UUID, question: String, answer: String) async {
        let result = await cards.prepare(answerID: answerID, question: question, answer: answer)
        cardInFlight = nil
        switch result {
        case .success(let card):
            guard let message = cards.makeMessage(card: card, question: question, answer: answer) else {
                await sendTextInstead(answer, lead: "Couldn't draw the card")
                endDelivery()
                return
            }
            guard let conversation = conversationProvider?() else {
                showToast(Self.noConversationText, systemImage: "exclamationmark.triangle")
                endDelivery()
                return
            }
            do {
                try await ConversationBridge.send(message, in: conversation)
                collapse()
            } catch {
                // The wait for the network usually used up the tap: stage it instead.
                await insertCard(message, fallbackText: answer)
            }
        case .failure(let error):
            await sendTextInstead(answer, lead: Self.cardFailureLead(error))
        }
        endDelivery()
    }

    private func insertCard(_ message: MSMessage, fallbackText: String) async {
        guard let conversation = conversationProvider?() else {
            showToast(Self.noConversationText, systemImage: "exclamationmark.triangle")
            return
        }
        do {
            try await ConversationBridge.insert(message, in: conversation)
            showToast("Your card is in the message field. Tap ↑ to send.", systemImage: "arrow.up.circle")
            collapse()
        } catch {
            await sendTextInstead(fallbackText, lead: "Couldn't add the card")
        }
    }

    /// The card fallback: send the answer as a text (or stage it when iOS refuses).
    private func sendTextInstead(_ text: String, lead: String) async {
        guard let conversation = conversationProvider?() else {
            showToast(Self.noConversationText, systemImage: "exclamationmark.triangle")
            return
        }
        do {
            try await ConversationBridge.sendText(text, in: conversation)
            showToast("\(lead), so it went as a text.", systemImage: "text.bubble")
            collapse()
        } catch {
            await insertTextFallback(text, note: "\(lead), so it's in the message field as a text.")
        }
    }

    private func insertTextFallback(_ text: String, note: String?) async {
        guard let conversation = conversationProvider?() else {
            showToast(Self.noConversationText, systemImage: "exclamationmark.triangle")
            return
        }
        do {
            try await ConversationBridge.insertText(text, in: conversation)
            let lead = note ?? "It's in the message field."
            showToast("\(lead) Tap ↑ to send.", systemImage: "arrow.up.circle")
            collapse()
        } catch {
            showToast("Couldn't add that to the conversation. Try Copy instead.", systemImage: "exclamationmark.triangle")
        }
    }

    private func endDelivery() {
        isDelivering = false
        cardInFlight = nil
        pendingCardMessage = nil
    }

    private static func cardFailureLead(_ error: NimbusError) -> String {
        switch error {
        case .network:
            return "You seem to be offline"
        case .notSignedIn, .unauthorized:
            return "Cards need you to be signed in"
        case .dailyLimit:
            return "Today's limit is reached"
        default:
            return "Couldn't make a card right now"
        }
    }

    // MARK: - Received cards

    /// Opens a tapped Nimbus card: question and answer as a thread, ready for a follow-up.
    /// Shows the copy carried in the URL right away and fetches the full answer if it was cut.
    func openCard(from url: URL?) {
        guard let url, let payload = CardPayload(url: url) else { return }
        if let current = receivedCard, current.payload.id == payload.id {
            return
        }
        fullCardTask?.cancel()
        let host = Self.hostString(of: url)
        let answerID = UUID()
        engine.load(Self.thread(question: payload.question, answer: payload.answer, answerID: answerID))
        receivedCard = ReceivedCard(payload: payload, host: host, answerID: answerID, loadState: .idle)
        draft = ""
        composerStyle = .default
        pendingSummarize = false
        pastedContext = nil
        wantsSignIn = false
        if let host {
            cards.seed(PreparedCard(id: payload.id, host: host), for: answerID)
        }
        if payload.isTruncated || payload.answer.isEmpty {
            loadFullCard()
        }
    }

    /// Fetches `/c/:id.json` for the open card (also the "Try again" after a failure).
    func loadFullCard() {
        guard let card = receivedCard, let host = card.host else {
            if receivedCard != nil {
                receivedCard?.loadState = .failed
            }
            return
        }
        receivedCard?.loadState = .loading
        let id = card.payload.id
        let answerID = card.answerID
        fullCardTask?.cancel()
        fullCardTask = Task {
            do {
                let detail = try await NimbusClient(credential: nil, host: host).fetchCard(id: id)
                guard !Task.isCancelled else { return }
                self.applyFullCard(detail, answerID: answerID)
            } catch {
                guard !Task.isCancelled else { return }
                self.fullCardFailed(answerID: answerID)
            }
        }
    }

    private func applyFullCard(_ detail: CardDetail, answerID: UUID) {
        guard var card = receivedCard, card.answerID == answerID else { return }
        let question = detail.question.isEmpty ? card.payload.question : detail.question
        let answer = detail.answer.isEmpty ? card.payload.answer : detail.answer
        // Only replace the card's own messages; never a follow-up thread.
        if engine.messages.count <= 2, !engine.isBusy {
            engine.load(Self.thread(question: question, answer: answer, answerID: answerID))
        }
        card.payload = CardPayload(id: card.payload.id, question: question, answer: answer, isTruncated: false)
        card.loadState = .idle
        receivedCard = card
    }

    private func fullCardFailed(answerID: UUID) {
        guard receivedCard?.answerID == answerID else { return }
        receivedCard?.loadState = .failed
    }

    // MARK: - Sign-in and consent

    /// Redeems an invite code from the extension (the keychain is shared with the app).
    /// Only called after the consent box is ticked.
    func signIn(code: String, host: String?) async throws {
        try await session.signIn(code: code, host: host, consentedAt: Date())
        wantsSignIn = false
    }

    /// Records consent for a sign-in saved before consent existed.
    func recordConsent() {
        guard var credential = session.credential else { return }
        credential.consentedAt = Date()
        try? CredentialStore.save(credential)
        session.credential = credential
        wantsSignIn = false
    }

    func signOut() {
        fullCardTask?.cancel()
        engine.reset()
        receivedCard = nil
        pastedContext = nil
        draft = ""
        wantsSignIn = false
        recents.clear()
        session.signOut()
    }

    // MARK: - Toasts

    func showToast(_ text: String, systemImage: String = "info.circle") {
        toastTask?.cancel()
        let toast = ExtensionToast(text: text, systemImage: systemImage)
        self.toast = toast
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(2_800))
            guard !Task.isCancelled, let self, self.toast?.id == toast.id else { return }
            self.toast = nil
        }
    }

    func dismissToast() {
        toastTask?.cancel()
        toastTask = nil
        toast = nil
    }

    // MARK: - Helpers

    /// The question an answer belongs to (for cards, recents and reports).
    func askedQuestion(for answer: ThreadMessage) -> String {
        if let question = answer.question?.trimmingCharacters(in: .whitespacesAndNewlines), !question.isEmpty {
            return question
        }
        guard let index = engine.messages.firstIndex(where: { $0.id == answer.id }) else { return "" }
        return engine.messages[..<index].last(where: { $0.isUser })?.text ?? ""
    }

    /// A question/answer pair as thread messages (empty parts are left out).
    nonisolated static func thread(question: String, answer: String, answerID: UUID, date: Date = Date()) -> [ThreadMessage] {
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAnswer = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        var messages: [ThreadMessage] = []
        if !trimmedQuestion.isEmpty {
            messages.append(ThreadMessage(role: .user, text: trimmedQuestion, createdAt: date))
        }
        if !trimmedAnswer.isEmpty {
            messages.append(ThreadMessage(
                id: answerID,
                role: .assistant,
                text: trimmedAnswer,
                question: trimmedQuestion.isEmpty ? nil : trimmedQuestion,
                createdAt: date
            ))
        }
        return messages
    }

    /// `host[:port]` of a card URL, normalized.
    nonisolated static func hostString(of url: URL) -> String? {
        guard let host = url.host(percentEncoded: false), !host.isEmpty else { return nil }
        if let port = url.port {
            return NimbusConfig.normalizeHost("\(host):\(port)")
        }
        return NimbusConfig.normalizeHost(host)
    }

    /// The longest suffix of `text` whose UTF-16 length is at most `limit`.
    nonisolated static func keepingEnd(_ text: String, maxUTF16 limit: Int) -> String {
        guard text.utf16.count > limit else { return text }
        var kept: [Character] = []
        var used = 0
        for character in text.reversed() {
            let size = character.utf16.count
            if used + size > limit { break }
            kept.append(character)
            used += size
        }
        return String(kept.reversed())
    }
}
