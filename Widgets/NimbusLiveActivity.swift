import ActivityKit
import Foundation
import SwiftUI
import WidgetKit

/// The Live Activity the app shows while an answer finishes in the background: Lock Screen
/// banner plus Dynamic Island (sparkle + "Thinking…" → "Answer ready").
struct NimbusLiveActivity: Widget {
    /// Tapping brings the app forward to the answer. The app's router ignores this host, so
    /// the chat on screen is kept.
    nonisolated static let openURL = URL(string: "nimbus://activity")

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NimbusActivityAttributes.self) { context in
            NimbusActivityLockScreenView(context: context)
                .activitySystemActionForegroundColor(NimbusTheme.violet)
                .widgetURL(NimbusLiveActivity.openURL)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "sparkles")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(NimbusTheme.sky)
                        .symbolEffect(.pulse, isActive: context.state.isWorking(isStale: context.isStale))
                        .padding(.leading, 6)
                        .padding(.top, 4)
                        .accessibilityHidden(true)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    IslandTrailingView(state: context.state)
                        .padding(.trailing, 6)
                        .padding(.top, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(verbatim: context.attributes.question)
                            .font(.headline)
                            .lineLimit(1)
                        Text(verbatim: context.state.headline(isStale: context.isStale))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(verbatim: context.state.previewText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 6)
                        .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: "sparkle")
                    .foregroundStyle(NimbusTheme.cyan)
                    .symbolEffect(.pulse, isActive: context.state.isWorking(isStale: context.isStale))
                    .accessibilityLabel("Nimbus")
            } compactTrailing: {
                IslandCompactTrailingView(state: context.state)
            } minimal: {
                Image(systemName: "sparkle")
                    .foregroundStyle(NimbusTheme.cyan)
                    .accessibilityLabel("Nimbus")
            }
            .widgetURL(NimbusLiveActivity.openURL)
            .keylineTint(NimbusTheme.violet)
        }
    }
}

/// Expanded island, trailing: the running word count, or the phase glyph before any text.
private struct IslandTrailingView: View {
    let state: NimbusActivityAttributes.ContentState

    var body: some View {
        if state.wordCount > 0 {
            VStack(alignment: .trailing, spacing: 0) {
                Text(state.wordCount, format: .number)
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .contentTransition(.numericText(value: Double(state.wordCount)))
                Text(verbatim: state.wordCount == 1 ? "word" : "words")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        } else {
            Image(systemName: state.phase.systemImage)
                .font(.title3)
                .foregroundStyle(NimbusTheme.cyan)
                .accessibilityLabel(Text(verbatim: state.phase.title))
        }
    }
}

/// Compact island, trailing: the word count while writing, otherwise the phase glyph.
private struct IslandCompactTrailingView: View {
    let state: NimbusActivityAttributes.ContentState

    var body: some View {
        if state.phase == .writing, state.wordCount > 0 {
            Text(state.wordCount, format: .number)
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(NimbusTheme.cyan)
                .contentTransition(.numericText(value: Double(state.wordCount)))
        } else {
            Image(systemName: state.phase.systemImage)
                .foregroundStyle(state.phase == .failed ? Color.orange : NimbusTheme.cyan)
                .accessibilityLabel(Text(verbatim: state.phase.title))
        }
    }
}
