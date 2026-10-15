import Foundation
import Observation

/// What a thread is doing right now (drives buttons, haptics and the Live Activity).
nonisolated enum ChatPhase: Equatable, Sendable {
    case idle
    case thinking
    case searching
    case writing
    case done
    case failed(String)

    /// An answer is in flight.
    var isBusy: Bool {
        switch self {
        case .thinking, .searching, .writing: return true
        case .idle, .done, .failed: return false
        }
    }
}

/// Follow-up rewrites offered on an answer's long-press menu.
nonisolated enum RewriteKind: String, CaseIterable, Identifiable, Codable, Sendable {
    case shorter
    case funnier
    case formal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .shorter: return "Shorter"
        case .funnier: return "Funnier"
        case .formal: return "More formal"
        }
    }

    var systemImage: String {
        switch self {
        case .shorter: return "scissors"
        case .funnier: return "face.smiling"
        case .formal: return "briefcase"
        }
    }

    /// The user turn sent to the server.
    var instruction: String {
        switch self {
        case .shorter: return "Rewrite your last answer to be shorter."
        case .funnier: return "Rewrite your last answer to be funnier."
        case .formal: return "Rewrite your last answer to sound more formal."
        }
    }
}

/// Drives one chat thread for any surface: sends the history, streams the answer into the
/// last message, and exposes counters views can hang `.sensoryFeedback` on.
@Observable
final class ChatEngine {
    let surface: Surface

    /// The thread, oldest first. Safe to replace (e.g. restoring from SwiftData) via `load(_:)`.
    var messages: [ThreadMessage] = []
    /// Lets the server use web search for this thread's answers.
    var webSearch: Bool = true

    /// Style of the most recent request; rewrites and regenerations reuse it.
    private(set) var style: ChatStyle = .default
    /// Pasted conversation text; sticks to the thread until replaced or `reset()`.
    private(set) var context: String?
    /// Model reported by the last stream's `meta` event.
    private(set) var model: String?
    /// The last failure, cleared when a new answer starts.
    private(set) var lastError: NimbusError?

    /// Incremented when the first text of an answer arrives (soft tap).
    private(set) var firstTokenTick = 0
    /// Incremented when an answer finishes (success haptic).
    private(set) var completionTick = 0
    /// Incremented when an answer fails (error haptic).
    private(set) var errorTick = 0

    private let makeClient: @MainActor () -> NimbusClient
    @ObservationIgnored private var streamTask: Task<Void, Never>?

    init(
        surface: Surface,
        client: @escaping @MainActor () -> NimbusClient = { NimbusClient(credential: NimbusSession.shared.credential) }
    ) {
        self.surface = surface
        self.makeClient = client
    }

    // MARK: - State

    var phase: ChatPhase {
        guard let last = messages.last, last.role == .assistant else { return .idle }
        switch last.state {
        case .waiting: return .thinking
        case .searching: return .searching
        case .streaming: return .writing
        case .done: return .done
        case .failed(let message): return .failed(message)
        }
    }

    var isBusy: Bool { phase.isBusy }

    /// The latest finished answer (what Send / Card / Insert act on).
    var lastAnswer: ThreadMessage? {
        messages.last(where: { $0.isCompletedAnswer })
    }

    /// The latest assistant message in any state.
    var latestAssistantMessage: ThreadMessage? {
        messages.last(where: { $0.role == .assistant })
    }

    /// The latest thing the person asked.
    var lastQuestion: String? {
        messages.last(where: { $0.role == .user })?.text
    }

    // MARK: - Actions

    /// Asks a question. With `context` and nothing typed, sends the style's `contextPrompt`.
    func ask(_ text: String, style: ChatStyle = .default, context: String? = nil) {
        let typed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var newContext: String?
        if let pasted = context?.trimmingCharacters(in: .whitespacesAndNewlines), !pasted.isEmpty {
            newContext = String(pasted.prefix(20_000))
        }
        let question: String
        if !typed.isEmpty {
            question = String(typed.prefix(20_000))
        } else if newContext != nil {
            question = style.contextPrompt
        } else {
            return
        }

        cancel()
        if let newContext {
            self.context = newContext
        }
        self.style = style
        messages.append(ThreadMessage(role: .user, text: question))
        startStream(question: question)
    }

