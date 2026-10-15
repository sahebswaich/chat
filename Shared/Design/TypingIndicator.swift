import Foundation
import SwiftUI

/// The Messages "someone's typing" bubble: three dots pulsing in turn in a gray bubble.
struct TypingIndicator: View {
    var dotColor: Color = NimbusTheme.typingDot
    var bubbleColor: Color = NimbusTheme.typingBubble
    var dotSize: CGFloat = 8

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: dotSize * 0.6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(dotColor)
                        .frame(width: dotSize, height: dotSize)
                        .opacity(reduceMotion ? 0.6 : 0.35 + 0.65 * pulse(time: time, index: index))
                        .scaleEffect(reduceMotion ? 1 : 0.85 + 0.2 * pulse(time: time, index: index))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(bubbleColor, in: RoundedRectangle(cornerRadius: NimbusTheme.bubbleCornerRadius, style: .continuous))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Nimbus is typing")
    }

    /// 0...1, each dot a third of a cycle behind the previous one.
    private func pulse(time: TimeInterval, index: Int) -> Double {
        let period = 1.2
        let phase = (time / period - Double(index) / 3.0) * 2 * .pi
        return (sin(phase) + 1) / 2
    }
}

