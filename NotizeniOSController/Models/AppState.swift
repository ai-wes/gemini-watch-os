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
    @Published var watchData: WatchData = WatchData(isReachable: false)
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
        loadInitialData()
        setupWatchConnectivity()
        setupNotificationService()
    }
    
    private func setupNotificationService() {
        NotificationService.shared.setup(with: self)
        BatteryMonitoringService.shared.setup(with: self)
    }
    
    // MARK: - Initial Data
    private func loadInitialData() {
        // Start with clean state - notifications will come from real sources
        notifications = []
        
        // Default categories for notification classification
        categories = [
            NotificationCategory(name: "Finance", iconName: "banknote", bundleId: "com.bank.*", priority: 90),
            NotificationCategory(name: "Messages", iconName: "message", bundleId: "com.apple.MobileSMS", priority: 75),
            NotificationCategory(name: "Social", iconName: "person.2", bundleId: "com.facebook.*", priority: 40),
            NotificationCategory(name: "Shopping", iconName: "cart", bundleId: "com.amazon.*", priority: 25),
            NotificationCategory(name: "News", iconName: "newspaper", bundleId: "com.apple.news", priority: 20),
            NotificationCategory(name: "Games", iconName: "gamecontroller", bundleId: "com.game.*", priority: 15),
            NotificationCategory(name: "Work", iconName: "briefcase", bundleId: "com.microsoft.*", priority: 80),
            NotificationCategory(name: "Health", iconName: "heart", bundleId: "com.apple.Health", priority: 85)
        ]
        
        // Initialize empty history - will be populated with real data
        batteryHistory = []
        notificationHistory = []
        topDrainApps = []
        
        // Load persisted data if available
        loadPersistedData()
    }
    
    private func loadPersistedData() {
        // Load battery history from UserDefaults or Core Data
        if let savedBatteryData = UserDefaults.standard.data(forKey: "batteryHistory") {
            do {
                let decoder = JSONDecoder()
                batteryHistory = try decoder.decode([HistoryDataPoint].self, from: savedBatteryData)
            } catch {
                print("Failed to load battery history: \(error)")
            }
        }
        
        // Load notification history
        if let savedNotificationData = UserDefaults.standard.data(forKey: "notificationHistory") {
            do {
                let decoder = JSONDecoder()
                notificationHistory = try decoder.decode([HistoryDataPoint].self, from: savedNotificationData)
            } catch {
                print("Failed to load notification history: \(error)")
            }
        }
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
            // Sync updated category to watch
            syncCategoriesToWatch()
        }
        HapticManager.shared.rigid()
    }
    
    func updateBatteryMode(_ mode: BatteryMode) {
        batterySettings.mode = mode
        sendBatteryModeToWatch(mode)
        syncBatterySettingsToWatch()
        saveBatterySettings()
        HapticManager.shared.soft()
    }
    
    private func saveBatterySettings() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(batterySettings)
            UserDefaults.standard.set(data, forKey: "batterySettings")
        } catch {
            print("Failed to save battery settings: \(error)")
        }
    }
    
    func addCategory(_ category: NotificationCategory) {
        categories.append(category)
        // Sync new category to watch
        syncCategoriesToWatch()
        HapticManager.shared.success()
    }
    
    func deleteCategory(_ category: NotificationCategory) {
        categories.removeAll { $0.id == category.id }
        // Sync category deletion to watch
        syncCategoriesToWatch()
    }
    
    func exportHistoryData() -> String {
        // Generate CSV data
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        var csvContent = "Date,Type,Value,Category\n"
        
        for point in notificationHistory {
            csvContent += "\(formatter.string(from: point.timestamp)),Notification,\(point.value),\(point.category ?? "")\n"
        }
        
        for point in batteryHistory {
            csvContent += "\(formatter.string(from: point.timestamp)),Battery,\(point.value),\n"
        }
        
        return csvContent
    }
    
    // MARK: - Real Notification Handling
    func addNotification(_ notification: NotificationItem) {
        notifications.insert(notification, at: 0) // Add to beginning
        
        // Update history
        updateNotificationHistory()
        
        // Sync to watch if needed
        syncNotificationToWatch(notification)
        
        // Persist data
        saveNotificationHistory()
    }
    
    private func updateNotificationHistory() {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Update today's count
        if let todayIndex = notificationHistory.firstIndex(where: { Calendar.current.isDate($0.timestamp, inSameDayAs: today) }) {
            notificationHistory[todayIndex] = HistoryDataPoint(
                timestamp: today,
                value: notificationHistory[todayIndex].value + 1
            )
        } else {
            notificationHistory.append(HistoryDataPoint(timestamp: today, value: 1))
        }
        
        // Keep only last 30 days
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        notificationHistory = notificationHistory.filter { $0.timestamp >= thirtyDaysAgo }
    }
    
    private func syncNotificationToWatch(_ notification: NotificationItem) {
        #if canImport(WatchConnectivity)
        guard WCSession.default.isReachable else { return }
        
        do {
            let encoder = JSONEncoder()
            let notificationData = try encoder.encode([notification])
            
            let message = ["notifications": notificationData]
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Failed to send notification to watch: \(error.localizedDescription)")
            }
        } catch {
            print("Failed to encode notification: \(error.localizedDescription)")
        }
        #endif
    }
    
    private func saveNotificationHistory() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(notificationHistory)
            UserDefaults.standard.set(data, forKey: "notificationHistory")
        } catch {
            print("Failed to save notification history: \(error)")
        }
    }
    
    // MARK: - Watch Connectivity
    private func setupWatchConnectivity() {
        #if canImport(WatchConnectivity)
        guard WCSession.isSupported() else { 
            print("iOS: WatchConnectivity not supported on this device")
            return 
        }
        
        // Use the singleton connectivity manager
        WatchConnectivityManager.shared.appState = self
        WatchConnectivityManager.shared.activateSession()
        
        print("iOS: WatchConnectivity setup initiated")
        #endif
    }
    
    func checkWatchConnectionStatus() {
        #if canImport(WatchConnectivity)
        let session = WCSession.default
        let isConnected = session.activationState == .activated && session.isPaired && session.isWatchAppInstalled && session.isReachable
        
        print("iOS: Watch connection check - activated: \(session.activationState == .activated), paired: \(session.isPaired), installed: \(session.isWatchAppInstalled), reachable: \(session.isReachable)")
        
        self.watchData = WatchData(
            batteryMode: batterySettings.mode,
            isReachable: isConnected,
            lastSync: watchData.lastSync
        )
        #endif
    }
    
    func forceCheckConnection() {
        #if canImport(WatchConnectivity)
        WatchConnectivityManager.shared.checkConnectionStatus()
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
    
    // MARK: - Enhanced Watch Sync Methods
    func syncAllDataToWatch() {
        #if canImport(WatchConnectivity)
        guard WCSession.default.activationState == .activated else { return }
        
        // Sync categories
        syncCategoriesToWatch()
        
        // Sync battery settings
        syncBatterySettingsToWatch()
        
        // Sync user preferences
        syncUserPreferencesToWatch()
        
        print("iOS: Synced all data to watch")
        #endif
    }
    
    private func syncCategoriesToWatch() {
        #if canImport(WatchConnectivity)
        guard WCSession.default.activationState == .activated else { return }
        
        do {
            let encoder = JSONEncoder()
            let categoriesData = try encoder.encode(categories)
            
            if WCSession.default.isReachable {
                let message = ["syncCategories": categoriesData]
                WCSession.default.sendMessage(message, replyHandler: nil) { error in
                    print("Failed to send categories to watch: \(error.localizedDescription)")
                }
            } else {
                // Use application context for background updates
                try WCSession.default.updateApplicationContext(["categories": categoriesData])
            }
        } catch {
            print("Failed to encode categories: \(error.localizedDescription)")
        }
        #endif
    }
    
    private func syncBatterySettingsToWatch() {
        #if canImport(WatchConnectivity)
        guard WCSession.default.activationState == .activated else { return }
        
        do {
            let encoder = JSONEncoder()
            let settingsData = try encoder.encode(batterySettings)
            
            if WCSession.default.isReachable {
                let message = ["syncBatterySettings": settingsData]
                WCSession.default.sendMessage(message, replyHandler: nil) { error in
                    print("Failed to send battery settings to watch: \(error.localizedDescription)")
                }
            } else {
                try WCSession.default.updateApplicationContext(["batterySettings": settingsData])
            }
        } catch {
            print("Failed to encode battery settings: \(error.localizedDescription)")
        }
        #endif
    }
    
    private func syncUserPreferencesToWatch() {
        #if canImport(WatchConnectivity)
        guard WCSession.default.activationState == .activated else { return }
        
        let preferences = [
            "digestStartTime": ISO8601DateFormatter().string(from: Date()),
            "digestEndTime": ISO8601DateFormatter().string(from: Date()),
            "batteryMode": batterySettings.mode.rawValue
        ]
        
        if WCSession.default.isReachable {
            let message = ["syncUserPreferences": preferences]
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Failed to send user preferences to watch: \(error.localizedDescription)")
            }
        } else {
            do {
                try WCSession.default.updateApplicationContext(["userPreferences": preferences])
            } catch {
                print("Failed to update application context: \(error.localizedDescription)")
            }
        }
        #endif
    }
    
    func sendTestPingToWatch() {
        #if canImport(WatchConnectivity)
        // First check and update connection status
        WatchConnectivityManager.shared.checkConnectionStatus()
        
        let session = WCSession.default
        guard session.activationState == .activated else {
            print("iOS: Session not activated")
            HapticManager.shared.warning()
            return
        }
        
        guard session.isWatchAppInstalled else {
            print("iOS: Watch app not installed")
            HapticManager.shared.warning()
            return
        }
        
        guard session.isReachable else {
            print("iOS: Watch not reachable")
            HapticManager.shared.warning()
            return
        }
        
        let message = ["ping": "test"]
        session.sendMessage(message, replyHandler: { response in
            DispatchQueue.main.async {
                print("iOS: Ping successful: \(response)")
                HapticManager.shared.success()
            }
        }) { error in
            DispatchQueue.main.async {
                print("iOS: Ping failed: \(error.localizedDescription)")
                HapticManager.shared.warning()
            }
        }
        #endif
    }
}

