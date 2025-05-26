// filepath: /Users/wes/Desktop/NotiZeniOS/NotiZenWatch Watch App/UI/Views/UnreadHighCardView.swift
import SwiftUI

// PRD A3: Card – Unread High
struct UnreadHighCardView: View {
    let count: Int
    let latestMessage: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "bell.badge.fill") // PRD Iconography
                    .foregroundColor(DesignTokens.Color.accentHigh) // PRD Palette
                Text("\(count) critical")
                    .font(DesignTokens.Typography.watchHeadline) // PRD Typography
            }
            Text(latestMessage)
                .font(DesignTokens.Typography.watchCaption)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignTokens.Layout.spacing2) // PRD Grid
        .background(DesignTokens.Color.tileDark) // PRD Palette
        .cornerRadius(DesignTokens.Layout.cornerRadiusMedium) // PRD Shapes
    }
}

#if DEBUG
struct UnreadHighCardView_Previews: PreviewProvider {
    static var previews: some View {
        UnreadHighCardView(count: 3, latestMessage: "Urgent: Action Required")
            .frame(width: 150, height: 80) // Example frame for preview
    }
}
#endif
