//
//  AppWebViewHandleEvent.swift
//  taya
//
//  Created by Developer on 2025/9/23.
//

import CoreTelephony
import FirebaseMessaging
import HandyJSON
import StoreKit
import UIKit

// MARK: - H5 Bridge Event Types

private let getDeviceID     = "getDeviceID"
private let getFirebaseID   = "getFirebaseID"
private let getAreaISO      = "getAreaISO"
private let getProxyStatus  = "getProxyStatus"
private let getMicStatus    = "getMicStatus"
private let getPhotoStatus  = "getPhotoStatus"
private let getCameraStatus = "getCameraStatus"
private let reportAdjust    = "reportAdjust"
private let requestLocalPush = "requestLocalPush"
private let getLangCode      = "getLangCode"
private let getTimeZone      = "getTimeZone"
private let getInstalledApps = "getInstalledApps"
private let getSystemUUID    = "getSystemUUID"
private let getCountryCode   = "getCountryCode"
private let inAppRating      = "inAppRating"
private let apPay            = "apPay"
private let subscribe        = "subscribe"
private let openSystemBrowser = "openSystemBrowser"
private let closeWebview     = "closeWebview"
private let openNewWebview   = "openNewWebview"
private let reloadWebview    = "reloadWebview"
private let openSettings = "openSettings"
private let getNotificationStatus = "getNotificationStatus"
private let setScheduledLocalPush = "setScheduledLocalPush"

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

// MARK: - Event Handling

extension AppWebViewController {
    func handleH5Message(schemeDic: [String: Any], callBack: @escaping (_ backDic: [String: Any]) -> Void) {
        if let model = JSMessageModel.deserialize(from: schemeDic) {
            switch model.typeName {
            case getDeviceID:
                let adidStr = AppAdjustManager.getAdjustAdid()
                callBack(["typeName": model.typeName, "deviceID": adidStr])

            case getFirebaseID:
                AppWebViewController.getFireBaseToken { str in
                    callBack(["typeName": model.typeName, "fireBaseID": str])
                }
                
            case getAreaISO:
                let arr = AppWebViewController.getCountryISOCode()
                callBack(["typeName": model.typeName, "areaISO": arr.joined(separator: ",")])
                
            case getProxyStatus:
                let status = AppWebViewController.getUsedProxyStatus()
                callBack(["typeName": model.typeName, "isProxy": status])
              
            case getLangCode:
                let langCode = UIDevice.langCode
                callBack(["typeName": model.typeName, "langCode": langCode])
                
            case getTimeZone:
                let timeZone = UIDevice.timeZone
                callBack(["typeName": model.typeName, "timeZone": timeZone])
                
            case getInstalledApps:
                let apps = UIDevice.getInstalledApps
                callBack(["typeName": model.typeName, "installedApps": apps])
                
            case getSystemUUID:
                let uuid = UIDevice.systemUUID
                callBack(["typeName": model.typeName, "systemUUID": uuid])
                
            case getCountryCode:
                let countryCode = UIDevice.countryCode
                callBack(["typeName": model.typeName, "countryCode": countryCode])
                
            case inAppRating:
                callBack(["typeName": model.typeName])
                AppWebViewController.requestInAppRating()

            case apPay:
                if let goodsId = model.goodsId, let source = model.source {
                    self.applePay(productId: goodsId, source: source, payType: .Pay) { success in
                        callBack(["typeName": model.typeName, "status": success])
                    }
                }

            case subscribe:
                if let goodsId = model.goodsId {
                    self.applePay(productId: goodsId, payType: .Subscribe) { success in
                        callBack(["typeName": model.typeName, "status": success])
                    }
                }
                
            case openSystemBrowser:
                callBack(["typeName": model.typeName])
                if let urlStr = model.url, let openURL = URL(string: urlStr) {
                    UIApplication.shared.open(openURL, options: [:], completionHandler: nil)
                }
                
            case closeWebview:
                callBack(["typeName": model.typeName])
                self.closeWeb()
                
            case openNewWebview:
                callBack(["typeName": model.typeName])
                if let urlStr = model.url,
                    let transparency = model.transparency,
                    let fullscreen = model.fullscreen {
                    AppWebViewController.openNewWebView(urlStr, transparency, fullscreen)
                }
                
            case reloadWebview:
                callBack(["typeName": model.typeName])
                self.reloadWebView()
            
            case openSettings:
                callBack(["typeName": model.typeName])
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: { _ in })
                }
                
            case setScheduledLocalPush:
                callBack(["typeName": model.typeName])
                LocalPushScheduler.shared.schedule(times: model.time ?? [], contents: model.msg ?? [])
                
            case getNotificationStatus:
                AppPermissionTool.shared.requestNotificationPermission { auth, isFirst in
                    callBack(["typeName": model.typeName, "isAuth": auth, "isFirst": isFirst])
                }
            
            case getMicStatus:
                AppPermissionTool.shared.requestMicPermission { auth, isFirst in
                    callBack(["typeName": model.typeName, "isAuth": auth, "isFirst": isFirst])
                }
                
            case getPhotoStatus:
                AppPermissionTool.shared.requestPhotoPermission { auth, isFirst in
                    callBack(["typeName": model.typeName, "isAuth": auth, "isFirst": isFirst])
                }
                
            case getCameraStatus:
                AppPermissionTool.shared.requestCameraPermission { auth, isFirst in
                    callBack(["typeName": model.typeName, "isAuth": auth, "isFirst": isFirst])
                }
                
            case reportAdjust:
                if let token = model.token {
                    if let count = model.totalCount {
                        AppAdjustManager.addPurchasedEvent(token: token, count: count)
                    } else {
                        AppAdjustManager.addEvent(token: token)
                    }
                }
                callBack(["typeName": model.typeName])

            case requestLocalPush:
                callBack(["typeName": model.typeName])
                AppWebViewController.pushLocalNotification(model)

            default: break
            }
        }
    }
}

