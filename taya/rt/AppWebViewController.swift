//
//  AppWebViewController.swift
//  taya
//
//  Created by DouXiu on 2025/9/23.
//

import UIKit
import WebKit

class AppWebViewController: UIViewController {
    
    var urlString: String = ""
    /// Whether background is transparent
    var clearBgColor = false
    /// Whether fullscreen
    var fullscreen = true
    
    private var bridge: WebViewJavascriptBridge?
    
    // Pending JS dialog completion handlers (ensure always-called to avoid WKWebView crash)
    private var pendingAlertCompletion: (() -> Void)?
    private var pendingConfirmCompletion: ((Bool) -> Void)?
    private var pendingPromptCompletion: ((String?) -> Void)?

    lazy var webView: WKWebView = {
        let webConfig = WKWebViewConfiguration()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        webConfig.preferences = preferences
        webConfig.allowsInlineMediaPlayback = true
        webConfig.mediaTypesRequiringUserActionForPlayback = []
        let userControl = WKUserContentController()
        webConfig.userContentController = userControl
        let w = WKWebView(frame: .zero, configuration: webConfig)
        w.uiDelegate = self
        w.navigationDelegate = self
        w.allowsLinkPreview = false
        w.allowsBackForwardNavigationGestures = true
        w.scrollView.contentInsetAdjustmentBehavior = .never
        w.isOpaque = false
        w.scrollView.bounces = false
        w.scrollView.alwaysBounceVertical = false
        w.scrollView.alwaysBounceHorizontal = false
        return w
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(self.webView)
        var frame = CGRect(origin: CGPoint.zero, size: UIScreen.main.bounds.size)
        if fullscreen == false {
            frame.origin.y = AppConfig.getStatusBarHeight()
        }
        self.webView.frame = frame
 
        self.addBridgeMethod()
        self.beginStartRequest()
 
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(jsEvent_onPageShow),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        jsEvent_onPageShow()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        jsEvent_onPageHide()
        finalizePendingJSHandlersIfNeeded()
    }

    deinit {
        removeBridgeMethod()
        finalizePendingJSHandlersIfNeeded()
    }

    /// Load web content
    private func beginStartRequest() {
        if let url = URL(string: urlString) {
            let urlRequest = URLRequest(url: url)
            self.webView.load(urlRequest)
            self.clearJSBgColor()
        }
    }
    
    /// Set page to transparent background
    private func clearJSBgColor() {
        guard clearBgColor == true else { return }
        webView.evaluateJavaScript("document.getElementsByTagName('body')[0].style.background='rgba(0,0,0,0)'") { _, _  in
        }
        view.backgroundColor = .clear
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.bounces = false
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.alwaysBounceHorizontal = false
        webView.isOpaque = false
    }
    
    /// Handle close/back navigation
    func closeWeb() {
        if webView.canGoBack {
            webView.goBack()
            return
        }
        
        removeBridgeMethod()
        if self.presentingViewController != nil {
            dismiss(animated: true) {
                if let currentVC = AppConfig.currentViewController() {
                    if currentVC.isKind(of: AppWebViewController.self) {
                        (currentVC as! AppWebViewController).jsEvent_onPageShow()
                    }
                }
            }
        }
    }
}

// MARK: - JS Bridge

extension AppWebViewController: WKScriptMessageHandler, WebViewJavascriptBridgeBaseDelegate {
    func _evaluateJavascript(_ javascriptCommand: String!) -> String! {
        return ""
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("js call method name = \(message.name), message = \(message.body)")
        DispatchQueue.main.async {
            let type = message.name
            if type == "closeWeb" {
                self.closeWeb()
            } else if type == "toUrl" {
                if let url = message.body as? String {
                    AppWebViewController.openNewWebView(url)
                }
            }
        }
    }

    func addBridgeMethod() {
        self.bridge = WebViewJavascriptBridge(self.webView)
        self.bridge?.setWebViewDelegate(self)
        self.bridge?.registerHandler("syncAppInfo", handler: { data, callback in
            print("js call getUserIdFromObjC, data from js is %@", data as Any)
            if callback != nil {
                if let dic = data as? [String: Any] {
                    self.handleH5Message(schemeDic: dic) { backDic in
                        callback?(backDic)
                        DispatchQueue.main.async {
                            self.handAuthOpenURL(dic: backDic)
                        }
                    }
                }
            }
        })
        let ucController = self.webView.configuration.userContentController
        ucController.add(AppWebViewScriptDelegateHandler(self), name: "closeWeb")
        ucController.add(AppWebViewScriptDelegateHandler(self), name: "toUrl")
    }

