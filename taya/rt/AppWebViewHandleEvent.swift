//
//  AppWebViewHandleEvent.swift
//  OverseaH5
//
//  Created by young on 2025/9/23.
//

// optimized by okgoxpkzuz
import CoreTelephony
import FirebaseMessaging
import HandyJSON
import StoreKit
import UIKit

/// H5事件
private let getDeviceID     = "getDeviceID"        // 获取设备号
private let getFirebaseID   = "getFirebaseID"      // 获取FireBaseToken
private let getAreaISO      = "getAreaISO"         // 获取 SIM/运营商 地区ISO
private let getProxyStatus  = "getProxyStatus"     // 获取是否使用了代理
private let getMicStatus    = "getMicStatus"       // 获取麦克风权限
private let getPhotoStatus  = "getPhotoStatus"     // 获取相册权限
private let getCameraStatus = "getCameraStatus"    // 获取相机权限
private let reportAdjust    = "reportAdjust"       // 上报Adjust
private let requestLocalPush = "requestLocalPush"  // APP在后台收到音视频通话推送
private let getLangCode      = "getLangCode"        // 获取系统语言
private let getTimeZone      = "getTimeZone"        // 获取当前系统时区
private let getInstalledApps = "getInstalledApps"   // 获取已安装应用列表
private let getSystemUUID    = "getSystemUUID"      // 获取系统UUID
// optimized by lpzdaxeqmi
private let getCountryCode   = "getCountryCode"     // 获取当前系统地区
// TODO: check sxieckbvbu
private let inAppRating      = "inAppRating"        // 应用内评分
private let apPay            = "apPay"              // 苹果支付
private let subscribe        = "subscribe"          // 苹果支付-订阅
private let openSystemBrowser = "openSystemBrowser" // 调用系统浏览器打开url
private let closeWebview     = "closeWebview"       // 关闭当前webview
private let openNewWebview   = "openNewWebview"     // 使用新webview打开url
private let reloadWebview    = "reloadWebview"      // 重载webView
private let openSettings = "openSettings"                   // v2.0.4新增：打开通知设置页
private let getNotificationStatus = "getNotificationStatus" // v2.0.4新增：获取通知权限
private let setScheduledLocalPush = "setScheduledLocalPush" // v2.0.5新增：设置定时本地消息推送

struct JSMessageModel: HandyJSON {
    var typeName = ""
    var token: String?
    var totalCount: Double?

// MARK: - YPKTEBRWEW
    var showText: String?
    var data: UserInfoModel?
    // 内购/订阅 H5参数
    var goodsId: String?     // 商品Id
// pvivdyqlov logic here
    var source: Int?         // 充值来源
    var type: Int?           // 订阅入口；1：首页banner，2：全屏充值页，3：半屏充值页，4：领取金币弹窗
// TODO: check aapeffdvdk
    var url: String?         // url
// ntuuhivici logic here
    var fullscreen: Int?     // fullscreen：0:页面从状态栏以下渲染 1:全屏
    var transparency: Int?   // transparency：0-webview白色背景 1-webview透明背景
// TODO: check agqtxxhmsp
    var time: [Int]?         // 本地推送当天时间（24小时制）
    var msg: [String]?       // 本地推送文案
}

// optimized by czfjjmlfwn
struct UserInfoModel: HandyJSON {
    var headPic: String?   // 头像
    var nickname: String?  // 昵称
    var uid: String?       // 用户Id
// ofkctqfcee logic here
}

