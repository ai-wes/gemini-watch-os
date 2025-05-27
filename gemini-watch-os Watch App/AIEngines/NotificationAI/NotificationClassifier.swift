import Foundation

/// `NotificationClassifier` is responsible for analyzing incoming notification events
/// and determining their priority, category, and whether they should be part of a digest.
///
/// This is a placeholder implementation. Future development will involve integrating
/// machine learning models or more complex rule-based systems for classification.
class NotificationClassifier {

    // MARK: - Properties

    // No longer need to store rules here if WatchAppState provides them dynamically.

    // MARK: - Initialization

    init() {
        // Initialization can be kept simple if category preferences are passed directly to classify method.
    }

    // MARK: - Classification Logic

    /// Classifies a given notification event based on user-defined categories and other heuristics.
    ///
    /// - Parameter notification: The `NotificationEvent` to classify.
    /// - Parameter userCategories: An array of `CategoryPreference` from `WatchAppState`.
    /// - Returns: A tuple containing priority, category, and digest status.
    func classify(notification: NotificationEvent, userCategories: [CategoryPreference]) -> (priority: NotificationPriority, category: String, shouldDigest: Bool) {
        // 1. Check against user-defined categories first
        for userCategory in userCategories where userCategory.isEnabled {
            // Simple matching: check if appName or message contains the category name (case-insensitive)
            // More sophisticated matching could involve keywords associated with each category.
            if notification.appName.lowercased().contains(userCategory.name.lowercased()) ||
               notification.message.lowercased().contains(userCategory.name.lowercased()) {
                // If a notification matches a user-defined category, it's considered high priority and not digested.
                // The category assigned is the user-defined category name.
                return (.high, userCategory.name, false)
            }
        }

        // 2. Advanced classification logic with scoring system
        let bundleID = notification.bundleID.lowercased()
        let appName = notification.appName.lowercased()
        let title = (notification.title ?? "").lowercased()
        let message = notification.message.lowercased()
        let combinedText = "\(title) \(message)"
        
        // Calculate scores for different priority levels
        let highScore = calculateHighPriorityScore(bundleID: bundleID, appName: appName, text: combinedText)
        let mediumScore = calculateMediumPriorityScore(bundleID: bundleID, appName: appName, text: combinedText)
        
        // Time-based adjustments
        let timeMultiplier = getTimeBasedMultiplier()
        let finalHighScore = highScore * timeMultiplier
        let finalMediumScore = mediumScore * timeMultiplier
        
        // Determine category and priority
        if finalHighScore >= 0.7 {
            let category = getCategoryFromHighPriority(bundleID: bundleID, appName: appName, text: combinedText)
            return (.high, category, false)
        } else if finalMediumScore >= 0.5 {
            let category = getCategoryFromMediumPriority(bundleID: bundleID, appName: appName, text: combinedText)
            return (.medium, category, false)
        } else {
            let category = getCategoryFromLowPriority(bundleID: bundleID, appName: appName)
            return (.low, category, true)
        }
    }

    // MARK: - Helper Methods
    
    private func calculateHighPriorityScore(bundleID: String, appName: String, text: String) -> Double {
        var score: Double = 0.0
        
        // Critical app patterns
        let criticalApps = ["bank", "finance", "payment", "paypal", "venmo", "cashapp", "chase", "wellsfargo", "bofa"]
        if criticalApps.contains(where: { bundleID.contains($0) || appName.contains($0) }) {
            score += 0.6
        }
        
        // Security and urgent keywords
        let urgentKeywords = ["urgent", "alert", "emergency", "fraud", "security", "breach", "suspicious", "unauthorized", "failed login", "verify"]
        let urgentMatches = urgentKeywords.filter { text.contains($0) }.count
        score += min(Double(urgentMatches) * 0.3, 0.8)
        
        // Financial keywords
        let financialKeywords = ["payment", "transaction", "charge", "declined", "overdraft", "deposit", "transfer"]
        let financialMatches = financialKeywords.filter { text.contains($0) }.count
        score += min(Double(financialMatches) * 0.2, 0.4)
        
        return min(score, 1.0)
    }
    
