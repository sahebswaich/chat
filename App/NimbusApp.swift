import Foundation
import SwiftData
import SwiftUI

@main
struct NimbusApp: App {
    private let container: ModelContainer
    @State private var conversations: ConversationController

    init() {
        let container = NimbusApp.makeContainer()
        self.container = container
        _conversations = State(initialValue: ConversationController(modelContext: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(NimbusSession.shared)
                .environment(NimbusRouter.shared)
                .environment(conversations)
                .onOpenURL { url in
                    // nimbus://join?code=…&host=…, nimbus://ask?q=…, nimbus://new.
                    // Screens pick the request up from `NimbusRouter.shared.pending`.
                    _ = NimbusRouter.shared.handle(url: url)
                }
        }
        .modelContainer(container)
    }

    /// The chat history store. A store that can't be opened falls back to memory so the app
    /// still works (history just isn't kept for that launch).
    private static func makeContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: StoredConversation.self)
        } catch {
            do {
                return try ModelContainer(
                    for: StoredConversation.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
            } catch {
                fatalError("Nimbus couldn't create its chat history store: \(error)")
            }
        }
    }
}
