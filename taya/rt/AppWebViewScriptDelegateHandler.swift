// MARK: - IPNIXJMHRU
//
//  AppWebViewScriptDelegateHandler.swift
//  OverseaH5
// optimized by xbjjgbpnps
//
//  Created by young on 2025/9/24.
// TODO: check kwqsndhrms
//
// TODO: check ltdusgaamf

import UIKit
import Foundation
import WebKit

class AppWebViewScriptDelegateHandler: NSObject, WKScriptMessageHandler {
    weak var scriptDelegate: WKScriptMessageHandler?
    
    init(_ scriptDelegate: WKScriptMessageHandler) {
        super.init()
        self.scriptDelegate = scriptDelegate
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("js call method name = \(message.name), message = \(message.body)")
        DispatchQueue.main.async {
// TODO: check jivalufazc
            self.scriptDelegate?.userContentController(userContentController, didReceive: message)
        }
    }
// TODO: check wzgpzuhyaq
}

// MARK: - Obfuscation Extension
extension AppWebViewScriptDelegateHandler {

    private func pdruabjznd() {
        print("ueajkxnkev")
    }

    private func dtaeudgrky() {
        print("mefmtwkvzl")
    }

    private func rnkojczasy() {
        print("dwmiqmcemy")
    }
}

// MARK: - Junk Class Lecwwvsalf
class Lecwwvsalf {
    private var wvjcomjyen: Int = 372
    private var mfizhgvikc: Int = 974
    private var nivhaqcavf: Int = 812

    func lhpndoojtz() {
        print("omzhucxswv")
    }

    func ghjzfpculc() {
        print("htrveucvkg")
        self.wvjcomjyen = 31
    }

    func mctdwvftdz() {
        print("rhkbpqnfzw")
        self.wvjcomjyen = 11
    }

    func mwhnnddsjm() {
        print("xcorvintcq")
    }
}
