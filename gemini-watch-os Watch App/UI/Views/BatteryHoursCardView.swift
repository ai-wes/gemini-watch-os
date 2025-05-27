// filepath: /Users/wes/Desktop/NotiZeniOS/NotiZenWatch Watch App/UI/Views/BatteryHoursCardView.swift
import SwiftUI

struct BatteryHoursCardView: View {
    let hours: Int
    let batteryPercentage: Double
    
    private var batteryColor: Color {
        if batteryPercentage < 0.2 {
            return DesignTokens.Color.error
        } else if batteryPercentage < 0.5 {
            return .yellow
        } else {
            return DesignTokens.Color.accentHigh
        }
    }
    
    private var batteryIcon: String {
        let percentage = batteryPercentage * 100
        switch percentage {
        case 0..<25:
            return "battery.25"
        case 25..<50:
            return "battery.50"
        case 50..<75:
            return "battery.75"
        default:
            return "battery.100"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: batteryIcon)
                    .foregroundColor(batteryColor)
                Text("\(Int(batteryPercentage * 100))%")
                    .font(DesignTokens.Typography.watchHeadline)
                    .foregroundColor(batteryColor)
            }
            Text("\(hours) h remaining")
                .font(DesignTokens.Typography.watchCaption)
                .foregroundColor(DesignTokens.Color.accentLow)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignTokens.Layout.spacing2)
        .background(DesignTokens.Color.tileDark)
        .cornerRadius(DesignTokens.Layout.cornerRadius)
    }
}
