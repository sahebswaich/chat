import Foundation

/// The question/answer carried in a Nimbus card's `MSMessage.url`:
/// `https://<host>/c/<id>?q=<question ≤ 280 chars>&a=<answer, maybe truncated>&v=1`.
///
/// The whole URL is kept ≤ 4,000 characters (Messages allows 5,000); a trailing `…` on
/// the answer means it was cut and the full text lives at `/c/<id>.json`.
nonisolated struct CardPayload: Equatable, Sendable {
    var id: String
    var question: String
    var answer: String
    /// True when `answer` is a shortened copy (decoded from a URL whose answer ends in `…`).
    var isTruncated: Bool

    static let maxURLLength = 4_000
    static let maxQuestionLength = 280
    static let version = "1"
    static let ellipsis = "…"

    init(id: String, question: String, answer: String, isTruncated: Bool = false) {
        self.id = id
        self.question = question
        self.answer = answer
        self.isTruncated = isTruncated
    }

    /// Builds the card URL for `host`, shortening the question to 280 characters and the
    /// answer until the URL fits in `maxURLLength`.
    func url(host: String) -> URL {
        encode(host: host).url
    }

    /// Like `url(host:)`, also reporting whether the answer had to be shortened.
    func encode(host: String) -> (url: URL, answerTruncated: Bool) {
        let base = NimbusConfig.baseURL(for: host) ?? Self.fallbackBaseURL
        let prefix = base.absoluteString + "/c/" + Self.percentEncode(id) + "?q="

        var shortQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        if shortQuestion.count > Self.maxQuestionLength {
            shortQuestion = Self.truncated(shortQuestion, keeping: Self.maxQuestionLength - 1)
        }
        // Pathological grapheme clusters can make even 280 characters huge once encoded.
        let questionBudget = 1_500
        let encodedQuestion = Self.longestFitting(shortQuestion, encodedBudget: questionBudget).encoded

        let fixedLength = prefix.count + encodedQuestion.count + "&a=".count + "&v=".count + Self.version.count
        let answerBudget = max(Self.maxURLLength - fixedLength, Self.ellipsis.utf8.count * 3)
        let fitted = Self.longestFitting(answer, encodedBudget: answerBudget)

        let string = prefix + encodedQuestion + "&a=" + fitted.encoded + "&v=" + Self.version
        let url = URL(string: string) ?? base
        return (url, fitted.truncated)
    }

    /// Reads a card URL (`/c/<id>` path plus `q`/`a` query items). Returns nil for anything else.
    init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let scheme = components.scheme?.lowercased(),
              scheme == "https" || scheme == "http"
        else { return nil }

        let parts = components.path.split(separator: "/").map(String.init)
        guard let cIndex = parts.firstIndex(of: "c"),
              cIndex + 1 < parts.count
        else { return nil }
        var id = parts[cIndex + 1]
        if id.hasSuffix(".json") {
            id.removeLast(".json".count)
        }
        guard Self.isValidID(id) else { return nil }

        let items = components.queryItems ?? []
        let question = items.first(where: { $0.name == "q" })?.value ?? ""
        let answer = items.first(where: { $0.name == "a" })?.value
        self.init(
            id: id,
            question: question,
            answer: answer ?? "",
            isTruncated: answer == nil || (answer ?? "").hasSuffix(Self.ellipsis)
        )
    }

    /// Server card ids are URL-safe (letters, digits, `-`, `_`).
    static func isValidID(_ id: String) -> Bool {
        !id.isEmpty && id.count <= 128 && id.unicodeScalars.allSatisfy { idCharacters.contains($0) }
    }

    // MARK: - Encoding helpers

    private static let fallbackBaseURL: URL = URL(fileURLWithPath: "/")

    /// RFC 3986 unreserved characters; everything else is percent-encoded (including `+`,
    /// `&` and `=`, so any server-side query parser reads the values back exactly).
    private static let unreserved = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    )

    private static let idCharacters = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
    )

    static func percentEncode(_ text: String) -> String {
        text.addingPercentEncoding(withAllowedCharacters: unreserved) ?? ""
    }

    /// `text`'s first `count` characters, trailing whitespace trimmed, plus `…`.
    private static func truncated(_ text: String, keeping count: Int) -> String {
        let head = String(text.prefix(max(count, 0)))
        var trimmed = head
        while let last = trimmed.last, last.isWhitespace || last.isNewline {
            trimmed.removeLast()
        }
        return trimmed + ellipsis
    }

    /// The longest prefix of `text` (with `…` when shortened) whose percent-encoded form
    /// fits in `encodedBudget` characters.
    private static func longestFitting(_ text: String, encodedBudget: Int) -> (encoded: String, truncated: Bool) {
        let whole = percentEncode(text)
        if whole.count <= encodedBudget {
            return (whole, false)
        }
        let characters = Array(text)
        // Encoded length grows monotonically with the number of characters kept.
        var low = 0
        var high = characters.count - 1
        var best = percentEncode(ellipsis)
        while low <= high {
            let mid = (low + high) / 2
            let candidate = percentEncode(truncated(String(characters[0..<mid]), keeping: mid))
            if candidate.count <= encodedBudget {
                best = candidate
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        return (best, true)
    }
}
