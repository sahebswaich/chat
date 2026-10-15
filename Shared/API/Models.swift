import Foundation

// Request/response bodies for the Nimbus server. Keys match docs/ARCHITECTURE.md exactly.

// MARK: - Redeem / me

nonisolated struct RedeemRequest: Codable, Sendable, Equatable {
    var code: String
    var device: String
}

nonisolated struct RedeemResponse: Codable, Sendable, Equatable {
    var token: String
    var name: String
    var dailyLimit: Int
}

nonisolated struct MeResponse: Codable, Sendable, Equatable {
    var name: String
    var usedToday: Int
    var dailyLimit: Int
    /// Owner's contact address (`""` when unset on the server; nil from older servers).
    var supportEmail: String?

    init(name: String, usedToday: Int, dailyLimit: Int, supportEmail: String? = nil) {
        self.name = name
        self.usedToday = usedToday
        self.dailyLimit = dailyLimit
        self.supportEmail = supportEmail
    }
}

// MARK: - Chat

nonisolated enum ChatRole: String, Codable, Sendable, Hashable {
    case user
    case assistant
}

nonisolated struct ChatTurn: Codable, Sendable, Equatable, Hashable {
    var role: ChatRole
    var content: String

    init(role: ChatRole, content: String) {
        self.role = role
        self.content = content
    }
}

/// Where a request comes from; the server tunes length and formatting per surface.
nonisolated enum Surface: String, Codable, Sendable, Hashable, CaseIterable {
    case messages
    case app
    case intent
}

nonisolated struct ChatRequest: Codable, Sendable, Equatable {
    /// Alternating user/assistant turns, starting and ending with `user`, at most 40.
    var messages: [ChatTurn]
    var style: ChatStyle
    var surface: Surface
    /// Pasted conversation text (≤ 20k chars). Omitted from the JSON when nil.
    var context: String?
    var webSearch: Bool

    init(messages: [ChatTurn], style: ChatStyle = .default, surface: Surface, context: String? = nil, webSearch: Bool = true) {
        self.messages = messages
        self.style = style
        self.surface = surface
        self.context = context
        self.webSearch = webSearch
    }
}

/// Payload of the `done` SSE event.
nonisolated struct DoneInfo: Codable, Sendable, Equatable {
    var stopReason: String
    var usedToday: Int?
    var dailyLimit: Int?

    init(stopReason: String = "end_turn", usedToday: Int? = nil, dailyLimit: Int? = nil) {
        self.stopReason = stopReason
        self.usedToday = usedToday
        self.dailyLimit = dailyLimit
    }

    private nonisolated enum CodingKeys: String, CodingKey {
        case stopReason, usedToday, dailyLimit
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stopReason = try container.decodeIfPresent(String.self, forKey: .stopReason) ?? "end_turn"
        usedToday = try container.decodeIfPresent(Int.self, forKey: .usedToday)
        dailyLimit = try container.decodeIfPresent(Int.self, forKey: .dailyLimit)
    }
}

/// One decoded event of the `/v1/chat` stream. `error` events are thrown as `NimbusError`.
nonisolated enum ChatEvent: Sendable, Equatable {
    /// Stream opened; the model answering.
    case meta(model: String)
    /// Progress: `"searching"` (web search started) or `"writing"` (text started).
    case status(String)
    /// The next chunk of answer text, in order.
    case delta(String)
    /// Finished.
    case done(DoneInfo)
}

// MARK: - Cards

nonisolated struct CardRequest: Codable, Sendable, Equatable {
    var question: String
    var answer: String
}

nonisolated struct CardResponse: Codable, Sendable, Equatable {
    var id: String
    /// `https://<host>/c/<id>` (the web fallback page).
    var url: URL
}

/// `GET /c/:id.json`
nonisolated struct CardDetail: Codable, Sendable, Equatable {
    var id: String
    var question: String
    var answer: String
    /// Parsed from the server's ISO-8601 string (or epoch seconds); nil if missing/unreadable.
    var createdAt: Date?

    init(id: String, question: String, answer: String, createdAt: Date? = nil) {
        self.id = id
        self.question = question
        self.answer = answer
        self.createdAt = createdAt
    }

    private nonisolated enum CodingKeys: String, CodingKey {
        case id, question, answer, createdAt
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        question = try container.decodeIfPresent(String.self, forKey: .question) ?? ""
        answer = try container.decodeIfPresent(String.self, forKey: .answer) ?? ""
        if let text = try? container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = Self.parseDate(text)
        } else if let seconds = try? container.decodeIfPresent(Double.self, forKey: .createdAt) {
            // Accept epoch seconds or milliseconds.
            createdAt = Date(timeIntervalSince1970: seconds > 100_000_000_000 ? seconds / 1000 : seconds)
        } else {
            createdAt = nil
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(question, forKey: .question)
        try container.encode(answer, forKey: .answer)
        if let createdAt {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            try container.encode(formatter.string(from: createdAt), forKey: .createdAt)
        }
    }

    static func parseDate(_ text: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: text) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: text)
    }
}

// MARK: - Report

nonisolated struct ReportRequest: Codable, Sendable, Equatable {
    var messages: [ChatTurn]
    var answer: String
    var reason: String
}

// MARK: - Errors

/// `{"code": "...", "message": "..."}` — the body of an `error` SSE event, and the inner
/// object of every JSON error response.
nonisolated struct APIErrorPayload: Codable, Sendable, Equatable {
    var code: String
    var message: String?
}

/// `{"error": {"code": "...", "message": "..."}}`
nonisolated struct APIErrorEnvelope: Codable, Sendable, Equatable {
    var error: APIErrorPayload
}
