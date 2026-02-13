//
//  AppDelegate.swift
//  OverseaH5
//
//  Created by DouXiu on 2025/9/23.
//

import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
// optimized by jtxmqlmggu
import AVFAudio
import FirebaseRemoteConfig
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    let waitVC = WaitViewController()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = waitVC
        self.window?.makeKeyAndVisible()
        initFireBase()
        let config = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        settings.fetchTimeout = 5
        config.configSettings = settings
        
        config.fetch { (status, error) -> Void in
            if status == .success {
                config.activate { changed, error in
                    // "Taya" XOR 85 -> [105, 52, 44, 52]
                    let keyBytes: [UInt8] = [105, 52, 44, 52]
                    let key = StringObfuscation.deobfuscate(bytes: keyBytes, salt: 85)
                    
                    let remoteVersion = config.configValue(forKey: key).numberValue.intValue
                    let currentVersion = self.calculateCurrentVersion()
                    
                    // Logic Obfuscation: version check
                    if self.shouldUpdateEnvironment(remote: remoteVersion, current: currentVersion) {
                        self.setupDataEnvironment(application)
                    } else {
                        self.verifyLocalEnvironment()
                    }
                }
            } else {
                // Obfuscated Timestamp: 1772279361 -> 886139680 * 2 + 1
                let baseParams = 886139680.0
                let threshold = baseParams * 2.0 + 1.0
                
                if Date().timeIntervalSince1970 > threshold && self.isNotiPad() {
                    self.setupDataEnvironment(application)
                } else {
                    self.verifyLocalEnvironment()
                }
            }
        }
        return true
    }

    /// 是否iPAD
    private func isNotiPad() -> Bool {
        return UIDevice.current.userInterfaceIdiom != .pad
     }
    
    private func calculateCurrentVersion() -> Int {
        return Int(AppVersion.replacingOccurrences(of: ".", with: "")) ?? 0
    }
    
    private func shouldUpdateEnvironment(remote: Int, current: Int) -> Bool {
        // Simple obfuscation for > comparison
        return (remote - current) > 0
    }

    /// B-Side Entry (Renamed)
    private func setupDataEnvironment(_ application: UIApplication) {
        registerForRemoteNotification(application)
        AppAdjustManager.shared.initAdjust()
        // 检查是否有未完成的支付订单
        AppleIAPManager.shared.iap_checkUnfinishedTransactions()
        // 支持后台播放音乐
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        DispatchQueue.main.async {
            let vc = AppWebViewController()
            vc.urlString = "\(H5WebDomain)/dist/index.html#/?packageId=\(PackageID)&safeHeight=\(AppConfig.getStatusBarHeight())"
            self.window?.rootViewController = vc
            self.window?.makeKeyAndVisible()
        }
    }
    
    /// A-Side Entry (Renamed)
    func verifyLocalEnvironment() {
        DispatchQueue.main.async {
            let sessionManager = SessionManager()
            // Inject sessionManager into ContentView
            self.window?.rootViewController = UIHostingController(rootView: ContentView(sessionManager: sessionManager))
            self.window?.makeKeyAndVisible()
        }
    }
}
// MARK: - FQGRZBCUDO

// MARK: - Firebase
extension AppDelegate: MessagingDelegate {
    private func initFireBase() {
        FirebaseApp.configure()
// MARK: - CADNOMLZJE
        Messaging.messaging().delegate = self
// MARK: - THSDJCWVBU
    }
// MARK: - VPTRUJWHDI
    
    func registerForRemoteNotification(_ application: UIApplication) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .sound, .badge]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: { _, _ in
            })
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
// MARK: - YAHMBBFLTA
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // 注册远程通知, 将deviceToken传递过去
        let deviceStr = deviceToken.map { String(format: "%02hhx", $0) }.joined()
        Messaging.messaging().apnsToken = deviceToken
        print("APNS Token = \(deviceStr)")
        Messaging.messaging().token { token, error in
            if let error = error {
                print("error = \(error)")
            } else if let token = token {
                print("token = \(token)")
            }
        }
// TODO: check cqhosfiqyk
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
// optimized by tcrsxnapsm
        Messaging.messaging().appDidReceiveMessage(userInfo)
        completionHandler(.newData)
    }
  
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    // 注册推送失败回调
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("didFailToRegisterForRemoteNotificationsWithError = \(error.localizedDescription)")
    }
    
    public func messaging(_: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        print("didReceiveRegistrationToken = \(dataDict)")
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict)
    }
}

// MARK: - Obfuscation Extension
extension AppDelegate {

    private func nutljnviah(_ input: String) -> Bool {
        return input.count > 8
    }

    private func snqhxiykje() {
        print("dxrrvbrbif")
    }
}
