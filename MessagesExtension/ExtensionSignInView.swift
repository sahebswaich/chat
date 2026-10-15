import Foundation
import SwiftUI
import UIKit

/// Sign-in inside the extension: invite-code boxes, consent, and an optional custom server.
/// The keychain is shared with the app, so signing in here signs in both.
struct ExtensionSignInView: View {
    let model: MessagesModel

    @State private var code = ""
    @State private var host: String
    @State private var showsServer: Bool
    @State private var agreed = false
    @State private var isWorking = false
    @State private var errorText: String?
    @State private var errorTick = 0
    @FocusState private var hostFocused: Bool

    init(model: MessagesModel) {
        self.model = model
        let defaultHost = NimbusConfig.defaultHost
        _host = State(initialValue: defaultHost ?? "")
        _showsServer = State(initialValue: defaultHost == nil)
    }

    private var deviceName: String {
        UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
    }

    /// The server to redeem on: what's typed, else the one baked into the build.
    private var chosenHost: String? {
        let typed = host.trimmingCharacters(in: .whitespacesAndNewlines)
        if typed.isEmpty {
            return NimbusConfig.defaultHost
        }
        return NimbusConfig.normalizeHost(typed)
    }

    private var canSubmit: Bool {
        agreed && !isWorking && InviteCode.normalize(code) != nil && chosenHost != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter your invite code")
                        .font(.subheadline.weight(.semibold))
                    InviteCodeField(
                        code: $code,
                        errorTrigger: errorTick,
                        autoFocus: model.isExpanded,
                        onFocusChange: { focused in
                            if focused {
                                model.expand(focusComposer: false)
                            }
                        },
                        onComplete: { _ in
                            if agreed {
                                submit()
                            }
                        }
                    )
                    if let errorText {
                        Text(verbatim: errorText)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.opacity)
                    }
                }

                ConsentCheckbox(
                    isOn: $agreed,
                    termsURL: model.session.pageURL("terms", host: chosenHost),
                    privacyURL: model.session.pageURL("privacy", host: chosenHost),
                    onOpen: { url in model.open(url) }
                )

                Button {
                    submit()
                } label: {
                    HStack(spacing: 8) {
                        if isWorking {
                            ProgressView()
                        }
                        Text("Continue")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .disabled(!canSubmit)

                serverSection

                Text(verbatim: "Got a link? Open it on this \(deviceName) to sign in automatically.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if model.receivedCard != nil {
                    Button("Back to the card") {
                        model.wantsSignIn = false
                    }
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.borderless)
                }
            }
            .padding(16)
            .animation(.snappy(duration: 0.2), value: errorText)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollBounceBehavior(.basedOnSize)
        .onChange(of: hostFocused) { _, focused in
            if focused {
                model.expand(focusComposer: false)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: "✨ Nimbus")
                .font(.title2.weight(.bold))
            Text("Your AI for iMessage. Sign in with the invite code you were sent.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var serverSection: some View {
        DisclosureGroup("Server", isExpanded: $showsServer) {
            TextField("nimbus.yourname.workers.dev", text: $host)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($hostFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(NimbusTheme.assistantBubble, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.top, 6)
        }
        .font(.subheadline)
    }

    private func submit() {
        guard canSubmit else { return }
        let enteredCode = code
        let enteredHost = chosenHost
        isWorking = true
        errorText = nil
        Task {
            do {
                try await model.signIn(code: enteredCode, host: enteredHost)
            } catch {
                let failure = NimbusError.from(error) ?? NimbusError.network("Sign-in was interrupted. Try again?")
                errorText = failure.errorDescription
                errorTick += 1
            }
            isWorking = false
        }
    }
}
