import Foundation

/// What a redeemed invite code turns into. Stored in the shared keychain so the app and
/// the iMessage extension share one sign-in.
nonisolated struct Credential: Codable, Sendable, Equatable, Hashable {
    /// Server host without scheme, e.g. `nimbus.sahebswaich.workers.dev`.
    var host: String
    /// Opaque bearer token from `POST /v1/redeem`.
    var token: String
    /// The friend's name the invite was made for.
    var name: String
    /// Answers per UTC day.
    var dailyLimit: Int

    init(host: String, token: String, name: String, dailyLimit: Int) {
        self.host = host
        self.token = token
        self.name = name
        self.dailyLimit = dailyLimit
    }
}
