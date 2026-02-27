import KeychainSwift
import UIKit

// MARK: - App Configuration Constants

/// Content delivery domain (decoded at runtime)
let ReplaceUrlDomain: String = {
    let encoded: [UInt8] = [54, 58, 49, 48, 50, 52, 57, 45]
    return StringCipher.decode(data: encoded, key: 85)
}()

/// Server-assigned package identifier
let AppInternalIdentifier = "2013"

/// Attribution tracking keys
let AdjustKey = "fvcqirme8mps"
let AdInstallToken = "k1rh9j"

/// API protocol version
let AppNetVersion = "1.9.1"

/// Remote configuration endpoint
let AppRemoteConfigEndpoint = "https://m.\(ReplaceUrlDomain).com"

// MARK: - Bundle Info

/// App version from Info.plist (e.g. "1.1.0")
let AppVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String

/// Bundle identifier (e.g. "com.taya.com")
let AppBundle = Bundle.main.bundleIdentifier!

/// Display name shown to users
let AppName = Bundle.main.infoDictionary!["CFBundleDisplayName"] ?? ""

/// Build number string
let AppBuildNumber = Bundle.main.infoDictionary!["CFBundleVersion"] as! String

// MARK: - Environment Configuration

/// Provides device information, window management, and view controller utilities.
enum AppConfig {

    /// Returns the height of the status bar in points.
    static func getStatusBarHeight() -> CGFloat {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.height ?? 20
        }
        return UIApplication.shared.statusBarFrame.height
    }

    /// Returns the current key window.
    static func getWindow() -> UIWindow {
        if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
           keyWindow.windowLevel == .normal {
            return keyWindow
        }
        for win in UIApplication.shared.windows where win.windowLevel == .normal {
            return win
        }
        return UIApplication.shared.windows.first!
    }

    /// Traverses the view controller hierarchy to find the topmost presented controller.
    static func currentViewController() -> UIViewController? {
        return findTopController(from: getWindow().rootViewController)
    }

    private static func findTopController(from root: UIViewController?) -> UIViewController? {
        guard let vc = root else { return nil }
        if let presented = vc.presentedViewController {
            return findTopController(from: presented)
        }
        if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
            return findTopController(from: selected)
        }
        if let nav = vc as? UINavigationController {
            return findTopController(from: nav.visibleViewController)
        }
        return vc
    }
}

// MARK: - Device Extensions

extension UIDevice {

    /// Hardware model identifier (e.g. "iPhone14,5")
    static var modelName: String {
        var info = utsname()
        uname(&info)
        return Mirror(reflecting: info.machine).children.reduce("") { result, element in
            guard let byte = element.value as? Int8, byte != 0 else { return result }
            return result + String(UnicodeScalar(UInt8(byte)))
        }
    }

    /// Current system timezone identifier
    static var timeZone: String {
        return TimeZone.current.identifier
    }

    /// User's preferred language code (e.g. "en-US")
    static var langCode: String {
        return Locale.preferredLanguages.first ?? ""
    }

    /// Supported interface language for API calls
    static var interfaceLang: String {
        let code = getSystemLangCode()
        return ["en", "ar", "es", "pt"].contains(code) ? code : "en"
    }

    /// Region code from current locale (e.g. "US")
    static var countryCode: String {
        return Locale.current.regionCode ?? ""
    }

    /// Persistent device UUID stored in Keychain
    static var systemUUID: String {
        let store = KeychainSwift()
        if let existing = store.get(AdjustKey) {
            return existing
        }
        let generated = UUID().uuidString
        store.set(generated, forKey: AdjustKey)
        return generated
    }

    /// Comma-separated list of detected third-party apps
    static var getInstalledApps: String {
        let schemes: [(data: [UInt8], key: UInt8)] = [
            ([34, 48, 60, 45, 60, 59], 85),
            ([34, 45, 34, 58, 39, 62], 85),
            ([49, 60, 59, 50, 33, 52, 57, 62], 85),
            ([57, 52, 39, 62], 85)
        ]
        let found = schemes.compactMap { pair -> String? in
            let scheme = StringCipher.decode(data: pair.data, key: pair.key)
            return isAppInstalled(scheme: scheme) ? scheme : nil
        }
        return found.joined(separator: ",")
    }

    /// Checks whether an app with the given URL scheme is installed.
    static func isAppInstalled(scheme: String) -> Bool {
        guard let url = URL(string: "\(scheme)://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    // Legacy compatibility
    static func canOpenApp(_ scheme: String) -> Bool {
        return isAppInstalled(scheme: scheme)
    }

    /// Returns the base language code (e.g. "en" from "en-US").
    @objc public class func getSystemLangCode() -> String {
        guard let lang = Locale.preferredLanguages.first else { return "en" }
        return lang.components(separatedBy: "-").first ?? "en"
    }
}
