import CoreTelephony
import FirebaseMessaging
import HandyJSON
import StoreKit
import UIKit

// MARK: - Bridge Event Identifiers

private enum BridgeEvent {
    static let deviceId          = "getDeviceID"
    static let firebaseId        = "getFirebaseID"
    static let carrierISO        = "getAreaISO"
    static let proxyStatus       = "getProxyStatus"
    static let micPermission     = "getMicStatus"
    static let photoPermission   = "getPhotoStatus"
    static let cameraPermission  = "getCameraStatus"
    static let analytics         = "reportAdjust"
    static let localPush         = "requestLocalPush"
    static let language          = "getLangCode"
    static let timezone          = "getTimeZone"
    static let installedApps     = "getInstalledApps"
    static let uuid              = "getSystemUUID"
    static let country           = "getCountryCode"
    static let rating            = "inAppRating"
    static let purchase          = "apPay"
    static let subscribe         = "subscribe"
    static let openBrowser       = "openSystemBrowser"
    static let closeView         = "closeWebview"
    static let openNewView       = "openNewWebview"
    static let reloadView        = "reloadWebview"
    static let openSettings      = "openSettings"
    static let notifyPermission  = "getNotificationStatus"
    static let schedulePush      = "setScheduledLocalPush"
}

// MARK: - Bridge Message Model

struct JSMessageModel: HandyJSON {
    var typeName = ""
    var token: String?
    var totalCount: Double?
    var showText: String?
    var data: UserInfoModel?
    var goodsId: String?
    var source: Int?
    var type: Int?
    var url: String?
    var fullscreen: Int?
    var transparency: Int?
    var time: [Int]?
    var msg: [String]?
}

struct UserInfoModel: HandyJSON {
    var headPic: String?
    var nickname: String?
    var uid: String?
}

// MARK: - Event Dispatch

extension AppWebViewController {

    /// Routes an incoming H5 bridge message to the appropriate handler.
    func handleH5Message(schemeDic: [String: Any], callBack: @escaping (_ response: [String: Any]) -> Void) {
        guard let msg = JSMessageModel.deserialize(from: schemeDic) else { return }

        switch msg.typeName {

        // Device & System Info
        case BridgeEvent.deviceId:
            callBack(["typeName": msg.typeName, "deviceID": AnalyticsService.deviceId()])

        case BridgeEvent.firebaseId:
            fetchFirebaseToken { token in
                callBack(["typeName": msg.typeName, "fireBaseID": token])
            }

        case BridgeEvent.carrierISO:
            let codes = carrierISOCodes()
            callBack(["typeName": msg.typeName, "areaISO": codes.joined(separator: ",")])

        case BridgeEvent.proxyStatus:
            callBack(["typeName": msg.typeName, "isProxy": detectProxyOrVPN()])

        case BridgeEvent.language:
            callBack(["typeName": msg.typeName, "langCode": UIDevice.langCode])

        case BridgeEvent.timezone:
            callBack(["typeName": msg.typeName, "timeZone": UIDevice.timeZone])

        case BridgeEvent.installedApps:
            callBack(["typeName": msg.typeName, "installedApps": UIDevice.getInstalledApps])

        case BridgeEvent.uuid:
            callBack(["typeName": msg.typeName, "systemUUID": UIDevice.systemUUID])

        case BridgeEvent.country:
            callBack(["typeName": msg.typeName, "countryCode": UIDevice.countryCode])

        // User Actions
        case BridgeEvent.rating:
            callBack(["typeName": msg.typeName])
            requestAppRating()

        case BridgeEvent.purchase:
            if let productId = msg.goodsId, let source = msg.source {
                startPayment(productId: productId, source: source, type: .Pay) { ok in
                    callBack(["typeName": msg.typeName, "status": ok])
                }
            }

        case BridgeEvent.subscribe:
            if let productId = msg.goodsId {
                startPayment(productId: productId, source: -1, type: .Subscribe) { ok in
                    callBack(["typeName": msg.typeName, "status": ok])
                }
            }

        case BridgeEvent.openBrowser:
            callBack(["typeName": msg.typeName])
            if let urlStr = msg.url, let url = URL(string: urlStr) {
                UIApplication.shared.open(url)
            }

        // WebView Control
        case BridgeEvent.closeView:
            callBack(["typeName": msg.typeName])
            closeWeb()

        case BridgeEvent.openNewView:
            callBack(["typeName": msg.typeName])
            if let u = msg.url, let t = msg.transparency, let f = msg.fullscreen {
                AppWebViewController.presentWebView(url: u, transparency: t, fullscreen: f)
            }

        case BridgeEvent.reloadView:
            callBack(["typeName": msg.typeName])
            reloadWebView()

        case BridgeEvent.openSettings:
            callBack(["typeName": msg.typeName])
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }

        // Notifications & Permissions
        case BridgeEvent.schedulePush:
            callBack(["typeName": msg.typeName])
            NotificationScheduler.shared.configureWeeklySchedule(hours: msg.time ?? [], messages: msg.msg ?? [])

        case BridgeEvent.notifyPermission:
            PermissionService.shared.checkNotifications { granted, isFirst in
                callBack(["typeName": msg.typeName, "isAuth": granted, "isFirst": isFirst])
            }

        case BridgeEvent.micPermission:
            PermissionService.shared.checkMicrophone { granted, isFirst in
                callBack(["typeName": msg.typeName, "isAuth": granted, "isFirst": isFirst])
            }

        case BridgeEvent.photoPermission:
            PermissionService.shared.checkPhotoLibrary { granted, isFirst in
                callBack(["typeName": msg.typeName, "isAuth": granted, "isFirst": isFirst])
            }

        case BridgeEvent.cameraPermission:
            PermissionService.shared.checkCamera { granted, isFirst in
                callBack(["typeName": msg.typeName, "isAuth": granted, "isFirst": isFirst])
            }

        // Analytics
        case BridgeEvent.analytics:
            if let token = msg.token {
                if let amount = msg.totalCount {
                    AnalyticsService.trackRevenue(token: token, amount: amount)
                } else {
                    AnalyticsService.trackEvent(token: token)
                }
            }
            callBack(["typeName": msg.typeName])

        case BridgeEvent.localPush:
            callBack(["typeName": msg.typeName])
            deliverLocalNotification(msg)

        default:
            break
        }
    }
}

