import Foundation
import SwiftUI

/// A sidebar row: the question as the title, the start of the answer, and when it was updated.
struct ConversationRow: View {
    let conversation: StoredConversation

    init(conversation: StoredConversation) {
        self.conversation = conversation
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(conversation.title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer(minLength: 4)
                Text(conversation.updatedAt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if !conversation.preview.isEmpty {
                Text(conversation.preview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}
