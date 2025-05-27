
// filepath: /Users/wes/Desktop/NotiZeniOS/NotiZenWatch Watch App/UI/Views/SettingsMenuView.swift
import SwiftUI

// PRD A6: Settings Menu
struct SettingsMenuView: View {
    @EnvironmentObject var appState: WatchAppState
    @Environment(\.dismiss) var dismiss // For dismissing if presented as a sheet

    // Navigation states for sub-screens
    @State private var navigateToCategories = false
    @State private var navigateToDigestTime = false
    @State private var navigateToBatteryGuard = false
    @State private var navigateToAbout = false

    var body: some View {
        List {
                Section(header: Text("Notification Settings").font(DesignTokens.Typography.watchCaption)) {
                    NavigationLink(destination: CategoriesSettingsView()) {
                        Label("Categories", systemImage: "list.bullet.indent")
                    }
                    NavigationLink(destination: DigestTimeSettingsView()) {
                        Label("Digest Time", systemImage: "clock.arrow.2.circlepath")
                    }
                }

                Section(header: Text("System").font(DesignTokens.Typography.watchCaption)) {
                    NavigationLink(destination: BatteryGuardSettingsView()) {
                        Label("Battery Guard", systemImage: "battery.100.bolt")
                    }
                }
                
                Section(header: Text("Application").font(DesignTokens.Typography.watchCaption)) {
                    NavigationLink(destination: AboutSettingsView()) {
                        Label("About NotiZen", systemImage: "info.circle")
                    }
                }
        }
        .navigationTitle("Settings")
        .listStyle(.plain) // Standard for settings menus
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.Color.surfaceDark)
    }
}

// Placeholder Sub-Screen Views (to be implemented in separate files or fleshed out here)

// PRD A6-1: Categories Settings
struct CategoriesSettingsView: View {
    @EnvironmentObject var appState: WatchAppState
    // TODO: Implement category toggling and swipe-to-delete for custom categories
    @State private var categories: [String] = ["Finance", "Social", "Work", "Promotions", "News"]
    @State private var toggles: [Bool] = Array(repeating: true, count: 5)

    var body: some View {
        List {
            ForEach(categories.indices, id: \.self) { index in
                Toggle(categories[index], isOn: $toggles[index])
                    .font(DesignTokens.Typography.watchBody)
                    // TODO: Add swipe to delete for user-added categories
            }
        }
        .navigationTitle("Categories")
        .font(DesignTokens.Typography.watchBody)
    }
}

// PRD A6-2: Digest Time Settings
struct DigestTimeSettingsView: View {
    @EnvironmentObject var appState: WatchAppState
    @State private var digestTime = Date() // Default to current time
    // TODO: Persist this to appState/UserPreferences

    var body: some View {
        Form {
            Section(header: Text("Digest Collection Period").font(DesignTokens.Typography.watchCaption)) {
                DatePicker("Start Time", selection: $appState.digestStartTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                
                DatePicker("End Time", selection: $appState.digestEndTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
            }
            
            Section(footer: Text("Notifications will be collected into digests during this time period").font(DesignTokens.Typography.watchCaption).foregroundColor(DesignTokens.Color.accentLow)) {
                Button("Save Settings") {
                    appState.saveDigestTimePreference()
                    WKInterfaceDevice.current().play(.success)
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(DesignTokens.Color.accentHigh)
            }
        }
        .navigationTitle("Digest Times")
    }
}

// PRD A6-3: Battery Guard Settings
struct BatteryGuardSettingsView: View {
    @EnvironmentObject var appState: WatchAppState
    // TODO: Connect to appState.isBatteryGuardSmartModeEnabled
    // TODO: Implement time-to-empty dial (could be a custom view or simplified text)

    var body: some View {
        Form { // Form style is good for settings
            Section(header: Text("Mode").font(DesignTokens.Typography.watchCaption)) {
                Toggle("Smart Mode", isOn: $appState.isBatteryGuardSmartModeEnabled)
                    .font(DesignTokens.Typography.watchBody)
            }
            
            Section(header: Text("Status").font(DesignTokens.Typography.watchCaption)) {
                VStack(alignment: .leading) {
                    Text("Estimated Time to Empty")
                        .font(DesignTokens.Typography.watchBody)
                    Text("\(formatTimeInterval(appState.estimatedTimeToEmpty))")
                        .font(DesignTokens.Typography.watchTitle) // Larger font for the time
                        .foregroundColor(DesignTokens.Color.accentMed)
                }
                // TODO: Add a visual dial if feasible. For now, text representation.
            }
        }
        .navigationTitle("Battery Guard")
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? "N/A"
    }
}

// About Screen
struct AboutSettingsView: View {
    var body: some View {
        VStack(alignment: .center, spacing: DesignTokens.Layout.spacing2) {
            Image(systemName: "shield.lefthalf.filled") // App icon placeholder
                .font(.system(size: 50))
                .foregroundColor(DesignTokens.Color.accentHigh)
            Text("NotiZen")
                .font(DesignTokens.Typography.watchTitle)
            Text("Version 1.0.0 (Build 1)") // Placeholder version
                .font(DesignTokens.Typography.watchCaption)
            Text("Your intelligent notification companion.")
                .font(DesignTokens.Typography.watchBody)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            Text("© 2025 NotiZen Inc.")
                .font(DesignTokens.Typography.watchFootnote)
        }
        .padding(DesignTokens.Layout.spacing3)
        .navigationTitle("About")
    }
}


#if DEBUG
struct SettingsMenuView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsMenuView()
            .environmentObject(WatchAppState())
    }
}

struct CategoriesSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CategoriesSettingsView()
                .environmentObject(WatchAppState())
        }
    }
}

struct DigestTimeSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DigestTimeSettingsView()
                .environmentObject(WatchAppState())
        }
    }
}

struct BatteryGuardSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BatteryGuardSettingsView()
                .environmentObject(WatchAppState())
        }
    }
}

struct AboutSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AboutSettingsView()
        }
    }
}
#endif
