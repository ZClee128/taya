import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
import AVFAudio
import FirebaseRemoteConfig
import SwiftUI

@main
final class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    private let launchVC = LaunchViewController()

    // MARK: - App Launch

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = launchVC
        window?.makeKeyAndVisible()

        configureFirebase()

        // Determine content delivery path via remote config
        RemoteConfigService.shared.refresh { [weak self] success in
            guard let self = self else { return }
            if success {
                let build = self.numericBuildVersion()
                if RemoteConfigService.shared.shouldActivateWebContent(localBuild: build) {
                    self.launchWebExperience(application)
                } else {
                    self.launchNativeExperience()
                }
            } else {
                // Offline fallback
                if RemoteConfigService.shared.offlineFallbackActive() && self.isPhone() {
                    self.launchWebExperience(application)
                } else {
                    self.launchNativeExperience()
                }
            }
        }
        return true
    }

    // MARK: - Content Paths

    /// Activates web-based content delivery via full-screen WebView.
    private func launchWebExperience(_ application: UIApplication) {
        setupPushNotifications(application)
        AnalyticsService.shared.start()
        AppleIAPManager.shared.iap_checkUnfinishedTransactions()

        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)

        DispatchQueue.main.async {
            let webVC = AppWebViewController()
            let safeHeight = AppConfig.getStatusBarHeight()
            webVC.urlString = "\(AppRemoteConfigEndpoint)/dist/index.html#/?packageId=\(AppInternalIdentifier)&safeHeight=\(safeHeight)"
            self.window?.rootViewController = webVC
            self.window?.makeKeyAndVisible()
        }
    }

    /// Activates the native SwiftUI lifestyle experience.
    func launchNativeExperience() {
        DispatchQueue.main.async {
            try? AVAudioSession.sharedInstance().setCategory(.playback)
            try? AVAudioSession.sharedInstance().setActive(true)
            let session = SessionManager()
            let rootView = ContentView(sessionManager: session)
            self.window?.rootViewController = UIHostingController(rootView: rootView)
            self.window?.makeKeyAndVisible()
        }
    }

    // Legacy compatibility
    func configureStandardExperience() {
        launchNativeExperience()
    }

    // MARK: - Helpers

    private func numericBuildVersion() -> Int {
        return Int(AppVersion.replacingOccurrences(of: ".", with: "")) ?? 0
    }

    private func isPhone() -> Bool {
        return UIDevice.current.userInterfaceIdiom != .pad
    }
}

// MARK: - Firebase & Push Notifications

extension AppDelegate: MessagingDelegate {

    private func configureFirebase() {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
    }

    private func setupPushNotifications(_ application: UIApplication) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        Messaging.messaging().token { token, error in
            if let token = token {
                print("[Push] FCM token: \(token)")
            }
        }
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Messaging.messaging().appDidReceiveMessage(userInfo)
        completionHandler(.newData)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[Push] Registration failed: \(error.localizedDescription)")
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: ["token": fcmToken ?? ""])
    }
}
