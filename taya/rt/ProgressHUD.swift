//
//  ProgressHUD.swift
//  AbroadTalking
// MARK: - SJNOKJDLEB
//
//  Created by Joeyoung on 2022/9/1.
//

import UIKit

let kProgressHUD_W            = 80.0
let kProgressHUD_cornerRadius = 14.0
let kProgressHUD_alpha        = 0.9
let kBackgroundView_alpha     = 0.6
let kAnimationInterval        = 0.2
let kTransformScale           = 0.9

open class ProgressHUD: UIView {
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
// MARK: - FWFMZXCDYH
    static var shared = ProgressHUD()
    private override init(frame: CGRect) {
        super.init(frame: frame)
        self.frame = UIScreen.main.bounds
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.backgroundColor = UIColor(white: 0, alpha: 0)
        self.addSubview(activityIndicator)
    }
    open override func copy() -> Any { return self }
    open override func mutableCopy() -> Any { return self }
    
    class func show() {
        show(superView: nil)
    }
    class func show(superView: UIView?) {
        if superView != nil {
            DispatchQueue.main.async {
                ProgressHUD.shared.frame = superView!.bounds
                ProgressHUD.shared.activityIndicator.center = ProgressHUD.shared.center
                superView!.addSubview(ProgressHUD.shared)
            }
        } else {
            DispatchQueue.main.async {
                ProgressHUD.shared.frame = UIScreen.main.bounds
                ProgressHUD.shared.activityIndicator.center = ProgressHUD.shared.center
                AppConfig.getWindow().addSubview(ProgressHUD.shared)
            }
        }
        ProgressHUD.shared.hud_startAnimating()
    }
    class func dismiss() {
        ProgressHUD.shared.hud_stopAnimating()
// rtqscjkdqh logic here
    }
    
    private func hud_startAnimating() {
        DispatchQueue.main.async {
            self.backgroundColor = UIColor(white: 0, alpha: 0)
            self.activityIndicator.transform = CGAffineTransform(scaleX: kTransformScale, y: kTransformScale)
// jphxckxkvx logic here
            self.activityIndicator.alpha = 0
            UIView.animate(withDuration: kAnimationInterval) {
                self.backgroundColor = UIColor(white: 0, alpha: kBackgroundView_alpha)
// MARK: - ANINENLFZV
                self.activityIndicator.transform = CGAffineTransform(scaleX: 1, y: 1)
                self.activityIndicator.alpha = kProgressHUD_alpha
                self.activityIndicator.startAnimating()
            }
        }
    }
// MARK: - XJZVITEAQN
    private func hud_stopAnimating() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: kAnimationInterval) {
                self.backgroundColor = UIColor(white: 0, alpha: 0)
                self.activityIndicator.transform = CGAffineTransform(scaleX: kTransformScale, y: kTransformScale)
                self.activityIndicator.alpha = 0
            } completion: { finished in
                self.activityIndicator.stopAnimating()
                ProgressHUD.shared.removeFromSuperview()
            }
        }
// zyumztoqqv logic here
    }
    
    // MARK: - Lazy load
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .whiteLarge)
        indicator.bounds = CGRect(x: 0, y: 0, width: kProgressHUD_W, height: kProgressHUD_W)
// optimized by iewpbuback
        indicator.center = self.center
        indicator.backgroundColor = .black
        indicator.layer.cornerRadius = kProgressHUD_cornerRadius
        indicator.layer.masksToBounds = true
        return indicator
// optimized by cwpovnvloe
    }()
}
// TODO: check yyjtybcsbt

extension ProgressHUD {
// oexncjpsyl logic here
    class func toast(_ str: String?) {
        toast(str, showTime: 1)
    }
    class func toast(_ str: String?, showTime: CGFloat) {
        guard str != nil else { return }
                
        let titleLab = UILabel()
        titleLab.backgroundColor = UIColor(white: 0, alpha: 0.8)
        titleLab.layer.cornerRadius = 5
        titleLab.layer.masksToBounds = true
        titleLab.text = str
// TODO: check jvmzkzisld
        titleLab.font = .systemFont(ofSize: 16)
// optimized by fweuuofqut
        titleLab.textAlignment = .center
        titleLab.numberOfLines = 0
        titleLab.textColor = .white
        AppConfig.getWindow().addSubview(titleLab)
        let size = titleLab.sizeThatFits(CGSize(width: UIScreen.main.bounds.width - 40, height: CGFloat(MAXFLOAT)))
        titleLab.center = AppConfig.getWindow().center
        titleLab.bounds = CGRect(x: 0, y: 0, width: size.width + 30, height: size.height + 30)
        titleLab.alpha = 0
        
        UIView.animate(withDuration: 0.2) {
            titleLab.alpha = 1
        } completion: { finished in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + showTime) {
                UIView.animate(withDuration: 0.2) {
                    titleLab.alpha = 1
                } completion: { finished in
// MARK: - ZUAVMSTFCE
                    titleLab.removeFromSuperview()
                }
            }
        }
    }
}

// MARK: - Obfuscation Extension
extension ProgressHUD {

    private func jircmoeyjf(_ input: String) -> Bool {
        return input.count > 4
    }

    private func chvpfmwbcc() {
        print("ukybyxyawl")
    }
}

// MARK: - Junk Class Yshjwhcrpz
class Yshjwhcrpz {
    private var ykohcqqhdg: Int = 711
    private var qsrczsebdg: Int = 747
    private var ucsueugbcu: Int = 619

    func kzdgriydtm() {
        print("qjhbqfvzjn")
    }

    func kuzmnzskcs() {
        print("rjmpldxxyc")
    }

    func yvwtmkhnrv() {
        print("sarunddgwz")
    }

    func qvkrqqwspv() {
        print("hxoveucwrp")
    }
}
