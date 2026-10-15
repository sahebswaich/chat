import ActivityKit
import SwiftUI
import WidgetKit

/// Lock Screen (and StandBy / notification banner) presentation of the Live Activity:
/// the sky badge, the phase, the question and the last three lines of the answer.
struct NimbusActivityLockScreenView: View {
    let context: ActivityViewContext<NimbusActivityAttributes>

    init(context: ActivityViewContext<NimbusActivityAttributes>) {
        self.context = context
    }

    private var state: NimbusActivityAttributes.ContentState { context.state }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ActivitySparkle(isWorking: state.isWorking(isStale: context.isStale))
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Label(state.headline(isStale: context.isStale), systemImage: state.phase.systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(NimbusTheme.sky)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    if state.wordCount > 0 {
                        Text(verbatim: state.wordCountText)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText(value: Double(state.wordCount)))
                    }
                }
                Text(verbatim: context.attributes.question)
                    .font(.headline)
                    .lineLimit(1)
                Text(verbatim: state.previewText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .accessibilityElement(children: .combine)
    }
}
