import Foundation
import SwiftUI

/// Liquid Glass capsule for quick-action chips.
struct ChipButtonStyle: ButtonStyle {
    var isSelected: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .glassEffect(glass, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }

    private var glass: Glass {
        if isSelected {
            return Glass.regular.tint(NimbusTheme.accent.opacity(0.35)).interactive()
        }
        return Glass.regular.interactive()
    }
}

extension ButtonStyle where Self == ChipButtonStyle {
    /// `.buttonStyle(.chip)`
    static var chip: ChipButtonStyle { ChipButtonStyle() }
}

/// An emoji + title chip with a selection tick haptic, e.g. `[💬 Reply for me]`.
struct ChipButton: View {
    let emoji: String
    let title: String
    var isSelected: Bool
    let action: () -> Void

    init(emoji: String, title: String, isSelected: Bool = false, action: @escaping () -> Void) {
        self.emoji = emoji
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    init(style: ChatStyle, isSelected: Bool = false, action: @escaping () -> Void) {
        self.init(emoji: style.emoji, title: style.title, isSelected: isSelected, action: action)
    }

    init(quickAction: QuickAction, isSelected: Bool = false, action: @escaping () -> Void) {
        self.init(emoji: quickAction.emoji, title: quickAction.title, isSelected: isSelected, action: action)
    }

    @State private var tick = 0

    var body: some View {
        Button {
            tick += 1
            action()
        } label: {
            HStack(spacing: 6) {
                Text(verbatim: emoji)
                Text(verbatim: title)
            }
        }
        .buttonStyle(ChipButtonStyle(isSelected: isSelected))
        .sensoryFeedback(.selection, trigger: tick)
    }
}
