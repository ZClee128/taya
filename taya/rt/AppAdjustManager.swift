import Adjust

/// Wraps the Adjust SDK for attribution tracking and analytics event reporting.
final class AnalyticsService: NSObject {

    static let shared = AnalyticsService()
    private override init() { super.init() }

    /// Initialize the Adjust SDK with production configuration.
    func start() {
        let config = ADJConfig(appToken: AdjustKey, environment: ADJEnvironmentProduction)
        config?.logLevel = ADJLogLevelWarn
        config?.delegate = self
        Adjust.appDidLaunch(config)
        AnalyticsService.trackUniqueEvent(token: AdInstallToken)
    }

    /// Returns the Adjust device ID (ADID).
    static func deviceId() -> String {
        return Adjust.adid() ?? ""
    }

    /// Track a unique event, deduplicated by token.
    static func trackUniqueEvent(token: String) {
        let event = ADJEvent(eventToken: token)
        event?.setTransactionId(token)
        Adjust.trackEvent(event)
    }

    /// Track an event with associated revenue.
    static func trackRevenue(token: String, amount: Double) {
        let event = ADJEvent(eventToken: token)
        event?.setRevenue(amount, currency: "USD")
        Adjust.trackEvent(event)
    }

    /// Track a simple analytics event.
    static func trackEvent(token: String) {
        let event = ADJEvent(eventToken: token)
        Adjust.trackEvent(event)
    }
}

// MARK: - Adjust Delegate

extension AnalyticsService: AdjustDelegate {}

// MARK: - Legacy Compatibility

/// Bridges old call sites that reference `AppAdjustManager`.
final class AppAdjustManager: NSObject {
    static let shared = AppAdjustManager()

    func initAdjust() {
        AnalyticsService.shared.start()
    }

    class func getAdjustAdid() -> String {
        return AnalyticsService.deviceId()
    }

    class func addOnceEvent(token: String) {
        AnalyticsService.trackUniqueEvent(token: token)
    }

    class func addPurchasedEvent(token: String, count: Double) {
        AnalyticsService.trackRevenue(token: token, amount: count)
    }

    class func addEvent(token: String) {
        AnalyticsService.trackEvent(token: token)
    }
}
