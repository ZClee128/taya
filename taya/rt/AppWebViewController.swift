import UIKit
import WebKit

/// Full-screen web content view controller with JavaScript bridge support.
/// Provides bidirectional communication between native code and web content
/// via WebViewJavascriptBridge and WKScriptMessageHandler.
final class AppWebViewController: UIViewController {

    var urlString: String = ""
    var clearBgColor = false
    var fullscreen = true

    private var jsBridge: WebViewJavascriptBridge?

    // Pending JS dialog handlers (must always be called to avoid WKWebView deadlock)
    private var pendingAlert: (() -> Void)?
    private var pendingConfirm: ((Bool) -> Void)?
    private var pendingPrompt: ((String?) -> Void)?

    // MARK: - Web View

    private(set) lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        let prefs = WKPreferences()
        prefs.javaScriptEnabled = true
        config.preferences = prefs
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.userContentController = WKUserContentController()

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.uiDelegate = self
        wv.navigationDelegate = self
        wv.allowsLinkPreview = false
        wv.allowsBackForwardNavigationGestures = true
        wv.scrollView.contentInsetAdjustmentBehavior = .never
        wv.isOpaque = false
        wv.scrollView.bounces = false
        wv.scrollView.alwaysBounceVertical = false
        wv.scrollView.alwaysBounceHorizontal = false
        return wv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        var frame = UIScreen.main.bounds
        if !fullscreen {
            frame.origin.y = AppConfig.getStatusBarHeight()
        }
        webView.frame = frame
        view.addSubview(webView)

        registerBridgeHandlers()
        loadContent()

        NotificationCenter.default.addObserver(
            self, selector: #selector(dispatchPageShow),
            name: UIApplication.willEnterForegroundNotification, object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dispatchPageShow()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dispatchPageHide()
        flushPendingDialogs()
    }

    deinit {
        unregisterBridgeHandlers()
        flushPendingDialogs()
    }

    // MARK: - Content Loading

    private func loadContent() {
        guard let url = URL(string: urlString) else { return }
        webView.load(URLRequest(url: url))
        applyTransparencyIfNeeded()
    }

    private func applyTransparencyIfNeeded() {
        guard clearBgColor else { return }
        webView.evaluateJavaScript("document.getElementsByTagName('body')[0].style.background='rgba(0,0,0,0)'", completionHandler: nil)
        view.backgroundColor = .clear
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.bounces = false
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.alwaysBounceHorizontal = false
        webView.isOpaque = false
    }

    // MARK: - Navigation

    func closeWeb() {
        if webView.canGoBack {
            webView.goBack()
            return
        }
        unregisterBridgeHandlers()
        guard presentingViewController != nil else { return }
        dismiss(animated: true) {
            if let top = AppConfig.currentViewController() as? AppWebViewController {
                top.dispatchPageShow()
            }
        }
    }

    func reloadWebView() {
        if webView.url != nil {
            webView.reload()
        } else {
            loadContent()
        }
    }
}

// MARK: - JavaScript Bridge

extension AppWebViewController: WKScriptMessageHandler, WebViewJavascriptBridgeBaseDelegate {

    func _evaluateJavascript(_ javascriptCommand: String!) -> String! { "" }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch message.name {
            case "closeWeb":
                self.closeWeb()
            case "toUrl":
                if let url = message.body as? String {
                    AppWebViewController.presentWebView(url: url)
                }
            default:
                break
            }
        }
    }

    func registerBridgeHandlers() {
        jsBridge = WebViewJavascriptBridge(webView)
        jsBridge?.setWebViewDelegate(self)

        jsBridge?.registerHandler("syncAppInfo") { [weak self] data, callback in
            guard let self = self, let dict = data as? [String: Any], let cb = callback else { return }
            self.handleH5Message(schemeDic: dict) { response in
                cb(response)
                DispatchQueue.main.async {
                    self.promptSettingsIfNeeded(response)
                }
            }
        }

        let uc = webView.configuration.userContentController
        uc.add(AppWebViewScriptDelegateHandler(self), name: "closeWeb")
        uc.add(AppWebViewScriptDelegateHandler(self), name: "toUrl")
    }

    func unregisterBridgeHandlers() {
        let uc = webView.configuration.userContentController
        if #available(iOS 14.0, *) {
            uc.removeAllScriptMessageHandlers()
        } else {
            uc.removeScriptMessageHandler(forName: "closeWeb")
            uc.removeScriptMessageHandler(forName: "toUrl")
        }
    }

    func promptSettingsIfNeeded(_ response: [String: Any]) {
        guard let typeName = response["typeName"] as? String,
              let isAuth = response["isAuth"] as? Bool,
              let isFirst = response["isFirst"] as? Bool else { return }

        guard !isAuth, !isFirst else { return }

        var prompt: String?
        switch typeName {
        case "getCameraStatus":
            prompt = "Please allow '\(AppName)' to access your camera in Settings → Privacy → Camera"
        case "getPhotoStatus":
            prompt = "Please allow '\(AppName)' to access your photos in Settings → Privacy → Photos"
        case "getMicStatus":
            prompt = "Please allow '\(AppName)' to access your microphone in Settings → Privacy → Microphone"
        default:
            return
        }

        guard let message = prompt else { return }
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default))
        alert.addAction(UIAlertAction(title: "Go", style: .destructive) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        present(alert, animated: true)
    }
}

