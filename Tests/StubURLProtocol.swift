import Foundation
import os

/// Canned HTTP responses for `NimbusClient` tests. Stubs are keyed by host, so each test uses
/// its own host and suites can run in parallel.
nonisolated final class StubURLProtocol: URLProtocol {
    nonisolated struct Stub: Sendable {
        var status: Int
        var headers: [String: String]
        /// Delivered one by one, so tests can split SSE events at awkward byte offsets.
        var chunks: [Data]

        init(status: Int = 200, headers: [String: String] = ["Content-Type": "text/event-stream"], chunks: [Data] = []) {
            self.status = status
            self.headers = headers
            self.chunks = chunks
        }
    }

    private nonisolated struct State: Sendable {
        var stubs: [String: Stub] = [:]
        var requests: [String: [URLRequest]] = [:]
        var bodies: [String: [Data]] = [:]
    }

    private static let state = OSAllocatedUnfairLock(initialState: State())

    /// Answers every request to `host` with `stub`.
    static func register(_ stub: Stub, host: String) {
        state.withLock { state in
            state.stubs[host] = stub
        }
    }

    /// Requests seen for `host`, oldest first.
    static func requests(host: String) -> [URLRequest] {
        state.withLock { state in
            state.requests[host] ?? []
        }
    }

    /// Request bodies seen for `host` (read from the body stream URLSession hands protocols).
    static func bodies(host: String) -> [Data] {
        state.withLock { state in
            state.bodies[host] ?? []
        }
    }

    /// A session that routes everything through this protocol.
    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    /// `text` as UTF-8, cut into `size`-byte chunks (splitting multi-byte characters).
    static func chunks(_ text: String, size: Int) -> [Data] {
        let bytes = Array(text.utf8)
        let step = max(size, 1)
        return stride(from: 0, to: bytes.count, by: step).map { start in
            Data(bytes[start..<min(start + step, bytes.count)])
        }
    }

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let request = self.request
        let host = request.url?.host() ?? ""
        let body = Self.readBody(of: request)
        let registered: Stub? = Self.state.withLock { state in
            state.requests[host, default: []].append(request)
            state.bodies[host, default: []].append(body)
            return state.stubs[host]
        }
        guard let stub = registered,
              let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: stub.status, httpVersion: "HTTP/1.1", headerFields: stub.headers)
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.cannotFindHost))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        for chunk in stub.chunks {
            client?.urlProtocol(self, didLoad: chunk)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func readBody(of request: URLRequest) -> Data {
        if let body = request.httpBody {
            return body
        }
        guard let stream = request.httpBodyStream else { return Data() }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4_096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 { break }
            data.append(buffer, count: count)
        }
        return data
    }
}
