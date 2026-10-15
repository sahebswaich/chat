import Foundation
import Observation

/// One finished answer in the compact view's "Recent" row.
nonisolated struct RecentAnswer: Codable, Identifiable, Hashable, Sendable {
    /// The answer bubble's id, so a card made for it can be found again.
    var id: UUID
    var question: String
    var answer: String
    var date: Date
    /// The card created for this answer, so sending it as a card again needs no network.
    var cardID: String?
    var cardHost: String?

    init(id: UUID, question: String, answer: String, date: Date = Date(), cardID: String? = nil, cardHost: String? = nil) {
        self.id = id
        self.question = question
        self.answer = answer
        self.date = date
        self.cardID = cardID
        self.cardHost = cardHost
    }
}

/// The last few answers, kept as JSON in the extension's own `UserDefaults`.
@Observable
final class RecentAnswersStore {
    static let maxCount = 8
    static let defaultsKey = "nimbus.messages.recentAnswers"

    /// Newest first.
    private(set) var items: [RecentAnswer] = []

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.items = Self.load(from: defaults)
    }

    /// Adds an answer to the front, replacing an identical earlier one.
    func add(_ entry: RecentAnswer) {
        var entry = entry
        entry.question = TextLimit.clip(entry.question, maxUTF16: TextLimit.cardQuestion)
        entry.answer = TextLimit.clip(entry.answer, maxUTF16: TextLimit.cardAnswer)
        guard !entry.answer.isEmpty else { return }

        var updated = items.filter { existing in
            existing.id != entry.id && !(existing.question == entry.question && existing.answer == entry.answer)
        }
        updated.insert(entry, at: 0)
        if updated.count > Self.maxCount {
            updated.removeLast(updated.count - Self.maxCount)
        }
        items = updated
        save()
    }

    /// Remembers the card made for an answer.
    func attachCard(_ card: PreparedCard, to id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        guard items[index].cardID != card.id || items[index].cardHost != card.host else { return }
        items[index].cardID = card.id
        items[index].cardHost = card.host
        save()
    }

    func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    func clear() {
        items = []
        defaults.removeObject(forKey: Self.defaultsKey)
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: Self.defaultsKey)
    }

    private static func load(from defaults: UserDefaults) -> [RecentAnswer] {
        guard let data = defaults.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([RecentAnswer].self, from: data)
        else { return [] }
        return Array(decoded.prefix(maxCount))
    }
}
