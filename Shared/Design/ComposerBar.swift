import Foundation
import SwiftUI

/// The Messages-style compose bar: a Liquid Glass field that grows to five lines, with a blue
/// circular ↑ send button that turns into a stop button while an answer streams.
struct ComposerBar: View {
    @Binding var text: String
    var isStreaming: Bool
    var focus: FocusState<Bool>.Binding
    var placeholder: String
    var onSubmit: () -> Void
    var onStop: () -> Void

    init(
        text: Binding<String>,
        isStreaming: Bool,
        focus: FocusState<Bool>.Binding,
        placeholder: String = "Ask anything…",
        onSubmit: @escaping () -> Void,
        onStop: @escaping () -> Void = {}
    ) {
        self._text = text
        self.isStreaming = isStreaming
        self.focus = focus
        self.placeholder = placeholder
        self.onSubmit = onSubmit
        self.onStop = onStop
    }

    @State private var sendTick = 0
    /// When ↑ was last tapped: the button turns into Stop right away, so a quick double tap
    /// would otherwise cancel the answer it just asked for.
    @State private var lastSubmitAt = Date.distantPast

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var fieldShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            TextField(placeholder, text: $text, axis: .vertical)
                .lineLimit(1...5)
                .font(.body)
                .focused(focus)
                .submitLabel(.send)
                .onSubmit(submit)
                .padding(.leading, 16)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity, alignment: .leading)

            actionButton
                .padding(.trailing, 5)
                .padding(.bottom, 5)
        }
        .frame(minHeight: 44)
        .glassEffect(.regular.interactive(), in: fieldShape)
        .sensoryFeedback(.impact(weight: .medium), trigger: sendTick)
    }

    private var actionButton: some View {
        Button {
            if isStreaming {
                guard Date().timeIntervalSince(lastSubmitAt) > 0.6 else { return }
                sendTick += 1
                onStop()
            } else {
                submit()
            }
        } label: {
            Image(systemName: isStreaming ? "stop.fill" : "arrow.up")
                .font(.system(size: isStreaming ? 13 : 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle().fill(isStreaming || canSend ? NimbusTheme.sendBlue : Color(white: 0.6).opacity(0.5))
                )
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .disabled(!isStreaming && !canSend)
        .animation(.snappy(duration: 0.2), value: isStreaming)
        .animation(.snappy(duration: 0.2), value: canSend)
        .accessibilityLabel(isStreaming ? "Stop" : "Send")
    }

    private func submit() {
        guard canSend, !isStreaming else { return }
        lastSubmitAt = Date()
        sendTick += 1
        onSubmit()
    }
}
