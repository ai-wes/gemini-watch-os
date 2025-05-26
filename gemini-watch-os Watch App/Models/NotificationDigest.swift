
// filepath: /Users/wes/Desktop/NotiZeniOS/NotiZenWatch Watch App/Models/NotificationDigest.swift
import Foundation

/// Represents a collection of related low-priority notifications that have been batched together.
struct NotificationDigest: Identifiable, Codable, Hashable {
    let id: UUID
    var creationDate: Date
    var notifications: [NotificationEvent]
    var title: String // e.g., "Social Updates", "Latest Promotions"
    var summary: String? // A brief summary of the digest content, if generated

    init(id: UUID = UUID(), creationDate: Date = Date(), notifications: [NotificationEvent], title: String, summary: String? = nil) {
        self.id = id
        self.creationDate = creationDate
        self.notifications = notifications
        self.title = title
        self.summary = summary
    }
}
