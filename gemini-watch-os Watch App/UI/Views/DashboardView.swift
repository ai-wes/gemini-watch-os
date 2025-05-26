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
    @EnvironmentObject var appState: WatchAppState
    
    var body: some View {
        NavigationView {
            List {
                // PRD A2: Horizontally-scrolling Cards
                Section {
                    TabView {
                        UnreadHighCardView(
                            count: appState.unreadHighPriorityCount, 
                            latestMessage: appState.latestHighPriorityMessage
                        )
                        BatteryHoursCardView(hours: appState.batteryHoursRemaining)
                    }
                    .frame(height: 100) // Adjust height as needed for watch cards
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                .padding(.horizontal, -CGFloat(DesignTokens.Layout.watchSafePadding)) // Fix type conversion
                
                // PRD A2: List of notifications (up to 8 rows)
                Section {
                    ForEach(Array(appState.dashboardNotifications.prefix(8))) { notification in
                        NotificationRowView(notification: notification)
                    }
                }
            }
            .listStyle(.carousel) // More appropriate for top-level watchOS navigation
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(WatchAppState())
}
