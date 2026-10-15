import Foundation
import SwiftUI

/// The Nimbus badge for the Lock Screen activity: sparkles on a sky-gradient tile that pulse
/// while the answer is being worked on.
struct ActivitySparkle: View {
    var isWorking: Bool
    var size: CGFloat

    init(isWorking: Bool, size: CGFloat = 44) {
        self.isWorking = isWorking
        self.size = size
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(NimbusTheme.sky)
            Image(systemName: "sparkles")
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundStyle(Color.white)
                .symbolEffect(.pulse, isActive: isWorking)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
