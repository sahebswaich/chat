import Foundation
import Testing

@Suite("Models match the API contract")
struct ModelsCodingTests {
    // MARK: - Helpers

    private func jsonObject(_ value: some Encodable) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        let object = try JSONSerialization.jsonObject(with: data)
        return try #require(object as? [String: Any])
    }

    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    private func user(_ text: String, state: MessageState = .done) -> ThreadMessage {
        ThreadMessage(role: .user, text: text, state: state)
    }

    private func assistant(_ text: String, state: MessageState = .done) -> ThreadMessage {
        ThreadMessage(role: .assistant, text: text, state: state)
    }

    // MARK: - Raw values

    @Test func styleRawValuesAreTheServerStyles() {
        #expect(ChatStyle.allCases.map(\.rawValue) == ["default", "short", "funny", "formal", "explain", "reply", "factcheck"])
        #expect(ChatStyle.allCases.filter(\.needsContext) == [.explain, .reply, .factcheck])
    }

    @Test func surfaceAndRoleRawValues() {
        #expect(Surface.allCases.map(\.rawValue) == ["messages", "app", "intent"])
        #expect(ChatRole.user.rawValue == "user")
        #expect(ChatRole.assistant.rawValue == "assistant")
    }

    @Test func summarizeIsNotAServerStyle() {
        #expect(QuickAction.summarize.style == .default)
        #expect(QuickAction.summarize.prompt == "Summarize this conversation")
        #expect(QuickAction.reply.style == .reply)
        #expect(QuickAction.factcheck.style == .factcheck)
        #expect(QuickAction.explain.style == .explain)
    }

    // MARK: - Requests

    @Test func chatRequestEncodesExactlyTheContractKeys() throws {
        let request = ChatRequest(
            messages: [
                ChatTurn(role: .user, content: "what is nephilim"),
                ChatTurn(role: .assistant, content: "Giants in Genesis 6."),
                ChatTurn(role: .user, content: "shorter"),
            ],
            style: .factcheck,
            surface: .messages,
            context: "pasted text",
            webSearch: true
        )
        let object = try jsonObject(request)
        #expect(Set(object.keys) == ["messages", "style", "surface", "context", "webSearch"])
        #expect(object["style"] as? String == "factcheck")
        #expect(object["surface"] as? String == "messages")
        #expect(object["context"] as? String == "pasted text")
        #expect(object["webSearch"] as? Bool == true)

        let messages = try #require(object["messages"] as? [[String: Any]])
        #expect(messages.count == 3)
        #expect(messages.map { Set($0.keys) } == Array(repeating: Set(["role", "content"]), count: 3))
        #expect(messages.map { $0["role"] as? String } == ["user", "assistant", "user"])
        #expect(messages[0]["content"] as? String == "what is nephilim")
    }

    @Test func nilContextIsOmitted() throws {
        let request = ChatRequest(messages: [ChatTurn(role: .user, content: "hi")], surface: .app, webSearch: false)
        let object = try jsonObject(request)
        #expect(Set(object.keys) == ["messages", "style", "surface", "webSearch"])
        #expect(object["style"] as? String == "default")
        #expect(object["surface"] as? String == "app")
        #expect(object["webSearch"] as? Bool == false)
    }

    @Test func otherRequestBodies() throws {
        let redeem = try jsonObject(RedeemRequest(code: "K7QM-2XPA", device: "Saheb's iPhone"))
        #expect(Set(redeem.keys) == ["code", "device"])
        #expect(redeem["code"] as? String == "K7QM-2XPA")

        let card = try jsonObject(CardRequest(question: "q", answer: "a"))
        #expect(Set(card.keys) == ["question", "answer"])

        let report = try jsonObject(ReportRequest(
            messages: [ChatTurn(role: .user, content: "q")],
            answer: "a",
            reason: ReportReason.offensive.rawValue
        ))
        #expect(Set(report.keys) == ["messages", "answer", "reason"])
        #expect(report["reason"] as? String == "offensive")
    }

    // MARK: - Responses

    @Test func decodesRedeemAndMe() throws {
        let redeem = try decode(RedeemResponse.self, #"{"token": "tok_123", "name": "James", "dailyLimit": 200}"#)
        #expect(redeem == RedeemResponse(token: "tok_123", name: "James", dailyLimit: 200))

        let me = try decode(MeResponse.self, #"{"name": "James", "usedToday": 12, "dailyLimit": 200, "supportEmail": "owner@example.com"}"#)
        #expect(me == MeResponse(name: "James", usedToday: 12, dailyLimit: 200, supportEmail: "owner@example.com"))

        let older = try decode(MeResponse.self, #"{"name": "James", "usedToday": 0, "dailyLimit": 50}"#)
        #expect(older.supportEmail == nil)
    }

    @Test func decodesCards() throws {
        let created = try decode(CardResponse.self, #"{"id": "AbC_123-xyz0Qw", "url": "https://nimbus.test.dev/c/AbC_123-xyz0Qw"}"#)
        #expect(created.id == "AbC_123-xyz0Qw")
        #expect(created.url.absoluteString == "https://nimbus.test.dev/c/AbC_123-xyz0Qw")

        let detail = try decode(
            CardDetail.self,
            #"{"id": "AbC_123-xyz0Qw", "question": "what is nephilim", "answer": "Giants.", "createdAt": "2026-10-15T22:06:00.123Z"}"#
        )
        #expect(detail.question == "what is nephilim")
        #expect(detail.answer == "Giants.")
        let createdAt = try #require(detail.createdAt)
        #expect(abs(createdAt.timeIntervalSince1970 - 1_792_101_960.123) < 0.01)

        let noFraction = try decode(CardDetail.self, #"{"id": "x1", "question": "", "answer": "a", "createdAt": "2026-10-15T22:06:00Z"}"#)
        #expect(noFraction.createdAt != nil)

        let missingDate = try decode(CardDetail.self, #"{"id": "x1", "question": "q", "answer": "a"}"#)
        #expect(missingDate.createdAt == nil)
    }

    @Test func decodesTheDoneEvent() throws {
        let done = try decode(DoneInfo.self, #"{"stopReason": "end_turn", "usedToday": 13, "dailyLimit": 200}"#)
        #expect(done == DoneInfo(stopReason: "end_turn", usedToday: 13, dailyLimit: 200))

        let sparse = try decode(DoneInfo.self, "{}")
        #expect(sparse == DoneInfo(stopReason: "end_turn", usedToday: nil, dailyLimit: nil))

        let event = try ChatEventDecoder.decode(SSEEvent(event: "done", data: #"{"stopReason":"end_turn","usedToday":13,"dailyLimit":200}"#))
        #expect(event == ChatEvent.done(DoneInfo(stopReason: "end_turn", usedToday: 13, dailyLimit: 200)))
    }

    // MARK: - Errors

    @Test func mapsContractErrorBodies() {
        func mapped(_ status: Int, _ json: String) -> NimbusError {
            NimbusError.from(status: status, body: Data(json.utf8))
        }
        #expect(mapped(401, #"{"error": {"code": "unauthorized", "message": "Missing or invalid token."}}"#) == .unauthorized)
        #expect(mapped(404, #"{"error": {"code": "invalid_code", "message": "Nope"}}"#) == .invalidCode)
        #expect(mapped(410, #"{"error": {"code": "code_used_up", "message": "Used"}}"#) == .codeUsedUp)
        #expect(mapped(400, #"{"error": {"code": "invalid_request", "message": "Bad body"}}"#) == .invalidRequest("Bad body"))

        let limit = mapped(429, #"{"error": {"code": "daily_limit", "message": "Resets in 3h 12m.", "resetAt": "2026-10-16T00:00:00.000Z"}}"#)
        #expect(limit == .dailyLimit("Resets in 3h 12m."))
        #expect(limit.errorDescription == "Resets in 3h 12m.")

        let internalError = mapped(500, #"{"error": {"code": "internal", "message": "Boom"}}"#)
        #expect(internalError == .server(status: 500, code: "internal", message: "Boom"))
    }

    @Test func mapsBareStatusCodes() {
        #expect(NimbusError.from(status: 401, body: Data()) == .unauthorized)
        #expect(NimbusError.from(status: 429, body: Data("<html>".utf8)) == .dailyLimit(""))
        #expect(NimbusError.from(status: 503, body: Data()) == .overloaded)
        #expect(NimbusError.from(status: 418, body: Data()) == .server(status: 418, code: "http_418", message: ""))
    }

    @Test func mapsStreamErrorCodes() {
        #expect(NimbusError.from(code: "refusal", message: "x", status: 200) == .refusal)
        #expect(NimbusError.from(code: "overloaded", message: "x", status: 200) == .overloaded)
        #expect(NimbusError.from(code: "max_tokens", message: "x", status: 200) == .maxTokens)
        #expect(NimbusError.from(code: "upstream", message: "x", status: 200) == .upstream("x"))
    }

    @Test func everyErrorHasFriendlyText() {
        let errors: [NimbusError] = [
            .notSignedIn, .unauthorized, .invalidCode, .codeUsedUp, .dailyLimit(""), .invalidRequest(""),
            .refusal, .overloaded, .maxTokens, .upstream(""), .server(status: 500, code: "internal", message: ""),
            .network("You're offline."), .badResponse,
        ]
        for error in errors {
            let text = error.errorDescription ?? ""
            #expect(!text.isEmpty, "\(error)")
        }
    }

    @Test func transportErrorsMapToNetworkOrCancellation() {
        #expect(NimbusError.from(URLError(.cancelled)) == nil)
        #expect(NimbusError.from(CancellationError()) == nil)
        let offline = NimbusError.from(URLError(.notConnectedToInternet))
        #expect(offline?.code == "network")
        #expect(NimbusError.from(NimbusError.refusal) == NimbusError.refusal)
    }

    // MARK: - Thread messages

    @Test func threadMessagesRoundTrip() throws {
        let messages = [
            ThreadMessage(role: .user, text: "q"),
            ThreadMessage(role: .assistant, text: "a", question: "q", state: .done),
            ThreadMessage(role: .assistant, text: "", question: "q", state: .failed("Nope")),
            ThreadMessage(role: .assistant, text: "half", question: "q", state: .streaming),
        ]
        let data = try JSONEncoder().encode(messages)
        let decoded = try JSONDecoder().decode([ThreadMessage].self, from: data)
        #expect(decoded == messages)
        #expect(decoded[3].settled().state == .done)
        #expect(ThreadMessage(role: .assistant, text: "", state: .waiting).settled().state.isFailed)
    }

    // MARK: - History sent to the server

    @Test func historyAlternatesAndEndsWithTheQuestion() {
        let turns = ChatEngine.history(from: [
            user("what is nephilim"),
            assistant("Giants in Genesis 6."),
            user("who wrote genesis"),
        ])
        #expect(turns == [
            ChatTurn(role: .user, content: "what is nephilim"),
            ChatTurn(role: .assistant, content: "Giants in Genesis 6."),
            ChatTurn(role: .user, content: "who wrote genesis"),
        ])
    }

    @Test func historySkipsFailedAndUnfinishedAnswers() {
        let turns = ChatEngine.history(from: [
            user("first"),
            assistant("", state: .failed("Nope")),
            user("second"),
            assistant("half an answer", state: .failed("Dropped")),
            user("third"),
            assistant("", state: .waiting),
        ])
        // Unanswered questions are replaced by the next one; the conversation stays valid.
        #expect(turns == [ChatTurn(role: .user, content: "third")])
    }

    @Test func historyNeverEndsOrStartsWithTheAssistant() {
        let endsWithAnswer = ChatEngine.history(from: [user("q"), assistant("a")])
        #expect(endsWithAnswer == [ChatTurn(role: .user, content: "q")])

        let startsWithAnswer = ChatEngine.history(from: [assistant("Welcome!"), user("q")])
        #expect(startsWithAnswer == [ChatTurn(role: .user, content: "q")])

        #expect(ChatEngine.history(from: []).isEmpty)
        #expect(ChatEngine.history(from: [assistant("only me")]).isEmpty)
    }

    @Test func historySkipsBlankMessagesAndTrimsWhitespace() {
        let turns = ChatEngine.history(from: [
            user("  q1  "),
            assistant("\n a1 \n"),
            user("   "),
            user("q2"),
        ])
        #expect(turns == [
            ChatTurn(role: .user, content: "q1"),
            ChatTurn(role: .assistant, content: "a1"),
            ChatTurn(role: .user, content: "q2"),
        ])
    }

    @Test func historyKeepsTheNewest40Turns() {
        var messages: [ThreadMessage] = []
        for index in 0..<30 {
            messages.append(user("q\(index)"))
            messages.append(assistant("a\(index)"))
        }
        messages.append(user("latest"))

        let turns = ChatEngine.history(from: messages)
        #expect(turns.count <= 40)
        #expect(turns.count >= 39)
        #expect(turns.first?.role == .user)
        #expect(turns.last == ChatTurn(role: .user, content: "latest"))
        for (index, turn) in turns.enumerated() {
            #expect(turn.role == (index.isMultiple(of: 2) ? .user : .assistant), "turn \(index)")
        }
        // The oldest turns were dropped, the newest kept.
        #expect(turns.contains(ChatTurn(role: .assistant, content: "a29")))
        #expect(!turns.contains(ChatTurn(role: .user, content: "q0")))
    }

    @Test func historyClipsLongContentByUTF16() {
        let long = String(repeating: "😀", count: 15_000)
        let turns = ChatEngine.history(from: [user(long)])
        let content = turns.first?.content ?? ""
        #expect(content.utf16.count == TextLimit.chatContent)
        #expect(content.hasPrefix("😀"))
    }

    @Test func clipNeverSplitsACharacter() {
        #expect(TextLimit.clip("hello", maxUTF16: 10) == "hello")
        #expect(TextLimit.clip("hello", maxUTF16: 3) == "hel")
        #expect(TextLimit.clip("a😀b", maxUTF16: 2) == "a")
        #expect(TextLimit.clip("a😀b", maxUTF16: 3) == "a😀")
        #expect(TextLimit.clip("👨‍👩‍👧‍👦x", maxUTF16: 5) == "")
    }
}
