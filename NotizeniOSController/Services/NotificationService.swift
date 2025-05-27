import Foundation
import UserNotifications
import UIKit

@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var hasNotificationPermission = false
    
    weak var appState: AppState?
    
    override init() {
        super.init()
        checkNotificationPermissions()
    }
    
    func setup(with appState: AppState) {
        self.appState = appState
        requestNotificationPermissions()
    }
    
    private func checkNotificationPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.hasNotificationPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.hasNotificationPermission = granted
                if granted {
                    self?.registerForRemoteNotifications()
                }
            }
        }
    }
    
    private func registerForRemoteNotifications() {
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    // Process incoming notifications
    func processNotification(title: String, body: String, appName: String, bundleIdentifier: String) {
        let notification = NotificationItem(
            title: title,
            appName: appName,
            appIcon: iconForApp(bundleIdentifier: bundleIdentifier),
            timestamp: Date(),
            priority: determinePriority(title: title, body: body, bundleIdentifier: bundleIdentifier),
            isRead: false
        )
        
        appState?.addNotification(notification)
    }
    
    private func iconForApp(bundleIdentifier: String) -> String {
        // Map bundle identifiers to SF Symbols
        let lowercased = bundleIdentifier.lowercased()
        
        if lowercased.contains("mail") {
            return "mail"
        } else if lowercased.contains("message") {
            return "message"
        } else if lowercased.contains("phone") {
            return "phone"
        } else if lowercased.contains("calendar") {
            return "calendar"
        } else if lowercased.contains("bank") {
            return "banknote"
        } else if lowercased.contains("finance") {
            return "banknote"
        } else if lowercased.contains("social") {
            return "person.2"
        } else if lowercased.contains("instagram") {
            return "camera"
        } else if lowercased.contains("twitter") {
            return "bird"
        } else if lowercased.contains("facebook") {
            return "person.2"
        } else if lowercased.contains("news") {
            return "newspaper"
        } else if lowercased.contains("game") {
            return "gamecontroller"
        } else if lowercased.contains("shopping") {
            return "cart"
        } else if lowercased.contains("amazon") {
            return "cart"
        } else {
            return "app"
        }
    }
    
    private func determinePriority(title: String, body: String, bundleIdentifier: String) -> NotificationPriority {
        let content = (title + " " + body).lowercased()
        
        // High priority keywords
        let highPriorityKeywords = [
            "urgent", "important", "critical", "emergency", "alert",
            "bank", "payment", "transfer", "transaction", "security",
            "delivery", "delivered", "shipped", "arrived",
            "meeting", "appointment", "deadline", "due"
        ]
        
        // Check if any high priority keywords are present
        for keyword in highPriorityKeywords {
            if content.contains(keyword) {
                return .high
            }
        }
        
        // Check app-specific priorities
        if bundleIdentifier.contains("bank") || bundleIdentifier.contains("finance") {
            return .high
        }
        
        if bundleIdentifier.contains("message") || bundleIdentifier.contains("mail") {
            return .normal
        }
        
        // Low priority keywords
        let lowPriorityKeywords = [
            "sale", "discount", "offer", "promotion", "coupon",
            "newsletter", "update", "like", "comment", "follow"
        ]
        
        for keyword in lowPriorityKeywords {
            if content.contains(keyword) {
                return .low
            }
        }
        
        return .normal
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Handle notification while app is in foreground
        let userInfo = notification.request.content.userInfo
        let title = notification.request.content.title
        let body = notification.request.content.body
        let bundleIdentifier = userInfo["bundleIdentifier"] as? String ?? "unknown"
        let appName = userInfo["appName"] as? String ?? "Unknown App"
        
        Task { @MainActor in
            processNotification(title: title, body: body, appName: appName, bundleIdentifier: bundleIdentifier)
        }
        
        // Show notification even when app is active
        completionHandler([.banner, .sound, .badge])
    }
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo
        let title = response.notification.request.content.title
        let body = response.notification.request.content.body
        let bundleIdentifier = userInfo["bundleIdentifier"] as? String ?? "unknown"
        let appName = userInfo["appName"] as? String ?? "Unknown App"
        
        Task { @MainActor in
            processNotification(title: title, body: body, appName: appName, bundleIdentifier: bundleIdentifier)
        }
        
        completionHandler()
    }
}