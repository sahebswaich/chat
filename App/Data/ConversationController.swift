import Foundation
import Observation
import SwiftData

/// Owns the app's single `ChatEngine` and keeps it in sync with SwiftData.
///
/// Opening a saved conversation loads it into the engine. Each question is saved right away,
/// and the thread is saved again whenever an answer finishes or fails. Saving is driven by
/// observing the engine, not by a view, so an answer that finishes while the app is in the
/// background is still stored.
@Observable
final class ConversationController {
    /// The engine behind the chat on screen.
    let engine: ChatEngine
    /// The conversation on screen. A fresh id until its first question is saved.
    private(set) var currentID: UUID
    /// Answer style for the next question. It stays on the thread until changed.
    var selectedStyle: ChatStyle = .default
    /// Conversation text pasted for the next question (reply / explain / fact-check).
    private(set) var stagedContext: String? = nil
    /// Goes up when the composer should take focus (see `consumeFocusRequest()`).
    private(set) var focusRequest = 0

    @ObservationIgnored private var wantsFocus = false
    @ObservationIgnored private var pendingDraft: String?
    @ObservationIgnored private var stored: StoredConversation? = nil
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.engine = ChatEngine(surface: .app)
        self.currentID = UUID()
        observeAnswers()
    }

    // MARK: - Reading

    /// Navigation title: the first question, shortened.
    var title: String {
        guard let first = engine.messages.first(where: { $0.isUser }) else { return "New Chat" }
        return Self.title(for: first.text)
    }

    // MARK: - Switching threads

    /// Shows a saved conversation. A streaming answer in the current one is stopped and saved first.
    func open(_ conversation: StoredConversation) {
        guard conversation.id != currentID else { return }
        save(stoppingAnswer: true)
        stored = conversation
        currentID = conversation.id
        stagedContext = nil
        let style = conversation.style
        selectedStyle = style
        engine.load(conversation.messages, style: style, context: conversation.pastedContext)
    }

    /// Starts an empty, unsaved thread, optionally with text waiting in the composer.
    func startNew(focusComposer: Bool, draft: String? = nil) {
        save(stoppingAnswer: true)
        detachCurrent()
        pendingDraft = draft
        if focusComposer || draft != nil {
            requestComposerFocus()
        }
    }

    /// Text to put in the composer with the next focus request (once).
    func consumeDraft() -> String? {
        defer { pendingDraft = nil }
        return pendingDraft
    }

    /// Asks the chat screen to put the keyboard up (now, or as soon as it appears).
    func requestComposerFocus() {
        wantsFocus = true
        focusRequest += 1
    }

    /// True once per focus request.
    func consumeFocusRequest() -> Bool {
        let wanted = wantsFocus
        wantsFocus = false
        return wanted
    }

    // MARK: - Asking

    /// Asks a question in the selected style, with any staged pasted text as context.
    func ask(_ text: String) {
        engine.webSearch = AppSettings.webSearchEnabled
        engine.ask(text, style: selectedStyle, context: stagedContext)
        stagedContext = nil
        save()
    }

    /// Runs the selected style on the staged pasted text with nothing typed.
    func runOnPastedText() {
        ask("")
    }

    func stagePaste(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        stagedContext = trimmed.isEmpty ? nil : trimmed
    }

    func clearStagedPaste() {
        stagedContext = nil
    }

    func rewrite(_ kind: RewriteKind) {
        engine.webSearch = AppSettings.webSearchEnabled
        engine.rewrite(kind)
        save()
    }

    func regenerate() {
        engine.webSearch = AppSettings.webSearchEnabled
        engine.regenerate()
        save()
    }

    /// Stops the answer in flight, keeping what already arrived.
    func stop() {
        engine.cancel()
        save()
    }

    /// Saves the thread as it is now (e.g. when the app leaves the foreground).
    func saveNow() {
        save()
    }

    // MARK: - Deleting

    func delete(_ conversations: [StoredConversation]) {
        guard !conversations.isEmpty else { return }
        for conversation in conversations {
            if conversation.id == currentID {
                detachCurrent()
            }
            modelContext.delete(conversation)
        }
        try? modelContext.save()
    }

    /// Removes every saved conversation (Settings → Delete My Data).
    func deleteAllHistory() {
        detachCurrent()
        let all = (try? modelContext.fetch(FetchDescriptor<StoredConversation>())) ?? []
        for conversation in all {
            modelContext.delete(conversation)
        }
        try? modelContext.save()
    }

    // MARK: - Persistence

    private func detachCurrent() {
        stored = nil
        currentID = UUID()
        stagedContext = nil
        selectedStyle = .default
        engine.reset()
    }

    private func save(stoppingAnswer: Bool = false) {
        if stoppingAnswer, engine.isBusy {
            engine.cancel()
        }
        let messages = engine.messages.map { $0.settled() }
        guard let firstQuestion = messages.first(where: { $0.isUser }) else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(messages) else { return }

        let styleRaw = engine.style.rawValue
        let context = engine.context
        let conversation: StoredConversation
        if let stored {
            let unchanged = stored.messagesData == data
                && stored.styleRaw == styleRaw
                && stored.pastedContext == context
            // Don't bump `updatedAt` (and reorder the sidebar) when nothing changed.
            if unchanged { return }
            conversation = stored
        } else {
            conversation = StoredConversation(id: currentID, title: Self.title(for: firstQuestion.text))
            modelContext.insert(conversation)
            stored = conversation
        }
        conversation.title = Self.title(for: firstQuestion.text)
        conversation.messagesData = data
        conversation.preview = Self.preview(for: messages)
        conversation.styleRaw = styleRaw
        conversation.pastedContext = context
        conversation.updatedAt = Date()
        try? modelContext.save()
    }

    /// Saves whenever an answer finishes or fails, wherever the app is.
    /// (The controller lives as long as the app, so capturing it strongly is fine.)
    private func observeAnswers() {
        withObservationTracking {
            _ = engine.completionTick
            _ = engine.errorTick
        } onChange: {
            // Called just before the change; hop so the save sees the finished message.
            Task { @MainActor in
                self.answerSettled()
            }
        }
    }

    private func answerSettled() {
        save()
        observeAnswers()
    }

    // MARK: - Text helpers

    /// The first non-empty line of a question, at most 60 characters.
    nonisolated static func title(for question: String) -> String {
        let firstLine = question
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first(where: { !$0.isEmpty }) ?? ""
        guard !firstLine.isEmpty else { return "New Chat" }
        guard firstLine.count > 60 else { return firstLine }
        return String(firstLine.prefix(59)).trimmingCharacters(in: .whitespaces) + "…"
    }

    /// The latest finished answer flattened to one line without Markdown marks, for the sidebar.
    nonisolated static func preview(for messages: [ThreadMessage]) -> String {
        guard let answer = messages.last(where: { $0.isCompletedAnswer }) else { return "" }
        let markup: Set<Character> = ["*", "#", "`"]
        let flat = answer.text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .filter { !markup.contains($0) }
        return String(flat.prefix(160))
    }
}
