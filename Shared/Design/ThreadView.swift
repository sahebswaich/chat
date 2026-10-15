import Foundation
import SwiftUI

/// A scrolling Messages-style thread of `ChatBubble`s that follows the answer as it streams.
/// `footer` renders under the last message (e.g. the glass action bar under the latest answer).
struct ThreadView<Footer: View>: View {
    let messages: [ThreadMessage]
    var markdown: Bool = false
    var onCopy: ((ThreadMessage) -> Void)?
    var onRewrite: ((ThreadMessage, RewriteKind) -> Void)?
    var onRegenerate: ((ThreadMessage) -> Void)?
    var onReport: ((ThreadMessage) -> Void)?
    var onRetry: ((ThreadMessage) -> Void)?
    private let footer: Footer

    init(
        messages: [ThreadMessage],
        markdown: Bool = false,
        onCopy: ((ThreadMessage) -> Void)? = nil,
        onRewrite: ((ThreadMessage, RewriteKind) -> Void)? = nil,
        onRegenerate: ((ThreadMessage) -> Void)? = nil,
        onReport: ((ThreadMessage) -> Void)? = nil,
        onRetry: ((ThreadMessage) -> Void)? = nil,
        @ViewBuilder footer: () -> Footer
    ) {
        self.messages = messages
        self.markdown = markdown
        self.onCopy = onCopy
        self.onRewrite = onRewrite
        self.onRegenerate = onRegenerate
        self.onReport = onReport
        self.onRetry = onRetry
        self.footer = footer()
    }

    private let bottomID = "nimbus.thread.bottom"

    /// Changes whenever a message is added or the streaming answer grows.
    private var scrollKey: String {
        guard let last = messages.last else { return "empty" }
        return "\(messages.count)-\(last.text.utf8.count)-\(String(describing: last.state))"
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(messages) { message in
                        bubble(for: message)
                            .id(message.id)
                    }
                    footer
                    Color.clear
                        .frame(height: 1)
                        .id(bottomID)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: scrollKey) {
                proxy.scrollTo(bottomID, anchor: .bottom)
            }
            .onAppear {
                proxy.scrollTo(bottomID, anchor: .bottom)
            }
        }
    }

    private func bubble(for message: ThreadMessage) -> ChatBubble {
        ChatBubble(
            message: message,
            markdown: markdown,
            onCopy: bind(onCopy, to: message),
            onRewrite: bindRewrite(to: message),
            onRegenerate: bind(onRegenerate, to: message),
            onReport: bind(onReport, to: message),
            onRetry: bind(onRetry, to: message)
        )
    }

    private func bind(_ handler: ((ThreadMessage) -> Void)?, to message: ThreadMessage) -> (() -> Void)? {
        guard let handler else { return nil }
        return { handler(message) }
    }

    private func bindRewrite(to message: ThreadMessage) -> ((RewriteKind) -> Void)? {
        guard let onRewrite else { return nil }
        return { kind in onRewrite(message, kind) }
    }
}

extension ThreadView where Footer == EmptyView {
    init(
        messages: [ThreadMessage],
        markdown: Bool = false,
        onCopy: ((ThreadMessage) -> Void)? = nil,
        onRewrite: ((ThreadMessage, RewriteKind) -> Void)? = nil,
        onRegenerate: ((ThreadMessage) -> Void)? = nil,
        onReport: ((ThreadMessage) -> Void)? = nil,
        onRetry: ((ThreadMessage) -> Void)? = nil
    ) {
        self.init(
            messages: messages,
            markdown: markdown,
            onCopy: onCopy,
            onRewrite: onRewrite,
            onRegenerate: onRegenerate,
            onReport: onReport,
            onRetry: onRetry,
            footer: { EmptyView() }
        )
    }
}
