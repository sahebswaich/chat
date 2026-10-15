import Foundation
import SwiftUI

/// The expanded thread: `ChatBubble`s that follow the streaming answer, with the action bar
/// under the latest finished answer.
///
/// Built on `ChatBubble` rather than `ThreadView` so each bubble gets only the actions that
/// work on it: `ChatEngine`'s rewrite, regenerate and retry always act on the latest answer,
/// so older answers offer Copy and Report only, and "Try again" is hidden for errors a retry
/// can't fix (like the daily limit).
struct MessagesThreadView: View {
    let model: MessagesModel

    private static let bottomID = "nimbus.messages.thread.bottom"

    private var engine: ChatEngine { model.engine }

    /// Changes whenever a message is added, the streaming answer grows, or the footer changes.
    private var scrollKey: String {
        guard let last = engine.messages.last else {
            return "empty-\(model.receivedCard?.loadState == .loading)"
        }
        return "\(engine.messages.count)-\(last.text.utf8.count)-\(String(describing: last.state))-\(model.actionableAnswer != nil)-\(model.isAtDailyLimit)"
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(engine.messages) { message in
                        bubble(for: message)
                            .id(message.id)
                    }
                    footer
                    Color.clear
                        .frame(height: 1)
                        .id(Self.bottomID)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .animation(.snappy(duration: 0.25), value: model.actionableAnswer?.id)
            }
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: scrollKey) {
                proxy.scrollTo(Self.bottomID, anchor: .bottom)
            }
            .onAppear {
                proxy.scrollTo(Self.bottomID, anchor: .bottom)
            }
        }
    }

    // MARK: - Bubbles

    private func bubble(for message: ThreadMessage) -> ChatBubble {
        let isLast = message.id == engine.messages.last?.id
        let isLatestAnswer = isLast && message.isCompletedAnswer && !engine.isBusy

        var rewrite: ((RewriteKind) -> Void)?
        var regenerate: (() -> Void)?
        if isLatestAnswer {
            rewrite = { kind in model.rewrite(kind) }
            regenerate = { model.regenerate() }
        }

        var report: (() -> Void)?
        if message.isAssistant {
            report = { model.requestReport(message) }
        }

        var retry: (() -> Void)?
        if isLast, message.isAssistant, message.state.isFailed, model.canRetryLast, model.canAsk {
            retry = { model.retry(message) }
        }

        return ChatBubble(
            message: message,
            markdown: false,
            onCopy: { model.copy(message) },
            onRewrite: rewrite,
            onRegenerate: regenerate,
            onReport: report,
            onRetry: retry
        )
    }

    // MARK: - Footer

    @ViewBuilder
    private var footer: some View {
        if let card = model.receivedCard {
            cardLoadRow(card.loadState)
        }
        if let answer = model.actionableAnswer {
            AnswerActionBar(
                isPreparingCard: model.cardInFlight == answer.id,
                isDisabled: model.isDelivering,
                onSend: { model.send(answer) },
                onCard: { model.sendCard(answer) },
                onInsert: { model.insert(answer) },
                onCopy: { model.copy(answer) },
                onRewrite: { kind in model.rewrite(kind) },
                onRegenerate: { model.regenerate() },
                onReport: { model.requestReport(answer) }
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
        if model.isAtDailyLimit {
            LimitNotice(session: model.session)
                .transition(.opacity)
        }
    }

    @ViewBuilder
    private func cardLoadRow(_ state: ReceivedCard.LoadState) -> some View {
        switch state {
        case .idle:
            EmptyView()
        case .loading:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Loading the full answer…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 6)
        case .failed:
            Button {
                model.loadFullCard()
            } label: {
                Label("Couldn't load the full answer. Try again", systemImage: "arrow.clockwise")
                    .font(.footnote.weight(.semibold))
            }
            .buttonStyle(.borderless)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 6)
        }
    }
}
