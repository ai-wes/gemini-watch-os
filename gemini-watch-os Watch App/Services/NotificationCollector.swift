import Foundation
import UserNotifications
import os.log

// As per PRD: Subscribe to UNNotificationServiceExtension, capture metadata, redact payload

class NotificationCollector: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "NotiZenWatch", category: "NotificationCollector")

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        self.bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        logger.log("Received notification request")

        if let bestAttemptContent = bestAttemptContent {
            // Capture metadata
            let bundleID = request.content.userInfo["bundleID"] as? String ?? "unknown"
            let title = bestAttemptContent.title
            let category = bestAttemptContent.categoryIdentifier
            let timestamp = Date()
            let subtitle = bestAttemptContent.subtitle
            let body = bestAttemptContent.body

            // PRD: "No raw notification payload stored – titles/body discarded post-classification; only hashes retained."
            // For now, we'll capture the title, but actual redaction/hashing will be part of the classification step.
            
            logger.log("Notification Metadata: BundleID: (bundleID, privacy: .public), Title: (title, privacy: .private), Category: (category, privacy: .public)")

            var messageContent = body
            if !subtitle.isEmpty {
                messageContent = "(subtitle)(body)" // Corrected newline and interpolation
            }

            // Create a NotificationEvent (assuming this will be saved to Core Data later)
            // For now, we're just logging. The actual storage will be handled by a data persistence service.
            let _ = NotificationEvent(
                id: UUID(), // Or derive from request identifier if appropriate
                date: timestamp,
                appName: bundleID, // Using bundleID for appName
                bundleID: bundleID,
                title: title, // This will be redacted/hashed later
                message: messageContent, // Using subtitle + body for message
                category: category,
                score: 0.0, // Classification score to be filled by NotifClassifier
                digestedID: nil
            )
            
            // TODO: Implement saving of notificationEvent to local store (CoreData + CloudKit)
            // TODO: Trigger NotificationClassifier

            // Modify content as needed, e.g., for testing or if the extension itself adds info
            // bestAttemptContent.title = "[Collected] \(bestAttemptContent.title)"
            
            contentHandler(bestAttemptContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        logger.log("Service extension time will expire")
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
