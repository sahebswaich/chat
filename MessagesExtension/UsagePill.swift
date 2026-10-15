import Foundation
import SwiftUI

/// `12/200 today` in a small glass capsule; orange once today's answers are used up.
struct UsagePill: View {
    let session: NimbusSession

    private var isUsedUp: Bool {
        session.remainingToday == 0
    }

    var body: some View {
        if let text = session.usageText {
            Text(verbatim: text)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(isUsedUp ? Color.orange : Color.secondary)
                .contentTransition(.numericText())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .glassEffect(.regular, in: Capsule())
                .animation(.snappy, value: text)
                .accessibilityLabel(accessibilityText)
        }
    }

    private var accessibilityText: String {
        guard let used = session.usedToday, let limit = session.dailyLimit else { return "" }
        return "\(used) of \(limit) answers used today"
    }
}
