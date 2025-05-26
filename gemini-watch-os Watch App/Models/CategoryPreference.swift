import Foundation

struct CategoryPreference: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var isEnabled: Bool
    var keywords: [String] // Keywords to help identify notifications for this category
    // let isSystemCategory: Bool // Future: To distinguish between default and user-added

    init(id: UUID = UUID(), name: String, isEnabled: Bool = true, keywords: [String] = []) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.keywords = keywords
    }
}
