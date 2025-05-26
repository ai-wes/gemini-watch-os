//
//  NotiZenWatchApp.swift
//  NotiZenWatch Watch App
//
//  Created by Wesley Lagarde on 5/24/25.
//

import SwiftUI

@main
struct NotiZenWatch_Watch_AppApp: App {
    @StateObject private var appState = WatchAppState() // Create and manage the app state

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(appState) // Inject into the environment
        }
    }
}
