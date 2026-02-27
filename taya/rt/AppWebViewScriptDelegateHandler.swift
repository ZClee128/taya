import Foundation
import WebKit

/// Weak-reference proxy for WKScriptMessageHandler.
/// Prevents retain cycles between WKUserContentController and the owning view controller.
/// All received messages are dispatched to the main queue before forwarding.
final class ScriptMessageProxy: NSObject, WKScriptMessageHandler {

    private weak var forwardTarget: WKScriptMessageHandler?

    init(target: WKScriptMessageHandler) {
        self.forwardTarget = target
        super.init()
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        DispatchQueue.main.async { [weak self] in
            self?.forwardTarget?.userContentController(controller, didReceive: message)
        }
    }
}

// MARK: - Legacy Compatibility

/// Preserves existing initializer pattern used throughout the project.
final class AppWebViewScriptDelegateHandler: NSObject, WKScriptMessageHandler {

    private weak var scriptDelegate: WKScriptMessageHandler?

    init(_ delegate: WKScriptMessageHandler) {
        self.scriptDelegate = delegate
        super.init()
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        DispatchQueue.main.async { [weak self] in
            self?.scriptDelegate?.userContentController(controller, didReceive: message)
        }
    }
}
