import Foundation
import SwiftUI

/// `[📋 Paste] [💬 Reply for me] [🧠 Explain] [✅ Fact-check] [😂 Funny] [📝 Summarize]`,
/// wrapped onto as many rows as the width needs.
struct QuickActionChips: View {
    let model: MessagesModel

    private nonisolated enum Chip: Hashable, Sendable {
        case paste
        case action(QuickAction)
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            rows([
                [.paste, .action(.reply), .action(.explain), .action(.factcheck)],
                [.action(.funny), .action(.summarize)],
            ])
            rows([
                [.paste, .action(.reply), .action(.explain)],
                [.action(.factcheck), .action(.funny), .action(.summarize)],
            ])
            rows([
                [.paste, .action(.reply)],
                [.action(.explain), .action(.factcheck)],
                [.action(.funny), .action(.summarize)],
            ])
        }
    }

    private func rows(_ layout: [[Chip]]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(layout.indices, id: \.self) { index in
                HStack(spacing: 8) {
                    ForEach(layout[index], id: \.self) { chip in
                        chipView(chip)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func chipView(_ chip: Chip) -> some View {
        switch chip {
        case .paste:
            PasteChatButton(model: model)
        case .action(let action):
            ChipButton(quickAction: action, isSelected: model.pastedContext != nil) {
                model.run(action)
            }
            .accessibilityHint(model.pastedContext == nil ? "Opens the keyboard with this style picked." : "Runs on the pasted chat.")
        }
    }
}

/// The system Paste button (no paste-permission alert). Its text stores the copied chat as
/// context for the quick actions.
struct PasteChatButton: View {
    let model: MessagesModel

    var body: some View {
        PasteButton(payloadType: String.self) { @Sendable [model] strings in
            Task { @MainActor in
                model.receivePaste(strings)
            }
        }
        .buttonBorderShape(.capsule)
        .labelStyle(.titleAndIcon)
        .tint(NimbusTheme.accent)
        .sensoryFeedback(.selection, trigger: model.pasteTick)
        .accessibilityHint("Pastes a conversation you copied so Nimbus can reply to it, explain it or fact-check it.")
    }
}
