// filepath: /Users/wes/Desktop/NotiZeniOS/NotiZenWatch Watch App/UI/Views/UnreadHighCardView.swift
import SwiftUI

// PRD A3: Card – Unread High
struct UnreadHighCardView: View {
    let count: Int
    let latestMessage: String
    
    private var urgencyColor: Color {
        switch count {
        case 0:
            return DesignTokens.Color.accentLow
        case 1...2:
            return DesignTokens.Color.accentMed
        default:
            return DesignTokens.Color.error
        }
    }
    
    private var urgencyIcon: String {
        switch count {
        case 0:
            return "checkmark.circle.fill"
        case 1...2:
            return "bell.badge.fill"
        default:
            return "exclamationmark.triangle.fill"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: urgencyIcon)
                    .foregroundColor(urgencyColor)
                Text(count == 0 ? "All clear" : "\(count) critical")
                    .font(DesignTokens.Typography.watchHeadline)
                    .foregroundColor(urgencyColor)
            }
            
            if count == 0 {
                Text("No urgent notifications")
                    .font(DesignTokens.Typography.watchCaption)
                    .foregroundColor(DesignTokens.Color.accentLow)
            } else {
                Text(latestMessage.isEmpty ? "High priority notifications" : latestMessage)
                    .font(DesignTokens.Typography.watchCaption)
                    .foregroundColor(DesignTokens.Color.accentLow)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignTokens.Layout.spacing2)
        .background(DesignTokens.Color.tileDark)
        .cornerRadius(DesignTokens.Layout.cornerRadiusMedium)
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
