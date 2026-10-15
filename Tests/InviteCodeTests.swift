import Foundation
import Testing

@Suite("Invite codes")
struct InviteCodeTests {
    @Test(arguments: [
        "K7QM2XPA",
        "K7QM-2XPA",
        "k7qm-2xpa",
        " k7qm 2xpa ",
        "K7QM–2XPA",
        "K7QM—2XPA",
        "K7-QM-2X-PA",
        "\tK7QM\n2XPA ",
    ])
    func normalizesWhatPeopleTypeOrPaste(_ input: String) {
        #expect(InviteCode.normalize(input) == "K7QM2XPA")
    }

    @Test(arguments: [
        "K7QM2XPI",
        "K7QM2XPL",
        "K7QM2XPO",
        "K7QM2XPU",
        "k7qm-2xpo",
    ])
    func rejectsLettersOutsideCrockfordBase32(_ input: String) {
        #expect(InviteCode.normalize(input) == nil)
    }

    @Test(arguments: [
        "",
        "K7QM",
        "K7QM2XP",
        "K7QM2XPAB",
        "K7QM-2XP!",
        "K7QM 2XP😀",
        "ÄBCD2XPA",
    ])
    func rejectsWrongLengthOrSymbols(_ input: String) {
        #expect(InviteCode.normalize(input) == nil)
    }

    @Test func acceptsEveryAlphabetCharacter() {
        let alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
        #expect(alphabet.count == 32)
        let characters = Array(alphabet)
        for start in stride(from: 0, to: characters.count, by: 8) {
            let code = String(characters[start..<(start + 8)])
            #expect(InviteCode.normalize(code) == code)
            #expect(InviteCode.normalize(code.lowercased()) == code)
        }
    }

    @Test func formatsWithADash() {
        #expect(InviteCode.format("K7QM2XPA") == "K7QM-2XPA")
        #expect(InviteCode.format("k7qm 2xpa") == "K7QM-2XPA")
        #expect(InviteCode.format("K7QM-2XPA") == "K7QM-2XPA")
        // Not a code: cleaned up, otherwise unchanged.
        #expect(InviteCode.format(" abc ") == "ABC")
    }

    @Test func sanitizeKeepsValidCharactersForTheBoxes() {
        let pasted = InviteCode.sanitize("K7QM-2XPA")
        #expect(pasted.code == "K7QM2XPA")
        #expect(pasted.rejected == false)

        let typo = InviteCode.sanitize("K7QI")
        #expect(typo.code == "K7Q")
        #expect(typo.rejected)

        let tooLong = InviteCode.sanitize("K7QM2XPAZZZZ")
        #expect(tooLong.code == "K7QM2XPA")
        #expect(tooLong.rejected == false)

        let link = InviteCode.sanitize("nimbus://join?code=K7QM-2XPA&host=nimbus.test.dev")
        #expect(link.code == "K7QM2XPA")
        #expect(link.rejected == false)
    }

    // MARK: - Join links

    @Test func parsesTheAppJoinLink() throws {
        let url = try #require(URL(string: "nimbus://join?code=K7QM-2XPA&host=nimbus.test.dev"))
        let link = try #require(InviteCode.parse(url: url))
        #expect(link.code == "K7QM2XPA")
        #expect(link.host == "nimbus.test.dev")
    }

    @Test func joinLinkHostIsNormalized() throws {
        let url = try #require(URL(string: "nimbus://join?code=k7qm2xpa&host=https%3A%2F%2FNimbus.Test.Dev%2F"))
        let link = try #require(InviteCode.parse(url: url))
        #expect(link.code == "K7QM2XPA")
        #expect(link.host == "nimbus.test.dev")
    }

    @Test func joinLinkWithoutHost() throws {
        let url = try #require(URL(string: "nimbus://join?code=K7QM-2XPA"))
        let link = try #require(InviteCode.parse(url: url))
        #expect(link.code == "K7QM2XPA")
        #expect(link.host == nil)
    }

    @Test func joinLinkWithPathCode() throws {
        let url = try #require(URL(string: "nimbus://join/K7QM-2XPA"))
        let link = try #require(InviteCode.parse(url: url))
        #expect(link.code == "K7QM2XPA")
    }

    @Test func parsesTheServerLandingPageLink() throws {
        let url = try #require(URL(string: "https://nimbus.test.dev/join/K7QM-2XPA"))
        let link = try #require(InviteCode.parse(url: url))
        #expect(link.code == "K7QM2XPA")
        #expect(link.host == "nimbus.test.dev")
    }

    @Test func rejectsOtherLinks() throws {
        let urls = [
            "nimbus://ask?q=hello",
            "nimbus://join?code=BAD",
            "nimbus://join?code=K7QM-2XPO",
            "nimbus://join",
            "https://nimbus.test.dev/c/abc123def456",
            "mailto:someone@example.com",
        ]
        for string in urls {
            let url = try #require(URL(string: string))
            let parsed = InviteCode.parse(url: url)
            #expect(parsed?.code == nil, "\(string)")
        }
    }

    // MARK: - Router

    @Test func routerHandlesNimbusLinks() throws {
        let router = NimbusRouter()
        let join = try #require(URL(string: "nimbus://join?code=K7QM-2XPA&host=nimbus.test.dev"))
        let ask = try #require(URL(string: "nimbus://ask?q=what%20is%20nephilim"))
        let blankAsk = try #require(URL(string: "nimbus://ask"))
        let other = try #require(URL(string: "https://apple.com"))

        #expect(router.handle(url: join))
        #expect(router.pending == NimbusRouter.Pending.join(code: "K7QM2XPA", host: "nimbus.test.dev"))

        #expect(router.handle(url: ask))
        #expect(router.pending == NimbusRouter.Pending.ask("what is nephilim"))

        #expect(router.handle(url: blankAsk))
        #expect(router.pending == NimbusRouter.Pending.newQuestion)

        #expect(router.consume() == NimbusRouter.Pending.newQuestion)
        #expect(router.pending == nil)

        let handledOther = router.handle(url: other)
        #expect(handledOther == false)
        #expect(router.pending == nil)
    }
}
