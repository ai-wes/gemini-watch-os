//
//  ContentView.swift
//  NotiZeniOS
//
//  Created by Wesley Lagarde on 5/24/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "square.grid.2x2")
                    Text("Dashboard")
                }
                .tag(0)
            
            CategoriesView()
                .tabItem {
                    Image(systemName: "bell.badge")
                    Text("Notifications")
                }
                .tag(1)
            
            BatteryView()
                .tabItem {
                    Image(systemName: "bolt.fill")
                    Text("Battery")
                }
                .tag(2)
            
            HistoryView()
                .tabItem {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("History")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .tag(4)
        }
        .environmentObject(appState)
        .onChange(of: selectedTab) { _, _ in
            HapticManager.shared.soft()
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
