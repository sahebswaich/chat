import Foundation

/// One dispatched server-sent event.
nonisolated struct SSEEvent: Sendable, Equatable {
    /// The `event:` field, `"message"` when absent.
    var event: String
    /// All `data:` lines joined with `\n`.
    var data: String

    init(event: String = "message", data: String) {
        self.event = event
        self.data = data
    }
}

/// Incremental parser for the subset of the SSE wire format Nimbus uses.
///
/// * Lines end in `\n`, `\r\n` or `\r` (a CRLF split across two chunks counts once).
/// * `event:` and `data:` fields; one leading space after the colon is stripped; other
///   fields (`id:`, `retry:`) are ignored.
/// * Multiple `data:` lines are joined with `\n`.
/// * Lines starting with `:` are comments (the server's `: ping` keep-alives).
/// * A blank line dispatches the event; an event without any `data:` line is dropped.
///
/// Bytes are buffered until a full line arrives, so multi-byte UTF-8 characters split across
/// network chunks decode correctly.
nonisolated struct SSEParser {
    private var line: [UInt8] = []
    private var lastByteWasCR = false
    private var isFirstLine = true
    private var eventType = ""
    private var dataLines: [String] = []
    private var hasData = false

    init() {}

    /// Feeds the next chunk of the stream and returns any events it completed.
    mutating func feed(_ bytes: some Sequence<UInt8>) -> [SSEEvent] {
        var events: [SSEEvent] = []
        for byte in bytes {
            if lastByteWasCR {
                lastByteWasCR = false
                if byte == 0x0A {
                    // Second half of a CRLF; the CR already ended the line.
                    continue
                }
            }
            switch byte {
            case 0x0A:
                processLine(into: &events)
            case 0x0D:
                processLine(into: &events)
                lastByteWasCR = true
            default:
                line.append(byte)
            }
        }
        return events
    }

    /// Call at end of stream: processes a final unterminated line and dispatches a pending
    /// event that wasn't followed by a blank line.
    mutating func finish() -> [SSEEvent] {
        var events: [SSEEvent] = []
        if !line.isEmpty {
            processLine(into: &events)
        }
        dispatch(into: &events)
        lastByteWasCR = false
        return events
    }

    private mutating func processLine(into events: inout [SSEEvent]) {
        var bytes = line
        line.removeAll(keepingCapacity: true)

        if isFirstLine {
            isFirstLine = false
            // Strip a UTF-8 byte-order mark at the very start of the stream.
            if bytes.count >= 3, bytes[0] == 0xEF, bytes[1] == 0xBB, bytes[2] == 0xBF {
                bytes.removeFirst(3)
            }
        }

        if bytes.isEmpty {
            dispatch(into: &events)
            return
        }
        if bytes[0] == 0x3A {
            // ":" comment / keep-alive.
            return
        }

        let field: String
        let value: String
        if let colon = bytes.firstIndex(of: 0x3A) {
            field = String(decoding: bytes[..<colon], as: UTF8.self)
            var valueStart = bytes.index(after: colon)
            if valueStart < bytes.endIndex, bytes[valueStart] == 0x20 {
                valueStart = bytes.index(after: valueStart)
            }
            value = String(decoding: bytes[valueStart...], as: UTF8.self)
        } else {
            field = String(decoding: bytes, as: UTF8.self)
            value = ""
        }

        switch field {
        case "event":
            eventType = value
        case "data":
            dataLines.append(value)
            hasData = true
        default:
            break
        }
    }

    private mutating func dispatch(into events: inout [SSEEvent]) {
        defer {
            eventType = ""
            dataLines.removeAll()
            hasData = false
        }
        guard hasData else { return }
        events.append(SSEEvent(
            event: eventType.isEmpty ? "message" : eventType,
            data: dataLines.joined(separator: "\n")
        ))
    }
}
