import Foundation
import SwiftUI
import UIKit

/// One message in a thread. User messages are right-aligned sky-gradient bubbles; answers are
/// left-aligned gray bubbles with typing dots, a "Searching the web…" label, the streaming
/// glow, an error row with retry, and a long-press menu.
struct ChatBubble: View {
    let message: ThreadMessage
    /// Render answers as inline Markdown (app surface). iMessage answers are plain text.
    var markdown: Bool = false
    /// Called for Copy; when nil the text goes to the general pasteboard.
    var onCopy: (() -> Void)?
    /// Shorter / Funnier / More formal. Hidden from the menu when nil.
    var onRewrite: ((RewriteKind) -> Void)?
    var onRegenerate: (() -> Void)?
    var onReport: (() -> Void)?
    /// "Try again" on a failed answer. Hidden when nil.
    var onRetry: (() -> Void)?

    init(
        message: ThreadMessage,
        markdown: Bool = false,
        onCopy: (() -> Void)? = nil,
        onRewrite: ((RewriteKind) -> Void)? = nil,
        onRegenerate: (() -> Void)? = nil,
        onReport: (() -> Void)? = nil,
        onRetry: (() -> Void)? = nil
    ) {
        self.message = message
        self.markdown = markdown
        self.onCopy = onCopy
        self.onRewrite = onRewrite
        self.onRegenerate = onRegenerate
        self.onReport = onReport
        self.onRetry = onRetry
    }

    @State private var copyTick = 0

    private var bubbleShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: NimbusTheme.bubbleCornerRadius, style: .continuous)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if message.role == .user {
                Spacer(minLength: 48)
                userBubble
            } else {
                assistantContent
                Spacer(minLength: 32)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
        .sensoryFeedback(.success, trigger: copyTick)
    }

    // MARK: - User

    private var userBubble: some View {
        Text(verbatim: message.text)
            .font(.body)
            .foregroundStyle(NimbusTheme.userBubbleText)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(NimbusTheme.userBubble, in: bubbleShape)
            .contentShape(.contextMenuPreview, bubbleShape)
            .contextMenu {
                Button {
                    copy()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }
            .accessibilityLabel(Text("You: \(message.text)"))
    }

    // MARK: - Assistant

    private var isSearching: Bool { message.state == .searching }
    private var isStreaming: Bool { message.state == .streaming }
    private var isWaiting: Bool { message.state == .waiting }
    private var isDone: Bool { message.state == .done }
    private var hasText: Bool { !message.text.isEmpty }

    @ViewBuilder
    private var assistantContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            if hasText {
                answerBubble
            } else if isWaiting || isSearching {
                TypingIndicator()
                    .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .bottomLeading)))
            }
            if isSearching {
                searchingLabel
            }
            if let failure = message.state.failureMessage {
                failureRow(failure)
            }
        }
        .animation(.snappy(duration: 0.25), value: message.state)
    }

    private var answerBubble: some View {
        answerText
            .font(.body)
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(NimbusTheme.assistantBubble, in: bubbleShape)
            .nimbusGlow(isActive: isStreaming || isSearching)
            .contentShape(.contextMenuPreview, bubbleShape)
            .contextMenu {
                answerMenu
            }
    }

    private var answerText: Text {
        if markdown,
           let attributed = try? AttributedString(
               markdown: MarkdownLite.inlineFriendly(message.text),
               options: AttributedString.MarkdownParsingOptions(
                   interpretedSyntax: .inlineOnlyPreservingWhitespace,
                   failurePolicy: .returnPartiallyParsedIfPossible
               )
           ) {
            return Text(attributed)
        }
        return Text(verbatim: message.text)
    }

    private var searchingLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: "globe")
                .symbolEffect(.pulse)
            Text("Searching the web…")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.leading, 6)
        .transition(.opacity)
    }

    private func failureRow(_ failure: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
            Text(verbatim: failure)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let onRetry {
                Button("Try again", action: onRetry)
                    .font(.callout.weight(.semibold))
                    .buttonStyle(.borderless)
            }
        }
        .padding(.leading, 6)
        .transition(.opacity)
    }

    @ViewBuilder
    private var answerMenu: some View {
        Button {
            copy()
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }
        if isDone {
            if let onRewrite {
                ForEach(RewriteKind.allCases) { kind in
                    Button {
                        onRewrite(kind)
                    } label: {
                        Label(kind.title, systemImage: kind.systemImage)
                    }
                }
            }
            if let onRegenerate {
                Button(action: onRegenerate) {
                    Label("Regenerate", systemImage: "arrow.clockwise")
                }
            }
            if let onReport {
                Divider()
                Button(role: .destructive, action: onReport) {
                    Label("Report", systemImage: "flag")
                }
            }
        }
    }

    private func copy() {
        if let onCopy {
            onCopy()
        } else {
            UIPasteboard.general.string = message.text
        }
        copyTick += 1
    }
}
