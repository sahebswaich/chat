import Foundation
import SwiftUI

/// The glass bar under the latest finished answer:
/// `[ ↑ Send ]  [ ▢ Card ]  [ ✎ Insert ]  [ ⋯ ]`. On narrow screens Card and Insert drop their
/// titles.
struct AnswerActionBar: View {
    /// Shows a spinner on Card while the card is made after the tap.
    var isPreparingCard: Bool
    /// A send or insert is already on its way.
    var isDisabled: Bool
    var onSend: () -> Void
    var onCard: () -> Void
    var onInsert: () -> Void
    var onCopy: () -> Void
    var onRewrite: (RewriteKind) -> Void
    var onRegenerate: () -> Void
    var onReport: () -> Void

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            ViewThatFits(in: .horizontal) {
                row(showsTitles: true)
                row(showsTitles: false)
            }
        }
        .disabled(isDisabled)
    }

    private func row(showsTitles: Bool) -> some View {
        HStack(spacing: 8) {
            Button {
                onSend()
            } label: {
                Label("Send", systemImage: "arrow.up")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.glassProminent)
            .tint(NimbusTheme.sendBlue)
            .accessibilityHint("Sends the answer into the chat as a message.")

            Button {
                onCard()
            } label: {
                cardLabel(showsTitle: showsTitles)
            }
            .buttonStyle(.glass)
            .accessibilityLabel("Card")
            .accessibilityHint("Sends the answer as a Nimbus card.")

            Button {
                onInsert()
            } label: {
                titled("Insert", systemImage: "pencil", showsTitle: showsTitles)
            }
            .buttonStyle(.glass)
            .accessibilityLabel("Insert")
            .accessibilityHint("Puts the answer in the message field so you can edit it.")

            Menu {
                menuItems
            } label: {
                Image(systemName: "ellipsis")
                    .frame(minWidth: 20, minHeight: 20)
            }
            .buttonStyle(.glass)
            .accessibilityLabel("More")
        }
        .labelStyle(.titleAndIcon)
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private func titled(_ title: String, systemImage: String, showsTitle: Bool) -> some View {
        if showsTitle {
            Label(title, systemImage: systemImage)
        } else {
            Image(systemName: systemImage)
        }
    }

    @ViewBuilder
    private func cardLabel(showsTitle: Bool) -> some View {
        if showsTitle {
            Label {
                Text("Card")
            } icon: {
                cardIcon
            }
        } else {
            cardIcon
        }
    }

    @ViewBuilder
    private var cardIcon: some View {
        if isPreparingCard {
            ProgressView()
                .controlSize(.mini)
        } else {
            Image(systemName: "rectangle.on.rectangle")
        }
    }

    @ViewBuilder
    private var menuItems: some View {
        Button {
            onCopy()
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }
        Section {
            ForEach(RewriteKind.allCases) { kind in
                Button {
                    onRewrite(kind)
                } label: {
                    Label(kind.title, systemImage: kind.systemImage)
                }
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
            Label("Report…", systemImage: "flag")
        }
    }
}
