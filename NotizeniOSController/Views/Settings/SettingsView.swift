import SwiftUI

#if canImport(MessageUI)
import MessageUI
#endif

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingPaywall = false
    @State private var showingMailComposer = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    
    var body: some View {
        NavigationStack {
            List {
                // Watch Link Section
                Section {
                    WatchLinkRowView()
                } header: {
                    Text("Watch Connection")
                }
                .listRowBackground(Color.tileDark)
                
                // Watch Settings Section
                Section {
                    WatchSettingsView()
                } header: {
                    Text("Watch Settings")
                }
                .listRowBackground(Color.tileDark)
                
                // Subscription Section
                Section {
                    SubscriptionRowView(subscription: appState.subscription) {
                        showingPaywall = true
                    }
                } header: {
                    Text("Subscription")
                }
                .listRowBackground(Color.tileDark)
                
                // Support Section
                Section {
                    SupportRowView(title: "Export Logs", icon: "doc.text") {
                        exportLogs()
                    }
                    
                    SupportRowView(title: "Report Bug", icon: "envelope") {
                        showingMailComposer = true
                    }
                    
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.accentMed)
                            .frame(width: 24)
                        
                        Text("Version")
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("1.0.0 (1)")
                            .foregroundColor(.accentLow)
                    }
                } header: {
                    Text("Support")
                }
                .listRowBackground(Color.tileDark)
            }
            .scrollContentBackground(.hidden)
            .background(Color.surfaceDark)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showingMailComposer) {
            MailComposerView(result: $mailResult)
        }
    }
    
    private func exportLogs() {
        // Generate comprehensive log data
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        
        let logData = """
        NotiZen App Logs
        ================
        
        Export Date: \(formatter.string(from: Date()))
        App Version: 1.0.0 (1)
        Device: \(UIDevice.current.model)
        iOS Version: \(UIDevice.current.systemVersion)
        
        === BATTERY DATA ===
        Current Level: \(Int(appState.batteryData.level))%
        Is Charging: \(appState.batteryData.isCharging)
        Estimated Hours: \(appState.batteryData.estimatedHours)
        Battery Mode: \(appState.batterySettings.mode.displayName)
        Smart Low Power: \(appState.batterySettings.smartLowPowerEnabled)
        Low Power Threshold: \(appState.batterySettings.lowPowerThreshold)%
        
        === NOTIFICATIONS ===
        Total Notifications: \(appState.notifications.count)
        High Priority: \(appState.highPriorityCount)
        Unread Count: \(appState.unreadCount)
        
        === CATEGORIES ===
        Total Categories: \(appState.categories.count)
        \(appState.categories.map { "\($0.name): Priority \(Int($0.priority))" }.joined(separator: "\n"))
        
        === WATCH CONNECTIVITY ===
        Watch Connected: \(appState.watchData.isReachable)
        Last Sync: \(formatter.string(from: appState.watchData.lastSync))
        Watch Battery Mode: \(appState.watchData.batteryMode)
        
        === HISTORY DATA ===
        Battery History Points: \(appState.batteryHistory.count)
        Notification History Points: \(appState.notificationHistory.count)
        
        === RECENT ACTIVITY ===
        - Dashboard viewed
        - Settings accessed
        - Log export requested
        - Watch sync status checked
        """
        
        let activityController = UIActivityViewController(
            activityItems: [logData],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityController, animated: true)
        }
        
        HapticManager.shared.soft()
    }
}

struct WatchLinkRowView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: LayoutTokens.spacing3) {
            // Reachability Status
            HStack {
                Image(systemName: "applewatch")
                    .foregroundColor(.accentMed)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Watch")
                        .foregroundColor(.white)
                    Text("Last sync: \(lastSyncText)")
                        .font(.caption)
                        .foregroundColor(.accentLow)
                }
                
                Spacer()
                
