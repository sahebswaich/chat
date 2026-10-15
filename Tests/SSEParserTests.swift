import Foundation
import Testing

@Suite("SSE parser")
struct SSEParserTests {
    /// A stream in the exact shape the server sends (docs/ARCHITECTURE.md).
    private let contractStream = """
    : ping

    event: meta
    data: {"model": "claude-opus-5-5"}

    event: status
    data: {"state": "searching"}

    : ping

    event: status
    data: {"state": "writing"}

    event: delta
    data: {"text": "Nephilim 👋🏽 are "}

    event: delta
    data: {"text": "giants in Genesis 6."}

    event: done
    data: {"stopReason": "end_turn", "usedToday": 13, "dailyLimit": 200}


    """

    private func parseAll(_ chunks: [[UInt8]]) -> [SSEEvent] {
        var parser = SSEParser()
        var events: [SSEEvent] = []
        for chunk in chunks {
            events += parser.feed(chunk)
        }
        events += parser.finish()
        return events
    }

    @Test func parsesSingleEvent() {
        var parser = SSEParser()
        let events = parser.feed("event: delta\ndata: {\"text\":\"Hi\"}\n\n".utf8)
        #expect(events == [SSEEvent(event: "delta", data: "{\"text\":\"Hi\"}")])
    }

    @Test func contractStreamParses() {
        let events = parseAll([Array(contractStream.utf8)])
        #expect(events.map(\.event) == ["meta", "status", "status", "delta", "delta", "done"])
        #expect(events[3].data == "{\"text\": \"Nephilim 👋🏽 are \"}")
    }

    @Test func everySplitPointGivesTheSameEvents() {
        let bytes = Array(contractStream.utf8)
        let expected = parseAll([bytes])
        for split in 1..<bytes.count {
            let chunks = [Array(bytes[..<split]), Array(bytes[split...])]
            #expect(parseAll(chunks) == expected, "split at \(split)")
        }
    }

    @Test func byteByByteFeedHandlesSplitEmoji() {
        let bytes = Array(contractStream.utf8)
        let events = parseAll(bytes.map { [$0] })
        #expect(events == parseAll([bytes]))
        #expect(events[3].data.contains("👋🏽"))
    }

    @Test func emojiSplitMidCodePointDecodesCorrectly() throws {
        let line = Array("data: 😀 ok\n\n".utf8)
        // The emoji's four UTF-8 bytes start right after "data: ".
        let emojiStart = 6
        var parser = SSEParser()
        var events = parser.feed(line[..<(emojiStart + 2)])
        #expect(events.isEmpty)
        events += parser.feed(line[(emojiStart + 2)...])
        #expect(events == [SSEEvent(event: "message", data: "😀 ok")])
    }

    @Test func crlfAndCRLineEndings() {
        let crlf = "event: delta\r\ndata: one\r\n\r\n"
        let cr = "event: delta\rdata: two\r\r"
        #expect(parseAll([Array(crlf.utf8)]) == [SSEEvent(event: "delta", data: "one")])
        #expect(parseAll([Array(cr.utf8)]) == [SSEEvent(event: "delta", data: "two")])
    }

    @Test func crlfSplitAcrossChunksIsOneLineBreak() {
        // "\r" ends chunk one, "\n" starts chunk two: still one line ending, not a blank line.
        let first = Array("event: delta\r".utf8)
        let second = Array("\ndata: x\r\n\r\n".utf8)
        #expect(parseAll([first, second]) == [SSEEvent(event: "delta", data: "x")])
    }

    @Test func multipleDataLinesJoinWithNewline() {
        let stream = "data: line one\ndata: line two\ndata:\ndata: four\n\n"
        #expect(parseAll([Array(stream.utf8)]) == [SSEEvent(event: "message", data: "line one\nline two\n\nfour")])
    }

