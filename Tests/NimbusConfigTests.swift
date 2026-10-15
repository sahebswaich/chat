import Foundation
import Testing

@Suite("Server host handling")
struct NimbusConfigTests {
    @Test(arguments: [
        "nimbus.test.dev",
        "Nimbus.Test.Dev",
        " nimbus.test.dev ",
        "nimbus.test.dev/",
        "https://nimbus.test.dev",
        "https://nimbus.test.dev/",
        "http://nimbus.test.dev/join/K7QM-2XPA?x=1",
        "HTTPS://NIMBUS.TEST.DEV",
        "nimbus.test.dev.",
    ])
    func baseURLAcceptsWhatPeopleType(_ input: String) {
        #expect(NimbusConfig.baseURL(for: input)?.absoluteString == "https://nimbus.test.dev")
    }

    @Test func keepsAPort() {
        #expect(NimbusConfig.baseURL(for: "localhost:8787")?.absoluteString == "https://localhost:8787")
    }

    @Test(arguments: ["", "   ", "https://", "bad host", "nim bus.dev", "-nimbus.dev", ".nimbus.dev", "nimbus_dev!"])
    func rejectsThingsThatAreNotHosts(_ input: String) {
        #expect(NimbusConfig.baseURL(for: input) == nil)
    }

    @Test func ignoresPlaceholderInfoPlistValues() {
        #expect(NimbusConfig.usableHost("$(NIMBUS_API_HOST)") == nil)
        #expect(NimbusConfig.usableHost("nimbus.example.workers.dev") == nil)
        #expect(NimbusConfig.usableHost("") == nil)
        #expect(NimbusConfig.usableHost("nimbus.sahebswaich.workers.dev") == "nimbus.sahebswaich.workers.dev")
    }

    @Test func buildsPageURLs() {
        #expect(NimbusConfig.webURL(path: "terms", host: "nimbus.test.dev")?.absoluteString == "https://nimbus.test.dev/terms")
        #expect(NimbusConfig.webURL(path: "privacy", host: "https://nimbus.test.dev/")?.absoluteString == "https://nimbus.test.dev/privacy")
    }

    @Test func userAgentNamesTheApp() {
        #expect(NimbusConfig.userAgent.hasPrefix("Nimbus/"))
        #expect(NimbusConfig.userAgent.contains("tests"))
    }
}
