import Foundation
import SwiftUI
import UIKit

/// A three-step mini animation of finding Nimbus in Messages: tap **+**, tap **More**, tap
/// **Nimbus**. The mock is styled like the iOS 26 Messages + menu (a glass list of round
/// icons). Steps advance on their own (not with Reduce Motion) and the dots jump to a step.
struct SetupGuideView: View {
    /// The sidebar card's smaller version; the full one adds tips and an Open Messages button.
    var compact: Bool

    init(compact: Bool = false) {
        self.compact = compact
    }

    @State private var step = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL

    private let stepCount = 3

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 12 : 20) {
            mock
                .frame(maxWidth: .infinity)
                .frame(height: compact ? 190 : 270)
                .background {
                    mockBackground
                }
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
                }
                .accessibilityHidden(true)
            caption
            if !compact {
                details
            }
        }
        .task(id: reduceMotion) {
            await autoAdvance()
        }
    }

    // MARK: - Mock

    private var mockBackground: some View {
        LinearGradient(
            colors: [Color(uiColor: .systemBackground), Color(uiColor: .secondarySystemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    private var mock: some View {
        ZStack {
            switch step {
            case 0:
                composeMock
                    .transition(stepTransition)
            case 1:
                menuMock(rows: MockRow.firstPage, highlighted: "More")
                    .transition(stepTransition)
            default:
                menuMock(rows: MockRow.morePage, highlighted: "Nimbus")
                    .transition(stepTransition)
            }
        }
    }

    /// Step 1: a chat with the + button next to the text field.
    private var composeMock: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 0)
            HStack {
                Spacer()
                mockBubble(width: compact ? 110 : 140, color: NimbusTheme.sendBlue)
            }
            HStack {
                mockBubble(width: compact ? 150 : 190, color: Color(uiColor: .systemGray4))
                Spacer()
            }
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(uiColor: .systemGray5))
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 36, height: 36)
                .background {
                    TapHighlight(shape: Circle())
                        .padding(-5)
                }
                .overlay(alignment: .bottomTrailing) {
                    pointer
                        .offset(x: 14, y: 14)
                }
                Capsule()
                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                    .frame(height: 36)
                    .overlay(alignment: .leading) {
                        Text(verbatim: "iMessage")
                            .font(.callout)
                            .foregroundStyle(.tertiary)
                            .padding(.leading, 14)
                    }
            }
        }
        .padding(14)
    }

    private func mockBubble(width: CGFloat, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(color.opacity(0.85))
            .frame(width: width, height: 28)
    }

    /// Steps 2 and 3: the + menu list, with the row to tap highlighted.
    private func menuMock(rows: [MockRow], highlighted: String) -> some View {
        VStack(alignment: .leading, spacing: compact ? 2 : 4) {
            ForEach(rows) { row in
                menuRow(row, isHighlighted: row.title == highlighted)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .frame(width: compact ? 214 : 250, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .padding(compact ? 10 : 12)
    }

    private func menuRow(_ row: MockRow, isHighlighted: Bool) -> some View {
        let iconSize: CGFloat = compact ? 24 : 30
        return HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(row.isNimbus ? AnyShapeStyle(NimbusTheme.sky) : AnyShapeStyle(row.tint))
                Image(systemName: row.systemImage)
                    .font(.system(size: iconSize * 0.46, weight: .semibold))
                    .foregroundStyle(Color.white)
            }
            .frame(width: iconSize, height: iconSize)
            Text(row.title)
                .font(compact ? Font.subheadline : Font.body)
                .fontWeight(isHighlighted ? Font.Weight.semibold : Font.Weight.regular)
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
            if isHighlighted {
                pointer
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, compact ? 2 : 5)
        .background {
            if isHighlighted {
                ZStack {
                    Capsule()
                        .fill(NimbusTheme.accent.opacity(0.14))
                    TapHighlight(shape: Capsule())
                }
            }
        }
    }

    private var pointer: some View {
        Image(systemName: "hand.tap.fill")
            .font(.system(size: compact ? 15 : 18))
            .foregroundStyle(NimbusTheme.accent)
            .symbolEffect(.pulse, isActive: !reduceMotion)
    }

    // MARK: - Caption

    private var caption: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(verbatim: "\(step + 1)")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.white)
                .frame(width: 22, height: 22)
                .background(NimbusTheme.sky, in: Circle())
            Text(Self.title(for: step))
                .font(compact ? Font.subheadline.weight(.semibold) : Font.headline)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            stepDots
        }
        .accessibilityElement(children: .contain)
    }

    private var stepDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<stepCount, id: \.self) { index in
                Button {
                    withAnimation(reduceMotion ? nil : Animation.smooth(duration: 0.4)) {
                        step = index
                    }
                } label: {
                    Capsule()
                        .fill(index == step ? AnyShapeStyle(NimbusTheme.sky) : AnyShapeStyle(Color.secondary.opacity(0.3)))
                        .frame(width: index == step ? 18 : 7, height: 7)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Step \(index + 1): \(Self.title(for: index))")
            }
        }
    }

    private static func title(for step: Int) -> String {
        switch step {
        case 0: return "In a chat, tap + next to the text field"
        case 1: return "Tap More"
        default: return "Tap Nimbus"
        }
    }

    // MARK: - Full guide

    private var details: some View {
        VStack(alignment: .leading, spacing: 16) {
            tip(
                symbol: "sparkles",
                title: "Ask anything",
                text: "Type a question in Nimbus, then tap Send to drop the answer into the chat as a normal message."
            )
            tip(
                symbol: "doc.on.clipboard",
                title: "Paste the chat",
                text: "Copy what your friends said, tap Paste chat, and Nimbus can reply for you, explain it or fact-check it."
            )
            tip(
                symbol: "hand.draw",
                title: "Keep it handy",
                text: "Touch and hold Nimbus in the + menu and drag it up so it's always one tap away."
            )
            Button {
                if let url = URL(string: "sms:") {
                    openURL(url)
                }
            } label: {
                Label("Open Messages", systemImage: "message.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.glassProminent)
            .tint(NimbusTheme.accent)
            .controlSize(.large)
        }
    }

    private func tip(symbol: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(NimbusTheme.sky)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Timing

    private func autoAdvance() async {
        guard !reduceMotion else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(2.8))
            guard !Task.isCancelled else { return }
            withAnimation(.smooth(duration: 0.5)) {
                step = (step + 1) % stepCount
            }
        }
    }
}

