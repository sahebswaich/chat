import Foundation
import Observation
import UIKit

/// The signed-in state shared by every screen in a process (app or extension).
@Observable
final class NimbusSession {
    static let shared = NimbusSession(credential: CredentialStore.load())

    /// The current sign-in, or nil when signed out.
    var credential: Credential?
    /// Answers used today (UTC), when known.
    var usedToday: Int?
    /// Answers allowed per day, when known.
    var dailyLimit: Int?

    init(credential: Credential?) {
        self.credential = credential
        self.dailyLimit = credential?.dailyLimit
    }

    var isSignedIn: Bool { credential != nil }

    /// The friend's name from the invite.
    var name: String? { credential?.name }

    /// The host requests go to: the signed-in server, else the one baked into the build.
    var host: String? { credential?.host ?? NimbusConfig.defaultHost }

    /// Answers left today, when both numbers are known.
    var remainingToday: Int? {
        guard let usedToday, let dailyLimit else { return nil }
        return max(dailyLimit - usedToday, 0)
    }

    /// Fraction of today's answers used (0...1), when known.
    var usageFraction: Double? {
        guard let usedToday, let dailyLimit, dailyLimit > 0 else { return nil }
        return min(max(Double(usedToday) / Double(dailyLimit), 0), 1)
    }

    /// Re-reads the keychain, e.g. when the extension becomes active after the app signed in.
    func reload() {
        let stored = CredentialStore.load()
        guard stored != credential else { return }
        credential = stored
        dailyLimit = stored?.dailyLimit
        usedToday = nil
    }

    /// Redeems an invite code and stores the resulting credential.
    /// - Parameters:
    ///   - code: What the person typed or pasted (`k7qm 2xpa`, `K7QM-2XPA`, …).
    ///   - host: Server from a join link; defaults to the current/baked-in host.
    func signIn(code: String, host: String? = nil) async throws {
        guard let normalized = InviteCode.normalize(code) else {
            throw NimbusError.invalidCode
        }
        let chosenHost: String
        if let host {
            guard let normalizedHost = NimbusConfig.normalizeHost(host) else {
                throw NimbusError.invalidRequest("That server address doesn't look right.")
            }
            chosenHost = normalizedHost
        } else if let fallback = self.host {
            chosenHost = fallback
        } else {
            throw NimbusError.invalidRequest(
                "Nimbus doesn't know which server to use yet. Open your invite link again."
            )
        }

        let client = NimbusClient(credential: nil, host: chosenHost)
        let response = try await client.redeem(code: InviteCode.format(normalized), device: Self.deviceName)
        let newCredential = Credential(
            host: chosenHost,
            token: response.token,
            name: response.name,
            dailyLimit: response.dailyLimit
        )
        // The code is already spent at this point, so a keychain hiccup must not fail sign-in;
        // the credential still works for this session.
        try? CredentialStore.save(newCredential)
        credential = newCredential
        dailyLimit = response.dailyLimit
        usedToday = nil
        await refreshUsage()
    }

    func signOut() {
        CredentialStore.clear()
        credential = nil
        usedToday = nil
        dailyLimit = nil
    }

    /// Fetches `GET /v1/me`. Signs out when the server says the token is no longer valid.
    func refreshUsage() async {
        guard let current = credential else { return }
        do {
            let me = try await NimbusClient(credential: current).me()
            guard credential == current else { return }
            usedToday = me.usedToday
            dailyLimit = me.dailyLimit
            if me.name != current.name || me.dailyLimit != current.dailyLimit {
                var updated = current
                updated.name = me.name
                updated.dailyLimit = me.dailyLimit
                try? CredentialStore.save(updated)
                credential = updated
            }
        } catch NimbusError.unauthorized {
            if credential == current {
                signOut()
            }
        } catch {
            // Usage is a nice-to-have; keep the last known numbers.
        }
    }

    /// Updates usage from a stream's `done` event.
    func handle(done: DoneInfo) {
        if let used = done.usedToday {
            usedToday = used
        }
        if let limit = done.dailyLimit {
            dailyLimit = limit
        }
    }

    /// Reacts to errors that change account state.
    func handle(error: NimbusError) {
        switch error {
        case .unauthorized:
            signOut()
        case .dailyLimit:
            if let dailyLimit {
                usedToday = dailyLimit
            }
        default:
            break
        }
    }

    /// Shown to the owner in `npm run admin -- users`.
    static var deviceName: String {
        let name = UIDevice.current.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? UIDevice.current.model : name
    }
}
