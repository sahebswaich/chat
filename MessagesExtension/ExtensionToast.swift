import Foundation
import SwiftUI

/// A short message shown at the top of the extension for a few seconds.
nonisolated struct ExtensionToast: Identifiable, Equatable, Sendable {
    let id: UUID
    let text: String
    /// SF Symbol name.
    let systemImage: String

    init(text: String, systemImage: String) {
        self.id = UUID()
        self.text = text
        self.systemImage = systemImage
    }
}

/// The glass banner that shows an `ExtensionToast`.
struct ToastBanner: View {
    let toast: ExtensionToast

    var body: some View {
        Label {
            Text(verbatim: toast.text)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: toast.systemImage)
        }
        .font(.subheadline.weight(.semibold))
        .multilineTextAlignment(.leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}
