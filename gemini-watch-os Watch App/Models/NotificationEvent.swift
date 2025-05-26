import Foundation

struct NotificationEvent: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var appName: String
    var bundleID: String
    var title: String?
    var message: String
    var category: String?
    var score: Double
    var digestedID: UUID?
}
