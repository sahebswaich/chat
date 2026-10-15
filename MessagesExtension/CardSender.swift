import Foundation
import Messages
import UIKit

/// A card the server knows about: enough to build its `MSMessage.url`.
nonisolated struct PreparedCard: Equatable, Sendable {
    var id: String
    /// Server host (`host[:port]`) the card lives on.
    var host: String
}

/// Creates Nimbus card bubbles.
///
/// Card ids are created ahead of time (`prefetch`) as soon as an answer finishes, because iOS
/// only allows a direct send right after a tap: waiting for `POST /v1/cards` after the tap
/// would make the send fail and fall back to an insert.
final class CardSender {
    nonisolated enum Status: Equatable, Sendable {
        case preparing
        case ready(PreparedCard)
        case failed(NimbusError)
    }

    /// Called on the main actor when a card id arrives for an answer.
    var onPrepared: (@MainActor (UUID, PreparedCard) -> Void)?

    /// Only the newest few answers keep a card.
    static let maxCached = 6

    private var statuses: [UUID: Status] = [:]
    private var tasks: [UUID: Task<Status, Never>] = [:]
    private var order: [UUID] = []
    private let makeClient: @MainActor () -> NimbusClient

    init(client: @escaping @MainActor () -> NimbusClient = { NimbusClient(credential: NimbusSession.shared.credential) }) {
        self.makeClient = client
    }

    func status(for answerID: UUID) -> Status? {
        statuses[answerID]
    }

    /// The card is already known (a received card, or a recent answer that has one).
    func seed(_ card: PreparedCard, for answerID: UUID) {
        tasks[answerID]?.cancel()
        tasks[answerID] = nil
        statuses[answerID] = .ready(card)
        remember(answerID)
    }

    /// Starts creating a card for an answer in the background, unless one exists or is on its way.
    func prefetch(answerID: UUID, question: String, answer: String) {
        switch statuses[answerID] {
        case .preparing?, .ready?:
            return
        case .failed?, nil:
            start(answerID: answerID, question: question, answer: answer)
        }
    }

    /// The card for an answer: immediately when prefetched, otherwise after waiting for (or
    /// retrying) the request.
    func prepare(answerID: UUID, question: String, answer: String) async -> Result<PreparedCard, NimbusError> {
        if case .ready(let card)? = statuses[answerID] {
            return .success(card)
        }
        if tasks[answerID] == nil {
            start(answerID: answerID, question: question, answer: answer)
        }
        guard let task = tasks[answerID] else {
            if case .failed(let error)? = statuses[answerID] {
                return .failure(error)
            }
            return .failure(.notSignedIn)
        }
        switch await task.value {
        case .ready(let card):
            return .success(card)
        case .failed(let error):
            return .failure(error)
        case .preparing:
            return .failure(.badResponse)
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

    private func start(answerID: UUID, question: String, answer: String) {
        let client = makeClient()
        guard client.credential != nil, let host = client.resolvedHost else {
            statuses[answerID] = .failed(.notSignedIn)
            return
        }
        statuses[answerID] = .preparing
        remember(answerID)
        let task = Task<Status, Never> { [weak self] in
            let status: Status
            do {
                let response = try await client.createCard(question: question, answer: answer)
                if CardPayload.isValidID(response.id) {
                    status = .ready(PreparedCard(id: response.id, host: host))
                } else {
                    status = .failed(.badResponse)
                }
            } catch {
                status = .failed(NimbusError.from(error) ?? .network("The card request was cancelled."))
            }
            self?.finish(answerID, with: status)
            return status
        }
        tasks[answerID] = task
    }

    private func finish(_ answerID: UUID, with status: Status) {
        tasks[answerID] = nil
        // Evicted (or replaced by a seeded card) while the request was in flight.
        guard case .preparing? = statuses[answerID] else { return }
        statuses[answerID] = status
        if case .ready(let card) = status {
            onPrepared?(answerID, card)
        }
    }

    private func remember(_ answerID: UUID) {
        order.removeAll { $0 == answerID }
        order.append(answerID)
        while order.count > Self.maxCached {
            let evicted = order.removeFirst()
            tasks[evicted]?.cancel()
            tasks[evicted] = nil
            statuses[evicted] = nil
        }
    }

    private static func clipped(_ text: String, to length: Int) -> String {
        guard text.count > length else { return text }
        return String(text.prefix(max(length - 1, 0))).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }
}
