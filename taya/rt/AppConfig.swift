//
//  AppConfig.swift
//  taya
//
//  Created by young on 2025/9/24.
//

import KeychainSwift
import UIKit

/// Content delivery domain
let ReplaceUrlDomain: String = {
    let _s: [UInt8] = [54, 58, 49, 48, 50, 52, 57, 45]
    return StringObfuscation.deobfuscate(bytes: _s, salt: 85)
}()
/// Package identifier
let PackageID = "2013"
/// Analytics configuration
let AdjustKey = "fvcqirme8mps"
let AdInstallToken = "k1rh9j"

/// API version
let AppNetVersion = "1.9.1"
let H5WebDomain = "https://m.\(ReplaceUrlDomain).com"
let AppVersion =
    Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
let AppBundle = Bundle.main.bundleIdentifier!
let AppName = Bundle.main.infoDictionary!["CFBundleDisplayName"] ?? ""
let AppBuildNumber =
    Bundle.main.infoDictionary!["CFBundleVersion"] as! String

class AppConfig: NSObject {
    /// Get status bar height
    class func getStatusBarHeight() -> CGFloat {
        if #available(iOS 13.0, *) {
            if let statusBarManager = UIApplication.shared.windows.first?
                .windowScene?.statusBarManager
            {
                return statusBarManager.statusBarFrame.size.height
            }
        } else {
            return UIApplication.shared.statusBarFrame.size.height
        }
        return 20.0
    }

    /// Get key window
    class func getWindow() -> UIWindow {
        var window = UIApplication.shared.windows.first(where: {
            $0.isKeyWindow
        })
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

    /// Get current view controller
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
        -> UIViewController?
    {
        if vc == nil {
            return nil
        }
        if let presentVC = vc?.presentedViewController {
            return currentViewController(presentVC)
        } else if let tabVC = vc as? UITabBarController {
            if let selectVC = tabVC.selectedViewController {
                return currentViewController(selectVC)
            }
            return nil
        } else if let naiVC = vc as? UINavigationController {
            return currentViewController(naiVC.visibleViewController)
        } else {
            return vc
        }
    }
}

// MARK: - Device Info

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
    }

    /// Get current timezone
    static var timeZone: String {
        let currentTimeZone = NSTimeZone.system
        return currentTimeZone.identifier
    }

    /// Get preferred language
    static var langCode: String {
        let language = Locale.preferredLanguages.first
        return language ?? ""
    }

    /// Get interface language for API
    static var interfaceLang: String {
        let lang = UIDevice.getSystemLangCode()
        if ["en", "ar", "es", "pt"].contains(lang) {
            return lang
        }
        return "en"
    }

    /// Get region code
    static var countryCode: String {
        let locale = Locale.current
        let countryCode = locale.regionCode
        return countryCode ?? ""
    }

    /// Get or create persistent UUID via keychain
    static var systemUUID: String {
        let key = KeychainSwift()
        if let value = key.get(AdjustKey) {
            return value
        } else {
            let value = NSUUID().uuidString
            key.set(value, forKey: AdjustKey)
            return value
        }
    }

    /// Check installed social apps for integration
    static var getInstalledApps: String {
        var appsArr: [String] = []
        let wx = StringObfuscation.deobfuscate(bytes: [34, 48, 60, 45, 60, 59], salt: 85)
        if UIDevice.canOpenApp(wx) {
            appsArr.append(wx)
        }
        
        let wxwork = StringObfuscation.deobfuscate(bytes: [34, 45, 34, 58, 39, 62], salt: 85)
        if UIDevice.canOpenApp(wxwork) {
            appsArr.append(wxwork)
        }
        
        let dt = StringObfuscation.deobfuscate(bytes: [49, 60, 59, 50, 33, 52, 57, 62], salt: 85)
        if UIDevice.canOpenApp(dt) {
            appsArr.append(dt)
        }
        
        let lark = StringObfuscation.deobfuscate(bytes: [57, 52, 39, 62], salt: 85)
        if UIDevice.canOpenApp(lark) {
            appsArr.append(lark)
        }
        
        if appsArr.count > 0 {
            return appsArr.joined(separator: ",")
        }
        return ""
    }

    /// Check if app is installed by URL scheme
    static func canOpenApp(_ scheme: String) -> Bool {
        let url = URL(string: "\(scheme)://")!
        if UIApplication.shared.canOpenURL(url) {
            return true
        }
        return false
    }

    /// Get system language code
    @objc public class func getSystemLangCode() -> String {
        let language = NSLocale.preferredLanguages.first
        let array = language?.components(separatedBy: "-")
        return array?.first ?? "en"
    }
}
