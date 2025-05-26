//
//  ContentView.swift
//  NotiZenWatch Watch App
//
//  Created by Wesley Lagarde on 5/24/25.
//

import SwiftUI

// Renamed from ContentView to DashboardView
// PRD A2: Dashboard (push root)
struct DashboardView: View {
    // Dummy data for now - will be replaced by data from AppState/ViewModel
    @State private var unreadHighPriorityCount: Int = 2
    @State private var latestHighPriorityMessage: String = "Wire transfer..."
    @State private var batteryHoursRemaining: Int = 18
    
    // Dummy notification list items
    struct WatchNotificationItem: Identifiable {
        let id = UUID()
        let appName: String
        let messageSummary: String
        let iconName: String // SF Symbol name
    }
    
    @State private var notifications: [WatchNotificationItem] = [
        WatchNotificationItem(appName: "Messages", messageSummary: "1 new", iconName: "message.fill"),
        WatchNotificationItem(appName: "Finance", messageSummary: "-", iconName: "creditcard.fill"),
        WatchNotificationItem(appName: "Social", messageSummary: "5 mut...", iconName: "person.2.fill"),
        WatchNotificationItem(appName: "Calendar", messageSummary: "Event starting soon", iconName: "calendar"),
        WatchNotificationItem(appName: "Mail", messageSummary: "New important email", iconName: "envelope.fill")
    ]

    var body: some View {
        NavigationView { // Or ScrollView if full-screen scrolling is preferred over title bar
            List {
                // PRD A2: Horizontally-scrolling Cards
                Section {
                    TabView {
                        UnreadHighCardView(
                            count: unreadHighPriorityCount, 
                            latestMessage: latestHighPriorityMessage
                        )
                        BatteryHoursCardView(hours: batteryHoursRemaining)
                    }
                    .frame(height: 100) // Adjust height as needed for watch cards
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                .padding(.horizontal, -LayoutTokens.watchSafePadding) // Counteract list padding for full-width cards
                
                // PRD A2: List of notifications (up to 8 rows)
                Section {
                    ForEach(notifications.prefix(8)) { notification in
                        NotificationRowView(notification: notification)
                    }
                }
            }
            // .navigationTitle("Dashboard") // Optional title
            .listStyle(.carousel) // More appropriate for top-level watchOS navigation
        }
    }
}

// Placeholder for UnreadHighCardView
struct UnreadHighCardView: View {
    let count: Int
    let latestMessage: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "bell.badge.fill") // PRD Iconography
                    .foregroundColor(Color.accentHigh) // PRD Palette
                Text("\(count) critical")
                    .font(.watchHeadline) // PRD Typography
            }
            Text(latestMessage)
                .font(.watchCaption)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(LayoutTokens.spacing2) // PRD Grid
        .background(Color.tileDark) // PRD Palette
        .cornerRadius(LayoutTokens.cornerRadius) // PRD Shapes
    }
}

// Placeholder for BatteryHoursCardView
struct BatteryHoursCardView: View {
    let hours: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "bolt.fill") // PRD Iconography
                    .foregroundColor(Color.accentMed) // PRD Palette
                Text("\(hours) h")
                    .font(.watchHeadline) // PRD Typography (Marble Number is larger, might be for a detail view)
            }
            Text("Estimated remaining")
                .font(.watchCaption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(LayoutTokens.spacing2)
        .background(Color.tileDark)
        .cornerRadius(LayoutTokens.cornerRadius)
    }
}

// Placeholder for NotificationRowView
struct NotificationRowView: View {
    let notification: DashboardView.WatchNotificationItem
    
    var body: some View {
        HStack {
            Image(systemName: notification.iconName)
                .frame(width: 20, alignment: .center)
            VStack(alignment: .leading) {
                Text(notification.appName)
                    .font(.watchBody) // PRD Typography
                Text(notification.messageSummary)
                    .font(.watchCaption)
                    .foregroundColor(.accentLow)
            }
            Spacer()
        }
        .padding(.vertical, LayoutTokens.spacing1)
    }
}

#Preview {
    DashboardView()
}