                StatusChip(
                    text: appState.watchData.isReachable ? "Connected" : "Disconnected",
                    color: appState.watchData.isReachable ? .accentHigh : .accentLow
                )
            }
            
            // Action Buttons
            HStack(spacing: LayoutTokens.spacing3) {
                Button("Test Connection") {
                    appState.sendTestPingToWatch()
                }
                .font(.footnote)
                .foregroundColor(.accentMed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, LayoutTokens.spacing2)
                .background(
                    RoundedRectangle(cornerRadius: LayoutTokens.spacing2)
                        .fill(Color.accentMed.opacity(0.1))
                )
                
                Button("Force Sync") {
                    appState.syncAllDataToWatch()
                }
                .font(.footnote)
                .foregroundColor(.accentHigh)
                .frame(maxWidth: .infinity)
                .padding(.vertical, LayoutTokens.spacing2)
                .background(
                    RoundedRectangle(cornerRadius: LayoutTokens.spacing2)
                        .fill(Color.accentHigh.opacity(0.1))
                )
            }
        }
    }
    
    private var lastSyncText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: appState.watchData.lastSync)
    }
}

struct WatchSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var autoSyncEnabled = true
    @State private var syncBatteryData = true
    @State private var syncNotifications = true
    @State private var syncCategories = true
    
    var body: some View {
        VStack(spacing: LayoutTokens.spacing4) {
            // Auto Sync Toggle
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Auto Sync")
                        .foregroundColor(.white)
                    Text("Automatically sync settings to watch")
                        .font(.caption)
                        .foregroundColor(.accentLow)
                }
                
                Spacer()
                
                Toggle("", isOn: $autoSyncEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: .accentMed))
            }
            
            Divider()
                .background(Color.accentLow.opacity(0.3))
            
            // Sync Options
            VStack(spacing: LayoutTokens.spacing3) {
                Text("Sync Options")
                    .font(.footnote)
                    .foregroundColor(.accentLow)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: LayoutTokens.spacing2) {
                    SyncOptionRow(
                        title: "Battery Data",
                        description: "Share battery level and drain data",
                        isEnabled: $syncBatteryData
                    )
                    
                    SyncOptionRow(
                        title: "Notifications",
                        description: "Sync notification history and counts",
                        isEnabled: $syncNotifications
                    )
                    
                    SyncOptionRow(
                        title: "Categories",
                        description: "Share category preferences and priorities",
                        isEnabled: $syncCategories
                    )
                }
            }
        }
    }
}

struct SyncOptionRow: View {
    let title: String
    let description: String
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.white)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.accentLow)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .accentMed))
                .onChange(of: isEnabled) { _, _ in
                    HapticManager.shared.soft()
                }
        }
    }
}

struct SubscriptionRowView: View {
    let subscription: SubscriptionInfo
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.accentMed)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Subscription")
                        .foregroundColor(.white)
                    
                    Text(subscriptionStatus)
                        .font(.caption)
                        .foregroundColor(.accentLow)
                }
                
                Spacer()
                
                StatusChip(
                    text: subscription.tier.displayName,
                    color: chipColor
                )
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.accentLow)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var subscriptionStatus: String {
        switch subscription.tier {
        case .free:
            return "Limited features available"
        case .plus:
            return "Access to premium features"
        case .pro:
            return "Full feature access"
        }
    }
    
    private var chipColor: Color {
        switch subscription.tier {
        case .free:
            return .accentLow
        case .plus:
            return .accentMed
        case .pro:
            return .accentHigh
        }
    }
}

