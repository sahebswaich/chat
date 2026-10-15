import Foundation
import SwiftUI

/// The "Add Nimbus to Messages" card pinned to the top of the sidebar until dismissed.
struct SetupGuideCard: View {
    var onDismiss: () -> Void

    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "message.fill")
                    .font(.headline)
                    .foregroundStyle(NimbusTheme.sky)
                Text("Add Nimbus to Messages")
                    .font(.headline)
                Spacer(minLength: 8)
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(Color.secondary.opacity(0.15)))
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Dismiss")
            }
            SetupGuideView(compact: true)
        }
        .padding(.vertical, 6)
    }
}