/// One row of the mock + menu.
private struct MockRow: Identifiable {
    let title: String
    let systemImage: String
    let tint: Color
    var isNimbus: Bool = false

    var id: String { title }

    static let firstPage: [MockRow] = [
        MockRow(title: "Camera", systemImage: "camera.fill", tint: .gray),
        MockRow(title: "Photos", systemImage: "photo.fill", tint: .blue),
        MockRow(title: "Stickers", systemImage: "face.smiling", tint: .orange),
        MockRow(title: "Audio", systemImage: "waveform", tint: .pink),
        MockRow(title: "More", systemImage: "chevron.down", tint: .gray),
    ]

    static let morePage: [MockRow] = [
        MockRow(title: "Location", systemImage: "location.fill", tint: .green),
        MockRow(title: "Check In", systemImage: "checkmark.circle.fill", tint: .teal),
        MockRow(title: "Send Later", systemImage: "clock.fill", tint: .indigo),
        MockRow(title: "Nimbus", systemImage: "sparkle", tint: .purple, isNimbus: true),
    ]
}

/// A ring that pulses outward from the thing to tap.
private struct TapHighlight<S: InsettableShape>: View {
    let shape: S

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let progress = reduceMotion
                ? 0.3
                : context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.4) / 1.4
            shape
                .strokeBorder(NimbusTheme.accent, lineWidth: 2)
                .scaleEffect(1 + CGFloat(progress) * 0.12)
                .opacity(1 - progress * 0.8)
        }
        .allowsHitTesting(false)
    }
}
