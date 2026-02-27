import Foundation
import UserNotifications

/// Manages scheduled local push notifications that repeat weekly.
/// Receives a list of hours and message texts, then creates repeating
/// calendar-based triggers for each day-of-week / hour combination.
final class NotificationScheduler {

    static let shared = NotificationScheduler()
    private init() {}

    /// Replaces all pending notifications with a new weekly schedule.
    /// - Parameters:
    ///   - hours: Delivery hours (0–23). Invalid values are filtered out.
    ///   - messages: Notification body texts, cycled through sequentially.
    func configureWeeklySchedule(hours: [Int], messages: [String]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        guard !hours.isEmpty, !messages.isEmpty else { return }

        let validHours = hours.filter { (0..<24).contains($0) }.sorted()
        guard !validHours.isEmpty else { return }

        let calendar = Calendar.current
        let today = Date()
        var messageIndex = 0

        for dayOffset in 0..<7 {
            guard let targetDay = calendar.date(byAdding: .day, value: dayOffset, to: today),
                  let weekday = calendar.dateComponents([.weekday], from: targetDay).weekday else {
                continue
            }

            for hour in validHours {
                let body = messages[messageIndex % messages.count]

                let content = UNMutableNotificationContent()
                content.title = (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String) ?? ""
                content.body = body
                content.sound = .default

                var components = DateComponents()
                components.weekday = weekday
                components.hour = hour
                components.minute = 0
                components.second = 0

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let requestId = "weekly_\(weekday)_\(hour)"
                let request = UNNotificationRequest(identifier: requestId, content: content, trigger: trigger)
                center.add(request, withCompletionHandler: nil)

                messageIndex += 1
            }
        }
    }
}

// MARK: - Legacy Compatibility

/// Bridges old call sites that use `LocalPushScheduler.shared.schedule(...)`.
final class LocalPushScheduler {
    static let shared = LocalPushScheduler()
    private init() {}

    func schedule(times: [Int], contents: [String]) {
        NotificationScheduler.shared.configureWeeklySchedule(hours: times, messages: contents)
    }
}
