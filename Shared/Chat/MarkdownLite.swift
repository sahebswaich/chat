import Foundation

/// Prepares Markdown answers for SwiftUI's inline-only Markdown parsing
/// (`AttributedString(markdown:)` with `.inlineOnlyPreservingWhitespace`), which keeps line
/// breaks but shows block syntax literally. Headings become bold lines, bullets become `•`,
/// and lines inside fenced code blocks become inline code (monospaced). Everything else,
/// including `**bold**`, `_italic_`, `` `code` `` and links, is left for the inline parser.
nonisolated enum MarkdownLite {
    static func inlineFriendly(_ text: String) -> String {
        var output: [String] = []
        var inCodeBlock = false
        for rawLine in text.components(separatedBy: "\n") {
            let line = rawLine.hasSuffix("\r") ? String(rawLine.dropLast()) : rawLine
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                // The fence line itself (with its language tag) isn't shown.
                inCodeBlock.toggle()
                continue
            }
            if inCodeBlock {
                output.append(codeLine(line))
            } else {
                output.append(blockLine(line))
            }
        }
        return output.joined(separator: "\n")
    }

    /// A line inside a fenced block as inline code, when it can be wrapped safely.
    private static func codeLine(_ line: String) -> String {
        guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { return "" }
        guard !line.contains("`") else { return line }
        return "`" + line + "`"
    }

    /// Headings and bullet markers outside code blocks.
    private static func blockLine(_ line: String) -> String {
        let indent = String(line.prefix(while: { $0 == " " || $0 == "\t" }))
        let body = String(line.dropFirst(indent.count))

        // "# Title" … "###### Title"
        let hashes = body.prefix(while: { $0 == "#" }).count
        if hashes >= 1, hashes <= 6 {
            let rest = body.dropFirst(hashes)
            if rest.first == " " {
                var title = rest.trimmingCharacters(in: .whitespaces)
                while title.hasSuffix("#") {
                    title.removeLast()
                }
                title = title.trimmingCharacters(in: .whitespaces)
                guard !title.isEmpty else { return "" }
                return title.contains("**") ? title : "**" + title + "**"
            }
        }

        // "- item", "* item", "+ item"
        for marker in ["- ", "* ", "+ "] where body.hasPrefix(marker) {
            return indent + "• " + String(body.dropFirst(marker.count))
        }
        return line
    }
}
