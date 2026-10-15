import Foundation
import Messages

/// Async wrappers around `MSConversation`'s send and insert calls, for the fallback paths that
/// run after an `await`.
///
/// Messages calls the completion handlers on a background queue, so the `@Sendable` closures
/// below only resume a continuation; callers stay on the main actor. The first send after a
/// tap is made synchronously from the tap itself (see `MessagesModel`), because `send*` only
/// works right after a touch while the extension is visible. These wrappers are used for the
/// `insert*` fallbacks and for sends that had to wait for the network.
enum ConversationBridge {
    /// `sendText`: a normal text bubble, sent without another tap. Throws
    /// `sendWithoutRecentInteraction` / `sendWhileNotVisible` when iOS refuses.
    static func sendText(_ text: String, in conversation: MSConversation) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            conversation.sendText(text) { @Sendable (error: (any Error)?) in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// `insertText`: puts the text in the message field for the person to edit and send.
    static func insertText(_ text: String, in conversation: MSConversation) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            conversation.insertText(text) { @Sendable (error: (any Error)?) in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// `send(_:)` for a card bubble.
    static func send(_ message: MSMessage, in conversation: MSConversation) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            conversation.send(message) { @Sendable (error: (any Error)?) in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// `insert(_:)` for a card bubble: stages it in the message field.
    static func insert(_ message: MSMessage, in conversation: MSConversation) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            conversation.insert(message) { @Sendable (error: (any Error)?) in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
