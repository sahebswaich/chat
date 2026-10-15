import Foundation

/// Build-time configuration read from the target's Info.plist, plus host helpers.
nonisolated enum NimbusConfig {
    /// The server host baked into the build (`NimbusAPIHost`), or nil when the build
    /// still carries the placeholder / an unexpanded build setting.
    static var defaultHost: String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "NimbusAPIHost") as? String else {
            return nil
        }
        return usableHost(raw)
    }

    /// The shared keychain access group (`NimbusKeychainGroup`), or nil when it is
    /// missing or was not expanded (for example an unsigned build without a team).
    static var keychainGroup: String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "NimbusKeychainGroup") as? String else {
            return nil
        }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !value.contains("$("), !value.hasPrefix(".") else { return nil }
        return value
    }

    /// `https://<host>` for a host the user typed or that came from Info.plist.
    /// Accepts input with or without a scheme, path or trailing slash.
    static func baseURL(for host: String) -> URL? {
        guard let normalized = normalizeHost(host) else { return nil }
        return URL(string: "https://\(normalized)")
    }

    /// Lowercased `host[:port]` with any scheme, path, query or trailing slash removed,
    /// or nil when the input can't be a host name.
    static func normalizeHost(_ input: String) -> String? {
        var value = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if value.hasPrefix("https://") {
            value.removeFirst("https://".count)
        } else if value.hasPrefix("http://") {
            value.removeFirst("http://".count)
        }
        if let end = value.firstIndex(where: { $0 == "/" || $0 == "?" || $0 == "#" }) {
            value = String(value[..<end])
        }
        while value.hasSuffix(".") {
            value.removeLast()
        }
        guard !value.isEmpty,
              value.allSatisfy({ hostCharacters.contains($0) }),
              let first = value.first,
              first != ".", first != "-", first != ":"
        else { return nil }
        return value
    }

    /// Info.plist host values that are placeholders or unexpanded are ignored.
    static func usableHost(_ raw: String) -> String? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty,
              !value.contains("$("),
              !value.lowercased().contains("example")
        else { return nil }
        return normalizeHost(value)
    }

    /// `Nimbus/1.0 (42; iOS; messages)`
    static let userAgent: String = {
        let info = Bundle.main.infoDictionary ?? [:]
        let version = info["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info["CFBundleVersion"] as? String ?? "1"
        return "Nimbus/\(version) (\(build); iOS; \(targetName))"
    }()

    /// Which binary this code is running in.
    static var targetName: String {
        #if NIMBUS_APP
        return "app"
        #elseif NIMBUS_MESSAGES_EXTENSION
        return "messages"
        #elseif NIMBUS_WIDGETS
        return "widgets"
        #elseif NIMBUS_TESTS
        return "tests"
        #else
        return "unknown"
        #endif
    }

    private static let hostCharacters: Set<Character> = Set("abcdefghijklmnopqrstuvwxyz0123456789.-:")
}
