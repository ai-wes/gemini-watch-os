//
//  NotiZenWatchApp.swift
//  NotiZenWatch Watch App
//
//  Created by Wesley Lagarde on 5/24/25.
//

import SwiftUI
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

@main
struct NotiZenWatch_Watch_AppApp: App {
    @StateObject private var appState = WatchAppState() // Create and manage the app state

    // The init() method is no longer needed as WatchAppState handles WCSession activation.
    // If other setup were needed in init(), it would remain.

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState) // Inject into the environment
        }
    }
}
