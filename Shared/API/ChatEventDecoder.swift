import Foundation

/// Turns raw `SSEEvent`s from `/v1/chat` into `ChatEvent`s.
nonisolated enum ChatEventDecoder {
    /// - Returns: the decoded event, or nil for events Nimbus doesn't use (unknown names,
    ///   unreadable `meta`/`status` payloads).
    /// - Throws: `NimbusError` for `error` events, and `.badResponse` when a `delta` or
    ///   `done` payload can't be read.
    static func decode(_ event: SSEEvent) throws -> ChatEvent? {
        let data = Data(event.data.utf8)
        let decoder = JSONDecoder()
        switch event.event {
        case "meta":
            let payload = try? decoder.decode(MetaPayload.self, from: data)
            return .meta(model: payload?.model ?? "")
        case "status":
            guard let payload = try? decoder.decode(StatusPayload.self, from: data) else { return nil }
            return .status(payload.state)
        case "delta":
            guard let payload = try? decoder.decode(DeltaPayload.self, from: data) else {
                throw NimbusError.badResponse
            }
            return .delta(payload.text)
        case "done":
            guard let info = try? decoder.decode(DoneInfo.self, from: data) else {
                throw NimbusError.badResponse
            }
            return .done(info)
        case "error":
            let payload = try? decoder.decode(APIErrorPayload.self, from: data)
            throw NimbusError.from(
                code: payload?.code ?? "upstream",
                message: payload?.message ?? "",
                status: 200
            )
        default:
            return nil
        }
    }
}

private nonisolated struct MetaPayload: Decodable, Sendable {
    var model: String?
}

private nonisolated struct StatusPayload: Decodable, Sendable {
    var state: String
}

private nonisolated struct DeltaPayload: Decodable, Sendable {
    var text: String
}
