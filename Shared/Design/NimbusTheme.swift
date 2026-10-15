import Foundation
import SwiftUI
import UIKit

/// Nimbus colors and gradients, defined in code so they work in every target
/// (the widgets extension and the test bundle don't carry the app's asset catalog).
nonisolated enum NimbusTheme {
    /// #5856F6
    static let indigo = Color(red: 88 / 255, green: 86 / 255, blue: 246 / 255)
    /// #8B5CF6
    static let violet = Color(red: 139 / 255, green: 92 / 255, blue: 246 / 255)
    /// #22D3EE
    static let cyan = Color(red: 34 / 255, green: 211 / 255, blue: 238 / 255)
    /// #6C5CF6 (matches the AccentColor asset)
    static let accent = Color(red: 108 / 255, green: 92 / 255, blue: 246 / 255)
    /// Messages-style send button blue (adapts to light/dark).
    static let sendBlue = Color.blue

    /// indigo → violet → cyan
    static var skyColors: [Color] { [indigo, violet, cyan] }

    /// The "sky" gradient used for the icon, onboarding and highlights.
    static var sky: LinearGradient {
        LinearGradient(colors: skyColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Closed loop of sky colors for rotating angular strokes (the AI glow).
    static var glowColors: [Color] { [indigo, violet, cyan, violet, indigo] }

    /// Right-aligned user bubble: a sky gradient dark enough for white text.
    static var userBubble: LinearGradient {
        LinearGradient(
            colors: [Color(red: 64 / 255, green: 118 / 255, blue: 246 / 255), indigo, violet],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static let userBubbleText = Color.white

    /// Left-aligned answer bubble.
    static var assistantBubble: Color { Color(uiColor: .secondarySystemBackground) }

    /// The gray of an incoming iMessage bubble (typing dots).
    static var typingBubble: Color { Color(uiColor: .systemGray5) }

    static var typingDot: Color { Color(uiColor: .systemGray) }

    static let bubbleCornerRadius: CGFloat = 20

    /// 3×3 mesh for full-screen sky backgrounds; `phase` (seconds) gently moves the middle.
    static func meshPoints(phase: Float) -> [SIMD2<Float>] {
        let dx = 0.08 * sin(phase * 0.5)
        let dy = 0.06 * cos(phase * 0.4)
        return [
            SIMD2<Float>(0, 0), SIMD2<Float>(0.5, 0), SIMD2<Float>(1, 0),
            SIMD2<Float>(0, 0.5), SIMD2<Float>(0.5 + dx, 0.5 + dy), SIMD2<Float>(1, 0.5),
            SIMD2<Float>(0, 1), SIMD2<Float>(0.5, 1), SIMD2<Float>(1, 1),
        ]
    }

    static var meshColors: [Color] {
        [
            indigo, violet, indigo,
            violet, Color(red: 96 / 255, green: 120 / 255, blue: 246 / 255), cyan,
            indigo, cyan, cyan,
        ]
    }
}
