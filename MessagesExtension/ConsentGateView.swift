import Foundation
import SwiftUI

/// Asks for consent when the stored sign-in predates it (`Credential.consentedAt == nil`), so
/// nothing reaches the AI before the person agrees.
struct ConsentGateView: View {
    let model: MessagesModel

    @State private var agreed = false

    init(model: MessagesModel) {
        self.model = model
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: "✨ Nimbus")
                        .font(.title2.weight(.bold))
                    Text("One quick thing before you start.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ConsentCheckbox(
                    isOn: $agreed,
                    termsURL: model.session.termsURL,
                    privacyURL: model.session.privacyURL,
                    onOpen: { url in model.open(url) }
                )

                Button {
                    model.recordConsent()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .disabled(!agreed)

                HStack {
                    Button("Not now") {
                        if model.receivedCard != nil {
                            model.wantsSignIn = false
                        } else {
                            model.close()
                        }
                    }
                    Spacer()
                    Button("Sign out", role: .destructive) {
                        model.signOut()
                    }
                }
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.borderless)
            }
            .padding(16)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}
