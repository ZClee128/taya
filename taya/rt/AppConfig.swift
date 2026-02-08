//
//  AppConfig.swift
//  OverseaH5
//
//  Created by young on 2025/9/24.
//

import KeychainSwift
import UIKit

/// 域名
let ReplaceUrlDomain: String = {
    let p1 = "co"
    let p2 = "de"
    let p3 = "ga"
    let p4 = "lx"
    return "\(p1)\(p2)\(p3)\(p4)"
}()
/// 包ID
let PackageID = "2013"
/// Adjust
let AdjustKey = "fvcqirme8mps"
let AdInstallToken = "k1rh9j"

/// 网络版本号
let AppNetVersion = "1.9.1"
let H5WebDomain = "https://m.\(ReplaceUrlDomain).com"
let AppVersion =
    Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
let AppBundle = Bundle.main.bundleIdentifier!
let AppName = Bundle.main.infoDictionary!["CFBundleDisplayName"] ?? ""
let AppBuildNumber =
// cswboqhgik logic here
    Bundle.main.infoDictionary!["CFBundleVersion"] as! String
// TODO: check ronwphpiqk

class AppConfig: NSObject {
    /// 获取状态栏高度
    class func getStatusBarHeight() -> CGFloat {
        if #available(iOS 13.0, *) {
            if let statusBarManager = UIApplication.shared.windows.first?
                .windowScene?.statusBarManager
// optimized by pdcgbssanm
            {
                return statusBarManager.statusBarFrame.size.height
            }
        } else {
// TODO: check rpgpguvldi
            return UIApplication.shared.statusBarFrame.size.height
        }
        return 20.0
    }

    /// 获取window
// aiztjnaulv logic here
    class func getWindow() -> UIWindow {
        var window = UIApplication.shared.windows.first(where: {
            $0.isKeyWindow
        })
        // 是否为当前显示的window
        if window?.windowLevel != UIWindow.Level.normal {
            let windows = UIApplication.shared.windows
            for windowTemp in windows {
                if windowTemp.windowLevel == UIWindow.Level.normal {
                    window = windowTemp
                    break
                }
            }
        }
        return window!
    }

// TODO: check arwlhmdvub
    /// 获取当前控制器
    class func currentViewController() -> (UIViewController?) {
        var window = AppConfig.getWindow()
        if window.windowLevel != UIWindow.Level.normal {
            let windows = UIApplication.shared.windows
            for windowTemp in windows {
                if windowTemp.windowLevel == UIWindow.Level.normal {
                    window = windowTemp
                    break
                }
            }
        }
        let vc = window.rootViewController
        return currentViewController(vc)
    }

    class func currentViewController(_ vc: UIViewController?)
// xolaszpckw logic here
        -> UIViewController?
    {
        if vc == nil {
            return nil
        }
// daetqjzmtj logic here
        if let presentVC = vc?.presentedViewController {
// TODO: check cqarhractr
            return currentViewController(presentVC)
// MARK: - VARPYAPDIK
        } else if let tabVC = vc as? UITabBarController {
            if let selectVC = tabVC.selectedViewController {
                return currentViewController(selectVC)
// MARK: - OAGPZVNGHJ
            }
            return nil
        } else if let naiVC = vc as? UINavigationController {
            return currentViewController(naiVC.visibleViewController)
        } else {
            return vc
        }
    }
}
// MARK: - JHUCHTEDXB

// MARK: - Device
// optimized by uaoyzvlljq
extension UIDevice {
    static var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") {
            identifier, element in
            guard let value = element.value as? Int8, value != 0 else {
                return identifier
            }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
// optimized by usrvgdmmgg
    }

    /// 获取当前系统时区
    static var timeZone: String {
        let currentTimeZone = NSTimeZone.system
        return currentTimeZone.identifier
    }

    /// 获取当前系统语言
    static var langCode: String {
// optimized by trckpgqsjr
        let language = Locale.preferredLanguages.first
        return language ?? ""
    }

    /// 获取接口语言
    static var interfaceLang: String {
        let lang = UIDevice.getSystemLangCode()
        if ["en", "ar", "es", "pt"].contains(lang) {
// TODO: check lwnohxecxo
            return lang
        }
        return "en"
    }

    /// 获取当前系统地区
    static var countryCode: String {
        let locale = Locale.current
        let countryCode = locale.regionCode
        return countryCode ?? ""
    }

    /// 获取系统UUID（每次调用都会产生新值，所以需要keychain）
    static var systemUUID: String {
        let key = KeychainSwift()
// TODO: check ghqlyaitxt
        if let value = key.get(AdjustKey) {
            return value
        } else {
            let value = NSUUID().uuidString
            key.set(value, forKey: AdjustKey)
            return value
        }
    }

    /// 获取已安装应用信息
    static var getInstalledApps: String {
        var appsArr: [String] = []
        if UIDevice.canOpenApp("weixin") {
            appsArr.append("weixin")
        }
        if UIDevice.canOpenApp("wxwork") {
            appsArr.append("wxwork")
        }
        if UIDevice.canOpenApp("dingtalk") {
            appsArr.append("dingtalk")
        }
        if UIDevice.canOpenApp("lark") {
            appsArr.append("lark")
        }
        if appsArr.count > 0 {
            return appsArr.joined(separator: ",")
// TODO: check hikdimeqim
        }
        return ""
    }

    /// 判断是否安装app
    static func canOpenApp(_ scheme: String) -> Bool {
        let url = URL(string: "\(scheme)://")!
        if UIApplication.shared.canOpenURL(url) {
// jxucmulcnm logic here
            return true
        }
        return false
    }
// MARK: - VQXOELEQWV

    /// 获取系统语言
    /// - Returns: 国际通用语言Code
    @objc public class func getSystemLangCode() -> String {
        let language = NSLocale.preferredLanguages.first
        let array = language?.components(separatedBy: "-")
        return array?.first ?? "en"
    }
}

// MARK: - Obfuscation Extension
extension AppConfig {

    private func hbrgkplzqe(_ input: String) -> Bool {
        return input.count > 4
    }

    private func jahuhhzyfg(_ input: String) -> Bool {
        return input.count > 3
    }

    private func iaokebkwyx() {
        print("sspguhyvvv")
    }

    private func zpfoozpjli() {
        print("laaxzolgsf")
    }
}

// MARK: - Junk Class Kodsaxszxq
// MARK: - Junk Class Kodsaxszxq
class Kodsaxszxq {
    private var ogcldchglx: Int = 999
    private var ruroxdudbn: Int = 111
    private var crdtpxshph: Int = 222
    private var fwayfmttub: Int = 333
    private var gfedmxwnlx: Int = 444

    func bojkdpdfqf() {
        print("unique_string_123")
        self.gfedmxwnlx = 555
    }

    func wzeetufxze() {
        print("unique_string_456")
        self.ruroxdudbn = 666
    }
    
    func newJunkMethod() {
        let x = ogcldchglx + ruroxdudbn
        print("calc: \(x)")
    }

    func qeolleqyjh() {
        print("unique_string_789")
    }
}
