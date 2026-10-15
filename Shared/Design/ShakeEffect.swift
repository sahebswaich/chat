import CoreGraphics
import Foundation
import SwiftUI

/// Horizontal "nope" shake. Animate `animatableData` from n to n + 1 to shake once.
nonisolated struct ShakeEffect: GeometryEffect {
    var travel: CGFloat = 10
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    init(travel: CGFloat = 10, shakesPerUnit: CGFloat = 3, animatableData: CGFloat) {
        self.travel = travel
        self.shakesPerUnit = shakesPerUnit
        self.animatableData = animatableData
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = travel * sin(animatableData * .pi * 2 * shakesPerUnit)
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}
