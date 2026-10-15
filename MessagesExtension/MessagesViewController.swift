import Foundation
import Messages
import SwiftUI
import UIKit

/// The extension's principal class (`NSExtensionPrincipalClass` =
/// `$(PRODUCT_MODULE_NAME).MessagesViewController`). Hosts the SwiftUI UI and forwards the
/// Messages lifecycle to `MessagesModel`.
final class MessagesViewController: MSMessagesAppViewController {
    private let model = MessagesModel()
    private var hostingController: UIHostingController<MessagesRootView>?
    private var isModelConnected = false

    override func viewDidLoad() {
        super.viewDidLoad()
        connectModel()
        embedSwiftUI()
    }

    // MARK: - Conversation lifecycle

    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        connectModel()
        model.becomeActive(selectedMessageURL: conversation.selectedMessage?.url, style: presentationStyle)
    }

    override func didResignActive(with conversation: MSConversation) {
        super.didResignActive(with: conversation)
        model.resignActive()
    }

    override func didSelect(_ message: MSMessage, conversation: MSConversation) {
        super.didSelect(message, conversation: conversation)
        model.openCard(from: message.url)
    }

    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        super.didStartSending(message, conversation: conversation)
        model.didStartSending()
    }

    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.willTransition(to: presentationStyle)
        model.willTransition(to: presentationStyle)
    }

    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.didTransition(to: presentationStyle)
        model.didTransition(to: presentationStyle)
    }

    // MARK: - Setup

    /// Gives the model its hooks back into the controller. Safe to call more than once.
    private func connectModel() {
        guard !isModelConnected else { return }
        isModelConnected = true
        model.requestPresentation = { [weak self] style in
            guard let self, self.presentationStyle != style else { return }
            self.requestPresentationStyle(style)
        }
        model.dismissExtension = { [weak self] in
            self?.dismiss()
        }
        model.openURLHandler = { [weak self] url in
            self?.extensionContext?.open(url, completionHandler: nil)
        }
        model.conversationProvider = { [weak self] in
            self?.activeConversation
        }
    }

    private func embedSwiftUI() {
        guard hostingController == nil else { return }
        let host = UIHostingController(rootView: MessagesRootView(model: model))
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(host)
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        host.didMove(toParent: self)
        hostingController = host
    }
}
