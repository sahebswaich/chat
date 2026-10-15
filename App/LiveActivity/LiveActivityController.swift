import ActivityKit
import Foundation
import UIKit

/// Shows an answer that is still streaming as a Live Activity once the app leaves the screen,
/// and asks iOS for background time so the answer can finish (and be saved) meanwhile.
///
/// iOS only lets an app start a Live Activity while it's in the foreground, so the request is
/// made as the scene turns inactive on its way out (and tried again on background). Updates go
/// out at most once a second. When the answer is done or fails, the activity ends with the final
/// state and stays on the Lock Screen for 15 minutes. Coming back to the app ends it at once.
final class LiveActivityController {
    static let shared = LiveActivityController()

    private typealias ActivityState = NimbusActivityAttributes.ContentState

    private var activity: Activity<NimbusActivityAttributes>?
    private var lastState: ActivityState?
    private var monitor: Task<Void, Never>?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    private init() {}

    // MARK: - Scene events

    /// The scene is leaving the foreground (inactive from active, or background).
    func sceneWillLeaveForeground(engine: ChatEngine, showsLiveActivity: Bool) {
        guard engine.isBusy else { return }
        beginBackgroundTime()
        if showsLiveActivity {
            startActivityIfNeeded(for: engine)
        }
        startMonitoring(engine)
    }

    /// The app is on screen again: the answer is visible there, so the activity goes away.
    func sceneDidBecomeActive() {
        monitor?.cancel()
        monitor = nil
        activity = nil
        lastState = nil
        endBackgroundTime()
        // Also clears activities left over from an earlier launch.
        let running = Activity<NimbusActivityAttributes>.activities
        guard !running.isEmpty else { return }
        Task {
            for activity in running {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    // MARK: - Activity

    private func startActivityIfNeeded(for engine: ChatEngine) {
        guard activity == nil,
              ActivityAuthorizationInfo().areActivitiesEnabled,
              let phase = ActivityState.Phase(engine.phase),
              !phase.isFinished
        else { return }
        let state = ActivityState(phase: phase, answer: engine.latestAssistantMessage?.text ?? "")
        do {
            activity = try Activity<NimbusActivityAttributes>.request(
                attributes: NimbusActivityAttributes(question: Self.question(for: engine)),
                content: ActivityContent(state: state, staleDate: Self.staleDate()),
                pushType: nil
            )
            lastState = state
        } catch {
            // Not allowed right now (e.g. already in the background). Background time still runs.
            activity = nil
        }
    }

    private func startMonitoring(_ engine: ChatEngine) {
        guard monitor == nil else { return }
        monitor = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self else { return }
                if await self.refresh(from: engine) {
                    self.monitor = nil
                    return
                }
            }
        }
    }

    /// Pushes the engine's current state to the activity. Returns true once the answer settled.
    private func refresh(from engine: ChatEngine) async -> Bool {
        let assistant = engine.latestAssistantMessage
        guard let phase = ActivityState.Phase(engine.phase), !phase.isFinished else {
            let finalPhase = ActivityState.Phase(engine.phase) ?? .done
            let text = assistant?.state.failureMessage ?? assistant?.text ?? ""
            await finishActivity(with: ActivityState(phase: finalPhase, answer: text))
            endBackgroundTime()
            return true
        }
        let state = ActivityState(phase: phase, answer: assistant?.text ?? "")
        if let activity, state != lastState {
            lastState = state
            await activity.update(ActivityContent(state: state, staleDate: Self.staleDate()))
        }
        return false
    }

    private func finishActivity(with state: ActivityState) async {
        guard let activity else { return }
        self.activity = nil
        lastState = nil
        await activity.end(
            ActivityContent(state: state, staleDate: nil),
            dismissalPolicy: .after(Date().addingTimeInterval(15 * 60))
        )
    }

    // MARK: - Background time

    private func beginBackgroundTime() {
        guard backgroundTask == .invalid else { return }
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "Nimbus answer") { [weak self] in
            // Runs on the main thread, and must end the task before returning.
            MainActor.assumeIsolated {
                self?.backgroundTimeExpired()
            }
        }
    }

    private func backgroundTimeExpired() {
        monitor?.cancel()
        monitor = nil
        if let activity {
            self.activity = nil
            let state = ActivityState(
                phase: .failed,
                preview: "Nimbus paused in the background. Open it to finish the answer.",
                wordCount: lastState?.wordCount ?? 0
            )
            lastState = nil
            Task {
                await activity.end(
                    ActivityContent(state: state, staleDate: nil),
                    dismissalPolicy: .after(Date().addingTimeInterval(15 * 60))
                )
            }
        }
        endBackgroundTime()
    }

    private func endBackgroundTime() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }

    // MARK: - Helpers

    /// If the app is suspended before the next update, the activity shows as stale
    /// ("Open Nimbus to see the answer") instead of "Writing…" forever.
    private static func staleDate() -> Date {
        Date().addingTimeInterval(45)
    }

    /// One short line: the question being answered (for rewrites, the original question).
    private static func question(for engine: ChatEngine) -> String {
        let raw = engine.latestAssistantMessage?.question ?? engine.lastQuestion ?? ""
        return ConversationController.title(for: raw)
    }
}