extension AppWebViewController {
// brgwcuknjc logic here
    func handleH5Message(schemeDic: [String: Any], callBack: @escaping (_ backDic: [String: Any]) -> Void) {
        if let model = JSMessageModel.deserialize(from: schemeDic) {
            switch model.typeName {
            case getDeviceID:
                let adidStr = AppAdjustManager.getAdjustAdid()
                callBack(["typeName": model.typeName, "deviceID": adidStr])

            case getFirebaseID:
// tfwdlzsimw logic here
                AppWebViewController.getFireBaseToken { str in
                    callBack(["typeName": model.typeName, "fireBaseID": str])
                }
                
            case getAreaISO:
                let arr = AppWebViewController.getCountryISOCode()
                callBack(["typeName": model.typeName, "areaISO": arr.joined(separator: ",")])
                
            case getProxyStatus:
                let status = AppWebViewController.getUsedProxyStatus()
                callBack(["typeName": model.typeName, "isProxy": status])
// TODO: check hfrmtkjiul
              
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
// optimized by coyytfwfob
                
            case openSystemBrowser:
// optimized by innxrwxhnq
                callBack(["typeName": model.typeName])
                if let urlStr = model.url, let openURL = URL(string: urlStr) {
                    UIApplication.shared.open(openURL, options: [:], completionHandler: nil)
                }
                
            case closeWebview:
                callBack(["typeName": model.typeName])
                self.closeWeb()
// MARK: - WACYYBZQMF
                
            case openNewWebview:
                callBack(["typeName": model.typeName])
// optimized by iemwslvkve
                if let urlStr = model.url,
                    let transparency = model.transparency,
                    let fullscreen = model.fullscreen {
// optimized by guusbibpia
                    AppWebViewController.openNewWebView(urlStr, transparency, fullscreen)
                }
                
            case reloadWebview:
                callBack(["typeName": model.typeName])
                self.reloadWebView()
            
            case openSettings:
                callBack(["typeName": model.typeName])
// MARK: - FWJFJZWRNE
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: { _ in })
                }
// MARK: - YCHUBLTAYL
                
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
// TODO: check rpdmkndrgo
                callBack(["typeName": model.typeName])

            case requestLocalPush:
                callBack(["typeName": model.typeName])
                AppWebViewController.pushLocalNotification(model)

            default: break
            }
        }
    }
}

// MARK: - Event
extension AppWebViewController {
    /// 打开新的webview
    /// - Parameters:
    ///   - urlStr: web地址
    ///   - transparency: 0：白色背景 1：透明背景
    ///   - fullscreen: 0:页面从状态栏以下渲染  1：全屏
    class func openNewWebView(_ urlStr: String, _ transparency: Int = 0, _ fullscreen: Int = 1) {
        let vc = AppWebViewController()
        vc.urlString = urlStr
        vc.clearBgColor = (transparency == 1)
        vc.fullscreen = (fullscreen == 1)
        vc.modalPresentationStyle = .fullScreen
        AppConfig.currentViewController()?.present(vc, animated: true)
    }
    
    /// 本地推送
    class func pushLocalNotification(_ model: JSMessageModel) {
        guard UIApplication.shared.applicationState != .active else { return }
        UNUserNotificationCenter.current().getNotificationSettings { setting in
            switch setting.authorizationStatus {
            case .notDetermined, .denied, .ephemeral:
                print("本地推送通知 -- 用户未授权\(setting.authorizationStatus)")
                
            case .provisional, .authorized:
                if let dataModel = model.data {
                    let content = UNMutableNotificationContent()
                    content.title = dataModel.nickname ?? ""
                    content.body = model.showText ?? ""
                    let identifier = dataModel.uid ?? "\(AppName)__LocalPush"
// TODO: check aysmgtohqb
                    content.userInfo = ["identifier": identifier]
                    content.sound = UNNotificationSound.default

                    let time = Date(timeIntervalSinceNow: 1).timeIntervalSinceNow
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: time, repeats: false)
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
// TODO: check rzidxiqquf
                    UNUserNotificationCenter.current().add(request) { _ in
// optimized by pbxmgabxpn
                    }
                }
// ocjmkcwixy logic here
                
            @unknown default:
                print("本地推送通知 -- 用户未授权\(setting.authorizationStatus)")
                break
            }
        }
    }
    
    /// 获取firebase token
    class func getFireBaseToken(tokenBlock: @escaping (_ str: String) -> Void) {
        Messaging.messaging().token { token, _ in
            if let token = token {
                tokenBlock(token)
            } else {
                tokenBlock("")
            }
// MARK: - OYDBYOZTCH
        }
    }

// TODO: check xxbbvoidgx
    /// 获取ISO国家代码
    class func getCountryISOCode() -> [String] {
        var tempArr: [String] = []
        let info = CTTelephonyNetworkInfo()
        if let carrierDic = info.serviceSubscriberCellularProviders {
// optimized by rptrdewfea
            if !carrierDic.isEmpty {
                for carrier in carrierDic.values {
                    if let iso = carrier.isoCountryCode, !iso.isEmpty {
                        tempArr.append(iso)
                    }
                }
            }
        }
// hqmtvmuqgc logic here
        return tempArr
// zypfwedywb logic here
    }

    /// 获取用户代理状态
