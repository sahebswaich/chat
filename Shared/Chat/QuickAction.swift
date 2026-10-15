import Foundation

/// The chips that run on pasted conversation text in the iMessage extension
/// (`[💬 Reply for me] [🧠 Explain] [✅ Fact-check] [😂 Funny] [📝 Summarize]`).
///
/// Each maps to a server `ChatStyle` plus the user turn to send alongside the context.
/// Summarize isn't a server style: it sends `.default` with "Summarize this conversation".
nonisolated enum QuickAction: String, CaseIterable, Identifiable, Sendable {
    case reply
    case explain
    case factcheck
    case funny
    case summarize

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reply: return "Reply for me"
        case .explain: return "Explain"
        case .factcheck: return "Fact-check"
        case .funny: return "Funny"
        case .summarize: return "Summarize"
        }
    }

    var emoji: String {
        switch self {
        case .reply: return "💬"
        case .explain: return "🧠"
        case .factcheck: return "✅"
        case .funny: return "😂"
        case .summarize: return "📝"
        }
    }

    /// SF Symbol name.
    var systemImage: String {
        switch self {
        case .reply: return "arrowshape.turn.up.left"
        case .explain: return "lightbulb"
        case .factcheck: return "checkmark.seal"
        case .funny: return "face.smiling"
        case .summarize: return "text.alignleft"
        }
    }

    var style: ChatStyle {
        switch self {
        case .reply: return .reply
        case .explain: return .explain
        case .factcheck: return .factcheck
        case .funny: return .funny
        case .summarize: return .default
        }
    }

    /// The user turn sent with the pasted context.
    var prompt: String {
        switch self {
        case .reply: return ChatStyle.reply.contextPrompt
        case .explain: return ChatStyle.explain.contextPrompt
        case .factcheck: return ChatStyle.factcheck.contextPrompt
        case .funny: return "Write a funny reply to this."
        case .summarize: return "Summarize this conversation"
        }
    }
}
