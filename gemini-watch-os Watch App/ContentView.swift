import SwiftUI

// This ContentView can serve as a wrapper or initial navigation point if DashboardView becomes more complex
// or if other initial views are needed before the dashboard.
struct ContentView: View {
    @EnvironmentObject var appState: WatchAppState

    var body: some View {
        TabView {
            // Dashboard View
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house")
                }

            // Settings View
            SettingsMenuView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .sheet(isPresented: $appState.shouldShowDigestPreviewSheet) {
            DigestPreviewSheetView()
        }
    }
}

#Preview {
    ContentView()
}