// MARK: - Utility Methods

extension AppWebViewController {
    /// Open a new webview controller
    class func openNewWebView(_ urlStr: String, _ transparency: Int = 0, _ fullscreen: Int = 1) {
        let vc = AppWebViewController()
        vc.urlString = urlStr
        vc.clearBgColor = (transparency == 1)
        vc.fullscreen = (fullscreen == 1)
        vc.modalPresentationStyle = .fullScreen
        AppConfig.currentViewController()?.present(vc, animated: true)
    }
    
    /// Schedule local notification
    class func pushLocalNotification(_ model: JSMessageModel) {
        guard UIApplication.shared.applicationState != .active else { return }
        UNUserNotificationCenter.current().getNotificationSettings { setting in
            switch setting.authorizationStatus {
            case .notDetermined, .denied, .ephemeral:
                print("Local push - user not authorized: \(setting.authorizationStatus)")
                
            case .provisional, .authorized:
                if let dataModel = model.data {
                    let content = UNMutableNotificationContent()
                    content.title = dataModel.nickname ?? ""
                    content.body = model.showText ?? ""
                    let identifier = dataModel.uid ?? "\(AppName)__LocalPush"
                    content.userInfo = ["identifier": identifier]
                    content.sound = UNNotificationSound.default

                    let time = Date(timeIntervalSinceNow: 1).timeIntervalSinceNow
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: time, repeats: false)
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    UNUserNotificationCenter.current().add(request) { _ in
                    }
                }
                
            @unknown default:
                print("Local push - unknown authorization: \(setting.authorizationStatus)")
                break
            }
        }
    }
    
    /// Get Firebase Cloud Messaging token
    class func getFireBaseToken(tokenBlock: @escaping (_ str: String) -> Void) {
        Messaging.messaging().token { token, _ in
            if let token = token {
                tokenBlock(token)
            } else {
                tokenBlock("")
            }
        }
    }

    /// Get carrier ISO country codes
    class func getCountryISOCode() -> [String] {
        var tempArr: [String] = []
        let info = CTTelephonyNetworkInfo()
        if let carrierDic = info.serviceSubscriberCellularProviders {
            if !carrierDic.isEmpty {
                for carrier in carrierDic.values {
                    if let iso = carrier.isoCountryCode, !iso.isEmpty {
                        tempArr.append(iso)
                    }
                }
            }
        }
        return tempArr
    }

    /// Check if proxy or VPN is active
    class func getUsedProxyStatus() -> Bool {
        if AppWebViewController.isUsedProxy() || AppWebViewController.isUsedVPN() {
            return true
        }
        return false
    }
    
    /// Detect HTTP/HTTPS/SOCKS proxy
    class func isUsedProxy() -> Bool {
        guard let proxy = CFNetworkCopySystemProxySettings()?.takeUnretainedValue() else { return false }
        guard let dict = proxy as? [String: Any] else { return false }

        let kHTTP = StringObfuscation.deobfuscate(bytes: [29, 1, 1, 5, 5, 39, 58, 45, 44], salt: 85)
        if let httpProxy = dict[kHTTP] as? String, !httpProxy.isEmpty { return true }
        
        let kHTTPS = StringObfuscation.deobfuscate(bytes: [29, 1, 1, 5, 6, 5, 39, 58, 45, 44], salt: 85)
        if let httpsProxy = dict[kHTTPS] as? String, !httpsProxy.isEmpty { return true }
        
        let kSOCKS = StringObfuscation.deobfuscate(bytes: [6, 26, 22, 30, 6, 5, 39, 58, 45, 44], salt: 85)
        if let socksProxy = dict[kSOCKS] as? String, !socksProxy.isEmpty { return true }

        return false
    }
    
    /// Detect VPN tunnel interfaces
   class func isUsedVPN() -> Bool {
       guard let proxy = CFNetworkCopySystemProxySettings()?.takeUnretainedValue() else { return false }
       guard let dict = proxy as? [String: Any] else { return false }
       
       let kScoped = StringObfuscation.deobfuscate(bytes: [10, 10, 6, 22, 26, 5, 16, 17, 10, 10], salt: 85)
       guard let scopedDic = dict[kScoped] as? [String: Any] else { return false }
       
       let keys = [
           StringObfuscation.deobfuscate(bytes: [33, 52, 37], salt: 85),
           StringObfuscation.deobfuscate(bytes: [33, 32, 59], salt: 85),
           StringObfuscation.deobfuscate(bytes: [60, 37, 38, 48, 54], salt: 85),
           StringObfuscation.deobfuscate(bytes: [37, 37, 37], salt: 85)
       ]
       
       for keyStr in scopedDic.keys {
           for k in keys {
               if keyStr.contains(k) {
                   return true
               }
           }
       }
       return false
   }
    
    /// Request in-app rating
    class func requestInAppRating() {
        if #available(iOS 14.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        } else {
            SKStoreReviewController.requestReview()
        }
    }
    
    // MARK: - In-App Purchase
    
    /// Start Apple Pay / subscription purchase flow
    func applePay(productId: String, source: Int = -1, payType: ApplePayType, completion: ((Bool) -> Void)? = nil) {
        ProgressHUD.show()
        var index = 0
        if source != -1 {
            index = source
        }
        AppleIAPManager.shared.iap_startPurchase(productId: productId, payType: payType, source: index) { status, _, _ in
            ProgressHUD.dismiss()
            DispatchQueue.main.async {
                var isSuccess = false
                switch status {
                case .verityFail:
                    ProgressHUD.toast( "Retry After or Go to \"Feedback\" to contact us")
                    
                case .veritySucceed, .renewSucceed:
                    isSuccess = true
                    self.third_jsEvent_refreshCoin()
                    
                default:
                    print("Apple payment failed: \(status.rawValue)")
                    break
                }
                completion?(isSuccess)
            }
        }
    }
}
