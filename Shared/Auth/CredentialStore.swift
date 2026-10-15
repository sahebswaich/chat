import Foundation
import Security

/// Keychain persistence for the signed-in `Credential`.
///
/// Uses the shared access group (`NimbusConfig.keychainGroup`) so the app and the iMessage
/// extension see the same sign-in. When the keychain refuses for lack of entitlements
/// (`errSecMissingEntitlement`, typical for unsigned simulator builds) it retries without the
/// group and finally falls back to `UserDefaults.standard`.
nonisolated enum CredentialStore {
    static let service = "nimbus.credential"
    static let account = "default"
    static let defaultsKey = "nimbus.credential"

    nonisolated enum StoreError: LocalizedError, Sendable, Equatable {
        case encodingFailed
        case keychain(OSStatus)

        var errorDescription: String? {
            switch self {
            case .encodingFailed:
                return "Couldn't save your sign-in."
            case .keychain(let status):
                return "Couldn't save your sign-in to the keychain (\(status))."
            }
        }
    }

    static func load() -> Credential? {
        for group in candidateGroups() {
            let (status, data) = read(group: group)
            if status == errSecSuccess, let data, let credential = decode(data) {
                return credential
            }
            // Not found, missing entitlement or locked: try the next place.
        }
        // Only ever written when the keychain refused for lack of entitlements.
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return nil }
        return decode(data)
    }

    static func save(_ credential: Credential) throws {
        let data: Data
        do {
            data = try JSONEncoder().encode(credential)
        } catch {
            throw StoreError.encodingFailed
        }
        for group in candidateGroups() {
            let status = write(data, group: group)
            if status == errSecSuccess {
                UserDefaults.standard.removeObject(forKey: defaultsKey)
                return
            }
            if status == missingEntitlement {
                continue
            }
            throw StoreError.keychain(status)
        }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    static func clear() {
        for group in candidateGroups() {
            SecItemDelete(baseQuery(group: group) as CFDictionary)
        }
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }

    // MARK: - Keychain plumbing

    /// -34018: the binary isn't entitled to the keychain (or to the access group).
    private static let missingEntitlement: OSStatus = -34018

    /// The shared group first (when configured), then the app's default group.
    private static func candidateGroups() -> [String?] {
        if let group = NimbusConfig.keychainGroup {
            return [group, nil]
        }
        return [nil]
    }

    private static func baseQuery(group: String?) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        if let group {
            query[kSecAttrAccessGroup as String] = group
        }
        return query
    }

    private static func read(group: String?) -> (status: OSStatus, data: Data?) {
        var query = baseQuery(group: group)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        return (status, result as? Data)
    }

    private static func write(_ data: Data, group: String?) -> OSStatus {
        let query = baseQuery(group: group)
        let deleteStatus = SecItemDelete(query as CFDictionary)
        if deleteStatus == missingEntitlement {
            return deleteStatus
        }
        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return SecItemAdd(attributes as CFDictionary, nil)
    }

    private static func decode(_ data: Data) -> Credential? {
        try? JSONDecoder().decode(Credential.self, from: data)
    }
}
