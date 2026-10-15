import Foundation
import SwiftUI

/// Onboarding while signed out, the chat app once signed in. Also shows the "You're in"
/// banner and hands scene changes to the Live Activity controller.
struct RootView: View {
    @Environment(NimbusSession.self) private var session
    @Environment(ConversationController.self) private var conversations
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppSettings.liveActivitiesKey) private var liveActivitiesEnabled = true

    @State private var banner: String?
    @State private var bannerTick = 0

    var body: some View {
        ZStack {
            if session.isSignedIn {
                MainView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.45), value: session.isSignedIn)
        .overlay(alignment: .top) {
            if let banner {
                Label(banner, systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .glassEffect(.regular, in: Capsule())
                    .padding(.top, 8)
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onTapGesture {
                        withAnimation(.smooth) {
                            self.banner = nil
                        }
                    }
                    .accessibilityAddTraits(.isStaticText)
            }
        }
        .sensoryFeedback(.success, trigger: bannerTick)
        .task(id: bannerTick) {
            await hideBannerLater()
        }
        .onChange(of: session.credential) { previous, current in
            credentialChanged(from: previous, to: current)
        }
        .onChange(of: scenePhase) { previous, phase in
            scenePhaseChanged(from: previous, to: phase)
        }
    }

    private func credentialChanged(from previous: Credential?, to current: Credential?) {
        guard let current, current.token != previous?.token else { return }
        withAnimation(.snappy) {
            banner = "You're in, \(current.name)!"
        }
        bannerTick += 1
    }

    private func hideBannerLater() async {
        guard banner != nil else { return }
        try? await Task.sleep(for: .seconds(3))
        guard !Task.isCancelled else { return }
        withAnimation(.smooth) {
            banner = nil
        }
    }

    private func scenePhaseChanged(from previous: ScenePhase, to phase: ScenePhase) {
        if phase == .active {
            LiveActivityController.shared.sceneDidBecomeActive()
            // The iMessage extension may have signed in or out meanwhile.
            session.reload()
        } else if phase == .background || (phase == .inactive && previous == .active) {
            guard session.isSignedIn else { return }
            conversations.saveNow()
            LiveActivityController.shared.sceneWillLeaveForeground(
                engine: conversations.engine,
                showsLiveActivity: liveActivitiesEnabled
            )
        }
    }
}
