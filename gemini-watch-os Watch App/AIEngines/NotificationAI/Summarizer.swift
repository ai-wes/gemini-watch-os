\
// filepath: /Users/wes/Desktop/NotiZeniOS/NotiZenWatch Watch App/AIEngines/NotificationAI/Summarizer.swift
import Foundation

/// `Summarizer` is responsible for creating concise summaries for individual
/// notifications or batches of notifications.
/// This could involve extracting key information, truncating long messages,
/// or even using more advanced NLP techniques for abstractive summarization if feasible on-device.
class Summarizer {

    // MARK: - Properties
    
    // TODO: Define any properties needed for summarization, e.g., length constraints.
    // private let defaultSummaryLength: Int = 100 // Max characters for a summary

    // MARK: - Initialization
    
    init() {
        // TODO: Initialize any models or configurations needed for summarization.
        // For instance, if using a Core ML model for summarization, load it here.
        print("Summarizer initialized.")
    }

    // MARK: - Summarization Logic

    /// Generates a summary for a single notification event.
    /// - Parameter notification: The `NotificationEvent` to summarize.
    /// - Returns: A string containing the summary.
    func summarize(notification: NotificationEvent) -> String {
        var summaryParts: [String] = []
        if let title = notification.title, !title.isEmpty {
            summaryParts.append(title)
        }
        // Use notification.message which is more comprehensive
        if !notification.message.isEmpty {
            let snippet = notification.message.prefix(50) // Take first 50 chars of message
            summaryParts.append(String(snippet) + (notification.message.count > 50 ? "..." : ""))
        }

        if summaryParts.isEmpty {
            return "Notification from \\(notification.appName)"
        } else {
            // Prefer appName in the summary if title is missing
            if notification.title == nil || notification.title?.isEmpty == true {
                 return "\\(notification.appName): \\(summaryParts.joined(separator: ": "))"
            }
            return summaryParts.joined(separator: ": ")
        }
    }
    
    /// Generates a title and an optional detailed summary for a `NotificationDigest`.
    /// - Parameter digest: The `NotificationDigest` to summarize.
    /// - Returns: A tuple containing a `title` string and an optional `summaryDetails` string.
    func summarize(digest: NotificationDigest) -> (title: String, summaryDetails: String?) {
        guard !digest.notifications.isEmpty else {
            return (title: "Empty Digest", summaryDetails: "This digest contains no notifications.")
        }

        // For the title, try to find a common app name or use the first notification's app name.
        let firstAppName = digest.notifications.first?.appName ?? "Mixed"
        let allSameApp = digest.notifications.allSatisfy { $0.appName == firstAppName }
        
        let title: String
        if allSameApp {
            title = "\\(digest.notifications.count) notification\\(digest.notifications.count > 1 ? "s" : "") from \\(firstAppName)"
        } else {
            title = "\\(digest.notifications.count) notification\\(digest.notifications.count > 1 ? "s" : "") from multiple apps"
        }

        // For summaryDetails, list the individual notification summaries.
        // This can be shown in a more detailed view like DigestPreviewSheetView.
        var details: [String] = []
        if digest.notifications.count > 1 { // Only add detailed list if more than one notification
            details.append("Includes:")
            for notification in digest.notifications.prefix(5) { // Show details for up to 5 notifications
                details.append("• \\(summarize(notification: notification))")
            }
            if digest.notifications.count > 5 {
                details.append("...and \\(digest.notifications.count - 5) more.")
            }
        } else if let firstNotification = digest.notifications.first {
            // If only one notification, the detail can be its full message or a slightly longer summary.
            details.append(firstNotification.message.prefix(100) + (firstNotification.message.count > 100 ? "..." : ""))
        }
        
        let summaryDetails = details.isEmpty ? nil : details.joined(separator: "\\n")

        return (title: title, summaryDetails: summaryDetails)
    }

    /// Generates an overall summary string for multiple `NotificationDigest` objects.
    /// This is suitable for `appState.notificationSummary`.
    /// - Parameter digests: An array of `NotificationDigest` to summarize.
    /// - Returns: A string containing the overall summary.
    func generateOverallSummary(for digests: [NotificationDigest]) -> String {
        guard !digests.isEmpty else {
            return "No new notification digests."
        }

        let totalNotifications = digests.reduce(0) { $0 + $1.notifications.count }
        if totalNotifications == 0 {
            return "No new notifications in digests."
        }
        
        var appCounts: [String: Int] = [:]
        for digest in digests {
            for notification in digest.notifications {
                appCounts[notification.appName, default: 0] += 1
            }
        }

        if appCounts.count == 1, let appName = appCounts.first?.key {
            return "\\(totalNotifications) new notification\\(totalNotifications > 1 ? "s" : "") from \\(appName)."
        } else if appCounts.count > 1 {
            let topApps = appCounts.sorted { $0.value > $1.value }.prefix(2)
            let appSummary = topApps.map { "\\($0.value) from \\($0.key)" }.joined(separator: ", ")
            let remainingAppsCount = appCounts.count - topApps.count
            let andMoreString = remainingAppsCount > 0 ? ", and more" : ""
            
            return "\\(totalNotifications) new notification\\(totalNotifications > 1 ? "s" : ""): \\(appSummary)\\(andMoreString)."
        } else {
             return "\\(totalNotifications) new notification\\(totalNotifications > 1 ? "s" : "") available."
        }
    }
    
    // Deprecating the old batch summarizer as digests are now the primary batching mechanism.
    // /// Generates a summary for a batch of notifications, considering category preferences.
    // /// - Parameters:
    // ///   - notifications: An array of `NotificationEvent` to summarize.
    // ///   - categoryPreferences: An array of `CategoryPreference` to determine which categories are active.
    // /// - Returns: A string containing the summary for the batch.
    // func summarize(notifications: [NotificationEvent], categoryPreferences: [CategoryPreference]) -> String { ... }


    // MARK: - Advanced Summarization (Future Considerations)
    
    /// Placeholder for more advanced summarization using NLP models.
    /// This would likely require a Core ML model trained for text summarization.
    private func performAdvancedSummarization(text: String) -> String {
        // TODO: Integrate Core ML model for summarization if available and performant.
        print("Performing advanced summarization (not implemented).")
        return text // Fallback to original text
    }

    // MARK: - Deinitialization
    
    deinit {
        // Perform any cleanup if necessary.
        print("Summarizer deinitialized.")
    }
}
