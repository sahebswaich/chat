import Foundation

/// Lifecycle of a message in a thread. User messages are always `.done`.
nonisolated enum MessageState: Codable, Sendable, Equatable, Hashable {
    /// Request sent, no text yet (typing dots).
    case waiting
    /// The server is searching the web.
    case searching
    /// Text is arriving.
    case streaming
    /// Complete.
    case done
    /// Failed with a message for people.
    case failed(String)

    /// Waiting, searching or streaming.
    var isInProgress: Bool {
        switch self {
        case .waiting, .searching, .streaming: return true
        case .done, .failed: return false
        }
    }

    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }

    var failureMessage: String? {
        if case .failed(let message) = self { return message }
        return nil
    }
}

/// One bubble in a chat thread (any surface). Codable so the app can persist threads.
nonisolated struct ThreadMessage: Identifiable, Equatable, Hashable, Codable, Sendable {
    var id: UUID
    var role: ChatRole
    var text: String
    /// For assistant messages: the question this answers (used for cards and reports).
    var question: String?
    var state: MessageState
    var createdAt: Date

    init(
        id: UUID = UUID(),
        role: ChatRole,
        text: String,
        question: String? = nil,
        state: MessageState = .done,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.question = question
        self.state = state
        self.createdAt = createdAt
    }

    var isUser: Bool { role == .user }
    var isAssistant: Bool { role == .assistant }

    /// A finished assistant answer with text (what Send / Card / Insert act on).
    var isCompletedAnswer: Bool {
        role == .assistant && state == .done && !text.isEmpty
    }

    /// The same message with an in-progress state resolved, for threads restored from disk
    /// after the process died mid-stream.
    func settled() -> ThreadMessage {
        guard state.isInProgress else { return self }
        var copy = self
        copy.state = text.isEmpty ? .failed("This answer didn't finish.") : .done
        return copy
    }
}
