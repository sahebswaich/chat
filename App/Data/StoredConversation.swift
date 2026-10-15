import Foundation
import SwiftData

/// One saved chat thread.
///
/// The messages are stored as one JSON blob so the schema stays flat and migration-free.
/// Every field added after the first four has a default, so SwiftData can add more later
/// without a migration plan.
///
/// `nonisolated` keeps the model (and the key paths `@Query` / `#Predicate` build from it) out of
/// the module's default MainActor isolation, exactly like SwiftData models in any other module.
@Model
nonisolated final class StoredConversation {
    @Attribute(.unique) var id: UUID
    /// The first question, shortened.
    var title: String
    var createdAt: Date
    var updatedAt: Date
    /// `[ThreadMessage]` encoded as JSON.
    var messagesData: Data
    /// The start of the latest answer, for the sidebar.
    var preview: String = ""
    /// `ChatStyle.rawValue` of the latest request.
    var styleRaw: String = "default"
    /// Pasted conversation text the thread runs on, if any.
    var pastedContext: String? = nil

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        messagesData: Data = Data()
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messagesData = messagesData
    }

    /// The decoded thread (empty when the data can't be read).
    var messages: [ThreadMessage] {
        (try? JSONDecoder().decode([ThreadMessage].self, from: messagesData)) ?? []
    }

    /// The style of the latest request.
    var style: ChatStyle {
        ChatStyle(rawValue: styleRaw) ?? .default
    }
}
