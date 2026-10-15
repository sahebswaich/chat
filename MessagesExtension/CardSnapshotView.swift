import Foundation
import SwiftUI
import UIKit

/// What a Nimbus card bubble shows, rendered to an image for `MSMessageTemplateLayout`:
/// a "✨ NIMBUS" label, the question in secondary text and the answer (up to 6 lines) on a
/// light card with a hairline sky-gradient border.
///
/// Always light, with a fixed width and text size, so the card looks the same for everyone.
struct CardSnapshotView: View {
    let question: String
    let answer: String

    /// Points; the image is rendered at `renderScale`.
    static let width: CGFloat = 300
    static let renderScale: CGFloat = 3

    private var trimmedQuestion: String {
        question.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedAnswer: String {
        answer.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: "✨ Nimbus")
                .font(.caption.weight(.semibold).smallCaps())
                .kerning(0.8)
                .foregroundStyle(NimbusTheme.indigo)

            if !trimmedQuestion.isEmpty {
                Text(verbatim: trimmedQuestion)
                    .font(.callout)
                    .foregroundStyle(Color(white: 0.42))
                    .lineLimit(3)
            }

            Text(verbatim: trimmedAnswer)
                .font(.body)
                .foregroundStyle(Color(white: 0.08))
                .lineLimit(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(red: 0.98, green: 0.98, blue: 1.0), in: cardShape)
        .overlay {
            cardShape.strokeBorder(NimbusTheme.sky, lineWidth: 1)
        }
        // Messages crops about 6 pt from each side of a template image and rounds the corners,
        // so keep the card (and its border) clear of the edges.
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: Self.width)
        .background(Color.white)
    }

    /// The card as an opaque image, or nil if rendering failed.
    static func renderImage(question: String, answer: String) -> UIImage? {
        let content = CardSnapshotView(question: question, answer: answer)
            .environment(\.colorScheme, .light)
            .environment(\.dynamicTypeSize, .large)
        let renderer = ImageRenderer(content: content)
        renderer.scale = renderScale
        renderer.isOpaque = true
        return renderer.uiImage
    }
}
