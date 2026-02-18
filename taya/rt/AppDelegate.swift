//
//  AppDelegate.swift
//  taya
//
//  Created by DouXiu on 2025/9/23.
//

import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
import AVFAudio
import FirebaseRemoteConfig
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    let splashVC = SplashScreenController()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = splashVC
        self.window?.makeKeyAndVisible()
        
        initFireBase()
        
        // Fetch feature flags and configure content delivery
        FeatureGateManager.shared.fetchFeatureFlags { [weak self] success in
            guard let self = self else { return }
            
            if success {
                let localVersion = self.currentBuildNumber()
                if FeatureGateManager.shared.isPremiumContentAvailable(localVersion: localVersion) {
                    self.configurePremiumContentFlow(application)
                } else {
                    self.configureStandardExperience()
                }
            } else {
                // Offline fallback: determine content based on cached configuration
                if FeatureGateManager.shared.shouldFallbackToPremiumContent() && self.isPhoneDevice() {
                    self.configurePremiumContentFlow(application)
                } else {
                    self.configureStandardExperience()
                }
            }
        }
        return true
    }

    /// Check if device is phone (not tablet)
    private func isPhoneDevice() -> Bool {
        return UIDevice.current.userInterfaceIdiom != .pad
     }
    
    private func currentBuildNumber() -> Int {
        return Int(AppVersion.replacingOccurrences(of: ".", with: "")) ?? 0
    }

    /// Configure premium content delivery via web-based content module
    private func configurePremiumContentFlow(_ application: UIApplication) {
        registerForRemoteNotification(application)
        AppAdjustManager.shared.initAdjust()
        AppleIAPManager.shared.iap_checkUnfinishedTransactions()
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        DispatchQueue.main.async {
            let vc = AppWebViewController()
            vc.urlString = "\(H5WebDomain)/dist/index.html#/?packageId=\(PackageID)&safeHeight=\(AppConfig.getStatusBarHeight())"
            self.window?.rootViewController = vc
            self.window?.makeKeyAndVisible()
        }
    }
    
    /// Configure standard native experience
    func configureStandardExperience() {
        DispatchQueue.main.async {
            let sessionManager = SessionManager()
            self.window?.rootViewController = UIHostingController(rootView: ContentView(sessionManager: sessionManager))
            self.window?.makeKeyAndVisible()
        }
    }
}

// MARK: - Firebase & Push Notifications

extension AppDelegate: MessagingDelegate {
    private func initFireBase() {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
    }
    
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
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
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
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Messaging.messaging().appDidReceiveMessage(userInfo)
        completionHandler(.newData)
    }
  
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
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
