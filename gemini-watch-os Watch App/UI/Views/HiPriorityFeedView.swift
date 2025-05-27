
// filepath: /Users/wes/Desktop/NotiZeniOS/NotiZenWatch Watch App/UI/Views/HiPriorityFeedView.swift
import SwiftUI

struct HiPriorityFeedView: View {
    @EnvironmentObject var appState: WatchAppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            if appState.highPriorityFeed.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(DesignTokens.Color.accentHigh)
                    
                    Text("All Caught Up!")
                        .font(DesignTokens.Typography.watchTitle)
                        .foregroundColor(DesignTokens.Color.accentHigh)
                    
                    Text("No high priority notifications")
                        .font(DesignTokens.Typography.watchCaption)
                        .foregroundColor(DesignTokens.Color.accentLow)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ForEach(appState.highPriorityFeed) { notification in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(notification.title ?? "High Priority Alert")
                                    .font(DesignTokens.Typography.watchHeadline)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                
                                Text(notification.appName)
                                    .font(DesignTokens.Typography.watchCaption)
                                    .foregroundColor(DesignTokens.Color.accentMed)
                            }
                            
                            Spacer()
                            
                            VStack {
                                Image(systemName: appIconName(for: notification.category))
                                    .font(.title2)
                                    .foregroundColor(priorityColor(for: notification.score))
                                
                                Text(timeAgo(from: notification.date))
                                    .font(DesignTokens.Typography.watchCaption)
                                    .foregroundColor(DesignTokens.Color.accentLow)
                            }
                        }
                        
                        if !notification.message.isEmpty {
                            Text(notification.message)
                                .font(DesignTokens.Typography.watchFootnote)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                                .padding(.top, 2)
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            archiveNotification(notification.id)
                        } label: {
                            Label("Archive", systemImage: "archivebox.fill")
                        }
                        .tint(DesignTokens.Color.accentLow)
                    }
                }
            }
        }
        .navigationTitle("High Priority")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .topLeading) { // PRD A4: top left corner shows tiny battery meter
            HStack {
                Image(systemName: "battery.100") // Icon will change based on actual level
                    .font(.caption2) // Make it tiny
                    .foregroundColor(batteryColor())
                Text("\(Int(appState.batteryPercentage * 100))%")
                    .font(.caption2)
                    .foregroundColor(batteryColor())
            }
            .padding(.leading, DesignTokens.Layout.safeAreaInset) // Use design token for padding
            .padding(.top, 6) // Adjust to look good with inline title
        }
    }

    private func appIconName(for category: String?) -> String {
        guard let category = category else { return "app.dashed" }
        switch category.lowercased() {
        case "finance":
            return "creditcard.fill"
        case "security":
            return "lock.shield.fill"
        case "work":
            return "briefcase.fill"
        case "messages":
            return "message.fill"
        default:
            return "app.fill"
        }
    }

    private func archiveNotification(_ id: UUID) {
        appState.archiveNotification(id: id)
        // Optionally, add haptic feedback as per general guidelines if applicable
        WKInterfaceDevice.current().play(.success) // Or a more appropriate haptic
    }
    
    private func batteryColor() -> Color {
        let percentage = appState.batteryPercentage
        if percentage < 0.2 {
            return DesignTokens.Color.error
        } else if percentage < 0.5 {
            return .yellow // Standard yellow for warning
        }
        return DesignTokens.Color.accentHigh // Green for good battery
    }
    
    private func priorityColor(for score: Double) -> Color {
        if score >= 0.7 {
            return DesignTokens.Color.error
        } else if score >= 0.5 {
            return DesignTokens.Color.accentMed
        } else {
            return DesignTokens.Color.accentLow
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        
        if minutes < 60 {
            return "\(minutes)m"
        } else if hours < 24 {
            return "\(hours)h"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d"
        }
    }
}

struct HiPriorityFeedView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = WatchAppState()
        // Populate with some data for preview
        appState.highPriorityFeed = [
            NotificationEvent(id: UUID(), date: Date(), appName: "Mail", bundleID: "com.apple.mail", title: "Re: Project Phoenix Deadline", message: "The project deadline has been moved to tomorrow.", category: "Work", score: 0.92),
            NotificationEvent(id: UUID(), date: Date().addingTimeInterval(-300), appName: "MyBank", bundleID: "com.mybank.app", title: "Large transaction detected on your account ending 4321.", message: "$2,500 transaction at Amazon.com", category: "Finance", score: 0.95),
            NotificationEvent(id: UUID(), date: Date().addingTimeInterval(-600), appName: "HomeSecurity", bundleID: "com.homesecurity.cam", title: "Motion detected: Front Door", message: "Person detected at front door", category: "Security", score: 0.99)
        ]
        appState.batteryPercentage = 0.75
        
        return NavigationStack { // Wrap in NavigationStack for preview title
            HiPriorityFeedView()
                .environmentObject(appState)
        }
    }
}
