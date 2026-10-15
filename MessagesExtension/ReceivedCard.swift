import Foundation

/// A Nimbus card someone sent into the conversation, opened by tapping its bubble.
nonisolated struct ReceivedCard: Equatable, Sendable {
    nonisolated enum LoadState: Equatable, Sendable {
        /// The full answer is showing.
        case idle
        /// The message URL carried a shortened answer; fetching `/c/:id.json`.
        case loading
        /// The fetch failed; the shortened answer (if any) is still showing.
        case failed
    }

    var payload: CardPayload
    /// The server that made the card (`host[:port]` from the message URL).
    var host: String?
    /// Id of the answer bubble in the thread.
    var answerID: UUID
    var loadState: LoadState
}