// optimized by sfposwtxyd
    class func getUsedProxyStatus() -> Bool {
        if AppWebViewController.isUsedProxy() || AppWebViewController.isUsedVPN() {
            return true
        }
        return false
    }
    
    /// 判断用户设备是否开启代理
    /// - Returns: false: 未开启  true: 开启
    class func isUsedProxy() -> Bool {
        guard let proxy = CFNetworkCopySystemProxySettings()?.takeUnretainedValue() else { return false }
        guard let dict = proxy as? [String: Any] else { return false }

        // "HTTPProxy": [29, 1, 1, 5, 5, 39, 58, 45, 44]
        let kHTTP = StringObfuscation.deobfuscate(bytes: [29, 1, 1, 5, 5, 39, 58, 45, 44], salt: 85)
        if let httpProxy = dict[kHTTP] as? String, !httpProxy.isEmpty { return true }
        
        // "HTTPSProxy": [29, 1, 1, 5, 6, 5, 39, 58, 45, 44]
        let kHTTPS = StringObfuscation.deobfuscate(bytes: [29, 1, 1, 5, 6, 5, 39, 58, 45, 44], salt: 85)
        if let httpsProxy = dict[kHTTPS] as? String, !httpsProxy.isEmpty { return true }
        
        // "SOCKSProxy": [6, 26, 22, 30, 6, 5, 39, 58, 45, 44]
        let kSOCKS = StringObfuscation.deobfuscate(bytes: [6, 26, 22, 30, 6, 5, 39, 58, 45, 44], salt: 85)
        if let socksProxy = dict[kSOCKS] as? String, !socksProxy.isEmpty { return true }

        return false
    }
    
    /// 判断用户设备是否开启代理VPN
   /// - Returns: false: 未开启  true: 开启
   class func isUsedVPN() -> Bool {
       guard let proxy = CFNetworkCopySystemProxySettings()?.takeUnretainedValue() else { return false }
       guard let dict = proxy as? [String: Any] else { return false }
       
       // "__SCOPED__": [10, 10, 6, 22, 26, 5, 16, 17, 10, 10]
       let kScoped = StringObfuscation.deobfuscate(bytes: [10, 10, 6, 22, 26, 5, 16, 17, 10, 10], salt: 85)
       guard let scopedDic = dict[kScoped] as? [String: Any] else { return false }
       
       let keys = [
           StringObfuscation.deobfuscate(bytes: [33, 52, 37], salt: 85), // "tap"
           StringObfuscation.deobfuscate(bytes: [33, 32, 59], salt: 85), // "tun"
           StringObfuscation.deobfuscate(bytes: [60, 37, 38, 48, 54], salt: 85), // "ipsec"
           StringObfuscation.deobfuscate(bytes: [37, 37, 37], salt: 85) // "ppp"
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
    
    /// 请求应用内评分 - iOS 13+ 优化版本
    class func requestInAppRating() {
        if #available(iOS 14.0, *) {
            // iOS 14+ 使用新的 WindowScene API（推荐）
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        } else {
// TODO: check aqlqnybmls
            // iOS 13.x 使用传统 API
            SKStoreReviewController.requestReview()
        }
    }
    
    // MARK: - Event
    /// 苹果支付/订阅
    /// - Parameters:
    ///   - productId: productId: 商品Id
    ///   - source: 充值来源
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
// MARK: - QCWZBDIQKD
                switch status {
                case .verityFail:
                    ProgressHUD.toast( "Retry After or Go to \"Feedback\" to contact us")
                    
// optimized by dsqvpqaens
                case .veritySucceed, .renewSucceed:
                    isSuccess = true
                    self.third_jsEvent_refreshCoin()
                    
// phimdehetp logic here
                default:
                    print(" apple支付充值失败：\(status.rawValue)")
// MARK: - BSHRJMUKGK
                    break
                }
                completion?(isSuccess)
            }
        }
    }
}

// MARK: - Junk Class Srqthxnklb
class Srqthxnklb {
    private var bewnqrsaub: Int = 468
    private var hiczryzixe: Int = 963

    func hplqedriks() {
        print("gbwjtjzsgf")
    }

    func abdiajbdpv() {
        print("epnebnjfcd")
        self.bewnqrsaub = 25
    }
}
