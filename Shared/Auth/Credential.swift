import Foundation

/// What a redeemed invite code turns into. Stored in the shared keychain so the app and
/// the iMessage extension share one sign-in (and one consent record).
nonisolated struct Credential: Codable, Sendable, Equatable, Hashable {
    /// Server host without scheme, e.g. `nimbus.sahebswaich.workers.dev`.
    var host: String
    /// Opaque bearer token from `POST /v1/redeem`.
    var token: String
    /// The friend's name the invite was made for.
    var name: String
    /// Answers per UTC day.
    var dailyLimit: Int
    /// When the person agreed to the Terms and to sending their questions to Claude
    /// (App Review guideline 5.1.2(i)). Nil for credentials saved before consent existed.
    var consentedAt: Date?

    init(host: String, token: String, name: String, dailyLimit: Int, consentedAt: Date? = nil) {
        self.host = host
        self.token = token
        self.name = name
        self.dailyLimit = dailyLimit
        self.consentedAt = consentedAt
    }
}