    @Test func commentsAndPingsAreIgnored() {
        let stream = ": ping\n\n:another comment\n\nevent: delta\n: inline comment\ndata: hi\n\n: ping\n\n"
        #expect(parseAll([Array(stream.utf8)]) == [SSEEvent(event: "delta", data: "hi")])
    }

    @Test func onlyOneLeadingSpaceIsStripped() {
        let stream = "data:no-space\n\ndata:  two-spaces\n\n"
        #expect(parseAll([Array(stream.utf8)]) == [
            SSEEvent(event: "message", data: "no-space"),
            SSEEvent(event: "message", data: " two-spaces"),
        ])
    }

    @Test func eventTypeResetsAfterDispatch() {
        let stream = "event: delta\ndata: a\n\ndata: b\n\n"
        #expect(parseAll([Array(stream.utf8)]) == [
            SSEEvent(event: "delta", data: "a"),
            SSEEvent(event: "message", data: "b"),
        ])
    }

    @Test func eventWithoutDataIsDropped() {
        let stream = "event: delta\n\nid: 7\nretry: 1000\n\n"
        #expect(parseAll([Array(stream.utf8)]).isEmpty)
    }

    @Test func finishFlushesPendingEvent() {
        var parser = SSEParser()
        let fed = parser.feed("event: done\ndata: {\"stopReason\":\"end_turn\"}".utf8)
        #expect(fed.isEmpty)
        #expect(parser.finish() == [SSEEvent(event: "done", data: "{\"stopReason\":\"end_turn\"}")])
        #expect(parser.finish().isEmpty)
    }

    @Test func leadingByteOrderMarkIsIgnored() {
        let bytes: [UInt8] = [0xEF, 0xBB, 0xBF] + Array("event: delta\ndata: x\n\n".utf8)
        #expect(parseAll([bytes]) == [SSEEvent(event: "delta", data: "x")])
    }

    // MARK: - ChatEvent decoding

    @Test func contractEventsDecodeToChatEvents() throws {
        let events = parseAll([Array(contractStream.utf8)])
        let decoded = try events.compactMap { try ChatEventDecoder.decode($0) }
        #expect(decoded == [
            .meta(model: "claude-opus-5-5"),
            .status("searching"),
            .status("writing"),
            .delta("Nephilim 👋🏽 are "),
            .delta("giants in Genesis 6."),
            .done(DoneInfo(stopReason: "end_turn", usedToday: 13, dailyLimit: 200)),
        ])
    }

    @Test func errorEventsThrowNimbusErrors() {
        let refusal = SSEEvent(event: "error", data: "{\"code\": \"refusal\", \"message\": \"Can't help.\"}")
        #expect(throws: NimbusError.refusal) {
            try ChatEventDecoder.decode(refusal)
        }
        let overloaded = SSEEvent(event: "error", data: "{\"code\": \"overloaded\", \"message\": \"Busy\"}")
        #expect(throws: NimbusError.overloaded) {
            try ChatEventDecoder.decode(overloaded)
        }
        let maxTokens = SSEEvent(event: "error", data: "{\"code\": \"max_tokens\", \"message\": \"Too long\"}")
        #expect(throws: NimbusError.maxTokens) {
            try ChatEventDecoder.decode(maxTokens)
        }
        let upstream = SSEEvent(event: "error", data: "{\"code\": \"upstream\", \"message\": \"Boom\"}")
        #expect(throws: NimbusError.upstream("Boom")) {
            try ChatEventDecoder.decode(upstream)
        }
    }

    @Test func unknownEventsAreSkipped() throws {
        #expect(try ChatEventDecoder.decode(SSEEvent(event: "message", data: "{}")) == nil)
        #expect(try ChatEventDecoder.decode(SSEEvent(event: "future_thing", data: "{}")) == nil)
    }

    @Test func malformedDeltaIsABadResponse() {
        #expect(throws: NimbusError.badResponse) {
            try ChatEventDecoder.decode(SSEEvent(event: "delta", data: "not json"))
        }
    }
}
