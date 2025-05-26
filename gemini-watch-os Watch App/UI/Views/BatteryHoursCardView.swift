
// filepath: /Users/wes/Desktop/NotiZeniOS/NotiZenWatch Watch App/UI/Views/BatteryHoursCardView.swift
import SwiftUI

struct BatteryHoursCardView: View {
    let hours: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "bolt.fill") // PRD Iconography
                    .foregroundColor(Color.accentMed) // PRD Palette
                Text("\(hours) h")
                    .font(.watchHeadline) // PRD Typography
            }
            Text("Estimated remaining")
                .font(.watchCaption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(LayoutTokens.spacing2)
        .background(Color.tileDark)
        .cornerRadius(LayoutTokens.cornerRadiusMedium) // PRD Shapes
    }
}

#if DEBUG
struct BatteryHoursCardView_Previews: PreviewProvider {
    static var previews: some View {
        BatteryHoursCardView(hours: 18)
            .frame(width: 150, height: 80) // Example frame for preview
    }
}
#endif
