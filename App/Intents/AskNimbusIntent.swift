import AppIntents
import Foundation

/// "Ask Nimbus" for Siri, Shortcuts, Spotlight and the Action Button. It asks one question and
/// returns the whole answer: Siri reads it out, and Shortcuts can pass it on (for example to
/// Send Message).
///
/// Main-actor isolated (the project default) because Swift doesn't allow `nonisolated` on
/// property-wrapped vars like `@Parameter`; only the synchronous protocol requirements are
/// `nonisolated`.
struct AskNimbusIntent: AppIntent {
    nonisolated static let title: LocalizedStringResource = "Ask Nimbus"
    nonisolated static var description: IntentDescription {
        IntentDescription("Ask Nimbus a question and get the answer back.")
    }

    @Parameter(title: "Question", requestValueDialog: "What do you want to ask?")
    var question: String

    nonisolated init() {}

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AskNimbusIntentError.emptyQuestion
        }
        let storedCredential = await MainActor.run { () -> Credential? in
            // The app or the iMessage extension may have signed in since this process started.
            NimbusSession.shared.reload()
            return NimbusSession.shared.credential
        }
        guard let credential = storedCredential else {
            throw AskNimbusIntentError.notSignedIn
        }

        let request = ChatRequest(
            messages: [ChatTurn(role: .user, content: TextLimit.clip(trimmed, maxUTF16: TextLimit.chatContent))],
            style: .default,
            surface: .intent,
            webSearch: AppSettings.webSearchEnabled
        )

        var answer = ""
        do {
            for try await event in NimbusClient(credential: credential).stream(request) {
                switch event {
                case .delta(let text):
                    answer += text
                case .done(let info):
                    await MainActor.run {
                        NimbusSession.shared.handle(done: info)
                    }
                case .meta, .status:
                    break
                }
            }
        } catch {
            guard let mapped = NimbusError.from(error) else { throw error }
            if mapped == .unauthorized {
                await MainActor.run {
                    NimbusSession.shared.handle(error: mapped)
                }
            }
            throw AskNimbusIntentError.failed(mapped.errorDescription ?? "Nimbus couldn't answer that. Try again?")
        }

        let finalAnswer = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !finalAnswer.isEmpty else {
            throw AskNimbusIntentError.failed("Nimbus came back empty-handed. Try again?")
        }
        return .result(value: finalAnswer, dialog: IntentDialog(stringLiteral: finalAnswer))
    }
}

/// Friendly failures Siri and Shortcuts show as they are.
nonisolated enum AskNimbusIntentError: Error, CustomLocalizedStringResourceConvertible {
    case notSignedIn
    case emptyQuestion
    case failed(String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notSignedIn:
            return "Open Nimbus and enter your invite code first."
        case .emptyQuestion:
            return "Ask Nimbus a question first."
        case .failed(let message):
            return LocalizedStringResource(stringLiteral: message)
        }
    }
}
