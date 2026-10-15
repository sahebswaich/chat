import Foundation

/// Text the Live Activity views show for a state.
extension NimbusActivityAttributes.ContentState {
    /// Still thinking, searching or writing, and recently updated.
    nonisolated func isWorking(isStale: Bool) -> Bool {
        !phase.isFinished && !isStale
    }

    /// The phase line, or a nudge when an unfinished answer stopped updating.
    nonisolated func headline(isStale: Bool) -> String {
        if isStale && !phase.isFinished {
            return "Open Nimbus to see the answer"
        }
        return phase.title
    }

    /// The answer so far, or a placeholder while there's no text yet.
    nonisolated var previewText: String {
        if !preview.isEmpty {
            return preview
        }
        switch phase {
        case .thinking: return "Nimbus is thinking about your question…"
        case .searching: return "Looking things up on the web…"
        case .writing: return "Writing the answer…"
        case .done: return "Your answer is ready in Nimbus."
        case .failed: return "Open Nimbus to try again."
        }
    }

    /// "1 word" / "42 words".
    nonisolated var wordCountText: String {
        wordCount == 1 ? "1 word" : "\(wordCount) words"
    }
}
