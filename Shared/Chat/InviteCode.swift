import Foundation

/// Invite codes: 8 Crockford base32 characters (0-9, A-Z without I, L, O, U),
/// stored uppercase without a dash and shown as `XXXX-XXXX`.
nonisolated enum InviteCode {
    static let length = 8
    static let alphabet: Set<Character> = Set("0123456789ABCDEFGHJKMNPQRSTVWXYZ")

    /// Separators people type or paste between the halves.
    private static let separators: Set<Character> = ["-", "‐", "‑", "‒", "–", "—", "−", "_", "."]

    /// `" k7qm-2xpa "` → `"K7QM2XPA"`; nil unless it is exactly 8 valid characters.
    static func normalize(_ input: String) -> String? {
        let cleaned = input.uppercased().filter { !$0.isWhitespace && !separators.contains($0) }
        guard cleaned.count == length, cleaned.allSatisfy({ alphabet.contains($0) }) else { return nil }
        return cleaned
    }

    /// `"K7QM2XPA"` → `"K7QM-2XPA"`. Input that isn't a valid code comes back cleaned up but
    /// otherwise unchanged.
    static func format(_ code: String) -> String {
        guard let normalized = normalize(code) else {
            return code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        }
        return "\(normalized.prefix(4))-\(normalized.suffix(4))"
    }

    /// Filters live keyboard/paste input for the code boxes.
    /// - Returns: up to 8 valid characters, and whether anything invalid was dropped
    ///   (so the field can shake). Pasted join links are understood too.
    static func sanitize(_ input: String) -> (code: String, rejected: Bool) {
        if input.contains("://"), let url = URL(string: input.trimmingCharacters(in: .whitespacesAndNewlines)),
           let link = parse(url: url) {
            return (link.code, false)
        }
        var code = ""
        var rejected = false
        for character in input.uppercased() {
            if character.isWhitespace || separators.contains(character) {
                continue
            }
            if alphabet.contains(character) {
                if code.count < length {
                    code.append(character)
                }
            } else {
                rejected = true
            }
        }
        return (code, rejected)
    }

    /// Reads `nimbus://join?code=K7QM-2XPA&host=…`, `nimbus://join/K7QM-2XPA` and the
    /// server's `https://<host>/join/K7QM-2XPA` landing-page links.
    /// - Returns: the normalized code and the server host when the link names one.
    static func parse(url: URL) -> (code: String, host: String?)? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let scheme = components.scheme?.lowercased()
        else { return nil }
        let queryItems = components.queryItems ?? []
        func query(_ name: String) -> String? {
            queryItems.first(where: { $0.name == name })?.value
        }
        let pathParts = components.path.split(separator: "/").map(String.init)

        switch scheme {
        case "nimbus":
            let isJoin = components.host?.lowercased() == "join" || pathParts.first?.lowercased() == "join"
            guard isJoin else { return nil }
            let candidate = query("code") ?? pathParts.last(where: { $0.lowercased() != "join" })
            guard let rawCode = candidate, let code = normalize(rawCode) else { return nil }
            let host = query("host").flatMap { NimbusConfig.normalizeHost($0) }
            return (code, host)
        case "https", "http":
            guard let joinIndex = pathParts.firstIndex(where: { $0.lowercased() == "join" }),
                  joinIndex + 1 < pathParts.count,
                  let code = normalize(pathParts[joinIndex + 1])
            else { return nil }
            let host = query("host").flatMap { NimbusConfig.normalizeHost($0) }
                ?? components.host.flatMap { NimbusConfig.normalizeHost(hostWithPort($0, port: components.port)) }
            return (code, host)
        default:
            return nil
        }
    }

    private static func hostWithPort(_ host: String, port: Int?) -> String {
        guard let port else { return host }
        return "\(host):\(port)"
    }
}