    /// Stops the answer in flight, keeping any text that already arrived.
    func cancel() {
        streamTask?.cancel()
        streamTask = nil
        guard let index = messages.lastIndex(where: { $0.role == .assistant }),
              messages[index].state.isInProgress
        else { return }
        let text = messages[index].text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            messages[index].state = .failed("Stopped.")
        } else {
            messages[index].text = text
            messages[index].state = .done
        }
    }

    /// Replaces the last answer (finished or failed) with a fresh one.
    func regenerate() {
        cancel()
        guard let last = messages.last else { return }
        var question: String?
        if last.role == .assistant {
            question = last.question
            messages.removeLast()
        }
        startStream(question: question)
    }

    /// Same as `regenerate()`; reads better on a failed bubble's button.
    func retry() {
        regenerate()
    }

    /// Asks for the last answer again, rewritten.
    func rewrite(_ kind: RewriteKind) {
        cancel()
        guard let answer = lastAnswer else { return }
        messages.append(ThreadMessage(role: .user, text: kind.instruction))
        startStream(question: answer.question)
    }

    /// Clears the thread.
    func reset() {
        cancel()
        messages = []
        context = nil
        style = .default
        model = nil
        lastError = nil
    }

    /// Replaces the thread with saved messages, resolving any that never finished.
    func load(_ saved: [ThreadMessage], style: ChatStyle = .default, context: String? = nil) {
        cancel()
        messages = saved.map { $0.settled() }
        self.style = style
        self.context = context
        lastError = nil
    }

    // MARK: - History

    /// The `messages` array sent to the server: alternating user/assistant turns built from
    /// finished messages only, starting and ending with `user`, at most `limit` entries
    /// (oldest dropped), each at most `maxLength` characters.
    ///
    /// Failed or in-progress answers are skipped, and a question whose answer failed is
    /// replaced by the next question.
    nonisolated static func history(
        from messages: [ThreadMessage],
        limit: Int = 40,
        maxLength: Int = 20_000
    ) -> [ChatTurn] {
        var turns: [ChatTurn] = []
        for message in messages {
            let content = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !content.isEmpty else { continue }
            let turn = ChatTurn(role: message.role, content: String(content.prefix(maxLength)))
            switch message.role {
            case .user:
                guard !message.state.isFailed else { continue }
                if turns.last?.role == .user {
                    turns[turns.count - 1] = turn
                } else {
                    turns.append(turn)
                }
            case .assistant:
                guard message.state == .done else { continue }
                if turns.last?.role == .user {
                    turns.append(turn)
                } else if turns.last?.role == .assistant {
                    turns[turns.count - 1] = turn
                }
            }
        }
        while turns.last?.role == .assistant {
            turns.removeLast()
        }
        if turns.count > limit {
            turns.removeFirst(turns.count - limit)
        }
        while turns.first?.role == .assistant {
            turns.removeFirst()
        }
        return turns
    }

    // MARK: - Streaming

    private func startStream(question: String?) {
        let history = Self.history(from: messages)
        guard let lastTurn = history.last, lastTurn.role == .user else { return }

        let placeholder = ThreadMessage(
            role: .assistant,
            text: "",
            question: question ?? lastTurn.content,
            state: .waiting
        )
        messages.append(placeholder)
        lastError = nil

        let request = ChatRequest(
            messages: history,
            style: style,
            surface: surface,
            context: context,
            webSearch: webSearch
        )
        let client = makeClient()
        let id = placeholder.id
        streamTask = Task { [weak self] in
            do {
                for try await event in client.stream(request) {
                    guard !Task.isCancelled, let self else { return }
                    self.apply(event, to: id)
                }
                guard !Task.isCancelled else { return }
                self?.streamEnded(id: id)
            } catch {
                guard !Task.isCancelled else { return }
                self?.streamFailed(id: id, error: error)
            }
        }
    }

    private func apply(_ event: ChatEvent, to id: UUID) {
        guard let index = messages.lastIndex(where: { $0.id == id }) else { return }
        switch event {
        case .meta(let model):
            if !model.isEmpty {
                self.model = model
            }
        case .status(let state):
            if state == "searching" {
                messages[index].state = .searching
            } else if state == "writing" {
                messages[index].state = messages[index].text.isEmpty ? .waiting : .streaming
            }
        case .delta(let chunk):
            guard !chunk.isEmpty else { return }
            if messages[index].text.isEmpty {
                firstTokenTick += 1
            }
            messages[index].text += chunk
            if messages[index].state != .streaming {
                messages[index].state = .streaming
            }
        case .done(let info):
            let finalText = messages[index].text.trimmingCharacters(in: .whitespacesAndNewlines)
            messages[index].text = finalText
            if finalText.isEmpty {
                messages[index].state = .failed("Nimbus came back empty-handed. Try again?")
                errorTick += 1
            } else {
                messages[index].state = .done
                completionTick += 1
            }
            streamTask = nil
            NimbusSession.shared.handle(done: info)
        }
    }

    private func streamEnded(id: UUID) {
        streamTask = nil
        guard let index = messages.lastIndex(where: { $0.id == id }),
              messages[index].state.isInProgress
        else { return }
        messages[index] = messages[index].settled()
        if messages[index].state.isFailed {
            errorTick += 1
        }
    }

    private func streamFailed(id: UUID, error: any Error) {
        streamTask = nil
        guard let mapped = NimbusError.from(error) else { return }
        lastError = mapped
        if let index = messages.lastIndex(where: { $0.id == id }) {
            messages[index].state = .failed(mapped.errorDescription ?? "Something went wrong.")
        }
        errorTick += 1
        NimbusSession.shared.handle(error: mapped)
    }
}