    private func calculateMediumPriorityScore(bundleID: String, appName: String, text: String) -> Double {
        var score: Double = 0.0
        
        // Work-related apps
        let workApps = ["slack", "teams", "zoom", "calendar", "outlook", "gmail", "work", "enterprise"]
        if workApps.contains(where: { bundleID.contains($0) || appName.contains($0) }) {
            score += 0.4
        }
        
        // Important keywords
        let importantKeywords = ["meeting", "deadline", "reminder", "appointment", "schedule", "call", "conference"]
        let importantMatches = importantKeywords.filter { text.contains($0) }.count
        score += min(Double(importantMatches) * 0.2, 0.5)
        
        // Communication apps (but not social media)
        let communicationApps = ["messages", "whatsapp", "telegram", "signal", "imessage", "mail"]
        if communicationApps.contains(where: { bundleID.contains($0) || appName.contains($0) }) {
            score += 0.3
        }
        
        return min(score, 1.0)
    }
    
    private func getTimeBasedMultiplier() -> Double {
        let hour = Calendar.current.component(.hour, from: Date())
        
        // Higher priority during work hours (9 AM - 6 PM)
        if hour >= 9 && hour <= 18 {
            return 1.2
        }
        // Lower priority during sleep hours (11 PM - 7 AM)
        else if hour >= 23 || hour <= 7 {
            return 0.7
        }
        // Normal priority during other hours
        else {
            return 1.0
        }
    }
    
    private func getCategoryFromHighPriority(bundleID: String, appName: String, text: String) -> String {
        if bundleID.contains("bank") || appName.contains("bank") || text.contains("payment") || text.contains("transaction") {
            return "Finance"
        } else if text.contains("security") || text.contains("fraud") || text.contains("unauthorized") {
            return "Security"
        } else if text.contains("emergency") || text.contains("urgent") {
            return "Emergency"
        } else {
            return "Important"
        }
    }
    
    private func getCategoryFromMediumPriority(bundleID: String, appName: String, text: String) -> String {
        if bundleID.contains("calendar") || appName.contains("calendar") || text.contains("meeting") {
            return "Calendar"
        } else if bundleID.contains("mail") || appName.contains("mail") || bundleID.contains("message") {
            return "Communication"
        } else if bundleID.contains("work") || bundleID.contains("slack") || bundleID.contains("teams") {
            return "Work"
        } else {
            return "General"
        }
    }
    
    private func getCategoryFromLowPriority(bundleID: String, appName: String) -> String {
        if bundleID.contains("social") || appName.contains("social") || bundleID.contains("twitter") || bundleID.contains("facebook") {
            return "Social"
        } else if bundleID.contains("news") || appName.contains("news") {
            return "News"
        } else if bundleID.contains("game") || appName.contains("game") {
            return "Entertainment"
        } else {
            return "Other"
        }
    }

    // TODO: Define `NotificationPriority` enum if not already globally available.
    // enum NotificationPriority {
    //     case high, medium, low
    // }
}

// TODO: Define a struct or class for `ClassifiedNotification` if a more complex
// return type is needed from the `classify` method.
// struct ClassifiedNotification {
//     let originalEvent: NotificationEvent
//     let priority: NotificationClassifier.NotificationPriority
//     let category: String
//     let shouldDigest: Bool
//     let suggestedActions: [String]? // e.g., "Mute for 1h", "Archive"
// }

// TODO: Consider defining `NotificationRule` struct/class if using a rule-based system.
// struct NotificationRule {
//     let conditions: [String: String] // e.g., ["appName": "Messages", "keyword": "urgent"]
//     let resultingPriority: NotificationClassifier.NotificationPriority
//     let resultingCategory: String
//     let shouldDigest: Bool
// }
