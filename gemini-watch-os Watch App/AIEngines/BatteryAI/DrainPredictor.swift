//
// filepath: /Users/wes/Desktop/NotiZeniOS/NotiZenWatch Watch App/AIEngines/BatteryAI/DrainPredictor.swift
import Foundation
import WatchKit

/// `DrainPredictor` analyzes historical battery data (collected by `BatterySampler`)
/// to predict future battery drain patterns and estimate remaining battery life.
/// It might use simple linear regression, or more complex models if feasible.
class DrainPredictor {

    // MARK: - Properties
    
    private var snapshots: [BatterySnapshot] = []
    private let maxSnapshots = 288 // Keep 24 hours of 5-min interval data

    // MARK: - Initialization
    
    init() {
        // TODO: Load historical data and initialize/train the prediction model.
        // This might involve fetching from a persistent store (Core Data).
        print("DrainPredictor initialized.")
        // loadHistoricalData() 
    }

    // MARK: - Prediction Logic

    /// Updates the predictor with a new battery snapshot.
    /// - Parameter snapshot: The `BatterySnapshot` to add to the historical data.
    func addSnapshot(_ snapshot: BatterySnapshot) {
        snapshots.append(snapshot)
        
        // Keep historical data to a manageable size
        if snapshots.count > maxSnapshots {
            snapshots.removeFirst(snapshots.count - maxSnapshots)
        }
        
        print("DrainPredictor: Added new snapshot at \(snapshot.date) with level \(String(format: "%.1f", snapshot.level * 100))%")
    }
    
    /// Updates the predictor with multiple battery snapshots.
    /// - Parameter snapshots: An array of `BatterySnapshot` to add.
    func addSnapshots(_ snapshots: [BatterySnapshot]) {
        // historicalSnapshots.append(contentsOf: snapshots)
        // // Sort by date if not already sorted, and manage size
        // historicalSnapshots.sort { $0.date < $1.date }
        // if historicalSnapshots.count > 1000 { // Example limit
        //     historicalSnapshots.removeFirst(historicalSnapshots.count - 1000)
        // }
        // updateModel()
        let count = snapshots.count
        print("DrainPredictor: Added \(count) new snapshots.")
    }

