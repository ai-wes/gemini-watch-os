// filepath: /Users/wes/Desktop/NotiZeniOS/NotiZenWatch Watch App/UI/Views/DigestPreviewSheetView.swift
import SwiftUI

// PRD A5: Digest Preview Sheet
struct DigestPreviewSheetView: View {
    @EnvironmentObject var appState: WatchAppState
    @Environment(\.dismiss) var dismiss
    
    // State to control navigation to a full digest list (placeholder for now)
    @State private var navigateToDigestList = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Layout.spacing2) {
            Text("Today’s low-prio summary")
                .font(DesignTokens.Typography.watchHeadline)
                .padding(.bottom, DesignTokens.Layout.spacing1)

            Divider()
                .padding(.bottom, DesignTokens.Layout.spacing1)

            // Displaying digest items. For now, we use a simplified representation.
            // The PRD shows bullet points. We can simulate this.
            // "• 6 promos grouped"
            // "• Calendar invites 2"
            // "• Updates turned to digest"
            // This data should ideally come from appState.digestItems being processed or summarized.
            // For this example, we'll use appState.digestSummary for the main part and then list items.
            
            if !appState.digestSummary.isEmpty && appState.digestSummary != "Nothing to summarize yet." {
                Text(appState.digestSummary)
                    .font(DesignTokens.Typography.watchBody)
                    .padding(.bottom, DesignTokens.Layout.spacing1)
            }
            
            ForEach(appState.digestItems.prefix(3)) { item in // Show a few items as per PRD example
                HStack {
                    Text("•")
                    Text(item.title ?? "Summary item")
                        .font(DesignTokens.Typography.watchBody)
                }
            }

            Spacer() // Pushes buttons to the bottom

            HStack(spacing: DesignTokens.Layout.spacing2) {
                Button {
                    dismiss()
                } label: {
                    Text("Hide for Now")
                        .font(DesignTokens.Typography.watchBody)
                        .padding(DesignTokens.Layout.spacing2)
                        .frame(maxWidth: .infinity)
                        .background(DesignTokens.Color.tileDark)
                        .cornerRadius(DesignTokens.Layout.cornerRadiusSmall)
                }
                .buttonStyle(.plain)

                Button {
                    navigateToDigestList = true
                } label: {
                    Text("View List")
                        .font(DesignTokens.Typography.watchBody)
                        .padding(DesignTokens.Layout.spacing2)
                        .frame(maxWidth: .infinity)
                        .background(DesignTokens.Color.accentMed)
                        .foregroundColor(.black) // Ensure text is readable on accentMed
                        .cornerRadius(DesignTokens.Layout.cornerRadiusSmall)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, DesignTokens.Layout.safeAreaInset) // Ensure buttons are above safe area
        }
        .padding(DesignTokens.Layout.spacing3) // Overall padding for the sheet content
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.Color.surfaceDark)
        .cornerRadius(DesignTokens.Layout.cornerRadiusMedium) // PRD: 16pt for modal sheets
        .onAppear {
            // PRD Haptics: .warning when digest created
            HapticManager.shared.failure()
        }
        .sheet(isPresented: $navigateToDigestList) { // Using .sheet for "View List" for now
            // Placeholder for DigestListView - PRD doesn't specify this view in detail yet
            // For now, it can be a simple list of all digestItems
            NavigationView {
                DigestListView()
            }
        }
    }
}


#if DEBUG
struct DigestPreviewSheetView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = WatchAppState()
        appState.digestSummary = "Key updates from today:"
        appState.digestItems = [
            NotificationEvent(id: UUID(), date: Date(), appName: "PromoApp", bundleID: "com.example.promo", title: "6 promos grouped", message: "Summary of 6 promotional offers.", score: 0.2),
            NotificationEvent(id: UUID(), date: Date(), appName: "CalendarApp", bundleID: "com.example.calendar", title: "Calendar invites: 2", message: "Two new calendar invitations.", score: 0.3),
            NotificationEvent(id: UUID(), date: Date(), appName: "UpdatesApp", bundleID: "com.example.updates", title: "App updates turned to digest", message: "Various app updates have been summarized.", score: 0.1)
        ]

        return DigestPreviewSheetView()
            .environmentObject(appState)
    }
}
#endif
