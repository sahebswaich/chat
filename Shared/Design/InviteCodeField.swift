import Foundation
import SwiftUI
import UIKit

/// Eight verification-code boxes driven by one invisible text field, so typing auto-advances,
/// Backspace works, and long-press → Paste (`K7QM-2XPA` or a join link) fills every box.
/// Invalid characters (I, L, O, U, symbols) shake the boxes with an error haptic.
struct InviteCodeField: View {
    /// Up to 8 normalized characters, no dash.
    @Binding var code: String
    /// Change this (e.g. increment it) to shake the boxes after the server rejects the code.
    var errorTrigger: Int
    /// Focus the field (show the keyboard) when it appears.
    var autoFocus: Bool
    /// Called when the hidden field gains or loses focus (the iMessage extension expands on focus).
    var onFocusChange: (Bool) -> Void
    /// Called once each time the eighth valid character arrives.
    var onComplete: (String) -> Void

    init(
        code: Binding<String>,
        errorTrigger: Int = 0,
        autoFocus: Bool = true,
        onFocusChange: @escaping (Bool) -> Void = { _ in },
        onComplete: @escaping (String) -> Void = { _ in }
    ) {
        self._code = code
        self.errorTrigger = errorTrigger
        self.autoFocus = autoFocus
        self.onFocusChange = onFocusChange
        self.onComplete = onComplete
    }

    @State private var raw = ""
    @State private var shakes: CGFloat = 0
    @State private var rejectTick = 0
    @State private var showsError = false
    @FocusState private var isFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            TextField("", text: $raw)
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .focused($isFocused)
                .font(.system(size: 34))
                .foregroundStyle(.clear)
                .tint(.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("Invite code")
                .accessibilityValue(InviteCode.format(code))

            boxes
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .frame(height: 60)
        .modifier(ShakeEffect(animatableData: shakes))
        .sensoryFeedback(.error, trigger: rejectTick)
        .onAppear {
            if raw != code {
                raw = code
            }
            if autoFocus {
                isFocused = true
            }
        }
        .onChange(of: raw) { oldValue, newValue in
            handleInput(old: oldValue, new: newValue)
        }
        .onChange(of: code) { _, newValue in
            if newValue != raw {
                raw = newValue
            }
        }
        .onChange(of: errorTrigger) {
            reject()
        }
        .onChange(of: isFocused) { _, focused in
            onFocusChange(focused)
        }
    }

    // MARK: - Boxes

    private var boxes: some View {
        let characters = Array(code)
        let current = min(characters.count, InviteCode.length - 1)
        return HStack(spacing: 6) {
            ForEach(0..<InviteCode.length, id: \.self) { index in
                if index == InviteCode.length / 2 {
                    Text(verbatim: "-")
                        .font(.system(.title2, design: .monospaced, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                box(
                    character: index < characters.count ? String(characters[index]) : "",
                    isCurrent: isFocused && index == current
                )
            }
        }
    }

    private func box(character: String, isCurrent: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        return Text(verbatim: character.isEmpty ? " " : character)
            .font(.system(.title, design: .monospaced, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(minWidth: 26, maxWidth: 44, minHeight: 52, maxHeight: 58)
            .background(NimbusTheme.assistantBubble, in: shape)
            .overlay {
                shape.strokeBorder(borderColor(isCurrent: isCurrent), lineWidth: isCurrent || showsError ? 2 : 1)
            }
            .animation(.snappy(duration: 0.15), value: character)
            .animation(.snappy(duration: 0.15), value: isCurrent)
    }

    private func borderColor(isCurrent: Bool) -> Color {
        if showsError {
            return .red
        }
        return isCurrent ? NimbusTheme.accent : Color.secondary.opacity(0.25)
    }

    // MARK: - Input

    private func handleInput(old: String, new: String) {
        var result = InviteCode.sanitize(new)
        // Pasting a whole code on top of a partial one: keep the pasted code.
        if new.count - old.count > 1, new.hasPrefix(old) {
            let pasted = InviteCode.sanitize(String(new.dropFirst(old.count)))
            if pasted.code.count == InviteCode.length {
                result = pasted
            }
        }

        if result.rejected {
            reject()
        } else if showsError, result.code != code {
            showsError = false
        }

        let wasComplete = code.count == InviteCode.length
        if result.code != new {
            raw = result.code
        }
        if result.code != code {
            code = result.code
        }
        if !wasComplete, result.code.count == InviteCode.length {
            onComplete(result.code)
        }
    }

    private func reject() {
        rejectTick += 1
        showsError = true
        guard !reduceMotion else { return }
        withAnimation(.linear(duration: 0.4)) {
            shakes += 1
        }
    }
}