struct SupportRowView: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentMed)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.accentLow)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatusChip: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, LayoutTokens.spacing2)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color.opacity(0.2))
            )
            .overlay(
                Capsule()
                    .stroke(color, lineWidth: 1)
            )
    }
}

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    let features = [
        "Unlimited categories",
        "Advanced battery monitoring",
        "Custom notification rules",
        "Export history data",
        "Priority learning AI",
        "Watch complications"
    ]
    
    var body: some View {
        NavigationStack {
            TabView(selection: $currentPage) {
                // Intro Page
                VStack(spacing: LayoutTokens.spacing6) {
                    Spacer()
                    
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.accentHigh)
                    
                    Text("Unlock NotiZen Plus")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    VStack(alignment: .leading, spacing: LayoutTokens.spacing3) {
                        ForEach(features, id: \.self) { feature in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentHigh)
                                Text(feature)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, LayoutTokens.safePadding)
                .tag(0)
                
                // Pricing Page
                VStack(spacing: LayoutTokens.spacing6) {
                    Spacer()
                    
                    Text("Choose Your Plan")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: LayoutTokens.spacing4) {
                        // Annual Plan (Recommended)
                        PricingCardView(
                            title: "Annual",
                            price: "$19.00",
                            period: "per year",
                            savings: "Save 37%",
                            isRecommended: true
                        )
                        
                        // Monthly Plan
                        PricingCardView(
                            title: "Monthly",
                            price: "$2.99",
                            period: "per month",
                            savings: nil,
                            isRecommended: false
                        )
                    }
                    
                    Button("Continue") {
                        // Handle purchase
                        purchaseSubscription()
                    }
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LayoutTokens.spacing4)
                    .background(Color.accentHigh)
                    .cornerRadius(LayoutTokens.cornerRadius)
                    
                    Button("Restore Purchases") {
                        // Handle restore
                        restorePurchases()
                    }
                    .font(.footnote)
                    .foregroundColor(.accentMed)
                    
                    Spacer()
                }
                .padding(.horizontal, LayoutTokens.safePadding)
                .tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .background(Color.surfaceDark)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.accentMed)
                }
            }
        }
    }
    
    private func purchaseSubscription() {
        // In a real app, this would handle the actual purchase
        withAnimation(.spring()) {
            // Show success animation
            HapticManager.shared.success()
        }
        
        // Simulate success and dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            dismiss()
        }
    }
    
    private func restorePurchases() {
        // In a real app, this would restore purchases
        HapticManager.shared.soft()
    }
}

struct PricingCardView: View {
    let title: String
    let price: String
    let period: String
    let savings: String?
    let isRecommended: Bool
    
    var body: some View {
        VStack(spacing: LayoutTokens.spacing3) {
            if isRecommended {
                Text("RECOMMENDED")
                    .font(.caption)
                    .foregroundColor(.accentHigh)
                    .padding(.horizontal, LayoutTokens.spacing3)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.accentHigh.opacity(0.2))
                    )
            }
            
            Text(title)
                .font(.title)
                .foregroundColor(.white)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(price)
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Text(period)
                    .font(.footnote)
                    .foregroundColor(.accentLow)
            }
            
            if let savings = savings {
                Text(savings)
                    .font(.caption)
                    .foregroundColor(.accentHigh)
            }
        }
        .padding(LayoutTokens.spacing5)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: LayoutTokens.cornerRadius)
                .fill(Color.tileDark)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutTokens.cornerRadius)
                        .stroke(isRecommended ? Color.accentHigh : Color.clear, lineWidth: 2)
                )
        )
    }
}

struct MailComposerView: UIViewControllerRepresentable {
    @Binding var result: Result<MFMailComposeResult, Error>?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setSubject("NotiZen Bug Report")
        composer.setToRecipients(["support@notizen.app"])
        composer.setMessageBody("""
            Please describe the issue you encountered:
            
            
            
            ---
            Device Info:
            Device: \(UIDevice.current.model)
            iOS: \(UIDevice.current.systemVersion)
            App Version: 1.0.0 (1)
            """, isHTML: false)
        
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposerView
        
        init(_ parent: MailComposerView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                parent.result = .failure(error)
            } else {
                parent.result = .success(result)
            }
            parent.dismiss()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
