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
    private var sessionDelegate = WatchSessionDelegate()

    init() {
        // Activate WatchConnectivity early in app lifecycle (watchOS)
        #if canImport(WatchConnectivity)
        if WCSession.isSupported() {
            print("Watch App: Activating WatchConnectivity at launch")
            // WatchConnectivityManager.shared.activateSession() // Assuming this might fail
            let session = WCSession.default
            session.delegate = sessionDelegate
            session.activate()
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

#if canImport(WatchConnectivity)
class WatchSessionDelegate: NSObject, WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("Watch App: WCSession activation failed with error: \(error.localizedDescription)")
            return
        }
        print("Watch App: WCSession activated with state: \(activationState.rawValue)")
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("Watch App: WCSession reachability changed to: \(session.isReachable)")
    }
}
#endif
