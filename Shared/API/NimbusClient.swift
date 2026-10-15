import Foundation

/// Talks to the Nimbus server (see docs/ARCHITECTURE.md for the contract).
///
/// Value type, cheap to create: build one per request from the current credential.
nonisolated struct NimbusClient: Sendable {
    let credential: Credential?
    let host: String?
    let session: URLSession

    /// - Parameters:
    ///   - credential: Supplies the bearer token and, unless `host` is given, the server.
    ///   - host: Overrides the server host (used before sign-in, or to fetch a card from the
    ///     server that made it).
    init(credential: Credential?, host: String? = nil, session: URLSession = NimbusClient.defaultSession) {
        self.credential = credential
        self.host = host
        self.session = session
    }

    /// Seconds a chat stream may go without a byte before it counts as dropped. The server
    /// sends a `: ping` comment after ~10 s of silence, so this only trips on a dead connection.
    static let streamIdleTimeout: TimeInterval = 150

    /// The session every request uses by default: no HTTP cache (usage and cards must be
    /// fresh) and an idle timeout long enough for answers that think or search first.
    static let defaultSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = NimbusClient.streamIdleTimeout
        configuration.timeoutIntervalForResource = 15 * 60
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }()

    /// The host requests go to: explicit host, else the credential's, else the baked-in one.
    var resolvedHost: String? {
        host ?? credential?.host ?? NimbusConfig.defaultHost
    }

    var baseURL: URL? {
        guard let resolvedHost else { return nil }
        return NimbusConfig.baseURL(for: resolvedHost)
    }

    // MARK: - Endpoints

    /// `POST /v1/redeem`
    func redeem(code: String, device: String) async throws -> RedeemResponse {
        let body = try encode(RedeemRequest(code: code, device: device))
        let request = try makeRequest(path: "v1/redeem", method: "POST", body: body, authenticated: false)
        let data = try await perform(request)
        return try decode(RedeemResponse.self, from: data)
    }

    /// `GET /v1/me`
    func me() async throws -> MeResponse {
        let request = try makeRequest(path: "v1/me", method: "GET", body: nil, authenticated: true)
        let data = try await perform(request)
        return try decode(MeResponse.self, from: data)
    }

    /// `DELETE /v1/me` — deletes the account, its usage and its cards (Settings → Delete my data).
    /// The caller signs out afterwards.
    func deleteAccount() async throws {
        let request = try makeRequest(path: "v1/me", method: "DELETE", body: nil, authenticated: true)
        _ = try await perform(request)
    }

    /// `POST /v1/chat`, streamed. The stream finishes after `.done`, throws `NimbusError` on
    /// failure, and cancels the HTTP request when the consumer stops iterating.
    func stream(_ request: ChatRequest) -> AsyncThrowingStream<ChatEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await runStream(request, continuation: continuation)
                    continuation.finish()
                } catch {
                    if Task.isCancelled {
                        continuation.finish()
                    } else if let mapped = NimbusError.from(error) {
                        continuation.finish(throwing: mapped)
                    } else {
                        continuation.finish()
                    }
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// Streams `request` and returns the whole answer text. Handy for App Intents.
    func answer(_ request: ChatRequest) async throws -> String {
        var text = ""
        for try await event in stream(request) {
            if case .delta(let chunk) = event {
                text += chunk
            }
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// `POST /v1/cards` — stores a card for the web fallback page.
    func createCard(id: String? = nil, question: String, answer: String) async throws -> CardResponse {
        let body = try encode(CardRequest(
            id: id,
            question: TextLimit.clip(question, maxUTF16: TextLimit.cardQuestion),
            answer: TextLimit.clip(answer, maxUTF16: TextLimit.cardAnswer)
        ))
        let request = try makeRequest(path: "v1/cards", method: "POST", body: body, authenticated: true)
        let data = try await perform(request)
        return try decode(CardResponse.self, from: data)
    }

    /// `GET /c/:id.json` — the full card when the copy in the message URL was truncated.
    func fetchCard(id: String) async throws -> CardDetail {
        guard CardPayload.isValidID(id) else {
            throw NimbusError.invalidRequest("That card link looks broken.")
        }
        let request = try makeRequest(path: "c/\(id).json", method: "GET", body: nil, authenticated: false)
        let data = try await perform(request)
        return try decode(CardDetail.self, from: data)
    }

    /// `POST /v1/report` — flags an answer for the owner.
    func report(messages: [ChatTurn], answer: String, reason: String) async throws {
        let turns = messages.suffix(TextLimit.chatTurns).map {
            ChatTurn(role: $0.role, content: TextLimit.clip($0.content, maxUTF16: TextLimit.cardAnswer))
        }
        let body = try encode(ReportRequest(
            messages: turns,
            answer: TextLimit.clip(answer, maxUTF16: TextLimit.cardAnswer),
            reason: TextLimit.clip(reason, maxUTF16: TextLimit.reportReason)
        ))
        let request = try makeRequest(path: "v1/report", method: "POST", body: body, authenticated: true)
        _ = try await perform(request)
    }

    // MARK: - Plumbing

    private func makeRequest(
        path: String,
        method: String,
        body: Data?,
        authenticated: Bool,
        timeout: TimeInterval = 30
    ) throws -> URLRequest {
        if authenticated, credential == nil {
            throw NimbusError.notSignedIn
        }
        guard let baseURL else {
            if credential == nil {
                throw NimbusError.notSignedIn
            }
            throw NimbusError.invalidRequest("Nimbus doesn't know which server to talk to.")
        }
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(NimbusConfig.userAgent, forHTTPHeaderField: "User-Agent")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if authenticated, let token = credential?.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    /// Sends a request and returns the body of a 2xx response; maps everything else.
    private func perform(_ request: URLRequest) async throws -> Data {
        let result: (Data, URLResponse)
        do {
            result = try await session.data(for: request)
        } catch {
            if let mapped = NimbusError.from(error) {
                throw mapped
            }
            throw CancellationError()
        }
        let (data, response) = result
        guard let http = response as? HTTPURLResponse else {
            throw NimbusError.badResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw NimbusError.from(status: http.statusCode, body: data)
        }
        return data
    }

    private func runStream(
        _ chat: ChatRequest,
        continuation: AsyncThrowingStream<ChatEvent, Error>.Continuation
    ) async throws {
        let body = try encode(chat)
        var request = try makeRequest(
            path: "v1/chat",
            method: "POST",
            body: body,
            authenticated: true,
            timeout: Self.streamIdleTimeout
        )
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

        let (bytes, response) = try await session.bytes(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NimbusError.badResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            var errorBody = Data()
            for try await byte in bytes {
                errorBody.append(byte)
                if errorBody.count >= 65_536 { break }
            }
            throw NimbusError.from(status: http.statusCode, body: errorBody)
        }

        // Feed the parser a line at a time (not `bytes.lines`, which drops the blank lines
        // that end SSE events) so each event is delivered as soon as it is complete.
        var parser = SSEParser()
        var pending: [UInt8] = []
        pending.reserveCapacity(1_024)
        for try await byte in bytes {
            pending.append(byte)
            guard byte == 0x0A || byte == 0x0D || pending.count >= 16_384 else { continue }
            if Task.isCancelled {
                // The consumer went away: stop the request so the server stops generating.
                bytes.task.cancel()
                throw CancellationError()
            }
            let events = parser.feed(pending)
            pending.removeAll(keepingCapacity: true)
            if try Self.deliver(events, to: continuation) {
                bytes.task.cancel()
                return
            }
        }
        var tail = parser.feed(pending)
        tail.append(contentsOf: parser.finish())
        if try Self.deliver(tail, to: continuation) {
            return
        }
        throw NimbusError.network("The connection dropped before Nimbus finished. Try again?")
    }

    /// Yields decoded events; returns true once `done` has been delivered.
    private static func deliver(
        _ events: [SSEEvent],
        to continuation: AsyncThrowingStream<ChatEvent, Error>.Continuation
    ) throws -> Bool {
        for event in events {
            guard let chatEvent = try ChatEventDecoder.decode(event) else { continue }
            continuation.yield(chatEvent)
            if case .done = chatEvent {
                return true
            }
        }
        return false
    }

    private func encode(_ value: some Encodable) throws -> Data {
        do {
            return try JSONEncoder().encode(value)
        } catch {
            throw NimbusError.invalidRequest("Couldn't package that request.")
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw NimbusError.badResponse
        }
    }
}
