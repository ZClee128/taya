import Foundation
import UserNotifications

/// Schedules repeating local push notifications at specified times
public class LocalPushScheduler: NSObject {
    
    public static let shared = LocalPushScheduler()
    
    private override init() {
        super.init()
    }
    
    /// Schedule weekly repeating notifications at specified hours
    /// - Parameters:
    ///   - times: Hour values (0-23) for daily notification delivery
    ///   - contents: Notification body text, cycled through in order
    public func schedule(times: [Int], contents: [String]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        guard !times.isEmpty, !contents.isEmpty else { return }
        
        let validTimes = times.filter { $0 >= 0 && $0 < 24 }.sorted()
        guard !validTimes.isEmpty else { return }
        
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        let now = Date()
        
        var contentIndex = 0
        
        for dayOffset in 0..<7 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let dayComponents = calendar.dateComponents([.weekday], from: targetDate)
            guard let weekday = dayComponents.weekday else { continue }
            
            for hour in validTimes {
                let content = UNMutableNotificationContent()
                content.title = AppName as! String
                
                let text = contents[contentIndex % contents.count]
                content.body = text
                content.sound = .default
                
                var triggerComponents = DateComponents()
                triggerComponents.weekday = weekday
                triggerComponents.hour = hour
                triggerComponents.minute = 0
                triggerComponents.second = 0
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: true)
                
                let identifier = "offmarket_loop_\(weekday)_\(hour)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                center.add(request) { _ in }
                contentIndex += 1
            }
        }
    }
}
