import Foundation

/// Server-side length limits. The server measures JavaScript `string.length`, i.e. UTF-16
/// code units, so text is clipped by UTF-16 count (never splitting a character).
nonisolated enum TextLimit {
    /// Each `messages[].content` and the `context` of `POST /v1/chat`.
    static let chatContent = 20_000
    /// At most this many turns in `messages`.
    static let chatTurns = 40
    /// `POST /v1/cards` question.
    static let cardQuestion = 2_000
    /// `POST /v1/cards` answer, `POST /v1/report` answer and messages.
    static let cardAnswer = 20_000
    /// `POST /v1/report` reason.
    static let reportReason = 1_000

    /// The longest prefix of `text` whose UTF-16 length is at most `limit`.
    static func clip(_ text: String, maxUTF16 limit: Int) -> String {
        guard text.utf16.count > limit else { return text }
        var result = ""
        var used = 0
        for character in text {
            let size = character.utf16.count
            if used + size > limit { break }
            result.append(character)
            used += size
        }
        return result
    }
}
