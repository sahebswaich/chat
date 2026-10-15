import Foundation
import SwiftUI

/// Shown under the failed answer when today's answers are used up: when the limit resets
/// (midnight UTC) in the person's own time.
struct LimitNotice: View {
    let session: NimbusSession

    var body: some View {
        let reset = Self.nextReset(after: Date())
        HStack(alignment: .top, spacing: 12) {
            if let used = session.usedToday, let limit = session.dailyLimit, limit > 0 {
                UsageRing(used: used, limit: limit, lineWidth: 4, showsLabel: false)
                    .frame(width: 28, height: 28)
            } else {
                Image(systemName: "hourglass")
                    .font(.title3)
                    .foregroundStyle(NimbusTheme.accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Daily limit reached")
                    .font(.subheadline.weight(.semibold))
                Text(verbatim: "Resets at \(reset.formatted(date: .omitted, time: .shortened)) your time (midnight UTC). Your thread will still be here.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(NimbusTheme.assistantBubble, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    /// The next midnight UTC after `date`.
    nonisolated static func nextReset(after date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date.addingTimeInterval(86_400)
    }
}
