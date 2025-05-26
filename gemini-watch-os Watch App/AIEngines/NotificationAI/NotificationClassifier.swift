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

        // 2. Default classification logic if no user category matches
        // This can be expanded with more sophisticated rules or a basic ML model in the future.
        if notification.appName.lowercased().contains("bank") || notification.message.lowercased().contains("urgent") || notification.message.lowercased().contains("alert") {
            return (.high, "Finance", false) // Example: High priority, Finance, don't digest
        } else if notification.appName.lowercased().contains("calendar") || notification.message.lowercased().contains("meeting") || notification.message.lowercased().contains("reminder") {
            return (.high, "Reminders", false)
        } else if notification.appName.lowercased().contains("message") || notification.appName.lowercased().contains("mail") || notification.appName.lowercased().contains("chat") {
            // Could be medium or high depending on sender or content, for now, medium.
            return (.medium, "Communication", false)
        } else if notification.appName.lowercased().contains("social") || notification.appName.lowercased().contains("news") {
            return (.low, "Social", true) // Example: Low priority, Social, digest
        }

        // Default for anything else
        return (.medium, "General", true) // Default to medium, digestable, if not specifically handled
    }

    // MARK: - Helper Methods

    // TODO: Implement helper methods for loading rules, processing text, etc.
    // private func loadRules() {
    //     // Load rules from a configuration file or user defaults.
    // }

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
