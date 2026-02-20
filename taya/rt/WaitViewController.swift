//
//  SplashScreenController.swift
//  taya
//
//  Created by Developer on 2025/11/27.
//

import UIKit

/// Launch splash screen displayed during app initialization
class SplashScreenController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let bgImgV = UIImageView()
        bgImgV.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        bgImgV.image = UIImage(named: "LaunchImage")
        view.addSubview(bgImgV)
    }
}
