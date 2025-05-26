// filepath: /Users/wes/Desktop/NotiZeniOS/NotiZenWatch Watch App/UI/Views/BatteryHoursCardView.swift
import SwiftUI

struct BatteryHoursCardView: View {
    let hours: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "bolt.fill") // PRD Iconography
                    .foregroundColor(DesignTokens.Color.accentMed) // PRD Palette
                Text("\(hours) h")
                    .font(DesignTokens.Typography.watchHeadline) // PRD Typography
            }
            Text("Estimated remaining")
                .font(DesignTokens.Typography.watchCaption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignTokens.Layout.spacing2)
        .background(DesignTokens.Color.tileDark)
        .cornerRadius(DesignTokens.Layout.cornerRadius)
    }
}
