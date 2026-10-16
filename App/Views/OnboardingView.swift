import Foundation
import SwiftUI
import UIKit

/// Sign-in: the sky, the floating icon, the invite-code boxes and the AI consent box.
///
/// A `nimbus://join?code=…&host=…` link fills the code (and server) and redeems as soon as the
/// consent box is ticked; nothing is sent to the server before that (App Review 5.1.2(i)).
struct OnboardingView: View {
    @Environment(NimbusSession.self) private var session
    @Environment(NimbusRouter.self) private var router

    @State private var code = ""
    @State private var customHost = ""
    @State private var showsServerField = false
    @State private var linkHost: String?
    @State private var agreed = false
    @State private var isWorking = false
    @State private var errorMessage: String?
    @State private var codeErrorTick = 0
    @State private var errorFeedbackTick = 0
    @State private var redeemWhenAgreed = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            SkyBackground()
            ScrollView {
                VStack(spacing: 28) {
                    header
                    card
                    Text("After you sign in, Nimbus shows you where to find it in Messages.")
                        .font(.footnote)
                        .foregroundStyle(Color.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .frame(maxWidth: 460)
                .padding(.horizontal, 20)
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
        }
        .sensoryFeedback(.error, trigger: errorFeedbackTick)
        .sensoryFeedback(.selection, trigger: agreed)
        .onAppear {
            if session.host == nil {
                showsServerField = true
            }
            withAnimation(.smooth(duration: 0.9)) {
                appeared = true
            }
        }
        .onChange(of: router.pending, initial: true) {
            consumeJoinLink()
        }
        .onChange(of: agreed) { _, isAgreed in
            if isAgreed, redeemWhenAgreed {
                redeem()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 14) {
            NimbusLogoView(size: 128)
                .padding(.bottom, 6)
            Text("Nimbus")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(Color.white)
            Text("Your AI for iMessage")
                .font(.title3.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.88))
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Card

    private var card: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Enter your invite code")
                    .font(.headline)
                Text("Invites come from the person who shared Nimbus with you. Tap their invite link, or type the code here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            InviteCodeField(
                code: $code,
                errorTrigger: codeErrorTick,
                autoFocus: false,
                onComplete: { _ in
                    if agreed {
                        redeem()
                    }
                }
            )

            if let joiningHost {
                Label("Joining \(joiningHost)", systemImage: "link")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            serverDisclosure

            Divider()

            consent

            if redeemWhenAgreed, !agreed {
                Label("Tick the box above to finish joining.", systemImage: "hand.point.up.left.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(NimbusTheme.accent)
                    .transition(.opacity)
            }

            if let errorMessage {
                Label {
                    Text(errorMessage)
                } icon: {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                }
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
                .transition(.opacity)
            }

            continueButton
        }
        .padding(22)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .animation(.snappy(duration: 0.25), value: errorMessage)
        .animation(.snappy(duration: 0.25), value: redeemWhenAgreed)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 24)
    }

    private var serverDisclosure: some View {
        DisclosureGroup(isExpanded: $showsServerField) {
            VStack(alignment: .leading, spacing: 6) {
                TextField("nimbus.yourname.workers.dev", text: $customHost)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .submitLabel(.done)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(NimbusTheme.assistantBubble, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text("Only needed if your invite came without a link.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
        } label: {
            Label("Use a different server", systemImage: "server.rack")
                .font(.subheadline.weight(.medium))
        }
    }

    private var consent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                agreed.toggle()
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: agreed ? "checkmark.square.fill" : "square")
                        .font(.title2)
                        .foregroundStyle(agreed ? NimbusTheme.accent : Color.secondary)
                        .contentTransition(.symbolEffect(.replace))
                    Text("I agree to the Terms and to sending my questions to Claude")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(agreed ? .isSelected : [])

            Text("Nimbus sends your questions, and any conversation text you paste, to Anthropic's Claude AI to write answers. Answers are AI-generated and can be wrong.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 18) {
                if let termsURL {
                    Link("Terms of Use", destination: termsURL)
                }
                if let privacyURL {
                    Link("Privacy Policy", destination: privacyURL)
                }
            }
            .font(.footnote.weight(.semibold))
            .tint(NimbusTheme.accent)
        }
    }

    private var continueButton: some View {
        Button {
            redeem()
        } label: {
            HStack(spacing: 8) {
                if isWorking {
                    ProgressView()
                        .tint(.white)
                    Text("Checking…")
                        .font(.headline)
                } else {
                    Text("Continue")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.glassProminent)
        .tint(NimbusTheme.accent)
        .controlSize(.large)
        .disabled(!canContinue)
    }

    // MARK: - State

    /// The server the person typed (when the field is open) or the one from the join link.
    private var hostInput: String? {
        let typed = customHost.trimmingCharacters(in: .whitespacesAndNewlines)
        if showsServerField, !typed.isEmpty {
            return typed
        }
        return linkHost
    }

    /// The server that will be used, normalized; nil when none is known yet.
    private var effectiveHost: String? {
        if let hostInput {
            return NimbusConfig.normalizeHost(hostInput)
        }
        return session.host
    }

    /// Shown under the boxes when a link (or the server field) points somewhere other than the
    /// build's own server.
    private var joiningHost: String? {
        guard let effectiveHost, effectiveHost != NimbusConfig.defaultHost else { return nil }
        return effectiveHost
    }

    private var termsURL: URL? { session.pageURL("terms", host: effectiveHost) }
    private var privacyURL: URL? { session.pageURL("privacy", host: effectiveHost) }

    private var canContinue: Bool {
        code.count == InviteCode.length && agreed && !isWorking && effectiveHost != nil
    }

    // MARK: - Actions

    private func consumeJoinLink() {
        guard case .join(code: let linkCode, host: let host)? = router.pending else { return }
        router.pending = nil
        code = linkCode
        errorMessage = nil
        if let host {
            linkHost = host
            customHost = host
            if host != NimbusConfig.defaultHost {
                // Another server (named under the code boxes): agree to its terms, linked below,
                // before the code is sent there.
                agreed = false
            }
        }
        if agreed {
            redeem()
        } else {
            redeemWhenAgreed = true
        }
    }

    private func redeem() {
        guard canContinue else { return }
        isWorking = true
        errorMessage = nil
        redeemWhenAgreed = false
        let session = self.session
        let typedCode = code
        let host = hostInput
        Task {
            do {
                // Consent was just given: it's recorded with the credential.
                try await session.signIn(code: typedCode, host: host, consentedAt: Date())
                // RootView switches to the app and says hello.
            } catch {
                isWorking = false
                guard let mapped = NimbusError.from(error) else { return }
                errorMessage = mapped.errorDescription
                if mapped == .invalidCode || mapped == .codeUsedUp {
                    codeErrorTick += 1
                } else {
                    errorFeedbackTick += 1
                }
            }
        }
    }
}
