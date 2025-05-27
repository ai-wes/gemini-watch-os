import Foundation
import UIKit
import Combine

@MainActor
class BatteryMonitoringService: ObservableObject {
    static let shared = BatteryMonitoringService()
    
    @Published var currentBatteryData: BatteryData
    
    weak var appState: AppState?
    private var batteryMonitoringTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Initialize with current device battery state
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        self.currentBatteryData = BatteryData(
            level: Double(UIDevice.current.batteryLevel * 100),
            isCharging: UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full,
            estimatedHours: 8.0, // Default estimate
            timestamp: Date()
        )
        
        setupBatteryMonitoring()
    }
    
    func setup(with appState: AppState) {
        self.appState = appState
        startBatteryMonitoring()
    }
    
    private func setupBatteryMonitoring() {
        // Enable battery monitoring
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        // Subscribe to battery level changes
        NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateBatteryData()
            }
            .store(in: &cancellables)
        
        // Subscribe to battery state changes
        NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateBatteryData()
            }
            .store(in: &cancellables)
    }
    
    private func startBatteryMonitoring() {
        // Start periodic battery monitoring
        batteryMonitoringTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.updateBatteryData()
        }
        
        // Initial update
        updateBatteryData()
    }
    
    private func updateBatteryData() {
        let device = UIDevice.current
        let level = Double(device.batteryLevel * 100)
        let isCharging = device.batteryState == .charging || device.batteryState == .full
        
        // Calculate estimated hours based on historical data and current usage
        let estimatedHours = calculateEstimatedHours(currentLevel: level, isCharging: isCharging)
        
        let newBatteryData = BatteryData(
            level: level,
            isCharging: isCharging,
            estimatedHours: estimatedHours,
            timestamp: Date()
        )
        
        currentBatteryData = newBatteryData
        appState?.batteryData = newBatteryData
        
        // Update battery history
        updateBatteryHistory(newBatteryData)
        
        // Update top drain apps (simplified - in a real app this would use more detailed analytics)
        updateTopDrainApps()
        
        print("iOS: Battery updated - Level: \(Int(level))%, Charging: \(isCharging), Estimated: \(Int(estimatedHours))h")
    }
    
    private func calculateEstimatedHours(currentLevel: Double, isCharging: Bool) -> Double {
        guard let appState = appState else { return 8.0 }
        
        if isCharging {
            // If charging, estimate time to full charge
            let remainingToCharge = 100.0 - currentLevel
            return remainingToCharge / 25.0 // Rough estimate: 25% per hour
        }
        
        // Calculate drain rate from historical data
        let recentHistory = appState.batteryHistory.suffix(5) // Last 5 data points
        
        if recentHistory.count >= 2 {
            let timeSpan = recentHistory.last!.timestamp.timeIntervalSince(recentHistory.first!.timestamp)
            let levelDrop = recentHistory.first!.value - recentHistory.last!.value
            
            if timeSpan > 0 && levelDrop > 0 {
                let drainRatePerHour = levelDrop / (timeSpan / 3600)
                return currentLevel / drainRatePerHour
            }
        }
        
        // Fallback to battery mode-based estimates
        switch appState.batterySettings.mode {
        case .performance:
            return currentLevel / 12.5 // ~8 hour total life
        case .balanced:
            return currentLevel / 10.0 // ~10 hour total life
        case .runtimePlus:
            return currentLevel / 8.33 // ~12 hour total life
        }
    }
    
    private func updateBatteryHistory(_ batteryData: BatteryData) {
        guard let appState = appState else { return }
        
        // Add new data point to history
        let historyPoint = HistoryDataPoint(timestamp: batteryData.timestamp, value: batteryData.level)
        appState.batteryHistory.append(historyPoint)
        
        // Keep only last 24 hours of data
        let oneDayAgo = Date().addingTimeInterval(-24 * 3600)
        appState.batteryHistory = appState.batteryHistory.filter { $0.timestamp >= oneDayAgo }
        
        // Save to persistence
        saveBatteryHistory()
    }
    
    private func updateTopDrainApps() {
        guard let appState = appState else { return }
        
        // In a real implementation, this would use actual app usage statistics
        // For now, we'll simulate based on common patterns
        let simulatedDrainApps = [
            AppDrainData(appName: "Display", iconName: "sun.max", drainPercentage: 25.3),
            AppDrainData(appName: "Background App Refresh", iconName: "arrow.clockwise", drainPercentage: 18.7),
            AppDrainData(appName: "Cellular", iconName: "antenna.radiowaves.left.and.right", drainPercentage: 15.2),
            AppDrainData(appName: "Location Services", iconName: "location", drainPercentage: 12.1),
            AppDrainData(appName: "Audio", iconName: "speaker.wave.2", drainPercentage: 8.9)
        ]
        
        appState.topDrainApps = simulatedDrainApps
    }
    
    private func saveBatteryHistory() {
        guard let appState = appState else { return }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(appState.batteryHistory)
            UserDefaults.standard.set(data, forKey: "batteryHistory")
        } catch {
            print("Failed to save battery history: \(error)")
        }
    }
    
    deinit {
        batteryMonitoringTimer?.invalidate()
        UIDevice.current.isBatteryMonitoringEnabled = false
    }
}