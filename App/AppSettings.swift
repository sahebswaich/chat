import Foundation

/// `UserDefaults` keys for the app's preferences (read in views with `@AppStorage`).
nonisolated enum AppSettings {
    /// Show a Live Activity while an answer finishes in the background. On by default.
    static let liveActivitiesKey = "nimbus.liveActivities"
    /// Let answers use web search. On by default.
    static let webSearchKey = "nimbus.webSearch"
    /// The sidebar's "Add Nimbus to Messages" card was dismissed.
    static let setupGuideDismissedKey = "nimbus.setupGuideDismissed"

    /// The current web-search preference (on unless the person turned it off).
    static var webSearchEnabled: Bool {
        UserDefaults.standard.object(forKey: webSearchKey) as? Bool ?? true
    }
}
