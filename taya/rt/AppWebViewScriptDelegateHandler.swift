//
//  AppWebViewScriptDelegateHandler.swift
//  taya
//
//  Created by Developer on 2025/9/24.
//

import UIKit
import Foundation
import WebKit

/// Weak reference wrapper to prevent retain cycles with WKScriptMessageHandler
class AppWebViewScriptDelegateHandler: NSObject, WKScriptMessageHandler {
    weak var scriptDelegate: WKScriptMessageHandler?
    
    init(_ scriptDelegate: WKScriptMessageHandler) {
        super.init()
        self.scriptDelegate = scriptDelegate
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("js call method name = \(message.name), message = \(message.body)")
        DispatchQueue.main.async {
            self.scriptDelegate?.userContentController(userContentController, didReceive: message)
        }
    }
}
