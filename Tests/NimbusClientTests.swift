import Foundation
import Testing

@Suite("NimbusClient and ChatEngine over the wire")
struct NimbusClientTests {
    /// A `/v1/chat` response in the exact shape the server sends.
    private static let contractStream: String = [
        ": keepalive", "",
        "event: meta", #"data: {"model":"claude-opus-5-5"}"#, "",
        "event: status", #"data: {"state":"searching"}"#, "",
        "event: status", #"data: {"state":"writing"}"#, "",
        "event: delta", #"data: {"text":"Nephilim 👋🏽 are "}"#, "",
        "event: delta", #"data: {"text":"giants."}"#, "",
        "event: done", #"data: {"stopReason":"end_turn","usedToday":13,"dailyLimit":200}"#, "",
    ].map { $0 + "\n" }.joined()

    private static let refusalStream: String = [
        "event: meta", #"data: {"model":"claude-opus-5-5"}"#, "",
        "event: delta", #"data: {"text":"Partial"}"#, "",
        "event: error", #"data: {"code":"refusal","message":"Nimbus can't help with that one."}"#, "",
    ].map { $0 + "\n" }.joined()

    private static let expectedEvents: [ChatEvent] = [
        .meta(model: "claude-opus-5-5"),
        .status("searching"),
        .status("writing"),
        .delta("Nephilim 👋🏽 are "),
        .delta("giants."),
        .done(DoneInfo(stopReason: "end_turn", usedToday: 13, dailyLimit: 200)),
    ]

    private func credential(_ host: String) -> Credential {
        Credential(host: host, token: "tok_test", name: "Tester", dailyLimit: 200)
    }

    private func makeClient(_ host: String, _ stub: StubURLProtocol.Stub, signedIn: Bool = true) -> NimbusClient {
        StubURLProtocol.register(stub, host: host)
        return NimbusClient(
            credential: signedIn ? credential(host) : nil,
            host: host,
            session: StubURLProtocol.makeSession()
        )
    }

    private func jsonStub(_ status: Int, _ json: String) -> StubURLProtocol.Stub {
        StubURLProtocol.Stub(status: status, headers: ["Content-Type": "application/json"], chunks: [Data(json.utf8)])
    }

    private func request(_ text: String = "what is nephilim") -> ChatRequest {
        ChatRequest(messages: [ChatTurn(role: .user, content: text)], style: .default, surface: .messages)
    }

    private func lastBody(_ host: String) throws -> [String: Any] {
        let data = try #require(StubURLProtocol.bodies(host: host).last)
        let object = try JSONSerialization.jsonObject(with: data)
        return try #require(object as? [String: Any])
    }

    private func sentContents(_ host: String) throws -> [String] {
        let body = try lastBody(host)
        let messages = try #require(body["messages"] as? [[String: Any]])
        return messages.compactMap { $0["content"] as? String }
    }

