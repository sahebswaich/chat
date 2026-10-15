import Foundation
import SwiftUI

/// The app icon motif drawn in SwiftUI: a speech bubble with a sparkle on the sky gradient.
/// It floats gently, and the sparkle drifts a little more than the bubble for a parallax feel.
/// Reduce Motion keeps it still.
struct NimbusLogoView: View {
    var size: CGFloat
    var animated: Bool

    init(size: CGFloat = 120, animated: Bool = true) {
        self.size = size
        self.animated = animated
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isAnimating: Bool { animated && !reduceMotion }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isAnimating)) { context in
            logo(time: isAnimating ? context.date.timeIntervalSinceReferenceDate : 0)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func logo(time: TimeInterval) -> some View {
        let float = CGFloat(sin(time * 1.1)) * size * 0.04
        let sway = CGFloat(cos(time * 0.7)) * size * 0.025
        let tilt = Angle.degrees(Double(sway / size) * 160)
        let corner = size * 0.27
        return ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(NimbusTheme.sky)
                .overlay {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: max(1, size * 0.012))
                }
                .shadow(color: NimbusTheme.indigo.opacity(0.4), radius: size * 0.16, x: 0, y: size * 0.1)
            Image(systemName: "bubble.fill")
                .font(.system(size: size * 0.48, weight: .semibold))
                .foregroundStyle(Color.white)
                .offset(x: sway * 0.6, y: float * 0.5)
            Image(systemName: "sparkle")
                .font(.system(size: size * 0.2, weight: .bold))
                .foregroundStyle(NimbusTheme.sky)
                .offset(x: sway * 1.5, y: -size * 0.035 + float * 1.2)
        }
        .rotation3DEffect(tilt, axis: (x: 0.15, y: 1, z: 0))
        .offset(y: float)
    }
}
