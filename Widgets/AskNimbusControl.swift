import AppIntents
import SwiftUI
import WidgetKit

/// Control Center / Lock Screen / Action Button control that opens Nimbus to a new question.
/// `OpenAskIntent` (Shared) is built into both the app and this extension and opens the app,
/// so it runs in the app, where it sets `NimbusRouter.shared.pending`.
struct AskNimbusControl: ControlWidget {
    static let kind = "com.nimbus.ask"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: AskNimbusControl.kind) {
            ControlWidgetButton(action: OpenAskIntent()) {
                Label("Ask Nimbus", systemImage: "sparkles")
            }
        }
        .displayName("Ask Nimbus")
        .description("Open Nimbus ready for a new question.")
    }
}
