import Foundation
import SwiftUI

/// The chat: a Messages-style thread with Markdown answers, the composer, the answer-style
/// menu and web-search toggle, the long-press answer menu and the share bar under the latest
/// answer. Styles that work on pasted text (Reply for me, Explain, Fact-check) show a Paste
/// button above the composer.
struct ChatView: View {
    @Bindable var conversations: ConversationController
    /// Starts a fresh thread (MainView also moves the sidebar selection).
    var onNewChat: () -> Void

    init(conversations: ConversationController, onNewChat: @escaping () -> Void) {
        _conversations = Bindable(wrappedValue: conversations)
        self.onNewChat = onNewChat
    }

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage(AppSettings.webSearchKey) private var webSearchEnabled = true

    @State private var draft = ""
    @FocusState private var composerFocused: Bool
    @State private var reportTarget: ThreadMessage?
    @State private var showsReportOptions = false
    @State private var notice: ChatNotice?
    @State private var showsNotice = false

    private var engine: ChatEngine { conversations.engine }
    private var style: ChatStyle { conversations.selectedStyle }
    /// "Try again" is hidden when retrying can't help (daily limit, refusal, signed out).
    private var canRetry: Bool { engine.lastError?.isRetryable ?? true }

    var body: some View {
        screen
            .nimbusHaptics(for: engine)
            .sensoryFeedback(.selection, trigger: conversations.selectedStyle)
            .confirmationDialog(
                "Report this answer",
                isPresented: $showsReportOptions,
                titleVisibility: .visible,
                presenting: reportTarget
            ) { message in
                ForEach(ReportReason.allCases) { reason in
                    Button(reason.title) {
                        submitReport(message, reason: reason)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { _ in
                Text("Reports go to the person who runs this Nimbus server and are reviewed within 24 hours.")
            }
            .alert(
                notice?.title ?? "",
                isPresented: $showsNotice,
                presenting: notice
            ) { _ in
                Button("OK", role: .cancel) {}
            } message: { notice in
                Text(notice.message)
            }
            .onChange(of: conversations.focusRequest, initial: true) {
                applyFocusRequest()
            }
            .onChange(of: conversations.currentID) {
                draft = ""
            }
    }

    // MARK: - Thread

    private var screen: some View {
        thread
            .overlay {
                if engine.messages.isEmpty {
                    ChatEmptyState { question in
                        conversations.ask(question)
                    }
                    .transition(.opacity)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                composerArea
            }
            .navigationTitle(conversations.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
    }

    private var thread: some View {
        ThreadView(
            messages: engine.messages,
            markdown: true,
            onRewrite: { message, kind in
                rewrite(message, kind: kind)
            },
            onRegenerate: { message in
                regenerate(message)
            },
            onReport: { message in
                reportTarget = message
                showsReportOptions = true
            },
            onRetry: canRetry ? { (message: ThreadMessage) in regenerate(message) } : nil
        ) {
            actionBar
        }
    }

    @ViewBuilder
    private var actionBar: some View {
        if let answer = engine.lastAnswer, answer.id == engine.messages.last?.id {
            AnswerActionBar(
                answer: answer,
                onRewrite: { kind in
                    conversations.rewrite(kind)
                },
                onRegenerate: {
                    conversations.regenerate()
                },
                onReport: {
                    reportTarget = answer
                    showsReportOptions = true
                }
            )
            .padding(.top, 2)
            .transition(.opacity)
        }
    }

    // MARK: - Composer

    private var composerArea: some View {
        VStack(spacing: 8) {
            if showsModeBar {
                modeBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            ComposerBar(
                text: $draft,
                isStreaming: engine.isBusy,
                focus: $composerFocused,
                placeholder: placeholder,
                onSubmit: {
                    send()
                },
                onStop: {
                    conversations.stop()
                }
            )
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .animation(.snappy(duration: 0.25), value: showsModeBar)
    }

    private var showsModeBar: Bool {
        style != .default || conversations.stagedContext != nil || engine.context != nil
    }

    /// The selected style chip (tap to clear) and the pasted-chat controls.
    private var modeBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                if style != .default {
                    Button {
                        conversations.selectedStyle = .default
                    } label: {
                        HStack(spacing: 6) {
                            Text(verbatim: style.emoji)
                            Text(style.title)
                            Image(systemName: "xmark")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(ChipButtonStyle(isSelected: true))
                    .accessibilityLabel(Text("Style: \(style.title)"))
                    .accessibilityHint(Text("Removes the style"))
                }
                if conversations.stagedContext != nil {
                    Button {
                        conversations.clearStagedPaste()
                    } label: {
                        HStack(spacing: 6) {
                            Text(verbatim: "📋")
                            Text("Chat pasted")
                            Image(systemName: "xmark")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.chip)
                    .accessibilityHint(Text("Removes the pasted chat"))

                    Button {
                        conversations.runOnPastedText()
                    } label: {
                        Text(runTitle)
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.glassProminent)
                    .tint(NimbusTheme.accent)
                    .disabled(engine.isBusy)
                } else if style.needsContext {
                    pasteButton
                } else if engine.context != nil {
                    Label("Answering about your pasted chat", systemImage: "doc.on.clipboard")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    /// Pastes through the system Paste button, so there's no "allow paste" prompt.
    private var pasteButton: some View {
        let controller = conversations
        return PasteButton(payloadType: String.self) { @Sendable (strings: [String]) in
            let text = strings.joined(separator: "\n")
            Task { @MainActor in
                controller.stagePaste(text)
            }
        }
        .buttonBorderShape(.capsule)
        .labelStyle(.titleAndIcon)
        .accessibilityHint(Text("Pastes the conversation you copied from Messages"))
    }

    private var runTitle: String {
        style == .default ? "✨ Help with this" : "\(style.emoji) \(style.title)"
    }

    private var placeholder: String {
        if conversations.stagedContext != nil {
            return "Add a note (optional)…"
        }
        if style.needsContext {
            return "Paste the chat, or ask anything…"
        }
        return engine.messages.isEmpty ? "Ask anything…" : "Ask a follow-up…"
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Answer style", selection: $conversations.selectedStyle) {
                    ForEach(ChatStyle.allCases) { option in
                        Label(option.title, systemImage: option.systemImage)
                            .tag(option)
                    }
                }
                .pickerStyle(.inline)
                Section {
                    Toggle(isOn: $webSearchEnabled) {
                        Label("Search the web", systemImage: "globe")
                    }
                }
            } label: {
                Label("Answer style", systemImage: style == .default ? "wand.and.stars" : style.systemImage)
            }
        }
        if horizontalSizeClass == .compact {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onNewChat()
                } label: {
                    Label("New Chat", systemImage: "square.and.pencil")
                }
            }
        }
    }

    // MARK: - Actions

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draft = ""
        conversations.ask(text)
    }

    /// The latest answer is rewritten in place; an older one is quoted into a new question.
    private func rewrite(_ message: ThreadMessage, kind: RewriteKind) {
        if message.id == engine.lastAnswer?.id {
            conversations.rewrite(kind)
        } else {
            conversations.ask(Self.rewriteRequest(kind, of: message.text))
        }
    }

    /// The last answer is replaced; an older one gets its question asked again.
    private func regenerate(_ message: ThreadMessage) {
        if message.id == engine.messages.last?.id {
            conversations.regenerate()
        } else if let question = message.question, !question.isEmpty {
            conversations.ask(question)
        }
    }

    private func submitReport(_ message: ThreadMessage, reason: ReportReason) {
        let engine = self.engine
        Task {
            do {
                try await engine.report(message, reason: reason)
                show(ChatNotice(
                    title: "Thanks for the report",
                    message: "The person who runs this Nimbus server reviews reports within 24 hours."
                ))
            } catch {
                guard let mapped = NimbusError.from(error) else { return }
                show(ChatNotice(
                    title: "Couldn't send the report",
                    message: mapped.errorDescription ?? "Try again in a moment."
                ))
            }
        }
    }

    private func show(_ newNotice: ChatNotice) {
        notice = newNotice
        showsNotice = true
    }

    private func applyFocusRequest() {
        guard conversations.consumeFocusRequest() else { return }
        let prefill = conversations.consumeDraft()
        Task {
            // Let a navigation push finish before the keyboard comes up (and after the
            // thread switch has cleared the old draft).
            try? await Task.sleep(for: .milliseconds(350))
            if let prefill {
                draft = prefill
            }
            composerFocused = true
        }
    }

    nonisolated static func rewriteRequest(_ kind: RewriteKind, of text: String) -> String {
        let lead: String
        switch kind {
        case .shorter: lead = "Make this shorter:"
        case .funnier: lead = "Make this funnier:"
        case .formal: lead = "Make this sound more formal:"
        }
        return lead + "\n\n" + TextLimit.clip(text, maxUTF16: 4_000)
    }
}

/// A one-off message for an alert (report sent / failed).
private struct ChatNotice {
    let title: String
    let message: String
}
