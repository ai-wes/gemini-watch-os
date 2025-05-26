import Foundation

/// Responsible for summarizing notifications or batches of notifications.
class Summarizer {

    // MARK: - Initialization

    init() {
        print("Summarizer initialized.")
    }

    // MARK: - Summarization Logic

    /// Generates a summary for a single notification event.
    func summarize(notification: NotificationEvent) -> String {
        var summaryParts: [String] = []
        if let title = notification.title, !title.isEmpty {
            summaryParts.append(title)
        }
        if !notification.message.isEmpty {
            let snippet = notification.message.prefix(50)
            summaryParts.append(String(snippet) + (notification.message.count > 50 ? "..." : ""))
        }

        if summaryParts.isEmpty {
            return "Notification from \(notification.appName)"
        } else {
            // Prefer appName in the summary if title is missing
            if notification.title == nil || notification.title?.isEmpty == true {
                return "\(notification.appName): \(summaryParts.joined(separator: ": "))"
            }
            return summaryParts.joined(separator: ": ")
        }
    }

    /// Generates a title and optional summary for a digest.
    func summarize(digest: NotificationDigest) -> (title: String, summaryDetails: String?) {
        guard !digest.notifications.isEmpty else {
            return (title: "Empty Digest", summaryDetails: "This digest contains no notifications.")
        }

        let firstAppName = digest.notifications.first?.appName ?? "Mixed"
        let allSameApp = digest.notifications.allSatisfy { $0.appName == firstAppName }

        let title: String
        if allSameApp {
            title = "\(digest.notifications.count) notification\(digest.notifications.count > 1 ? "s" : "") from \(firstAppName)"
        } else {
            title = "\(digest.notifications.count) notification\(digest.notifications.count > 1 ? "s" : "") from multiple apps"
        }

        var details: [String] = []
        if digest.notifications.count > 1 {
            details.append("Includes:")
            for notification in digest.notifications.prefix(5) {
                details.append("• \(summarize(notification: notification))")
            }
            if digest.notifications.count > 5 {
                details.append("...and \(digest.notifications.count - 5) more.")
            }
        } else if let firstNotification = digest.notifications.first {
            let msg = firstNotification.message
            details.append(String(msg.prefix(100)) + (msg.count > 100 ? "..." : ""))
        }

        let summaryDetails = details.isEmpty ? nil : details.joined(separator: "\n")
        return (title: title, summaryDetails: summaryDetails)
    }

    /// Generates an overall summary string for multiple digests.
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
            return "\(totalNotifications) new notification\(totalNotifications > 1 ? "s" : "") from \(appName)."
        } else if appCounts.count > 1 {
            let topApps = appCounts.sorted { $0.value > $1.value }.prefix(2)
            let appSummary = topApps.map { "\($0.value) from \($0.key)" }.joined(separator: ", ")
            let remainingAppsCount = appCounts.count - topApps.count
            let andMoreString = remainingAppsCount > 0 ? ", and more" : ""
            return "\(totalNotifications) new notification\(totalNotifications > 1 ? "s" : ""): \(appSummary)\(andMoreString)."
        } else {
            return "\(totalNotifications) new notification\(totalNotifications > 1 ? "s" : "") available."
        }
    }

    /// Summarizes a batch of notifications, considering category preferences.
    func summarize(notifications: [NotificationEvent], categoryPreferences: [CategoryPreference]) -> String {
        guard !notifications.isEmpty else {
            return "No notifications to summarize."
        }

        if notifications.count == 1 {
            return summarize(notification: notifications[0])
        }

        let groupedByApp = Dictionary(grouping: notifications) { $0.appName }
        var summaryParts: [String] = []

        for (appName, appNotifications) in groupedByApp {
            let count = appNotifications.count
            summaryParts.append("\(count) from \(appName)")
        }

        return summaryParts.joined(separator: ", ")
    }

    // MARK: - Advanced Summarization (Future Considerations)
    private func performAdvancedSummarization(text: String) -> String {
        // TODO: Integrate Core ML model for summarization if available and performant.
        print("Performing advanced summarization (not implemented).")
        return text
    }

    deinit {
        print("Summarizer deinitialized.")
    }
}
