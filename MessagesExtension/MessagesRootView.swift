import Foundation
import SwiftUI

/// Root of the extension's SwiftUI hierarchy: picks the screen and hosts the toast and the
/// thread haptics (so they fire whichever presentation style is showing).
struct MessagesRootView: View {
    let model: MessagesModel

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .overlay(alignment: .top) {
                if let toast = model.toast {
                    ToastBanner(toast: toast)
                        .padding(.top, 6)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onTapGesture {
                            model.dismissToast()
                        }
                }
            }
            .animation(.snappy(duration: 0.25), value: model.toast)
            .tint(NimbusTheme.accent)
            .nimbusHaptics(for: model.engine)
            .sensoryFeedback(.impact(weight: .medium), trigger: model.sendTick)
            .onChange(of: model.engine.completionTick) {
                model.answerDidFinish()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch model.screen {
        case .signIn:
            ExtensionSignInView(model: model)
        case .consent:
            ConsentGateView(model: model)
        case .compact:
            CompactView(model: model)
        case .expanded:
            ExpandedView(model: model)
        }
    }
}
