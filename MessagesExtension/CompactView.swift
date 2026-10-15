import Foundation
import SwiftUI

/// The compact (keyboard-height) panel from the + drawer: header with usage, a prompt bar that
/// expands to type, quick-action chips that run on a pasted chat, and recent answers.
struct CompactView: View {
    let model: MessagesModel

    private var engine: ChatEngine { model.engine }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header
                promptBar
                if engine.isBusy {
                    liveRow
                        .transition(.opacity)
                }
                QuickActionChips(model: model)
                if let context = model.pastedContext {
                    PastedContextPill(characterCount: context.count) {
                        model.clearPastedContext()
                    }
                } else if model.recents.items.isEmpty {
                    Text("Copy some messages, tap Paste, then pick what Nimbus should do.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !model.recents.items.isEmpty {
                    recentSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .animation(.snappy(duration: 0.25), value: model.pastedContext)
            .animation(.snappy(duration: 0.25), value: engine.isBusy)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Text(verbatim: "✨ Nimbus")
                .font(.headline)
            Spacer(minLength: 8)
            UsagePill(session: model.session)
        }
    }

    // MARK: - Prompt bar

    /// Looks like the composer, but compact mode has no keyboard: tapping expands and focuses.
    private var promptBar: some View {
        Button {
            model.startTyping()
        } label: {
            HStack(spacing: 8) {
                Text("Ask anything…")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(NimbusTheme.sendBlue))
            }
            .padding(.leading, 16)
            .padding(.trailing, 6)
            .frame(height: 44)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Capsule())
        .accessibilityLabel("Ask anything")
        .accessibilityHint("Opens Nimbus with the keyboard.")
    }

    // MARK: - Streaming in compact

    private var phaseText: String {
        switch engine.phase {
        case .searching: return "Searching the web…"
        case .writing: return "Writing…"
        case .idle, .thinking, .done, .failed: return "Thinking…"
        }
    }

    private var liveRow: some View {
        Button {
            model.expand(focusComposer: false)
        } label: {
            HStack(spacing: 10) {
                TypingIndicator()
                    .scaleEffect(0.75)
                    .frame(width: 54, height: 30)
                Text(verbatim: phaseText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                Image(systemName: "chevron.up")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 6)
            .padding(.trailing, 14)
            .padding(.vertical, 4)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Capsule())
        .accessibilityLabel("Nimbus is answering. Show the answer.")
    }

    // MARK: - Recent

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Recent")
                .font(.caption.weight(.semibold).smallCaps())
                .foregroundStyle(.secondary)
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 8) {
                    ForEach(model.recents.items) { recent in
                        RecentAnswerTile(recent: recent) {
                            model.openRecent(recent)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                model.recents.remove(recent.id)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, -16)
        }
    }
}

/// One recent answer: the question and the start of the answer. Tap to open it expanded.
private struct RecentAnswerTile: View {
    let recent: RecentAnswer
    let action: () -> Void

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
    }

    var body: some View {
        Button {
            action()
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: recent.question.isEmpty ? "Answer" : recent.question)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(verbatim: recent.answer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(width: 150, alignment: .topLeading)
            .padding(10)
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: shape)
        .accessibilityLabel(recent.question.isEmpty ? recent.answer : recent.question)
        .accessibilityHint("Opens this answer.")
    }
}