    func removeBridgeMethod() {
        let ucController = self.webView.configuration.userContentController
        if #available(iOS 14.0, *) {
            ucController.removeAllScriptMessageHandlers()
        } else {
            ucController.removeScriptMessageHandler(forName: "closeWeb")
            ucController.removeScriptMessageHandler(forName: "toUrl")
        }
    }

    func handAuthOpenURL(dic: [String: Any]) {
        if let typeName = dic["typeName"] as? String, let isAuth = dic["isAuth"] as? Bool, let isFirst = dic["isFirst"] as? Bool {
            if isAuth || isFirst {
                return
            }
            var message = "Please click 'Go' to allow access"
            var needAlert = false
            if typeName == "getCameraStatus" {
                needAlert = true
                message = "Please allow '\(AppName)' to access your camera in your iPhone's 'Settings-Privacy-Camera' option"
            } else if typeName == "getPhotoStatus" {
                needAlert = true
                message = "Please allow '\(AppName)' to access your album in your iPhone's 'Settings-Privacy-Album' option"
            } else if typeName == "getMicStatus" {
                needAlert = true
                message = "Please allow '\(AppName)' to access your microphone in your iPhone's 'Settings-Privacy-Microphone' option"
            }

            if needAlert {
                let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                let action1 = UIAlertAction(title: "Cancel", style: .default) { _ in
                }
                let action2 = UIAlertAction(title: "Go", style: .destructive) { _ in
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url, options: [:], completionHandler: { _ in })
                    }
                }
                alertController.addAction(action1)
                alertController.addAction(action2)
                present(alertController, animated: true)
            }
        }
    }
}

// MARK: - WKNavigationDelegate & WKUIDelegate

extension AppWebViewController: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        clearJSBgColor()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let alertController = UIAlertController(title: nil, message: "Poor network, loading failed", preferredStyle: .alert)
        let action = UIAlertAction(title: "Refresh", style: .default) { _ in
            self.reloadWebView()
        }
        alertController.addAction(action)
        present(alertController, animated: true)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    func reloadWebView() {
        if self.webView.url != nil {
            self.webView.reload()
        } else {
            self.beginStartRequest()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {}

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        DispatchQueue.global().async {
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
                if challenge.previousFailureCount == 0 {
                    let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
                    completionHandler(.useCredential, credential)
                } else {
                    completionHandler(.cancelAuthenticationChallenge, nil)
                }
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        self.reloadWebView()
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        pendingAlertCompletion = completionHandler
        let alertController = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { _ in
            self.pendingAlertCompletion?()
            self.pendingAlertCompletion = nil
        }
        alertController.addAction(action)
        if let topVC = AppConfig.currentViewController() {
            topVC.present(alertController, animated: true)
        } else {
            self.pendingAlertCompletion?()
            self.pendingAlertCompletion = nil
        }
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        pendingConfirmCompletion = completionHandler
        let alertController = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            self.pendingConfirmCompletion?(true)
            self.pendingConfirmCompletion = nil
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.pendingConfirmCompletion?(false)
            self.pendingConfirmCompletion = nil
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        if let topVC = AppConfig.currentViewController() {
            topVC.present(alertController, animated: true)
        } else {
            self.pendingConfirmCompletion?(false)
            self.pendingConfirmCompletion = nil
        }
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        pendingPromptCompletion = completionHandler
        let alertController = UIAlertController(title: prompt, message: "", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = defaultText
        }
        let doneAction = UIAlertAction(title: "Done", style: .default) { _ in
            let text = alertController.textFields?.first?.text
            self.pendingPromptCompletion?(text)
            self.pendingPromptCompletion = nil
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.pendingPromptCompletion?(nil)
            self.pendingPromptCompletion = nil
        }
        alertController.addAction(cancelAction)
        alertController.addAction(doneAction)
        if let topVC = AppConfig.currentViewController() {
            topVC.present(alertController, animated: true)
        } else {
            self.pendingPromptCompletion?(nil)
            self.pendingPromptCompletion = nil
        }
    }

    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(.grant)
    }
}

// MARK: - JS Events & Lifecycle

extension AppWebViewController {
    /// Ensure any pending JS dialog completion handlers are executed
    private func finalizePendingJSHandlersIfNeeded() {
        if let alertCompletion = pendingAlertCompletion {
            alertCompletion()
            pendingAlertCompletion = nil
        }
        if let confirmCompletion = pendingConfirmCompletion {
            confirmCompletion(false)
            pendingConfirmCompletion = nil
        }
        if let promptCompletion = pendingPromptCompletion {
            promptCompletion(nil)
            pendingPromptCompletion = nil
        }
    }
    
    /// Notify H5 to refresh coin balance
    func third_jsEvent_refreshCoin() {
        self.webView.evaluateJavaScript("HttpTool.NativeToJs('recharge')") { data, error in
        }
    }
    
    /// Notify H5 page is visible
    @objc private func jsEvent_onPageShow() {
        self.bridge?.callHandler("onPageShow")
        self.webView.evaluateJavaScript("window.onPageShow&&onPageShow();") { data, error in
            print("jsEvent(onPageShow): \(String(describing: data))---\(String(describing: error))")
        }
    }
    
    /// Notify H5 page is hidden
    private func jsEvent_onPageHide() {
        self.bridge?.callHandler("onPageHide")
        self.webView.evaluateJavaScript("window.onPageHide&&onPageHide();") { data, error in
            print("jsEvent(onPageHide): \(String(describing: data))---\(String(describing: error))")
        }
    }
}
