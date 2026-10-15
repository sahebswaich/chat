#if canImport(ActivityKit)
import ActivityKit
import Foundation

/// Live Activity shown on the Lock Screen / Dynamic Island while the app streams an answer.
nonisolated struct NimbusActivityAttributes: ActivityAttributes, Sendable {
    nonisolated struct ContentState: Codable, Hashable, Sendable {
        nonisolated enum Phase: String, Codable, Hashable, Sendable {
            case thinking
            case searching
            case writing
            case done
            case failed

            var title: String {
                switch self {
                case .thinking: return "Thinking…"
                case .searching: return "Searching the web…"
                case .writing: return "Writing…"
                case .done: return "Answer ready"
                case .failed: return "Something went wrong"
                }
            }

            /// SF Symbol name.
            var systemImage: String {
                switch self {
                case .thinking: return "sparkles"
                case .searching: return "globe"
                case .writing: return "ellipsis.bubble"
                case .done: return "checkmark.circle.fill"
                case .failed: return "exclamationmark.triangle.fill"
                }
            }

            var isFinished: Bool {
                self == .done || self == .failed
            }
        }

        var phase: Phase
        /// The latest bit of the answer (keep it short; Live Activity payloads are small).
        var preview: String
        var wordCount: Int

        init(phase: Phase, preview: String = "", wordCount: Int = 0) {
            self.phase = phase
            self.preview = preview
            self.wordCount = wordCount
        }
    }

    var question: String

    init(question: String) {
        self.question = question
    }
}

extension NimbusActivityAttributes.ContentState {
    /// State for an answer in progress: the tail of the text (≤ 120 characters) as the preview.
    nonisolated init(phase: Phase, answer: String) {
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = trimmed.split(whereSeparator: { $0.isWhitespace }).count
        let preview = trimmed.count > 120 ? "…" + String(trimmed.suffix(119)) : trimmed
        self.init(phase: phase, preview: preview, wordCount: words)
    }
}

extension NimbusActivityAttributes.ContentState.Phase {
    /// The Live Activity phase for a `ChatEngine` phase (nil while idle).
    nonisolated init?(_ phase: ChatPhase) {
        switch phase {
        case .idle: return nil
        case .thinking: self = .thinking
        case .searching: self = .searching
        case .writing: self = .writing
        case .done: self = .done
        case .failed: self = .failed
        }
    }
}
#endif
