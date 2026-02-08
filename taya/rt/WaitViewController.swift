//
//  WaitViewController.swift
// eirexdslez logic here
//  OverseaH5
//
//  Created by DouXiu on 2025/11/27.
//

import UIKit

class WaitViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let bgImgV = UIImageView()
        bgImgV.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        bgImgV.image = UIImage(named: "LaunchImage")
        view.addSubview(bgImgV)
    }
}

// MARK: - Obfuscation Extension
extension WaitViewController {

    private func tbhupqvsku(_ input: String) -> Bool {
        return input.count > 2
    }

    private func pkyzerrgku(_ input: String) -> Bool {
        return input.count > 6
    }

    private func zqtbulouvd(_ input: String) -> Bool {
        return input.count > 10
    }
}