    private func waitUntilFinished(_ engine: ChatEngine) async throws {
        let deadline = ContinuousClock.now + .seconds(10)
        while engine.phase.isBusy, ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }
    }

    // MARK: - Streaming

    @Test(arguments: [1, 3, 7, 64, 100_000])
    func streamsContractEvents(chunkSize: Int) async throws {
        let host = "stream-\(chunkSize).nimbus.test"
        let client = makeClient(host, StubURLProtocol.Stub(chunks: StubURLProtocol.chunks(Self.contractStream, size: chunkSize)))

        var events: [ChatEvent] = []
        for try await event in client.stream(request()) {
            events.append(event)
        }
        #expect(events == Self.expectedEvents)

        let sent = try #require(StubURLProtocol.requests(host: host).last)
        #expect(sent.httpMethod == "POST")
        #expect(sent.url?.absoluteString == "https://\(host)/v1/chat")
        #expect(sent.value(forHTTPHeaderField: "Authorization") == "Bearer tok_test")
        #expect(sent.value(forHTTPHeaderField: "Accept") == "text/event-stream")
        #expect(sent.value(forHTTPHeaderField: "Content-Type") == "application/json")

        let body = try lastBody(host)
        #expect(body["surface"] as? String == "messages")
        #expect(body["style"] as? String == "default")
        #expect(try sentContents(host) == ["what is nephilim"])
    }

    @Test func answerJoinsTheDeltas() async throws {
        let client = makeClient("answer.nimbus.test", StubURLProtocol.Stub(chunks: [Data(Self.contractStream.utf8)]))
        let text = try await client.answer(request())
        #expect(text == "Nephilim 👋🏽 are giants.")
    }

    @Test func errorEventEndsTheStreamWithANimbusError() async throws {
        let client = makeClient("refusal.nimbus.test", StubURLProtocol.Stub(chunks: StubURLProtocol.chunks(Self.refusalStream, size: 5)))
        var events: [ChatEvent] = []
        var thrown: (any Error)?
        do {
            for try await event in client.stream(request()) {
                events.append(event)
            }
        } catch {
            thrown = error
        }
        #expect(events == [ChatEvent.meta(model: "claude-opus-5-5"), ChatEvent.delta("Partial")])
        let error = thrown as? NimbusError
        #expect(error == NimbusError.refusal)
    }

    @Test func preStreamErrorsAreDecoded() async throws {
        let limited = makeClient(
            "limit.nimbus.test",
            jsonStub(429, #"{"error":{"code":"daily_limit","message":"You've used all 200 messages for today.","resetAt":"2026-10-16T00:00:00.000Z"}}"#)
        )
        var thrown: (any Error)?
        do {
            for try await _ in limited.stream(request()) {}
        } catch {
            thrown = error
        }
        let error = thrown as? NimbusError
        #expect(error == NimbusError.dailyLimit("You've used all 200 messages for today."))
    }

    @Test func droppedConnectionIsANetworkError() async throws {
        let truncated = "event: meta\ndata: {\"model\":\"m\"}\n\nevent: delta\ndata: {\"text\":\"Hal\"}\n\n"
        let client = makeClient("dropped.nimbus.test", StubURLProtocol.Stub(chunks: [Data(truncated.utf8)]))
        var events: [ChatEvent] = []
        var thrown: (any Error)?
        do {
            for try await event in client.stream(request()) {
                events.append(event)
            }
        } catch {
            thrown = error
        }
        #expect(events.count == 2)
        let error = thrown as? NimbusError
        #expect(error?.code == "network")
    }

    @Test func streamWithoutCredentialFailsFast() async throws {
        let client = NimbusClient(credential: nil, host: "nobody.nimbus.test", session: StubURLProtocol.makeSession())
        var thrown: (any Error)?
        do {
            for try await _ in client.stream(request()) {}
        } catch {
            thrown = error
        }
        let error = thrown as? NimbusError
        #expect(error == NimbusError.notSignedIn)
        #expect(StubURLProtocol.requests(host: "nobody.nimbus.test").isEmpty)
    }

    // MARK: - JSON endpoints

    @Test func redeemSendsTheCodeWithoutAToken() async throws {
        let host = "redeem.nimbus.test"
        let client = makeClient(host, jsonStub(200, #"{"token":"tok_new","name":"James","dailyLimit":200}"#), signedIn: false)
        let response = try await client.redeem(code: "K7QM-2XPA", device: "Test iPhone")
        #expect(response == RedeemResponse(token: "tok_new", name: "James", dailyLimit: 200))

        let sent = try #require(StubURLProtocol.requests(host: host).last)
        #expect(sent.url?.absoluteString == "https://\(host)/v1/redeem")
        #expect(sent.value(forHTTPHeaderField: "Authorization") == nil)
        let body = try lastBody(host)
        #expect(body["code"] as? String == "K7QM-2XPA")
        #expect(body["device"] as? String == "Test iPhone")
    }

    @Test func redeemErrors() async throws {
        let used = makeClient("used.nimbus.test", jsonStub(410, #"{"error":{"code":"code_used_up","message":"Used."}}"#), signedIn: false)
        await #expect(throws: NimbusError.codeUsedUp) {
            _ = try await used.redeem(code: "K7QM-2XPA", device: "d")
        }
        let unknown = makeClient("unknown.nimbus.test", jsonStub(404, #"{"error":{"code":"invalid_code","message":"No."}}"#), signedIn: false)
        await #expect(throws: NimbusError.invalidCode) {
            _ = try await unknown.redeem(code: "K7QM-2XPA", device: "d")
        }
    }

    @Test func meAndDeleteAccount() async throws {
        let host = "me.nimbus.test"
        let me = try await makeClient(host, jsonStub(200, #"{"name":"James","usedToday":12,"dailyLimit":200,"supportEmail":""}"#)).me()
        #expect(me.usedToday == 12)
        #expect(me.supportEmail == "")
        #expect(StubURLProtocol.requests(host: host).last?.value(forHTTPHeaderField: "Authorization") == "Bearer tok_test")

        let deleteHost = "delete.nimbus.test"
        try await makeClient(deleteHost, StubURLProtocol.Stub(status: 204, headers: [:])).deleteAccount()
        let sent = try #require(StubURLProtocol.requests(host: deleteHost).last)
        #expect(sent.httpMethod == "DELETE")
        #expect(sent.url?.absoluteString == "https://\(deleteHost)/v1/me")

        let revoked = makeClient("revoked.nimbus.test", jsonStub(401, #"{"error":{"code":"unauthorized","message":"Missing or invalid token."}}"#))
        await #expect(throws: NimbusError.unauthorized) {
            _ = try await revoked.me()
        }
    }

    @Test func cardsAndReports() async throws {
        let host = "cards.nimbus.test"
        let created = try await makeClient(host, jsonStub(200, #"{"id":"AbC_123-xyz0Qw","url":"https://cards.nimbus.test/c/AbC_123-xyz0Qw"}"#))
            .createCard(question: "what is nephilim", answer: "Giants.")
        #expect(created.id == "AbC_123-xyz0Qw")
        let body = try lastBody(host)
        #expect(body["question"] as? String == "what is nephilim")
        #expect(body["answer"] as? String == "Giants.")

        let fetchHost = "fetch.nimbus.test"
        let detail = try await makeClient(
            fetchHost,
            jsonStub(200, #"{"id":"AbC_123-xyz0Qw","question":"q","answer":"The full answer.","createdAt":"2026-10-15T22:06:00.123Z"}"#),
            signedIn: false
        ).fetchCard(id: "AbC_123-xyz0Qw")
        #expect(detail.answer == "The full answer.")
        let fetched = try #require(StubURLProtocol.requests(host: fetchHost).last)
        #expect(fetched.url?.absoluteString == "https://\(fetchHost)/c/AbC_123-xyz0Qw.json")
        #expect(fetched.value(forHTTPHeaderField: "Authorization") == nil)

        let reportHost = "report.nimbus.test"
        try await makeClient(reportHost, StubURLProtocol.Stub(status: 204, headers: [:]))
            .report(messages: [ChatTurn(role: .user, content: "q")], answer: "a", reason: ReportReason.wrong.rawValue)
        let report = try lastBody(reportHost)
        #expect(report["reason"] as? String == "wrong")
        #expect(report["answer"] as? String == "a")
    }

    // MARK: - ChatEngine

    @Test func engineStreamsAnAnswerAndRewritesIt() async throws {
        let host = "engine.nimbus.test"
        let client = makeClient(host, StubURLProtocol.Stub(chunks: StubURLProtocol.chunks(Self.contractStream, size: 9)))
        let engine = ChatEngine(surface: .messages, client: { client })

        engine.ask("  what is nephilim  ")
        #expect(engine.phase.isBusy)
        #expect(engine.messages.count == 2)
        try await waitUntilFinished(engine)

        #expect(engine.phase == .done)
        #expect(engine.messages.count == 2)
        #expect(engine.messages[0].role == .user)
        #expect(engine.messages[0].text == "what is nephilim")
        let answer = try #require(engine.lastAnswer)
        #expect(answer.text == "Nephilim 👋🏽 are giants.")
        #expect(answer.question == "what is nephilim")
        #expect(answer.state == .done)
        #expect(engine.firstTokenTick == 1)
        #expect(engine.completionTick == 1)
        #expect(engine.errorTick == 0)
        #expect(engine.model == "claude-opus-5-5")
        #expect(try sentContents(host) == ["what is nephilim"])

        engine.rewrite(.shorter)
        try await waitUntilFinished(engine)
        #expect(try sentContents(host) == [
            "what is nephilim",
            "Nephilim 👋🏽 are giants.",
            "Rewrite your last answer to be shorter.",
        ])
        #expect(engine.messages.count == 4)
        #expect(engine.lastAnswer?.question == "what is nephilim")
        #expect(engine.completionTick == 2)

        engine.regenerate()
        try await waitUntilFinished(engine)
        #expect(engine.messages.count == 4)
        #expect(try sentContents(host).count == 3)

        engine.reset()
        #expect(engine.messages.isEmpty)
        #expect(engine.phase == .idle)
    }

    @Test func engineSendsContextAndStyle() async throws {
        let host = "context.nimbus.test"
        let client = makeClient(host, StubURLProtocol.Stub(chunks: [Data(Self.contractStream.utf8)]))
        let engine = ChatEngine(surface: .messages, client: { client })

        engine.ask("", style: .reply, context: "Sam: dinner at 8?")
        try await waitUntilFinished(engine)

        let body = try lastBody(host)
        #expect(body["style"] as? String == "reply")
        #expect(body["context"] as? String == "Sam: dinner at 8?")
        #expect(body["webSearch"] as? Bool == true)
        #expect(try sentContents(host) == [ChatStyle.reply.contextPrompt])
    }

    @Test func engineMarksFailuresAndLeavesThemOutOfHistory() async throws {
        let host = "engine-refusal.nimbus.test"
        let client = makeClient(host, StubURLProtocol.Stub(chunks: [Data(Self.refusalStream.utf8)]))
        let engine = ChatEngine(surface: .app, client: { client })

        engine.ask("something sketchy")
        try await waitUntilFinished(engine)

        #expect(engine.lastError == NimbusError.refusal)
        #expect(engine.errorTick == 1)
        #expect(engine.completionTick == 0)
        #expect(engine.lastAnswer == nil)
        let failed = try #require(engine.messages.last)
        #expect(failed.state.isFailed)
        #expect(failed.state.failureMessage == NimbusError.refusal.errorDescription)
        if case .failed = engine.phase {
            // expected
        } else {
            Issue.record("phase should be .failed, got \(engine.phase)")
        }
        #expect(ChatEngine.history(from: engine.messages) == [ChatTurn(role: .user, content: "something sketchy")])
    }

    @Test func engineIgnoresBlankQuestions() {
        let engine = ChatEngine(surface: .app, client: { NimbusClient(credential: nil, host: "unused.nimbus.test") })
        engine.ask("   \n ")
        #expect(engine.messages.isEmpty)
        #expect(engine.phase == .idle)
    }
}
