#if NIMBUS_APP || NIMBUS_WIDGETS
import AppIntents
import Foundation

/// Opens Nimbus to a new question. Used by the Control Center / Lock Screen / Action Button
/// control (widgets extension) and by Shortcuts (app). Runs in the app process.
nonisolated struct OpenAskIntent: AppIntent {
    static let title: LocalizedStringResource = "Ask Nimbus"
    static var description: IntentDescription {
        IntentDescription("Open Nimbus ready for a new question.")
    }
    static let openAppWhenRun: Bool = true

    init() {}

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            NimbusRouter.shared.pending = .newQuestion
        }
        return .result()
    }
}
#endif
