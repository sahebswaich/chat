import Foundation
import Testing

@Suite("MarkdownLite block handling for app answers")
struct MarkdownLiteTests {
    @Test func headingsBecomeBoldLines() {
        #expect(MarkdownLite.inlineFriendly("## Giants of old") == "**Giants of old**")
        #expect(MarkdownLite.inlineFriendly("# Title #") == "**Title**")
        #expect(MarkdownLite.inlineFriendly("### **Already bold**") == "**Already bold**")
    }

    @Test func hashtagsAndLongRunsStayAsTyped() {
        #expect(MarkdownLite.inlineFriendly("#nephilim") == "#nephilim")
        #expect(MarkdownLite.inlineFriendly("####### seven") == "####### seven")
    }

    @Test func bulletsKeepTheirIndent() {
        let input = "- one\n* two\n  + nested\n**bold** stays"
        #expect(MarkdownLite.inlineFriendly(input) == "• one\n• two\n  • nested\n**bold** stays")
    }

    @Test func fencedCodeBecomesInlineCode() {
        let input = "Try this:\n```swift\nlet x = 2 * 3\n\nprint(`x`)\n```\nDone."
        #expect(MarkdownLite.inlineFriendly(input) == "Try this:\n`let x = 2 * 3`\n\nprint(`x`)\nDone.")
    }

    @Test func unclosedFenceWhileStreaming() {
        #expect(MarkdownLite.inlineFriendly("```\n# not a heading") == "`# not a heading`")
    }

    @Test func plainTextIsUnchanged() {
        let text = "Nephilim 👋🏽 are giants.\n\n1. First\n2. Second"
        #expect(MarkdownLite.inlineFriendly(text) == text)
    }
}
