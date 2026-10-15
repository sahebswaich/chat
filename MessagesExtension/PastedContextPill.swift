import Foundation
import SwiftUI

/// "Chat pasted ✓ 1.2k chars" with a clear button, shown while pasted text is attached.
struct PastedContextPill: View {
    let characterCount: Int
    var onClear: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(verbatim: "Chat pasted · \(Self.sizeText(characterCount))")
                .foregroundStyle(.primary)
            Button {
                onClear()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove pasted chat")
        }
        .font(.footnote.weight(.semibold))
        .padding(.leading, 10)
        .padding(.trailing, 8)
        .padding(.vertical, 6)
        .glassEffect(.regular, in: Capsule())
        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .leading)))
    }

    /// `850 chars`, `1.2k chars`
    nonisolated static func sizeText(_ count: Int) -> String {
        if count < 1_000 {
            return "\(count) chars"
        }
        return String(format: "%.1fk chars", Double(count) / 1_000)
    }
}
