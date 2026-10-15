import Foundation
import SwiftUI

extension View {
    /// The thread haptics from DESIGN.md, driven by a `ChatEngine`'s counters: a soft tap when
    /// the first word arrives, success when an answer finishes, an error buzz when it fails.
    /// (Chips add their own selection tick and the composer its send tap.)
    func nimbusHaptics(for engine: ChatEngine) -> some View {
        self
            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: engine.firstTokenTick)
            .sensoryFeedback(.success, trigger: engine.completionTick)
            .sensoryFeedback(.error, trigger: engine.errorTick)
    }
}
