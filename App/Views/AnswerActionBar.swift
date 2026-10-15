import Foundation
import SwiftUI
import UIKit

/// The glass action bar under the latest answer: Share (to Messages or anywhere), Copy, and a
/// menu with the rewrites, Regenerate and Report.
struct AnswerActionBar: View {
    let answer: ThreadMessage
    var onRewrite: (RewriteKind) -> Void
    var onRegenerate: () -> Void
    var onReport: () -> Void

    init(
        answer: ThreadMessage,
        onRewrite: @escaping (RewriteKind) -> Void,
        onRegenerate: @escaping () -> Void,
        onReport: @escaping () -> Void
    ) {
        self.answer = answer
        self.onRewrite = onRewrite
        self.onRegenerate = onRegenerate
        self.onReport = onReport
    }

    @State private var copyTick = 0

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                ShareLink(item: answer.text, subject: Text(verbatim: answer.question ?? "Nimbus")) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.glass)

                Button {
                    UIPasteboard.general.string = answer.text
                    copyTick += 1
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.glass)

                Menu {
                    ForEach(RewriteKind.allCases) { kind in
                        Button {
                            onRewrite(kind)
                        } label: {
                            Label(kind.title, systemImage: kind.systemImage)
                        }
                    }
                    Button {
                        onRegenerate()
                    } label: {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                    }
                    Divider()
                    Button(role: .destructive) {
                        onReport()
                    } label: {
                        Label("Report", systemImage: "flag")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis")
                        .labelStyle(.iconOnly)
                }
                .menuStyle(.button)
                .buttonStyle(.glass)
                .accessibilityLabel("More actions")
            }
            .font(.subheadline.weight(.semibold))
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sensoryFeedback(.success, trigger: copyTick)
    }
}