// MARK: - Utility Implementations

private extension AppWebViewController {

    /// Initiates an IAP payment flow.
    func startPayment(productId: String, source: Int, type: ApplePayType, completion: ((Bool) -> Void)?) {
        ProgressHUD.show()
        let src = source == -1 ? 0 : source
        AppleIAPManager.shared.iap_startPurchase(productId: productId, payType: type, source: src) { [weak self] status, _, _ in
            ProgressHUD.dismiss()
            DispatchQueue.main.async {
                var success = false
                switch status {
                case .verityFail:
                    ProgressHUD.toast("Retry later or contact us via Feedback")
                case .veritySucceed, .renewSucceed:
                    success = true
                    self?.third_jsEvent_refreshCoin()
                default:
                    break
                }
                completion?(success)
            }
        }
    }

    /// Requests the Firebase Cloud Messaging token.
    func fetchFirebaseToken(completion: @escaping (String) -> Void) {
        Messaging.messaging().token { token, _ in
            completion(token ?? "")
        }
    }

    /// Returns carrier ISO country codes.
    func carrierISOCodes() -> [String] {
        let info = CTTelephonyNetworkInfo()
        guard let carriers = info.serviceSubscriberCellularProviders else { return [] }
        return carriers.values.compactMap { $0.isoCountryCode }.filter { !$0.isEmpty }
    }

    /// Checks if VPN or HTTP proxy is active.
    func detectProxyOrVPN() -> Bool {
        return checkHTTPProxy() || checkVPNInterfaces()
    }

    func checkHTTPProxy() -> Bool {
        guard let proxy = CFNetworkCopySystemProxySettings()?.takeUnretainedValue() as? [String: Any] else {
            return false
        }
        let proxyKeys: [(data: [UInt8], key: UInt8)] = [
            ([29, 1, 1, 5, 5, 39, 58, 45, 44], 85),
            ([29, 1, 1, 5, 6, 5, 39, 58, 45, 44], 85),
            ([6, 26, 22, 30, 6, 5, 39, 58, 45, 44], 85)
        ]
        for pk in proxyKeys {
            let key = StringCipher.decode(data: pk.data, key: pk.key)
            if let val = proxy[key] as? String, !val.isEmpty { return true }
        }
        return false
    }

    func checkVPNInterfaces() -> Bool {
        guard let proxy = CFNetworkCopySystemProxySettings()?.takeUnretainedValue() as? [String: Any] else {
            return false
        }
        let scopedKey = StringCipher.decode(data: [10, 10, 6, 22, 26, 5, 16, 17, 10, 10], key: 85)
        guard let scoped = proxy[scopedKey] as? [String: Any] else { return false }

        let vpnPrefixes: [[UInt8]] = [
            [33, 52, 37],
            [33, 32, 59],
            [60, 37, 38, 48, 54],
            [37, 37, 37]
        ]
        let decodedPrefixes = vpnPrefixes.map { StringCipher.decode(data: $0, key: 85) }

        for scopeKey in scoped.keys {
            for prefix in decodedPrefixes {
                if scopeKey.contains(prefix) { return true }
            }
        }
        return false
    }

    /// Requests in-app rating dialog.
    func requestAppRating() {
        if #available(iOS 14.0, *) {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        } else {
            SKStoreReviewController.requestReview()
        }
    }

    /// Delivers an immediate local notification.
    func deliverLocalNotification(_ msg: JSMessageModel) {
        guard UIApplication.shared.applicationState != .active else { return }
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
            guard let info = msg.data else { return }

            let content = UNMutableNotificationContent()
            content.title = info.nickname ?? ""
            content.body = msg.showText ?? ""
            content.sound = .default

            let identifier = info.uid ?? "\(AppName)__LocalPush"
            content.userInfo = ["identifier": identifier]

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }
}
