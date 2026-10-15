import Foundation
import SwiftUI

/// Account, usage, the Messages guide, preferences, support links, sign out and data deletion.
struct SettingsView: View {
    @Environment(NimbusSession.self) private var session
    @Environment(ConversationController.self) private var conversations
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppSettings.liveActivitiesKey) private var liveActivitiesEnabled = true
    @AppStorage(AppSettings.webSearchKey) private var webSearchEnabled = true

    @State private var confirmsSignOut = false
    @State private var confirmsDelete = false
    @State private var isDeleting = false
    @State private var deleteError: String?
    @State private var showsDeleteError = false

    var body: some View {
        NavigationStack {
            Form {
                accountSection
                messagesSection
                preferencesSection
                serverSection
                supportSection
                accountActionsSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await session.refreshUsage()
            }
            .refreshable {
                await session.refreshUsage()
            }
            .confirmationDialog("Sign out of Nimbus?", isPresented: $confirmsSignOut, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This signs you out here and in Messages. Your chats stay on this device. Invite codes usually work only once, so you may need a new one to sign back in.")
            }
            .alert("Delete your Nimbus data?", isPresented: $confirmsDelete) {
                Button("Delete", role: .destructive) {
                    deleteData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This deletes your account, usage and shared cards from the Nimbus server, and your chat history on this device. You'll need a new invite to use Nimbus again.")
            }
            .alert("Couldn't delete your data", isPresented: $showsDeleteError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deleteError ?? "Try again in a moment.")
            }
        }
    }

    // MARK: - Sections

    private var accountSection: some View {
        Section {
            HStack(spacing: 18) {
                UsageRing(used: session.usedToday ?? 0, limit: usageLimit)
                    .frame(width: 76, height: 76)
                    .padding(8)
                    .glassEffect(.regular, in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.name ?? "Signed in")
                        .font(.title3.weight(.semibold))
                    Text(usageSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                    Text("Resets every day at midnight UTC.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 6)
            .animation(.smooth, value: session.usedToday)
        }
    }

    private var messagesSection: some View {
        Section {
            NavigationLink {
                ScrollView {
                    SetupGuideView(compact: false)
                        .padding(20)
                        .frame(maxWidth: 560)
                        .frame(maxWidth: .infinity)
                }
                .navigationTitle("Add to Messages")
                .navigationBarTitleDisplayMode(.inline)
            } label: {
                Label("Add Nimbus to Messages", systemImage: "message.fill")
            }
        } footer: {
            Text("Nimbus lives in the Messages + menu, so you can ask without leaving a chat.")
        }
    }

    private var preferencesSection: some View {
        Section {
            Toggle(isOn: $liveActivitiesEnabled) {
                Label("Live Activities", systemImage: "iphone")
            }
            Toggle(isOn: $webSearchEnabled) {
                Label("Search the web", systemImage: "globe")
            }
        } header: {
            Text("Answers")
        } footer: {
            Text("Live Activities show an answer's progress on the Lock Screen and in the Dynamic Island if you leave Nimbus while it's writing. Web search lets Nimbus look up current facts.")
        }
    }

    private var serverSection: some View {
        Section {
            LabeledContent("Host", value: session.host ?? "Not set")
                .textSelection(.enabled)
        } header: {
            Text("Server")
        } footer: {
            Text("To use a different server, sign out and open an invite link from it.")
        }
    }

    private var supportSection: some View {
        Section {
            if let url = session.supportURL {
                Link(destination: url) {
                    Label("Help & Support", systemImage: "questionmark.circle")
                }
            }
            if let email = session.supportEmail, let url = URL(string: "mailto:\(email)") {
                Link(destination: url) {
                    Label("Email \(email)", systemImage: "envelope")
                }
            }
            if let url = session.termsURL {
                Link(destination: url) {
                    Label("Terms of Use", systemImage: "doc.text")
                }
            }
            if let url = session.privacyURL {
                Link(destination: url) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
            }
        } header: {
            Text("Support")
        } footer: {
            Text("Touch and hold any answer and choose Report to flag it. Reports are reviewed within 24 hours.")
        }
    }

    private var accountActionsSection: some View {
        Section {
            Button(role: .destructive) {
                confirmsSignOut = true
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
            Button(role: .destructive) {
                confirmsDelete = true
            } label: {
                HStack {
                    Label("Delete My Data", systemImage: "trash")
                    Spacer()
                    if isDeleting {
                        ProgressView()
                    }
                }
            }
            .disabled(isDeleting)
        } footer: {
            Text(versionText)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
        }
    }

    // MARK: - Values

    private var usageLimit: Int {
        session.dailyLimit ?? session.credential?.dailyLimit ?? 0
    }

    private var usageSummary: String {
        guard let used = session.usedToday, let limit = session.dailyLimit else {
            return "Checking today's usage…"
        }
        let left = max(limit - used, 0)
        return "\(used) of \(limit) answers used today · \(left) left"
    }

    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "Nimbus \(version) (\(build))"
    }

    // MARK: - Actions

    private func signOut() {
        conversations.startNew(focusComposer: false)
        session.signOut()
    }

    private func deleteData() {
        isDeleting = true
        // Read the environment now: this view goes away when the account is gone.
        let session = self.session
        let conversations = self.conversations
        Task {
            do {
                try await session.deleteAccount()
                conversations.deleteAllHistory()
            } catch {
                isDeleting = false
                deleteError = NimbusError.from(error)?.errorDescription ?? "Try again in a moment."
                showsDeleteError = true
            }
        }
    }
}
