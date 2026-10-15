import Foundation
import Observation

/// Hand-off point for "open the app and do X" requests coming from URLs, App Intents and
/// controls. Screens observe `pending`, act on it, then clear it.
@Observable
final class NimbusRouter {
    static let shared = NimbusRouter()

    nonisolated enum Pending: Equatable, Sendable {
        /// Open a fresh question with the keyboard up.
        case newQuestion
        /// Ask this right away.
        case ask(String)
        /// Fill in (and redeem) an invite code.
        case join(code: String, host: String?)
    }

    var pending: Pending?

    init() {}

    /// Handles `nimbus://join?code=…&host=…`, `nimbus://ask?q=…`, `nimbus://new` and
    /// `https://<host>/join/<code>` links.
    /// - Returns: true when the URL was a Nimbus link.
    @discardableResult
    func handle(url: URL) -> Bool {
        if let join = InviteCode.parse(url: url) {
            pending = .join(code: join.code, host: join.host)
            return true
        }
        guard url.scheme?.lowercased() == "nimbus" else { return false }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        switch components?.host?.lowercased() {
        case "ask"?:
            let question = components?.queryItems?
                .first(where: { $0.name == "q" })?.value?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            pending = question.isEmpty ? .newQuestion : .ask(question)
            return true
        case "new"?, "open"?, nil:
            pending = .newQuestion
            return true
        default:
            return false
        }
    }

    /// Returns the pending request and clears it.
    func consume() -> Pending? {
        let request = pending
        pending = nil
        return request
    }
}
