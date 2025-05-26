
import Foundation

struct BatterySnapshot {
    var date: Date
    var level: Double   // 0…1
    var activeApp: String
    var screenOn: Bool
    var cpuLoad: Double
    var hrRest: Double? // optional
}
