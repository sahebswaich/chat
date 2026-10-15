import Foundation
import SwiftUI

/// "I agree to the Terms and to sending my questions to Claude", with links to the server's
/// Terms and Privacy pages. Nothing is sent to the AI until this is ticked
/// (App Review guideline 5.1.2(i)).
struct ConsentCheckbox: View {
    @Binding var isOn: Bool
    var termsURL: URL?
    var privacyURL: URL?
    var onOpen: (URL) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                isOn.toggle()
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Image(systemName: isOn ? "checkmark.square.fill" : "square")
                        .font(.title3)
                        .foregroundStyle(isOn ? NimbusTheme.accent : Color.secondary)
                        .contentTransition(.symbolEffect(.replace))
                    Text("I agree to the Terms and to sending my questions to Claude")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.selection, trigger: isOn)
            .accessibilityAddTraits(isOn ? .isSelected : [])

            Text("Nimbus sends your questions, and any chat you paste, to Anthropic's Claude AI to write answers. Answers are AI-generated and can be wrong.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if termsURL != nil || privacyURL != nil {
                HStack(spacing: 18) {
                    if let termsURL {
                        Button("Terms") {
                            onOpen(termsURL)
                        }
                    }
                    if let privacyURL {
                        Button("Privacy") {
                            onOpen(privacyURL)
                        }
                    }
                }
                .font(.footnote.weight(.semibold))
                .buttonStyle(.borderless)
            }
        }
    }
}
