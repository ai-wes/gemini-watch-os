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

    init() {
        // Activate WatchConnectivity early in app lifecycle (watchOS)
        #if canImport(WatchConnectivity)
        if WCSession.isSupported() {
            print("Watch App: Activating WatchConnectivity at launch")
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState) // Inject into the environment
        }
    }
}
