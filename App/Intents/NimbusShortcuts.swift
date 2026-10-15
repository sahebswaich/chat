import AppIntents
import Foundation

/// The App Shortcuts Siri and Spotlight offer without any setup. Every phrase names the app.
nonisolated struct NimbusShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AskNimbusIntent(),
            phrases: [
                "Ask \(.applicationName)",
                "Ask \(.applicationName) a question",
                "\(.applicationName) help me",
            ],
            shortTitle: "Ask Nimbus",
            systemImageName: "sparkles"
        )
        AppShortcut(
            intent: OpenAskIntent(),
            phrases: [
                "New \(.applicationName) chat",
            ],
            shortTitle: "New Chat",
            systemImageName: "square.and.pencil"
        )
    }
}
