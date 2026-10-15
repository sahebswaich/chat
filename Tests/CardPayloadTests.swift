import Foundation
import Testing

@Suite("Card URL payload")
struct CardPayloadTests {
    private let host = "nimbus.test.dev"

    @Test func shortCardRoundTrips() throws {
        let card = CardPayload(id: "abc123DEF456", question: "what is nephilim", answer: "Giants in Genesis 6 & Numbers 13.")
        let url = card.url(host: host)
        #expect(url.absoluteString.hasPrefix("https://nimbus.test.dev/c/abc123DEF456?q="))
        #expect(url.absoluteString.hasSuffix("&v=1"))

        let decoded = try #require(CardPayload(url: url))
        #expect(decoded.id == card.id)
        #expect(decoded.question == card.question)
        #expect(decoded.answer == card.answer)
        #expect(decoded.isTruncated == false)
    }

    @Test func reservedCharactersSurviveTheRoundTrip() throws {
        let question = "a+b=c? 50% & more #hash /slash"
        let answer = "Ünïcødé 中文 العربية 👋🏽 + & = ? # % ~ \"quotes\"\nnew line"
        let card = CardPayload(id: "id_with-dash", question: question, answer: answer)
        let url = card.url(host: "https://Nimbus.Test.Dev/")
        #expect(url.host() == "nimbus.test.dev")
        #expect(!url.absoluteString.contains("+"))

        let decoded = try #require(CardPayload(url: url))
        #expect(decoded.question == question)
        #expect(decoded.answer == answer)
        #expect(decoded.isTruncated == false)
    }

    @Test func longAnswerIsTrimmedToFit() throws {
        let answer = String(repeating: "The quick brown fox jumps over the lazy dog. ", count: 500)
        let card = CardPayload(id: "longcard0001", question: "tell me a long story", answer: answer)
        let encoded = card.encode(host: host)
        #expect(encoded.answerTruncated)
        #expect(encoded.url.absoluteString.count <= CardPayload.maxURLLength)
        // Uses most of the budget rather than cutting far too early.
        #expect(encoded.url.absoluteString.count > CardPayload.maxURLLength - 200)

        let decoded = try #require(CardPayload(url: encoded.url))
        #expect(decoded.isTruncated)
        #expect(decoded.answer.hasSuffix("…"))
        let kept = String(decoded.answer.dropLast())
        #expect(answer.hasPrefix(kept))
    }

    @Test func emojiHeavyAnswerRespectsTheEncodedLengthCap() throws {
        let answer = String(repeating: "😀👍🏽🇮🇪 ", count: 600)
        let card = CardPayload(id: "emoji0000001", question: "emoji please 🙏", answer: answer)
        let url = card.url(host: host)
        #expect(url.absoluteString.count <= CardPayload.maxURLLength)

        let decoded = try #require(CardPayload(url: url))
        #expect(decoded.isTruncated)
        #expect(decoded.question == "emoji please 🙏")
        let kept = String(decoded.answer.dropLast())
        #expect(answer.hasPrefix(kept))
        #expect(!kept.isEmpty)
    }

    @Test func questionIsCappedAt280Characters() throws {
        let question = String(repeating: "q", count: 1_000)
        let card = CardPayload(id: "question0001", question: question, answer: "short")
        let decoded = try #require(CardPayload(url: card.url(host: host)))
        #expect(decoded.question.count <= CardPayload.maxQuestionLength)
        #expect(decoded.question.hasSuffix("…"))
        #expect(decoded.answer == "short")
        #expect(decoded.isTruncated == false)
    }

    @Test func pathologicalQuestionStillFits() {
        let family = "👨‍👩‍👧‍👦"
        let card = CardPayload(
            id: "family000001",
            question: String(repeating: family, count: 280),
            answer: String(repeating: family, count: 500)
        )
        #expect(card.url(host: host).absoluteString.count <= CardPayload.maxURLLength)
    }

    @Test func rejectsNonCardURLs() throws {
        let strings = [
            "https://nimbus.test.dev/join/K7QM-2XPA",
            "nimbus://c/abc",
            "https://nimbus.test.dev/c/",
            "https://nimbus.test.dev/c/bad%20id",
            "https://nimbus.test.dev/c/..%2Fetc",
        ]
        for string in strings {
            let url = try #require(URL(string: string))
            #expect(CardPayload(url: url) == nil, "\(string)")
        }
    }

    @Test func serverStyleCardURLParses() throws {
        // What the server returns from POST /v1/cards (16-char base64url id), plus our query.
        let card = CardPayload(id: "Zm9vYmFyYmF6cXV4", question: "q", answer: "a")
        let url = card.url(host: "nimbus.test.dev")
        #expect(url.absoluteString == "https://nimbus.test.dev/c/Zm9vYmFyYmF6cXV4?q=q&a=a&v=1")
        #expect(url.scheme == "https")
    }

    @Test func missingAnswerMeansFetchTheFullCard() throws {
        let url = try #require(URL(string: "https://nimbus.test.dev/c/abc123?q=hello&v=1"))
        let decoded = try #require(CardPayload(url: url))
        #expect(decoded.id == "abc123")
        #expect(decoded.question == "hello")
        #expect(decoded.isTruncated)
    }

    @Test func validIDs() {
        #expect(CardPayload.isValidID("aB3_-x9"))
        #expect(!CardPayload.isValidID(""))
        #expect(!CardPayload.isValidID("../etc"))
        #expect(!CardPayload.isValidID("a b"))
    }

    @Test func newIDsAreValidUniqueAndServerShaped() {
        let ids = (0..<200).map { _ in CardPayload.newID() }
        #expect(Set(ids).count == ids.count)
        for id in ids {
            #expect(id.count == 16)
            #expect(CardPayload.isValidID(id))
            // Same alphabet the server accepts for app-chosen ids: [A-Za-z0-9_-]{16,64}.
            #expect(id.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_") })
        }
    }
}
