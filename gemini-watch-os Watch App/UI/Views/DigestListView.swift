import SwiftUI

// PRD A5: Digest List View (Placeholder for now, to be expanded)
// This view will be shown when the user taps "View List" on the DigestPreviewSheetView.
struct DigestListView: View {
    @EnvironmentObject var appState: WatchAppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
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
                            NotificationRowView(notification: WatchNotificationItem(id: notification.id, title: notification.title ?? notification.appName, messageSnippet: notification.message, timestamp: notification.date, type: .lowPriority)) // Not interactive, just for viewing
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

#if DEBUG
struct DigestListView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = WatchAppState()
        appState.lowPriorityNotifications = [
            NotificationEvent(id: UUID(), date: Date(), appName: "Email", bundleID: "com.email.app", title: "Newsletter", message: "Weekly updates and offers.", category: "Promotions", score: 0.3),
            NotificationEvent(id: UUID(), date: Date().addingTimeInterval(-60*30), appName: "SocialApp", bundleID: "com.social.app", title: "New Follower", message: "Someone followed you.", category: "Social", score: 0.2)
        ]
        return DigestListView()
            .environmentObject(appState)
    }
}
#endif
