import Foundation

/// Every failure the Nimbus client surfaces, with friendly text for the UI.
nonisolated enum NimbusError: LocalizedError, Sendable, Equatable {
    /// No credential stored; sign in first.
    case notSignedIn
    /// `401 unauthorized`: token unknown or revoked.
    case unauthorized
    /// `404 invalid_code`
    case invalidCode
    /// `410 code_used_up`
    case codeUsedUp
    /// `429 daily_limit`; the associated text says when it resets.
    case dailyLimit(String)
    /// `400 invalid_request`
    case invalidRequest(String)
    /// The model declined to answer.
    case refusal
    /// The AI provider is overloaded.
    case overloaded
    /// The answer hit the length limit.
    case maxTokens
    /// The AI provider failed.
    case upstream(String)
    /// Any other server error.
    case server(status: Int, code: String, message: String)
    /// Transport failure, already phrased for people.
    case network(String)
    /// The server sent something we couldn't read.
    case badResponse

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "You're not signed in yet. Pop in your invite code to get started."
        case .unauthorized:
            return "Your sign-in isn't working anymore. Enter your invite code again."
        case .invalidCode:
            return "Hmm, that code doesn't look right. Double-check it and try again."
        case .codeUsedUp:
            return "That invite code has already been used. Ask for a fresh one."
        case .dailyLimit(let message):
            return message.isEmpty ? "You've used all of today's answers. More tomorrow!" : message
        case .invalidRequest(let message):
            return message.isEmpty ? "Nimbus couldn't make sense of that request." : message
        case .refusal:
            return "Nimbus can't help with that one. Try asking another way."
        case .overloaded:
            return "Nimbus is swamped right now. Give it a few seconds and try again."
        case .maxTokens:
            return "That answer ran long and got cut off. Try asking for something shorter."
        case .upstream:
            return "Nimbus hit a snag on its end. Try again in a moment."
        case .server(let status, _, let message):
            return message.isEmpty ? "Something went wrong on the server (\(status)). Try again in a bit." : message
        case .network(let message):
            return message
        case .badResponse:
            return "Nimbus got a garbled reply. Try again?"
        }
    }

    /// The contract's snake_case code for this error (best effort for client-side cases).
    var code: String {
        switch self {
        case .notSignedIn: return "not_signed_in"
        case .unauthorized: return "unauthorized"
        case .invalidCode: return "invalid_code"
        case .codeUsedUp: return "code_used_up"
        case .dailyLimit: return "daily_limit"
        case .invalidRequest: return "invalid_request"
        case .refusal: return "refusal"
        case .overloaded: return "overloaded"
        case .maxTokens: return "max_tokens"
        case .upstream: return "upstream"
        case .server(_, let code, _): return code
        case .network: return "network"
        case .badResponse: return "bad_response"
        }
    }

    /// Whether trying the same thing again might work.
    var isRetryable: Bool {
        switch self {
        case .overloaded, .upstream, .network, .badResponse, .maxTokens, .server:
            return true
        case .notSignedIn, .unauthorized, .invalidCode, .codeUsedUp, .dailyLimit, .invalidRequest, .refusal:
            return false
        }
    }

    /// Maps a contract error code (from a JSON error body or an `error` SSE event).
    static func from(code: String, message: String, status: Int) -> NimbusError {
        switch code {
        case "unauthorized": return .unauthorized
        case "invalid_code": return .invalidCode
        case "code_used_up": return .codeUsedUp
        case "daily_limit": return .dailyLimit(message)
        case "invalid_request": return .invalidRequest(message)
        case "refusal": return .refusal
        case "overloaded": return .overloaded
        case "max_tokens": return .maxTokens
        case "upstream": return .upstream(message)
        default: return .server(status: status, code: code, message: message)
        }
    }

    /// Maps a non-2xx response, preferring the `{"error": {...}}` body.
    static func from(status: Int, body: Data) -> NimbusError {
        if let envelope = try? JSONDecoder().decode(APIErrorEnvelope.self, from: body) {
            return from(code: envelope.error.code, message: envelope.error.message ?? "", status: status)
        }
        switch status {
        case 401: return .unauthorized
        case 429: return .dailyLimit("")
        case 503, 529: return .overloaded
        case 502, 504: return .upstream("")
        default: return .server(status: status, code: "http_\(status)", message: "")
        }
    }

    /// Converts any thrown error into a `NimbusError`, or nil when it means cancellation.
    static func from(_ error: any Error) -> NimbusError? {
        if let nimbus = error as? NimbusError {
            return nimbus
        }
        if error is CancellationError {
            return nil
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .cancelled:
                return nil
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
                return .network("You're offline. Check your connection and try again.")
            case .timedOut:
                return .network("That took too long. Try again?")
            case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                return .network("Can't reach the Nimbus server right now.")
            case .secureConnectionFailed, .serverCertificateUntrusted, .serverCertificateHasBadDate,
                 .serverCertificateNotYetValid, .serverCertificateHasUnknownRoot, .clientCertificateRejected:
                return .network("Couldn't make a secure connection to the Nimbus server.")
            default:
                return .network("Network hiccup. Try again?")
            }
        }
        if error is DecodingError {
            return .badResponse
        }
        return .network("Something went wrong. Try again?")
    }
}
