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
#endif
