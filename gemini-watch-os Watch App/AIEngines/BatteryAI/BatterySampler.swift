import Foundation
import WatchKit

/// `BatterySampler` is responsible for periodically collecting battery-related data points.
/// This includes battery level, charging state, and potentially other performance metrics
/// that could correlate with battery drain (e.g., CPU usage, screen brightness - though some might be hard to get directly).
class BatterySampler: NSObject {

    // MARK: - Properties
    
    @Published var currentSnapshots: [BatterySnapshot] = []
    private var sampleTimer: Timer?
    private let sampleInterval: TimeInterval = 60 * 5 // Sample every 5 minutes
    private let maxSnapshotsToKeep = 288 // Keep up to 24 hours of 5-min interval data (24 * 12)

    // MARK: - Initialization
    
    override init() {
        super.init()
        WKInterfaceDevice.current().isBatteryMonitoringEnabled = true // Ensure battery monitoring is enabled
        print("BatterySampler initialized. Sampling interval: \(sampleInterval) seconds.")
    }

    // MARK: - Sampling Logic

    /// Starts the periodic collection of battery data.
    func startSampling() {
        guard sampleTimer == nil else {
            print("Battery sampling is already active.")
            return
        }
        
        collectSnapshot() // Initial snapshot
        
        sampleTimer = Timer.scheduledTimer(withTimeInterval: sampleInterval, repeats: true) { [weak self] _ in
            self?.collectSnapshot()
        }
        print("Battery sampling started.")
    }

    /// Stops the periodic collection of battery data.
    func stopSampling() {
        sampleTimer?.invalidate()
        sampleTimer = nil
        print("Battery sampling stopped.")
    }

    /// Collects a single battery snapshot.
    @objc private func collectSnapshot() {
        let device = WKInterfaceDevice.current()
        let batteryLevel = Double(device.batteryLevel) // -1.0 if unknown
        let chargingState = device.batteryState // .unknown, .unplugged, .charging, .full
        let timestamp = Date()

        // Active app and screen state are difficult to get accurately on watchOS without private APIs.
        // We can infer screen state based on app lifecycle if this sampler is tied to the app's active state.
        // For a background sampler, this is harder.
        // CPU load is also not directly available; MetricKit provides aggregated data.

        // Handle unknown battery level more gracefully
        let currentLevel: Double
        if batteryLevel == -1.0 {
            // Try to get the last known level, or use a more realistic default
            currentLevel = currentSnapshots.last?.level ?? 1.0 // Default to full if truly unknown
            print("Warning: Battery level unknown, using last known or default value")
        } else {
            currentLevel = batteryLevel
        }

        let snapshot = BatterySnapshot(
            date: timestamp,
            level: currentLevel,
            chargingState: chargingState.rawValue, // Store the raw Int value
            activeApp: "NotiZenWatch", // Simplification: assume our app if sampling is tied to it
            screenOn: device.batteryState != .unknown, // Simplification: screen is likely on if we can get a state
            cpuLoad: 0.0 // Placeholder; MetricKit is the source for this
        )
        
        DispatchQueue.main.async { // Ensure @Published property is updated on main thread
            self.currentSnapshots.append(snapshot)
            if self.currentSnapshots.count > self.maxSnapshotsToKeep {
                self.currentSnapshots.removeFirst(self.currentSnapshots.count - self.maxSnapshotsToKeep)
            }
        }
        
        print("Collected battery snapshot: Level \(String(format: "%.2f", currentLevel * 100))%, State: \(chargingState.name)")
        // TODO: Persist snapshot to Core Data or other persistent storage.
    }

    // MARK: - Deinitialization
    
    deinit {
        stopSampling()
        print("BatterySampler deinitialized.")
    }
}

extension WKInterfaceDeviceBatteryState {
    var name: String {
        switch self {
        case .unknown: return "Unknown"
        case .unplugged: return "Unplugged"
        case .charging: return "Charging"
        case .full: return "Full"
        @unknown default: return "Undefined"
        }
    }
}
