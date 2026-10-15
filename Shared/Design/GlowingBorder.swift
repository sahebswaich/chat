import Foundation
import SwiftUI

/// The Apple Intelligence-style edge glow: a slowly rotating angular gradient of sky colors,
/// stroked around the content with a soft blurred halo. Shown while an answer streams.
/// With Reduce Motion on, the rotation and halo are dropped for a still, subtle border.
struct GlowingBorder: ViewModifier {
    var isActive: Bool
    var cornerRadius: CGFloat = NimbusTheme.bubbleCornerRadius
    var lineWidth: CGFloat = 2
    /// Seconds per full turn.
    var period: Double = 3

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive {
                    glow
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: isActive)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    @ViewBuilder
    private var glow: some View {
        if reduceMotion {
            shape
                .strokeBorder(NimbusTheme.sky, lineWidth: lineWidth)
                .opacity(0.7)
        } else {
            TimelineView(.animation) { context in
                let turns = context.date.timeIntervalSinceReferenceDate / period
                let angle = Angle.degrees((turns - turns.rounded(.down)) * 360)
                let gradient = AngularGradient(
                    gradient: Gradient(colors: NimbusTheme.glowColors),
                    center: .center,
                    angle: angle
                )
                ZStack {
                    shape
                        .strokeBorder(gradient, lineWidth: lineWidth * 4)
                        .blur(radius: 10)
                        .opacity(0.55)
                    shape
                        .strokeBorder(gradient, lineWidth: lineWidth)
                }
            }
        }
    }
}

extension View {
    /// Adds the streaming "AI is working" glow around this view while `isActive`.
    func nimbusGlow(isActive: Bool, cornerRadius: CGFloat = NimbusTheme.bubbleCornerRadius) -> some View {
        modifier(GlowingBorder(isActive: isActive, cornerRadius: cornerRadius))
    }
}
