import Foundation
import SwiftUI

/// The expanded extension: a Messages-style thread with the streaming answer, the action bar
/// under the latest answer, and the composer (with a style picker) at the bottom.
struct ExpandedView: View {
    @Bindable var model: MessagesModel

    @FocusState private var composerFocused: Bool

    init(model: MessagesModel) {
        self.model = model
    }

    private var engine: ChatEngine { model.engine }

    private var showsEmptyState: Bool {
        engine.messages.isEmpty && model.receivedCard == nil
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if showsEmptyState {
                emptyState
            } else {
                MessagesThreadView(model: model)
            }
            bottomBar
        }
        .onChange(of: model.wantsComposerFocus, initial: true) { _, wants in
            guard wants else { return }
            model.wantsComposerFocus = false
            focusComposerSoon()
        }
        .confirmationDialog(
            "Report this answer?",
            isPresented: $model.isReporting,
            titleVisibility: .visible,
            presenting: model.reportTarget
        ) { message in
            ForEach(ReportReason.allCases) { reason in
                Button(reason.title) {
                    model.report(message, reason: reason)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("Reports go to the people who run this Nimbus server and are reviewed within 24 hours.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: "✨ Nimbus")
                    .font(.headline)
                if model.receivedCard != nil {
                    Text("Nimbus card")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            UsagePill(session: model.session)
            if !showsEmptyState {
                Button {
                    model.newChat()
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel("New chat")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                        .foregroundStyle(NimbusTheme.sky)
                        .symbolEffect(.pulse)
                        .accessibilityHidden(true)
                    Text("Ask anything")
                        .font(.title3.weight(.semibold))
                    Text("Answers go into this chat as a message or a Nimbus card.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 12)
                QuickActionChips(model: model)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Composer

    private var signInPrompt: String {
        model.session.isSignedIn ? "Continue to ask a follow-up" : "Sign in to ask a follow-up"
    }

    private var bottomBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let context = model.pastedContext {
                PastedContextPill(characterCount: context.count) {
                    model.clearPastedContext()
                }
            }
            if model.canAsk {
                HStack(alignment: .bottom, spacing: 8) {
                    styleMenu
                    ComposerBar(
                        text: $model.draft,
                        isStreaming: engine.isBusy,
                        focus: $composerFocused,
                        placeholder: model.placeholder,
                        onSubmit: { model.submitDraft() },
                        onStop: { model.engine.cancel() }
                    )
                    .disabled(model.isLoadingCard)
                }
            } else {
                Button {
                    model.wantsSignIn = true
                } label: {
                    Label(signInPrompt, systemImage: "person.crop.circle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .animation(.snappy(duration: 0.25), value: model.pastedContext)
    }

    /// A small glass button showing the current style's emoji; picks the answer style.
    private var styleMenu: some View {
        Menu {
            Picker("Answer style", selection: $model.composerStyle) {
                ForEach(ChatStyle.allCases) { style in
                    Label(style.title, systemImage: style.systemImage)
                        .tag(style)
                }
            }
            .pickerStyle(.inline)
        } label: {
            Text(verbatim: model.composerStyle.emoji)
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .glassEffect(.regular.interactive(), in: Circle())
        }
        .sensoryFeedback(.selection, trigger: model.composerStyle)
        .accessibilityLabel("Answer style")
        .accessibilityValue(model.composerStyle.title)
    }

    /// Focus after the expand animation settles so the keyboard comes up reliably.
    private func focusComposerSoon() {
        Task {
            try? await Task.sleep(for: .milliseconds(150))
            composerFocused = true
        }
    }
}
