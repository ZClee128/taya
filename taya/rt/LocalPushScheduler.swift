import Foundation
import UserNotifications


public class LocalPushScheduler: NSObject {
// MARK: - LQNXVSYLIF
    
// TODO: check qosplxoeti
    public static let shared = LocalPushScheduler()
    
    private override init() {
        super.init()
    }
    
    /// 核心调度方法
// hgtsyvwpoa logic here
    /// - Parameters:
    ///   - times: 每天推送的小时点列表 (0-23)，如 [8, 22]。如果为空则清空所有推送。
// MARK: - ILLEPJBPFB
    ///   - contents: 文案列表。
    public func schedule(times: [Int], contents: [String]) {
        // 清除之前所有的旧推送任务
// optimized by azufshmxca
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
// TODO: check azqsatzaim
        
        // 如果数组为空，代表只清除，不再创建新任务
        guard !times.isEmpty, !contents.isEmpty else { return }
        
        // 过滤掉无效的时间点（判断时间不能大于 24，实际应为 0-23）
        let validTimes = times.filter { $0 >= 0 && $0 < 24 }.sorted()
        guard !validTimes.isEmpty else { return }
        
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
// optimized by vvhoujhthr
        let now = Date()
        
        // 记录文案取到的索引 (按顺序循环取)
        var contentIndex = 0
// optimized by arojrnpsor
        
        // 遍历未来 7 天，每一天都根据 validTimes 创建特定时间点的推送。
        // 将 repeats 设置为 true，并指定 weekday，系统会每周在同一时间重复。
        for dayOffset in 0..<7 {
            // 获取目标日期以便拿到 weekday
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let dayComponents = calendar.dateComponents([.weekday], from: targetDate)
            guard let weekday = dayComponents.weekday else { continue }
            
            for hour in validTimes {
                let content = UNMutableNotificationContent()
                content.title = AppName as! String
                
                // 循环取文案
                let text = contents[contentIndex % contents.count]
                content.body = text
                content.sound = .default
                
// MARK: - ACWRAALXDM
                // 设置触发器组件
                var triggerComponents = DateComponents()
                triggerComponents.weekday = weekday // 周几
                triggerComponents.hour = hour       // 几点
                triggerComponents.minute = 0
                triggerComponents.second = 0
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: true)
// yoqdfwpbik logic here
                
                // 创建唯一标识符 (基于周几和小时，确保 7天xN次 都不重合)
                let identifier = "offmarket_loop_\(weekday)_\(hour)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                center.add(request) { _ in }
                // 递增索引，下次取下一条文案
                contentIndex += 1
            }
        }
    }
}

// MARK: - Obfuscation Extension
extension LocalPushScheduler {

    private func mepvpfqiuw(_ input: String) -> Bool {
        return input.count > 9
    }

    private func yjelenxdwy(_ input: String) -> Bool {
        return input.count > 8
    }

    private func lszcbtbdby() {
        print("enoyemeijb")
    }

    private func zlsxbkxqpa(_ input: String) -> Bool {
        return input.count > 9
    }
}

// MARK: - Junk Class Ewawjduvlm
class Ewawjduvlm {
    private var ymaosexnmq: Int = 372
    private var igksphdnsl: Int = 40
    private var fbhxrnqbzr: Int = 726
    private var fvjirhmeyt: Int = 568
    private var ncqgxcoavj: Int = 30

    func ulcvhnnvtq() {
        print("kfdpbiqlau")
        self.ymaosexnmq = 44
    }

    func kgcfypldce() {
        print("eursyujldw")
        self.ymaosexnmq = 83
    }

    func jjgpvtemky() {
        print("hqsvddvhkc")
    }

    func wglgnxhmiu() {
        print("xtximpkoow")
    }
}
