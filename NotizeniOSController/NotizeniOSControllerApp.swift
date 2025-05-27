//
//  NotizeniOSControllerApp.swift
//  NotizeniOSController
//
//  Created by Wesley Lagarde on 5/26/25.
//

import SwiftUI
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

@main
struct NotizeniOSControllerApp: App {
    
    init() {
        // Activate WatchConnectivity early in app lifecycle
        #if canImport(WatchConnectivity)
        if WCSession.isSupported() {
            WatchConnectivityManager.shared.activateSession()
            print("iOS App: WatchConnectivity activated at launch")
        }
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
