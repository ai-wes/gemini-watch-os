// filepath: /Users/wes/Desktop/NotiZeniOS/NotiZenWatch Watch App/UI/Views/NotificationRowView.swift
import SwiftUI

struct NotificationRowView: View {
    let notification: WatchNotificationItem
    
    var body: some View {
        HStack {
            Image(systemName: "app.badge")
                .frame(width: 20, alignment: .center)
            VStack(alignment: .leading) {
                Text(notification.title)
                    .font(DesignTokens.Typography.watchBody) // PRD Typography
                Text(notification.messageSnippet)
                    .font(DesignTokens.Typography.watchCaption)
                    .foregroundColor(DesignTokens.Color.accentLow)
            }
            Spacer()
        }
        .padding(.vertical, DesignTokens.Layout.spacing1)
    }
}


#if DEBUG
struct NotificationRowView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationRowView(notification: WatchNotificationItem(
            title: "Messages",
            messageSnippet: "1 new",
            timestamp: Date(),
            type: .highPriority
        ))
    }
}
#endif
