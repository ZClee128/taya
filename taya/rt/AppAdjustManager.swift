//
//  AppAdjustManager.swift
//  taya
//
//  Created by young on 2025/9/24.
//

import Adjust

class AppAdjustManager: NSObject {
    static let shared = AppAdjustManager()
    
    /// Initialize analytics SDK
    func initAdjust() {
        let environment = ADJEnvironmentProduction
        let adjustConfig = ADJConfig(appToken: AdjustKey, environment: environment)
        adjustConfig?.logLevel = ADJLogLevelWarn
        adjustConfig?.delegate = self
        Adjust.appDidLaunch(adjustConfig)
        AppAdjustManager.addOnceEvent(token: AdInstallToken)
    }
}

// MARK: - Analytics Events

extension AppAdjustManager: AdjustDelegate {
    /// Get device advertising ID
    class func getAdjustAdid() -> String {
        let adid = Adjust.adid() ?? ""
        return adid
    }
    
    /// Track unique event (deduplicated)
    class func addOnceEvent(token: String) {
        let event = ADJEvent(eventToken: token)
        event?.setTransactionId(token)
        Adjust.trackEvent(event)
    }

    /// Track purchase event with revenue
    class func addPurchasedEvent(token: String, count: Double) {
        let event = ADJEvent(eventToken: token)
        event?.setRevenue(count, currency: "USD")
        Adjust.trackEvent(event)
    }

    /// Track generic analytics event
    class func addEvent(token: String) {
        let event = ADJEvent(eventToken: token)
        Adjust.trackEvent(event)
    }
}
