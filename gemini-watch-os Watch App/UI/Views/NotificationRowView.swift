
// filepath: /Users/wes/Desktop/NotiZeniOS/NotiZenWatch Watch App/UI/Views/NotificationRowView.swift
import SwiftUI

// This struct was originally in DashboardView.
// It's moved here as it's primarily used by NotificationRowView.
// Consider moving to Models if it becomes more globally used.
struct WatchNotificationItem: Identifiable {
    let id = UUID()
    let appName: String
    let messageSummary: String
    let iconName: String // SF Symbol name
}

struct NotificationRowView: View {
    let notification: WatchNotificationItem
    
    var body: some View {
        HStack {
            Image(systemName: notification.iconName)
                .frame(width: LayoutTokens.spacing8, alignment: .center) // Adjusted for token
            VStack(alignment: .leading) {
                Text(notification.appName)
                    .font(.watchBody) // PRD Typography
                Text(notification.messageSummary)
                    .font(.watchCaption)
                    .foregroundColor(.accentLow)
            }
            Spacer()
        }
        .padding(.vertical, LayoutTokens.spacing2) // Adjusted for token
    }
}

#if DEBUG
struct NotificationRowView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationRowView(notification: WatchNotificationItem(
            appName: "Messages",
            messageSummary: "1 new",
            iconName: "message.fill"
        ))
    }
}
#endif
