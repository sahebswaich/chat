import Foundation

/// Server-side answer styles. Raw values are the exact `style` strings in the API contract.
nonisolated enum ChatStyle: String, Codable, Sendable, Hashable, CaseIterable, Identifiable {
    case `default`
    case short
    case funny
    case formal
    case explain
    case reply
    case factcheck

    var id: String { rawValue }

    var title: String {
        switch self {
        case .default: return "Ask"
        case .short: return "Short"
        case .funny: return "Funny"
        case .formal: return "Formal"
        case .explain: return "Explain"
        case .reply: return "Reply for me"
        case .factcheck: return "Fact-check"
        }
    }

    /// SF Symbol name.
    var systemImage: String {
        switch self {
        case .default: return "sparkles"
        case .short: return "scissors"
        case .funny: return "face.smiling"
        case .formal: return "briefcase"
        case .explain: return "lightbulb"
        case .reply: return "arrowshape.turn.up.left"
        case .factcheck: return "checkmark.seal"
        }
    }

    var emoji: String {
        switch self {
        case .default: return "✨"
        case .short: return "✂️"
        case .funny: return "😂"
        case .formal: return "👔"
        case .explain: return "🧠"
        case .reply: return "💬"
        case .factcheck: return "✅"
        }
    }

    /// Styles that work on pasted conversation text (`ChatRequest.context`).
    var needsContext: Bool {
        switch self {
        case .reply, .explain, .factcheck: return true
        case .default, .short, .funny, .formal: return false
        }
    }

    /// The user turn sent when the style runs on pasted context with nothing typed.
    var contextPrompt: String {
        switch self {
        case .default: return "Help me with this conversation."
        case .short: return "Sum this up in a sentence."
        case .funny: return "Say something funny about this."
        case .formal: return "Write a polite, formal reply to this."
        case .explain: return "Explain this simply."
        case .reply: return "Write my reply."
        case .factcheck: return "Fact-check this."
        }
    }
}
