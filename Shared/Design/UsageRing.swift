import Foundation
import SwiftUI

/// Circular meter of today's answers, sky gradient on a faint track.
struct UsageRing: View {
    let used: Int
    let limit: Int
    var lineWidth: CGFloat = 8
    var showsLabel: Bool = true

    init(used: Int, limit: Int, lineWidth: CGFloat = 8, showsLabel: Bool = true) {
        self.used = used
        self.limit = limit
        self.lineWidth = lineWidth
        self.showsLabel = showsLabel
    }

    /// 0...1
    var progress: Double {
        guard limit > 0 else { return 0 }
        return min(max(Double(used) / Double(limit), 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: NimbusTheme.skyColors),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * max(progress, 0.01))
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            if showsLabel {
                VStack(spacing: 0) {
                    Text(verbatim: "\(used)")
                        .font(.title2.weight(.bold).monospacedDigit())
                        .contentTransition(.numericText(value: Double(used)))
                    Text(verbatim: "of \(limit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(lineWidth)
                .minimumScaleFactor(0.5)
            }
        }
        .animation(.smooth(duration: 0.6), value: used)
        .animation(.smooth(duration: 0.6), value: limit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Usage today")
        .accessibilityValue("\(used) of \(limit) answers")
    }
}
