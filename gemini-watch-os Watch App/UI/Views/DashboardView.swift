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
        List {
                // PRD A2: Horizontally-scrolling Cards
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            NavigationLink(destination: HiPriorityFeedView()) {
                                UnreadHighCardView(
                                    count: appState.unreadHighPriorityCount, 
                                    latestMessage: appState.latestHighPriorityMessage
                                )
                                .frame(width: 140, height: 80)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            BatteryHoursCardView(
                                hours: appState.batteryHoursRemaining,
                                batteryPercentage: appState.batteryPercentage
                            )
                            .frame(width: 140, height: 80)
                        }
                        .padding(.horizontal)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                .padding(.horizontal, -CGFloat(DesignTokens.Layout.watchSafePadding))
                
                // PRD A2: List of notifications (up to 8 rows)
                Section("Recent Notifications") {
                    if appState.dashboardNotifications.isEmpty {
                        VStack(spacing: 8) {
                            Text("No recent notifications")
                                .foregroundColor(DesignTokens.Color.accentLow)
                                .font(DesignTokens.Typography.watchCaption)
                            
                            Button("Show Digest Preview") {
                                appState.shouldShowDigestPreviewSheet = true
                            }
                            .font(DesignTokens.Typography.watchFootnote)
                            .foregroundColor(DesignTokens.Color.accentMed)
                        }
                    } else {
                        ForEach(Array(appState.dashboardNotifications.prefix(8))) { notification in
                            NotificationRowView(notification: notification)
                        }
                        
                        if appState.currentDigests.count > 0 {
                            NavigationLink(destination: DigestListView()) {
                                HStack {
                                    Text("View All Digests")
                                    Spacer()
                                    Text("\(appState.currentDigests.count)")
                                        .foregroundColor(DesignTokens.Color.accentMed)
                                }
                            }
                        }
                    }
                }
        }
        .listStyle(.carousel) // More appropriate for top-level watchOS navigation
        .navigationTitle("NotiZen")
    }
}

#Preview {
    DashboardView()
        .environmentObject(WatchAppState())
}
