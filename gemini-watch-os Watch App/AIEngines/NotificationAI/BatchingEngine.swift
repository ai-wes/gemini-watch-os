//
//  BatchingEngine.swift
//  NotiZenWatch Watch App
//
//  Created by Developer on 10/10/2023.
//

import Foundation

/// `BatchingEngine` is responsible for grouping similar or related notifications
/// to reduce clutter and present them in a more digestible format.
/// It will analyze incoming notifications (potentially classified by `NotificationClassifier`)
/// and decide if they can be batched based on app, content similarity, or timing.
class BatchingEngine {

    // MARK: - Properties
    
    private var pendingLowPriorityNotifications: [NotificationEvent] = []
    private var batchingRules: [String: BatchingRule] = [:] // Keyed by category name
    private let defaultTimeWindow: TimeInterval = 15 * 60 // 15 minutes
    private let defaultMaxItemsPerAppBatch: Int = 5

    // MARK: - Initialization
    
    init() {
        loadDefaultBatchingRules()
        print("BatchingEngine initialized with default rules.")
    }
    
    private func loadDefaultBatchingRules() {
        // Example: Batch social notifications frequently, promotions less so.
        // These could be user-configurable in the future.
        batchingRules["Social"] = BatchingRule(maxTimeWindow: 10 * 60, maxItemsInBatch: 5, groupSimilarTitles: true)
        batchingRules["News"] = BatchingRule(maxTimeWindow: 30 * 60, maxItemsInBatch: 3, groupSimilarTitles: false)
        batchingRules["Promotions"] = BatchingRule(maxTimeWindow: 60 * 60, maxItemsInBatch: 10, groupSimilarTitles: true)
        // Add more rules as needed
    }

    // MARK: - Batching Logic
    
    /// Adds a notification to the pending list if it's suitable for digest.
    /// This is called by WatchAppState when a new low-priority notification is classified.
    func addNotificationToBatch(_ notification: NotificationEvent) {
        // Assuming classification already determined it's low priority and should be digested.
        // The shouldIncludeInDigest can be used by Summarizer or WatchAppState before calling this.
        pendingLowPriorityNotifications.append(notification)
        print("BatchingEngine: Added notification '\(notification.title ?? "N/A")' to pending low-priority list. Count: \(pendingLowPriorityNotifications.count)")
    }

    /// Triggers a review of pending low-priority notifications to form digests.
    /// This would typically be called by WatchAppState when it's time to show the digest preview.
    /// - Parameter categoryPreferences: User's category settings to respect enabled/disabled status.
    /// - Returns: An array of `NotificationDigest`.
    func finalizeAndCreateDigests(categoryPreferences: [CategoryPreference]) -> [NotificationDigest] {
        var digests: [NotificationDigest] = []
        var remainingNotifications = pendingLowPriorityNotifications.filter { notification in
            guard let categoryName = notification.category else { return true } // Include if no category
            return categoryPreferences.first { $0.name == categoryName }?.isEnabled ?? true
        }
        
        guard !remainingNotifications.isEmpty else {
            print("BatchingEngine: No pending low-priority notifications to create digests from.")
            return []
        }

        print("BatchingEngine: Finalizing digests from \(remainingNotifications.count) pending notifications.")

        // Group by category first
        let groupedByCategory = Dictionary(grouping: remainingNotifications) { $0.category ?? "Uncategorized" }

        for (category, notificationsInCategory) in groupedByCategory {
            let rule = batchingRules[category] ?? BatchingRule(maxTimeWindow: defaultTimeWindow, maxItemsInBatch: defaultMaxItemsPerAppBatch, groupSimilarTitles: false)
            
            // Further group by appName within the category
            let groupedByApp = Dictionary(grouping: notificationsInCategory) { $0.appName }
            
            for (appName, appNotifications) in groupedByApp {
                var currentBatch: [NotificationEvent] = []
                var sortedAppNotifications = appNotifications.sorted(by: { $0.date < $1.date })
                
                while !sortedAppNotifications.isEmpty {
                    let firstNotification = sortedAppNotifications.removeFirst()
                    currentBatch.append(firstNotification)
                    
                    // Add subsequent notifications if they fit the time window and batch size
                    while !sortedAppNotifications.isEmpty && currentBatch.count < rule.maxItemsInBatch {
                        if let nextNotification = sortedAppNotifications.first,
                           nextNotification.date.timeIntervalSince(firstNotification.date) <= rule.maxTimeWindow {
                            currentBatch.append(sortedAppNotifications.removeFirst())
                        } else {
                            break // Next notification is outside time window or doesn't fit other criteria
                        }
                    }
                    
                    if !currentBatch.isEmpty {
                        let digestTitle = "\(appName) Updates" // Simple title, can be improved
                        let digest = NotificationDigest(notifications: currentBatch, title: digestTitle)
                        digests.append(digest)
                        print("BatchingEngine: Created digest '\(digestTitle)' with \(currentBatch.count) items.")
                        currentBatch.removeAll()
                    }
                }
            }
        }
        
        // Clear the main pending list after processing all of them for this digest cycle
        pendingLowPriorityNotifications.removeAll()
        print("BatchingEngine: All pending low-priority notifications processed. Digests created: \(digests.count)")
        return digests
    }
    
    /// Determines if a notification should be included in the current digest pool.
    /// - Parameter notification: The `NotificationEvent` to process.
    /// - Parameter categoryPreferences: User's category settings.
    /// - Returns: `true` if the notification should be included, `false` otherwise.
    func shouldIncludeInDigest(_ notification: NotificationEvent, categoryPreferences: [CategoryPreference]) -> Bool {
        guard let categoryName = notification.category else {
            print("BatchingEngine: Notification '\(notification.title ?? "N/A")' has no category. Including in digest by default.")
            return true // Default behavior for uncategorized notifications
        }

        if let categoryPref = categoryPreferences.first(where: { $0.name == categoryName }) {
            if !categoryPref.isEnabled {
                print("BatchingEngine: Category '\(categoryName)' is disabled. Notification '\(notification.title ?? "N/A")' excluded from digest.")
                return false
            }
        } else {
            // Category not found in user's preferences. Decide default behavior.
            // For now, let's assume unknown categories are included if not explicitly disabled.
            print("BatchingEngine: Category '\(categoryName)' for notification '\(notification.title ?? "N/A")' not found in user preferences. Including in digest by default.")
            return true
        }
        
        print("BatchingEngine: Notification '\(notification.title ?? "N/A")' from category '\(categoryName)' will be included in digest pool.")
        return true
    }
    
    /// Clears all currently pending low-priority notifications.
    /// Called when digests are presented or discarded.
    func clearPendingNotifications() {
        pendingLowPriorityNotifications.removeAll()
        print("BatchingEngine: Cleared all pending low-priority notifications.")
    }

    // MARK: - Helper Types
    
    struct BatchingRule {
        let maxTimeWindow: TimeInterval // Max time between notifications to be batched
        let maxItemsInBatch: Int
        let groupSimilarTitles: Bool // Future: Implement logic to group by similar titles
        // Add other criteria like content similarity threshold, etc.
    }
    
    // Removed BatchResult as the flow is now: add to pending -> finalize into digests
}
