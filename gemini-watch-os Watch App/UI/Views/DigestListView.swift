import SwiftUI

// PRD A5: Digest List View (Placeholder for now, to be expanded)
// This view will be shown when the user taps "View List" on the DigestPreviewSheetView.
struct DigestListView: View {
    @EnvironmentObject var appState: WatchAppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                if appState.lowPriorityNotifications.isEmpty {
                    Spacer()
                    Text("No low-priority notifications in the current digest.")
                        .font(DesignTokens.Typography.watchBody)
                        .foregroundColor(DesignTokens.Color.accentLow)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(appState.lowPriorityNotifications) { notification in
                            NotificationRowView(notification: notification, isInteractive: false) // Not interactive, just for viewing
                        }
                    }
                    .listStyle(.carousel)
                }
            }
            .navigationTitle("Digest Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignTokens.Color.surfaceDark.edgesIgnoringSafeArea(.all))
        }
    }
}

#if DEBUG
struct DigestListView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = WatchAppState()
        appState.lowPriorityNotifications = [
            NotificationEvent(appName: "Email", title: "Newsletter", body: "Weekly updates and offers.", timestamp: Date(), category: "Promotions", priority: .low, appIcon: "envelope.fill"),
            NotificationEvent(appName: "SocialApp", title: "New Follower", body: "Someone followed you.", timestamp: Date().addingTimeInterval(-60*30), category: "Social", priority: .low, appIcon: "person.2.fill")
        ]
        return DigestListView()
            .environmentObject(appState)
    }
}
#endif
