import Foundation
import SwiftUI
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

@MainActor
class AppState: ObservableObject {
    // MARK: - Published Properties
    @Published var notifications: [NotificationItem] = []
    @Published var categories: [NotificationCategory] = []
    @Published var batteryData: BatteryData = BatteryData(level: 85, estimatedHours: 18)
    @Published var batterySettings: BatterySettings = BatterySettings()
    @Published var batteryHistory: [HistoryDataPoint] = []
    @Published var notificationHistory: [HistoryDataPoint] = []
    @Published var subscription: SubscriptionInfo = SubscriptionInfo()
    @Published var watchData: WatchData = WatchData()
    @Published var topDrainApps: [AppDrainData] = []
    
    // MARK: - Computed Properties
    var highPriorityNotifications: [NotificationItem] {
        notifications.filter { $0.priority == .high && !$0.isRead }
    }
    
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    var highPriorityCount: Int {
        highPriorityNotifications.count
    }
    
    var todayNotificationCounts: [HistoryDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        return (0..<24).map { hour in
            let hourDate = calendar.date(byAdding: .hour, value: hour, to: startOfDay) ?? startOfDay
            let count = notifications.filter { notification in
                calendar.isDate(notification.timestamp, inSameDayAs: hourDate) &&
                calendar.component(.hour, from: notification.timestamp) == hour
            }.count
            
            return HistoryDataPoint(timestamp: hourDate, value: Double(count))
        }
    }
    
    init() {
        loadSampleData()
        setupWatchConnectivity()
    }
    
    // MARK: - Sample Data
    private func loadSampleData() {
        // Sample notifications
        notifications = [
            NotificationItem(
                title: "Wire transfer of $2,500 completed",
                appName: "Banking",
                appIcon: "banknote",
                timestamp: Calendar.current.date(byAdding: .minute, value: -5, to: Date()) ?? Date(),
                priority: .high
            ),
            NotificationItem(
                title: "Your package has been delivered",
                appName: "Delivery",
                appIcon: "shippingbox",
                timestamp: Calendar.current.date(byAdding: .minute, value: -15, to: Date()) ?? Date(),
                priority: .high
            ),
            NotificationItem(
                title: "New message from John",
                appName: "Messages",
                appIcon: "message",
                timestamp: Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date(),
                priority: .normal
            ),
            NotificationItem(
                title: "50% off sale ends today",
                appName: "Shopping",
                appIcon: "cart",
                timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
                priority: .low
            ),
            NotificationItem(
                title: "Weekly digest ready",
                appName: "News",
                appIcon: "newspaper",
                timestamp: Calendar.current.date(byAdding: .hour, value: -3, to: Date()) ?? Date(),
                priority: .low
            )
        ]
        
        // Sample categories
        categories = [
            NotificationCategory(name: "Finance", iconName: "banknote", bundleId: "com.bank.app", priority: 90),
            NotificationCategory(name: "Messages", iconName: "message", bundleId: "com.apple.MobileSMS", priority: 75),
            NotificationCategory(name: "Social", iconName: "person.2", bundleId: "com.facebook.Facebook", priority: 40),
            NotificationCategory(name: "Shopping", iconName: "cart", bundleId: "com.amazon.Amazon", priority: 25),
            NotificationCategory(name: "News", iconName: "newspaper", bundleId: "com.apple.news", priority: 20),
            NotificationCategory(name: "Games", iconName: "gamecontroller", bundleId: "com.game.app", priority: 15)
        ]
        
        // Sample battery history (last 24 hours)
        let now = Date()
        batteryHistory = (0..<24).map { hour in
            let timestamp = Calendar.current.date(byAdding: .hour, value: -hour, to: now) ?? now
            let level = max(20, 100 - Double(hour) * 2.5 + Double.random(in: -5...5))
            return HistoryDataPoint(timestamp: timestamp, value: level)
        }.reversed()
        
        // Sample notification history
        notificationHistory = (0..<7).map { day in
            let timestamp = Calendar.current.date(byAdding: .day, value: -day, to: now) ?? now
            let count = Double.random(in: 15...45)
            return HistoryDataPoint(timestamp: timestamp, value: count)
        }.reversed()
        
        // Sample top drain apps
        topDrainApps = [
            AppDrainData(appName: "Social Media", iconName: "person.2", drainPercentage: 23.5),
            AppDrainData(appName: "Games", iconName: "gamecontroller", drainPercentage: 18.2),
            AppDrainData(appName: "Video", iconName: "play.rectangle", drainPercentage: 15.7),
            AppDrainData(appName: "Maps", iconName: "map", drainPercentage: 12.1),
            AppDrainData(appName: "Camera", iconName: "camera", drainPercentage: 8.3)
        ]
    }
    
    // MARK: - Actions
    func markNotificationAsRead(_ notification: NotificationItem) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index] = NotificationItem(
                title: notification.title,
                appName: notification.appName,
                appIcon: notification.appIcon,
                timestamp: notification.timestamp,
                priority: notification.priority,
                isRead: true
            )
        }
    }
    
    func archiveNotification(_ notification: NotificationItem) {
        notifications.removeAll { $0.id == notification.id }
        HapticManager.shared.soft()
    }
    
    func updateCategoryPriority(_ category: NotificationCategory, priority: Double) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index].priority = priority
        }
        HapticManager.shared.rigid()
    }
    
    func updateBatteryMode(_ mode: BatteryMode) {
        batterySettings.mode = mode
        sendBatteryModeToWatch(mode)
        HapticManager.shared.soft()
    }
    
    func addCategory(_ category: NotificationCategory) {
        categories.append(category)
        HapticManager.shared.success()
    }
    
    func deleteCategory(_ category: NotificationCategory) {
        categories.removeAll { $0.id == category.id }
    }
    
    func exportHistoryData() -> String {
        // Generate CSV data
        var csvContent = "Date,Type,Value,Category\n"
        
        for point in notificationHistory {
            csvContent += "\(point.timestamp),Notification,\(point.value),\(point.category ?? "")\n"
        }
        
        for point in batteryHistory {
            csvContent += "\(point.timestamp),Battery,\(point.value),\n"
        }
        
        return csvContent
    }
    
    // MARK: - Watch Connectivity
    private func setupWatchConnectivity() {
        #if canImport(WatchConnectivity)
        guard WCSession.isSupported() else { return }
        
        let session = WCSession.default
        session.delegate = WatchConnectivityDelegate.shared
        session.activate()
        #endif
    }
    
    private func sendBatteryModeToWatch(_ mode: BatteryMode) {
        #if canImport(WatchConnectivity)
        guard WCSession.default.isReachable else { return }
        
        let message = ["batteryMode": mode.rawValue]
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send battery mode to watch: \(error.localizedDescription)")
        }
        #endif
    }
    
    func sendTestPingToWatch() {
        #if canImport(WatchConnectivity)
        guard WCSession.default.isReachable else { return }
        
        let message = ["ping": "test"]
        WCSession.default.sendMessage(message, replyHandler: { response in
            DispatchQueue.main.async {
                HapticManager.shared.success()
            }
        }) { error in
            DispatchQueue.main.async {
                HapticManager.shared.warning()
            }
        }
        #endif
    }
}

// MARK: - Watch Connectivity Delegate
#if canImport(WatchConnectivity)
class WatchConnectivityDelegate: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityDelegate()
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Watch session activation: \(activationState)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Watch session became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("Watch session deactivated")
        session.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if message["ping"] != nil {
            replyHandler(["pong": "success"])
        }
    }
}
#endif
