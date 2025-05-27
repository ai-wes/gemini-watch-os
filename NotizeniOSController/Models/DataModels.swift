import Foundation

// MARK: - Notification Models
struct NotificationItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let appName: String
    let appIcon: String
    let timestamp: Date
    let priority: NotificationPriority
    let isRead: Bool
    
    init(title: String, appName: String, appIcon: String, timestamp: Date = Date(), priority: NotificationPriority = .normal, isRead: Bool = false) {
        self.title = title
        self.appName = appName
        self.appIcon = appIcon
        self.timestamp = timestamp
        self.priority = priority
        self.isRead = isRead
    }
}

enum NotificationPriority: String, CaseIterable {
    case high = "high"
    case normal = "normal"
    case low = "low"
    
    var displayName: String {
        switch self {
        case .high: return "High"
        case .normal: return "Normal"
        case .low: return "Low"
        }
    }
    
    var iconName: String {
        switch self {
        case .high: return "bell.badge.fill"
        case .normal: return "bell"
        case .low: return "bell.slash"
        }
    }
}

// MARK: - Category Models
struct NotificationCategory: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let iconName: String
    let bundleId: String
    var priority: Double // 0-100
    var isDigestEnabled: Bool
    var muteWindows: [MuteWindow]
    
    init(name: String, iconName: String, bundleId: String, priority: Double = 50, isDigestEnabled: Bool = true, muteWindows: [MuteWindow] = []) {
        self.name = name
        self.iconName = iconName
        self.bundleId = bundleId
        self.priority = priority
        self.isDigestEnabled = isDigestEnabled
        self.muteWindows = muteWindows
    }
}

struct MuteWindow: Identifiable, Hashable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    let isEnabled: Bool
    
    init(startTime: Date, endTime: Date, isEnabled: Bool = true) {
        self.startTime = startTime
        self.endTime = endTime
        self.isEnabled = isEnabled
    }
}

// MARK: - Battery Models
struct BatteryData: Hashable {
    let level: Double // 0-100
    let isCharging: Bool
    let estimatedHours: Double
    let timestamp: Date
    
    init(level: Double, isCharging: Bool = false, estimatedHours: Double = 0, timestamp: Date = Date()) {
        self.level = level
        self.isCharging = isCharging
        self.estimatedHours = estimatedHours
        self.timestamp = timestamp
    }
}

enum BatteryMode: String, CaseIterable {
    case balanced = "balanced"
    case runtimePlus = "runtime+"
    case performance = "performance"
    
    var displayName: String {
        switch self {
        case .balanced: return "Balanced"
        case .runtimePlus: return "Runtime+"
        case .performance: return "Performance"
        }
    }
}

struct BatterySettings {
    var mode: BatteryMode = .balanced
    var smartLowPowerEnabled: Bool = true
    var lowPowerThreshold: Int = 20 // 5-50%
}

// MARK: - App Drain Data
struct AppDrainData: Identifiable, Hashable {
    let id = UUID()
    let appName: String
    let iconName: String
    let drainPercentage: Double
    let sparklineData: [Double] // Last 3 hours
    
    init(appName: String, iconName: String, drainPercentage: Double, sparklineData: [Double] = []) {
        self.appName = appName
        self.iconName = iconName
        self.drainPercentage = drainPercentage
        self.sparklineData = sparklineData.isEmpty ? Array(repeating: drainPercentage, count: 12) : sparklineData
    }
}

// MARK: - History Data
struct HistoryDataPoint: Identifiable, Hashable {
    let id = UUID()
    let timestamp: Date
    let value: Double
    let category: String?
    
    init(timestamp: Date, value: Double, category: String? = nil) {
        self.timestamp = timestamp
        self.value = value
        self.category = category
    }
}

// MARK: - Subscription Models
enum SubscriptionTier: String, CaseIterable {
    case free = "free"
    case plus = "plus"
    case pro = "pro"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .plus: return "Plus"
        case .pro: return "Pro"
        }
    }
    
    var chipColor: String {
        switch self {
        case .free: return "accentLow"
        case .plus: return "accentMed"
        case .pro: return "accentHigh"
        }
    }
}

struct SubscriptionInfo {
    let tier: SubscriptionTier
    let expirationDate: Date?
    let features: [String]
    
    init(tier: SubscriptionTier = .free, expirationDate: Date? = nil, features: [String] = []) {
        self.tier = tier
        self.expirationDate = expirationDate
        self.features = features
    }
}

// MARK: - Watch Connectivity Models
struct WatchData: Codable {
    let batteryMode: String
    let isReachable: Bool
    let lastSync: Date
    
    init(batteryMode: BatteryMode = .balanced, isReachable: Bool = false, lastSync: Date = Date()) {
        self.batteryMode = batteryMode.rawValue
        self.isReachable = isReachable
        self.lastSync = lastSync
    }
}