    /// Predicts the estimated time remaining until the battery is depleted.
    /// - Parameter currentLevel: The current battery level (0.0 to 1.0).
    /// - Parameter chargingState: The current charging state of the device.
    /// - Returns: A `TimeInterval` representing the estimated time remaining, or `nil` if prediction is not possible.
    func estimateTimeRemaining(currentLevel: Double, /* currentChargingState: WKInterfaceDevice.BatteryState */_ currentChargingState: Int) -> TimeInterval? {
        // TODO: Implement prediction logic.
        // 1. If charging, time remaining is effectively infinite or until full.
        // 2. If not enough historical data, return nil.
        // 3. Use the model to predict drain rate based on recent patterns.
        // 4. Calculate time remaining based on currentLevel and predicted drain rate.

        // if currentChargingState == .charging || currentChargingState == .full {
        //     return TimeInterval.infinity // Or a very large number, or specific logic for time to full
        // }
        
        // guard historicalSnapshots.count >= 2 else {
        //     print("DrainPredictor: Not enough historical data to make a prediction.")
        //     return nil
        // }
        
        // // Simple linear extrapolation based on the last two points (very basic example)
        // let lastSnapshot = historicalSnapshots.last!
        // let previousSnapshot = historicalSnapshots[historicalSnapshots.count - 2]
        
        // let levelDrop = previousSnapshot.level - lastSnapshot.level
        // let timeDiff = lastSnapshot.date.timeIntervalSince(previousSnapshot.date)
        
        // if levelDrop <= 0 || timeDiff <= 0 { // No drop or invalid data
        //     // Could try to find a more stable period if recent data is noisy
        //     print("DrainPredictor: No significant drain detected recently or data anomaly.")
        //     return nil // Or a very long time if level is stable and high
        // }
        
        // let drainRatePerSecond = levelDrop / timeDiff // e.g., 0.0001 per second (0.01% per second)
        // let remainingTimeInSeconds = currentLevel / drainRatePerSecond
        
        // print("DrainPredictor: Estimated \(remainingTimeInSeconds / 3600) hours remaining.")
        // return remainingTimeInSeconds
        
        guard currentLevel > 0.0 else { return 0 } // Battery is empty
        
        // If charging, return nil as we're gaining power
        if currentChargingState == WKInterfaceDeviceBatteryState.charging.rawValue || 
           currentChargingState == WKInterfaceDeviceBatteryState.full.rawValue {
            return nil
        }
        
        // Need at least 2 snapshots to calculate drain rate
        guard snapshots.count >= 2 else {
            // Use default drain rate for Apple Watch (roughly 18 hours battery life)
            let defaultDrainRatePerHour = 1.0 / 18.0 // 1/18th per hour = ~18 hours total
            let hoursRemaining = currentLevel / defaultDrainRatePerHour
            print("DrainPredictor: Using default drain rate, estimated \(String(format: "%.1f", hoursRemaining)) hours remaining.")
            return hoursRemaining * 3600
        }
        
        // Calculate actual drain rate from recent snapshots
        let recentSnapshots = Array(snapshots.suffix(min(12, snapshots.count))) // Last 12 samples (1 hour if 5-min intervals)
        
        // Find the drain rate (level decrease per second)
        var totalDrain: Double = 0
        var totalTime: TimeInterval = 0
        
        for i in 1..<recentSnapshots.count {
            let currentSnapshot = recentSnapshots[i]
            let previousSnapshot = recentSnapshots[i-1]
            
            // Only count if not charging during this period
            if currentSnapshot.chargingState == WKInterfaceDeviceBatteryState.unplugged.rawValue &&
               previousSnapshot.chargingState == WKInterfaceDeviceBatteryState.unplugged.rawValue {
                
                let timeDiff = currentSnapshot.date.timeIntervalSince(previousSnapshot.date)
                let levelDiff = previousSnapshot.level - currentSnapshot.level // Positive if draining
                
                if timeDiff > 0 && levelDiff >= 0 { // Only count valid drain periods
                    totalDrain += levelDiff
                    totalTime += timeDiff
                }
            }
        }
        
        guard totalTime > 0 && totalDrain > 0 else {
            // Fall back to default if no valid drain data
            let defaultDrainRatePerHour = 1.0 / 18.0
            let hoursRemaining = currentLevel / defaultDrainRatePerHour
            print("DrainPredictor: No valid drain data, using default rate.")
            return hoursRemaining * 3600
        }
        
        let drainRatePerSecond = totalDrain / totalTime
        let secondsRemaining = currentLevel / drainRatePerSecond
        let hoursRemaining = secondsRemaining / 3600
        
        print("DrainPredictor: Calculated drain rate: \(String(format: "%.4f", drainRatePerSecond * 3600))%/hour, estimated \(String(format: "%.1f", hoursRemaining)) hours remaining.")
        
        return secondsRemaining
    }

    /// Updates or retrains the internal prediction model based on `historicalSnapshots`.
    private func updateModel() {
        // TODO: Implement model training/updating logic.
        // This could be as simple as calculating an average drain rate,
        // or as complex as training a machine learning model.
        // For on-device, simpler models are generally preferred for performance and battery life.
        print("DrainPredictor: Updating prediction model (not implemented).")
    }
    
    /// Loads historical battery data from persistence.
    private func loadHistoricalData() {
        // TODO: Implement loading from Core Data or other storage.
        // self.historicalSnapshots = MyDataManager.shared.fetchAllBatterySnapshots()
        print("DrainPredictor: Loading historical data (not implemented).")
    }

    // MARK: - Deinitialization
    
    deinit {
        // Perform any cleanup if necessary.
        print("DrainPredictor deinitialized.")
    }
}
