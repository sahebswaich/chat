import Foundation
import Messages
import UIKit

/// A card the server knows about: enough to build its `MSMessage.url`.
nonisolated struct PreparedCard: Equatable, Sendable {
    var id: String
    /// Server host (`host[:port]`) the card lives on.
    var host: String
}

/// A card ready to go into a bubble, and whether it still has to be uploaded.
nonisolated struct CardForSending: Sendable {
    var card: PreparedCard
    var isNew: Bool
}

/// Creates Nimbus card bubbles.
///
/// iOS only allows a direct send right after a tap, so the card can't wait for the server: on
/// the Card tap the app picks the card id itself (`CardPayload.newID()`), sends the bubble at
/// once, and uploads the card (`POST /v1/cards` with that id) in the background, retrying a few
/// times. Nothing is stored on the server for answers that are never sent as a card.
final class CardSender {
    nonisolated enum Status: Equatable, Sendable {
        case ready(PreparedCard)
    }

    /// Called on the main actor when an answer gets a card id (so Recents can reuse it).
    var onPrepared: (@MainActor (UUID, PreparedCard) -> Void)?
    /// Called on the main actor when a sent card couldn't be uploaded after retrying.
    var onUploadFailed: (@MainActor (NimbusError) -> Void)?

    /// Only the newest few answers keep a card.
    static let maxCached = 6
    /// Delays before each upload retry.
    static let retryDelays: [Duration] = [.seconds(1), .seconds(3), .seconds(8)]

    private var statuses: [UUID: Status] = [:]
    private var order: [UUID] = []
    private var uploads: [UUID: Task<Void, Never>] = [:]
    private let makeClient: @MainActor () -> NimbusClient

    init(client: @escaping @MainActor () -> NimbusClient = { NimbusClient(credential: NimbusSession.shared.credential) }) {
        self.makeClient = client
    }

    func status(for answerID: UUID) -> Status? {
        statuses[answerID]
    }

    /// The card is already on a server (a received card, or a recent answer that has one).
    func seed(_ card: PreparedCard, for answerID: UUID) {
        statuses[answerID] = .ready(card)
        remember(answerID)
    }

    /// The card to put in the bubble right now: the known one, or a new id on the signed-in
    /// server. Nil when signed out.
    func cardForSending(answerID: UUID) -> CardForSending? {
        if case .ready(let card)? = statuses[answerID] {
            return CardForSending(card: card, isNew: false)
        }
        let client = makeClient()
        guard client.credential != nil, let host = client.resolvedHost else { return nil }
        let card = PreparedCard(id: CardPayload.newID(), host: host)
        statuses[answerID] = .ready(card)
        remember(answerID)
        onPrepared?(answerID, card)
        return CardForSending(card: card, isNew: true)
    }

    /// Uploads a newly made card in the background so its link works on Macs and for
    /// truncated answers. Retries on network trouble; reports a final failure.
    func upload(_ card: PreparedCard, answerID: UUID, question: String, answer: String) {
        guard uploads[answerID] == nil else { return }
        let client = makeClient()
        uploads[answerID] = Task { [weak self] in
            var lastError = NimbusError.network("Couldn't reach Nimbus.")
            for attempt in 0...Self.retryDelays.count {
                if attempt > 0 {
                    try? await Task.sleep(for: Self.retryDelays[attempt - 1])
                }
                if Task.isCancelled { return }
                do {
                    _ = try await client.createCard(id: card.id, question: question, answer: answer)
                    self?.uploads[answerID] = nil
                    return
                } catch {
                    guard let mapped = NimbusError.from(error) else { return } // cancelled
                    lastError = mapped
                    if !mapped.isRetryable { break }
                }
            }
            self?.uploads[answerID] = nil
            self?.onUploadFailed?(lastError)
        }
    }

    /// The bubble: a rendered card image with caption = question and subcaption "Nimbus", and
    /// the card page URL (`https://<host>/c/<id>?q=…&a=…&v=1`) for Mac/Watch readers and for
    /// reopening it in the extension. Nil if the URL or image can't be made.
    func makeMessage(card: PreparedCard, question: String, answer: String) -> MSMessage? {
        let url = CardPayload(id: card.id, question: question, answer: answer).url(host: card.host)
        guard url.scheme?.lowercased() == "https", url.absoluteString.count <= 5_000 else { return nil }
        guard let image = CardSnapshotView.renderImage(question: question, answer: answer) else { return nil }

        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAnswer = answer.trimmingCharacters(in: .whitespacesAndNewlines)

        let layout = MSMessageTemplateLayout()
        layout.image = image
        layout.caption = Self.clipped(trimmedQuestion.isEmpty ? trimmedAnswer : trimmedQuestion, to: 100)
        layout.subcaption = "Nimbus"

        let message = MSMessage(session: MSSession())
        message.url = url
        message.layout = layout
        message.summaryText = trimmedQuestion.isEmpty
            ? "Nimbus answer"
            : "Nimbus: \(Self.clipped(trimmedQuestion, to: 100))"
        message.accessibilityLabel = trimmedQuestion.isEmpty
            ? "Nimbus card. \(Self.clipped(trimmedAnswer, to: 300))"
            : "Nimbus card. \(Self.clipped(trimmedQuestion, to: 200)). \(Self.clipped(trimmedAnswer, to: 300))"
        return message
    }

    // MARK: - Private

    private func remember(_ answerID: UUID) {
        order.removeAll { $0 == answerID }
        order.append(answerID)
        while order.count > Self.maxCached {
            let evicted = order.removeFirst()
            statuses[evicted] = nil
        }
    }

    private static func clipped(_ text: String, to length: Int) -> String {
        guard text.count > length else { return text }
        return String(text.prefix(max(length - 1, 0))).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }
}