// MARK: - Watch Connectivity Manager
#if canImport(WatchConnectivity)
final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    weak var appState: AppState?
    
    private override init() {
        super.init()
    }
    
    func activateSession() {
        guard WCSession.isSupported() else {
            print("iOS: WatchConnectivity not supported")
            return
        }
        
        let session = WCSession.default
        session.delegate = self
        session.activate()
        
        print("iOS: WatchConnectivity session activation initiated")
    }
    
    func checkConnectionStatus() {
        let session = WCSession.default
        let isConnected = session.activationState == .activated && session.isPaired && session.isWatchAppInstalled && session.isReachable
        
        print("iOS: Connection status check - activated: \(session.activationState == .activated), paired: \(session.isPaired), installed: \(session.isWatchAppInstalled), reachable: \(session.isReachable)")
        
        DispatchQueue.main.async {
            self.appState?.watchData = WatchData(
                batteryMode: self.appState?.batterySettings.mode ?? .balanced,
                isReachable: isConnected,
                lastSync: Date()
            )
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("iOS: Watch session activation: \(activationState), error: \(String(describing: error))")
        
        DispatchQueue.main.async {
            if activationState == .activated {
                // Only set reachable to true if session is actually reachable
                self.appState?.watchData = WatchData(
                    batteryMode: self.appState?.batterySettings.mode ?? .balanced,
                    isReachable: session.isReachable && session.isPaired,
                    lastSync: Date()
                )
                
                // Only sync if watch is actually reachable
                if session.isReachable && session.isPaired {
                    self.appState?.syncAllDataToWatch()
                }
            } else {
                // Session failed to activate properly
                self.appState?.watchData = WatchData(
                    batteryMode: self.appState?.batterySettings.mode ?? .balanced,
                    isReachable: false,
                    lastSync: Date()
                )
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("iOS: Watch session became inactive")
        DispatchQueue.main.async {
            self.appState?.watchData = WatchData(
                batteryMode: self.appState?.batterySettings.mode ?? .balanced,
                isReachable: false,
                lastSync: Date()
            )
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("iOS: Watch session deactivated")
        session.activate()
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("iOS: Watch reachability changed: \(session.isReachable), paired: \(session.isPaired), installed: \(session.isWatchAppInstalled)")
        DispatchQueue.main.async {
            self.appState?.watchData = WatchData(
                batteryMode: self.appState?.batterySettings.mode ?? .balanced,
                isReachable: session.isReachable && session.isPaired && session.isWatchAppInstalled,
                lastSync: Date()
            )
            
            // Auto-sync when watch becomes reachable
            if session.isReachable && session.isPaired && session.isWatchAppInstalled {
                self.appState?.syncAllDataToWatch()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("iOS: Received message from watch: \(message.keys)")
        
        if message["ping"] != nil {
            replyHandler(["pong": "success"])
            return
        }
        
        // Handle watch requesting data sync
        if message["requestSync"] != nil {
            DispatchQueue.main.async {
                self.appState?.syncAllDataToWatch()
            }
            replyHandler(["syncInitiated": true])
            return
        }
        
        // Handle battery data from watch
        if let batteryDataDict = message["batteryData"] as? [String: Any],
           let level = batteryDataDict["level"] as? Double,
           let isCharging = batteryDataDict["isCharging"] as? Bool,
           let estimatedHours = batteryDataDict["estimatedHours"] as? Double {
            
            DispatchQueue.main.async {
                self.appState?.batteryData = BatteryData(
                    level: level,
                    isCharging: isCharging,
                    estimatedHours: estimatedHours,
                    timestamp: Date()
                )
            }
            replyHandler(["batteryDataReceived": true])
            return
        }
        
        // Handle notifications from watch
        if let notificationsData = message["notifications"] as? Data {
            do {
                let decoder = JSONDecoder()
                let watchNotifications = try decoder.decode([NotificationItem].self, from: notificationsData)
                
                Task { @MainActor in
                    // Merge or update notifications from watch
                    self.updateNotificationsFromWatch(watchNotifications)
                }
                replyHandler(["notificationsReceived": true])
            } catch {
                print("Failed to decode notifications from watch: \(error)")
                replyHandler(["error": "Failed to decode notifications"])
            }
            return
        }
        
        // Handle watch requesting battery data update
        if message["requestBatterySync"] != nil {
            Task { @MainActor in
                // Send current battery data back to watch
                self.syncBatteryDataToWatch()
            }
            replyHandler(["batterySyncSent": true])
            return
        }
        
        replyHandler(["status": "unknown message type"])
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("iOS: Received application context from watch: \(applicationContext.keys)")
        
        DispatchQueue.main.async {
            // Handle background sync from watch
            if let batteryDataDict = applicationContext["batteryData"] as? [String: Any],
               let level = batteryDataDict["level"] as? Double,
               let isCharging = batteryDataDict["isCharging"] as? Bool,
               let estimatedHours = batteryDataDict["estimatedHours"] as? Double {
                
                self.appState?.batteryData = BatteryData(
                    level: level,
                    isCharging: isCharging,
                    estimatedHours: estimatedHours,
                    timestamp: Date()
                )
            }
        }
    }
    
    @MainActor
    private func updateNotificationsFromWatch(_ watchNotifications: [NotificationItem]) {
        guard let appState = appState else { return }
        
        // Update existing notifications or add new ones
        for watchNotification in watchNotifications {
            if let index = appState.notifications.firstIndex(where: { $0.id == watchNotification.id }) {
                // Update existing notification
                appState.notifications[index] = watchNotification
            } else {
                // Add new notification
                appState.notifications.append(watchNotification)
            }
        }
        
        // Sort by timestamp, newest first
        appState.notifications.sort { $0.timestamp > $1.timestamp }
        
        print("iOS: Updated \(watchNotifications.count) notifications from watch")
    }
    
    @MainActor
    private func syncBatteryDataToWatch() {
        #if canImport(WatchConnectivity)
        guard WCSession.default.isReachable else { return }
        
        let batteryData = [
            "level": self.appState?.batteryData.level ?? 100.0,
            "isCharging": self.appState?.batteryData.isCharging ?? false,
            "estimatedHours": self.appState?.batteryData.estimatedHours ?? 8.0
        ] as [String : Any]
        
        let message = ["batteryDataFromiOS": batteryData]
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send battery data to watch: \(error.localizedDescription)")
        }
        #endif
    }
}
#endif
