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
///
/// Only the activity's id is kept; ActivityKit calls happen in `nonisolated` helpers that look
/// the activity up, so no `Activity` object is held in main-actor state.
final class LiveActivityController {
    static let shared = LiveActivityController()

    private typealias ActivityState = NimbusActivityAttributes.ContentState

    private var activityID: String?
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
    /// This also clears activities left over from an earlier launch.
    func sceneDidBecomeActive() {
        monitor?.cancel()
        monitor = nil
        activityID = nil
        lastState = nil
        endBackgroundTime()
        Task {
            await Self.endActivities(id: nil, finalState: nil, immediately: true)
        }
    }

    // MARK: - Activity

    private func startActivityIfNeeded(for engine: ChatEngine) {
        guard activityID == nil,
              ActivityAuthorizationInfo().areActivitiesEnabled,
              let phase = ActivityState.Phase(engine.phase),
              !phase.isFinished
        else { return }
        let state = ActivityState(phase: phase, answer: engine.latestAssistantMessage?.text ?? "")
        do {
            let activity = try Activity<NimbusActivityAttributes>.request(
                attributes: NimbusActivityAttributes(question: Self.question(for: engine)),
                content: ActivityContent(state: state, staleDate: Self.staleDate()),
                pushType: nil
            )
            activityID = activity.id
            lastState = state
        } catch {
            // Not allowed right now (e.g. already in the background). Background time still runs.
            activityID = nil
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
            if let id = activityID {
                activityID = nil
                lastState = nil
                await Self.endActivities(id: id, finalState: ActivityState(phase: finalPhase, answer: text), immediately: false)
            }
            endBackgroundTime()
            return true
        }
        let state = ActivityState(phase: phase, answer: assistant?.text ?? "")
        if let id = activityID, state != lastState {
            lastState = state
            await Self.updateActivity(id: id, state: state)
        }
        return false
    }

    // MARK: - Background time

    private func beginBackgroundTime() {
        guard backgroundTask == .invalid else { return }
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "Nimbus answer") {
            // Runs on the main thread, and must end the task before returning.
            MainActor.assumeIsolated {
                LiveActivityController.shared.backgroundTimeExpired()
            }
        }
    }

    private func backgroundTimeExpired() {
        monitor?.cancel()
        monitor = nil
        if let id = activityID {
            activityID = nil
            let state = ActivityState(
                phase: .failed,
                preview: "Nimbus paused in the background. Open it to finish the answer.",
                wordCount: lastState?.wordCount ?? 0
            )
            lastState = nil
            Task {
                await Self.endActivities(id: id, finalState: state, immediately: false)
            }
        }
        endBackgroundTime()
    }

    private func endBackgroundTime() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }

    // MARK: - ActivityKit calls

    /// A fresh lookup each time, so every ActivityKit call gets its own value.
    private nonisolated static func lookUpActivity(id: String) -> Activity<NimbusActivityAttributes>? {
        Activity<NimbusActivityAttributes>.activities.first { $0.id == id }
    }

    private nonisolated static func updateActivity(id: String, state: ActivityState) async {
        guard let activity = lookUpActivity(id: id) else { return }
        await activity.update(ActivityContent(state: state, staleDate: staleDate()))
    }

    /// Ends the activity with `id` (every Nimbus activity when nil). A final state stays on the
    /// Lock Screen for 15 minutes unless `immediately`.
    private nonisolated static func endActivities(id: String?, finalState: ActivityState?, immediately: Bool) async {
        let ids: [String]
        if let id {
            ids = [id]
        } else {
            ids = Activity<NimbusActivityAttributes>.activities.map { $0.id }
        }
        for activityID in ids {
            guard let activity = lookUpActivity(id: activityID) else { continue }
            let content = finalState.map { ActivityContent(state: $0, staleDate: nil) }
            let policy: ActivityUIDismissalPolicy = immediately
                ? .immediate
                : .after(Date().addingTimeInterval(15 * 60))
            await activity.end(content, dismissalPolicy: policy)
        }
    }

    // MARK: - Helpers

    /// If the app is suspended before the next update, the activity shows as stale
    /// ("Open Nimbus to see the answer") instead of "Writing…" forever.
    private nonisolated static func staleDate() -> Date {
        Date().addingTimeInterval(45)
    }

    /// One short line: the question being answered (for rewrites, the original question).
    private static func question(for engine: ChatEngine) -> String {
        let raw = engine.latestAssistantMessage?.question ?? engine.lastQuestion ?? ""
        return ConversationController.title(for: raw)
    }
}
