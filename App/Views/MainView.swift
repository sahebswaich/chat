import Foundation
import SwiftData
import SwiftUI

/// The signed-in app: conversations in a sidebar (a list on iPhone), the chat as the detail.
/// Also handles "open a new question", "ask this" and invite links from `NimbusRouter`.
struct MainView: View {
    @Environment(ConversationController.self) private var conversations
    @Environment(NimbusRouter.self) private var router
    @Environment(NimbusSession.self) private var session
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \StoredConversation.updatedAt, order: .reverse) private var stored: [StoredConversation]
    @AppStorage(AppSettings.setupGuideDismissedKey) private var setupGuideDismissed = false

    @State private var selection: UUID?
    @State private var compactColumn: NavigationSplitViewColumn = .sidebar
    @State private var showsSettings = false
    @State private var joinRequest: JoinRequest?
    @State private var showsJoinConfirmation = false
    @State private var joinError: String?
    @State private var showsJoinError = false

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $compactColumn) {
            sidebar
        } detail: {
            ChatView(conversations: conversations) {
                newChat(focus: true)
            }
        }
        .sheet(isPresented: $showsSettings) {
            SettingsView()
                .environment(session)
                .environment(conversations)
        }
        .onAppear {
            // iPad: show the current (new) chat next to the list from the start.
            if horizontalSizeClass == .regular, selection == nil {
                selection = conversations.currentID
            }
        }
        .onChange(of: selection) { _, newValue in
            selectionChanged(to: newValue)
        }
        .onChange(of: compactColumn) { _, column in
            // iPhone: going back to the list clears the selection so any row can be tapped again.
            if horizontalSizeClass == .compact, column == .sidebar {
                selection = nil
            }
        }
        .onChange(of: router.pending, initial: true) {
            handlePendingRoute()
        }
        .confirmationDialog(
            "Use this invite?",
            isPresented: $showsJoinConfirmation,
            titleVisibility: .visible,
            presenting: joinRequest
        ) { request in
            Button("Switch to \(InviteCode.format(request.code))") {
                switchInvite(request)
            }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("You're signed in as \(session.name ?? "a friend"). Switching uses the new invite here and in Messages.")
        }
        .alert("Couldn't use that invite", isPresented: $showsJoinError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(joinError ?? "Try again in a moment.")
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selection) {
            if !setupGuideDismissed {
                Section {
                    SetupGuideCard {
                        withAnimation(.snappy) {
                            setupGuideDismissed = true
                        }
                    }
                }
            }
            Section {
                if stored.isEmpty {
                    emptyHistory
                } else {
                    ForEach(stored) { conversation in
                        ConversationRow(conversation: conversation)
                            .tag(conversation.id)
                            .contextMenu {
                                Button(role: .destructive) {
                                    delete([conversation])
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    .onDelete { offsets in
                        delete(offsets.map { stored[$0] })
                    }
                }
            } header: {
                if !stored.isEmpty {
                    Text("Chats")
                }
            }
        }
        .navigationTitle("Nimbus")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showsSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    newChat(focus: true)
                } label: {
                    Label("New Chat", systemImage: "square.and.pencil")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }

    private var emptyHistory: some View {
        ContentUnavailableView {
            Label("No chats yet", systemImage: "bubble.left.and.bubble.right")
        } description: {
            Text("Ask Nimbus anything. Your chats are saved here, on this device.")
        } actions: {
            Button("New Chat") {
                newChat(focus: true)
            }
            .buttonStyle(.glassProminent)
            .tint(NimbusTheme.accent)
        }
        .listRowBackground(Color.clear)
    }

    // MARK: - Navigation

    private func newChat(focus: Bool) {
        conversations.startNew(focusComposer: focus)
        selection = conversations.currentID
        compactColumn = .detail
    }

    private func selectionChanged(to id: UUID?) {
        guard let id else { return }
        if id != conversations.currentID, let conversation = stored.first(where: { $0.id == id }) {
            conversations.open(conversation)
        }
        compactColumn = .detail
    }

    private func delete(_ doomed: [StoredConversation]) {
        let removesCurrent = doomed.contains { $0.id == conversations.currentID }
        conversations.delete(doomed)
        if removesCurrent {
            selection = horizontalSizeClass == .regular ? conversations.currentID : nil
        }
    }

    // MARK: - Routes (URLs, App Intents, the Control Center control)

    private func handlePendingRoute() {
        guard let pending = router.pending else { return }
        switch pending {
        case .newQuestion:
            router.pending = nil
            newChat(focus: true)
        case .ask(let question):
            router.pending = nil
            newChat(focus: false)
            conversations.ask(question)
        case .join(let code, let host):
            router.pending = nil
            joinRequest = JoinRequest(code: code, host: host)
            showsJoinConfirmation = true
        }
    }

    private func switchInvite(_ request: JoinRequest) {
        guard let consentedAt = session.credential?.consentedAt else {
            // No consent on record: go through the sign-in screen (and its consent box) again.
            conversations.startNew(focusComposer: false)
            session.signOut()
            router.pending = .join(code: request.code, host: request.host)
            return
        }
        let currentSession = session
        Task {
            do {
                try await currentSession.signIn(code: request.code, host: request.host, consentedAt: consentedAt)
            } catch {
                guard let mapped = NimbusError.from(error) else { return }
                joinError = mapped.errorDescription
                showsJoinError = true
            }
        }
    }
}

/// An invite link that arrived while already signed in.
private nonisolated struct JoinRequest: Equatable, Sendable {
    let code: String
    let host: String?
}
