import Foundation
import SwiftUI

/// What a new chat shows before the first question: the icon, a hint and a few starters.
struct ChatEmptyState: View {
    var onAsk: (String) -> Void

    init(onAsk: @escaping (String) -> Void) {
        self.onAsk = onAsk
    }

    var body: some View {
        VStack(spacing: 20) {
            NimbusLogoView(size: 76)
            VStack(spacing: 6) {
                Text("What can I help with?")
                    .font(.title2.weight(.bold))
                Text("Ask anything. Touch and hold an answer to rewrite it, or share it to Messages.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(spacing: 10) {
                ForEach(Starter.all) { starter in
                    ChipButton(emoji: starter.emoji, title: starter.title) {
                        onAsk(starter.title)
                    }
                }
            }
        }
        .padding(32)
        .frame(maxWidth: 440)
    }
}

/// A suggested first question.
private struct Starter: Identifiable {
    let emoji: String
    let title: String

    var id: String { title }

    static let all: [Starter] = [
        Starter(emoji: "💡", title: "Explain black holes like I'm 10"),
        Starter(emoji: "🍝", title: "A quick dinner idea with pasta"),
        Starter(emoji: "📰", title: "What's in the news today?"),
        Starter(emoji: "🎂", title: "Help me write a birthday message"),
    ]
}