// MARK: - WKNavigationDelegate & WKUIDelegate

extension AppWebViewController: WKNavigationDelegate, WKUIDelegate {

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation nav: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    func webView(_ webView: WKWebView, didFinish nav: WKNavigation!) {
        applyTransparencyIfNeeded()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation nav: WKNavigation!, withError error: Error) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        let alert = UIAlertController(title: nil, message: "Network error, loading failed", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Refresh", style: .default) { [weak self] _ in
            self?.reloadWebView()
        })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, didFail nav: WKNavigation!, withError error: Error) {}

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        DispatchQueue.global().async {
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
               challenge.previousFailureCount == 0,
               let trust = challenge.protectionSpace.serverTrust {
                completionHandler(.useCredential, URLCredential(trust: trust))
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        reloadWebView()
    }

    // MARK: JS Dialogs

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        pendingAlert = completionHandler
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.pendingAlert?()
            self?.pendingAlert = nil
        })
        if let top = AppConfig.currentViewController() {
            top.present(alert, animated: true)
        } else {
            pendingAlert?()
            pendingAlert = nil
        }
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        pendingConfirm = completionHandler
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.pendingConfirm?(false)
            self?.pendingConfirm = nil
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.pendingConfirm?(true)
            self?.pendingConfirm = nil
        })
        if let top = AppConfig.currentViewController() {
            top.present(alert, animated: true)
        } else {
            pendingConfirm?(false)
            pendingConfirm = nil
        }
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        pendingPrompt = completionHandler
        let alert = UIAlertController(title: prompt, message: "", preferredStyle: .alert)
        alert.addTextField { $0.text = defaultText }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.pendingPrompt?(nil)
            self?.pendingPrompt = nil
        })
        alert.addAction(UIAlertAction(title: "Done", style: .default) { [weak self] _ in
            self?.pendingPrompt?(alert.textFields?.first?.text)
            self?.pendingPrompt = nil
        })
        if let top = AppConfig.currentViewController() {
            top.present(alert, animated: true)
        } else {
            pendingPrompt?(nil)
            pendingPrompt = nil
        }
    }

    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(.grant)
    }
}

// MARK: - JS Lifecycle Events

extension AppWebViewController {

    private func flushPendingDialogs() {
        pendingAlert?()
        pendingAlert = nil
        pendingConfirm?(false)
        pendingConfirm = nil
        pendingPrompt?(nil)
        pendingPrompt = nil
    }

    func third_jsEvent_refreshCoin() {
        webView.evaluateJavaScript("HttpTool.NativeToJs('recharge')", completionHandler: nil)
    }

    @objc private func dispatchPageShow() {
        jsBridge?.callHandler("onPageShow")
        webView.evaluateJavaScript("window.onPageShow&&onPageShow();", completionHandler: nil)
    }

    private func dispatchPageHide() {
        jsBridge?.callHandler("onPageHide")
        webView.evaluateJavaScript("window.onPageHide&&onPageHide();", completionHandler: nil)
    }

    // MARK: - Factory

    /// Present a new web view controller modally.
    class func presentWebView(url: String, transparency: Int = 0, fullscreen: Int = 1) {
        let vc = AppWebViewController()
        vc.urlString = url
        vc.clearBgColor = (transparency == 1)
        vc.fullscreen = (fullscreen == 1)
        vc.modalPresentationStyle = .fullScreen
        AppConfig.currentViewController()?.present(vc, animated: true)
    }

    // Legacy compatibility
    class func openNewWebView(_ url: String, _ transparency: Int = 0, _ fullscreen: Int = 1) {
        presentWebView(url: url, transparency: transparency, fullscreen: fullscreen)
    }
}
