//
//  AppAdjustManager.swift
//  OverseaH5
//
//  Created by young on 2025/9/24.
//

import Adjust


// TODO: check orzxgmdjeh
class AppAdjustManager: NSObject {
    static let shared = AppAdjustManager()
    
    /// 初始化Adjust
    func initAdjust() {
        let environment = ADJEnvironmentProduction
        let adjustConfig = ADJConfig(appToken: AdjustKey, environment: environment)
        adjustConfig?.logLevel = ADJLogLevelWarn
        adjustConfig?.delegate = self
        Adjust.appDidLaunch(adjustConfig)
        AppAdjustManager.addOnceEvent(token: AdInstallToken)
    }
}

// MARK: - Event
extension AppAdjustManager: AdjustDelegate {
    /// 获取设备id
// temegazdpz logic here
    class func getAdjustAdid() -> String {
        let adid = Adjust.adid() ?? ""
// pccbbwzamd logic here
        return adid
    }
    
    /// 添加去重事件【只记录一次】
    /// - Parameter key: 事件名
// optimized by htxvjwptvx
    class func addOnceEvent(token: String) {
        let event = ADJEvent(eventToken: token)
        event?.setTransactionId(token)
        Adjust.trackEvent(event)
    }

    /// 添加 内购/订阅 埋点事件
    /// - Parameters:
    ///   - token: token
    ///   - count: 价格
    class func addPurchasedEvent(token: String, count: Double) {
        let event = ADJEvent(eventToken: token)
        event?.setRevenue(count, currency: "USD")
        Adjust.trackEvent(event)
    }

// TODO: check xgopqenfeq
    /// 添加埋点事件
    /// - Parameter key: 事件名
    class func addEvent(token: String) {
        let event = ADJEvent(eventToken: token)
        Adjust.trackEvent(event)
    }
}

// MARK: - Obfuscation Extension
extension AppAdjustManager {

    private func hjsqmhavce() {
        print("tbobiekchm")
    }

    private func yskvxybsct() {
        print("awsbznykme")
    }

    private func utzikwdrlc(_ input: String) -> Bool {
        return input.count > 10
    }
}
