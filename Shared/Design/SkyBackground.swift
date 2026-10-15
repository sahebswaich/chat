import Foundation
import SwiftUI

/// Full-bleed sky mesh gradient that drifts slowly (still with Reduce Motion).
struct SkyBackground: View {
    var animated: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(animated: Bool = true) {
        self.animated = animated
    }

    private var isPaused: Bool { reduceMotion || !animated }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: isPaused)) { context in
            let seconds = isPaused ? 0 : context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3_600)
            MeshGradient(
                width: 3,
                height: 3,
                points: NimbusTheme.meshPoints(phase: Float(seconds)),
                colors: NimbusTheme.meshColors
            )
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
