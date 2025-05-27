import SwiftUI

// This ContentView can serve as a wrapper or initial navigation point if DashboardView becomes more complex
// or if other initial views are needed before the dashboard.
struct ContentView: View {
    @EnvironmentObject var appState: WatchAppState

    var body: some View {
        NavigationView {
            TabView {
                // Dashboard View
                DashboardView()
                    .tag(0)

                // Settings View
                SettingsMenuView()
                    .tag(1)
            }
            .tabViewStyle(.page)
        }
        .sheet(isPresented: $appState.shouldShowDigestPreviewSheet) {
            DigestPreviewSheetView()
                .environmentObject(appState)
        }
    }
}

#Preview {
    ContentView()
}
