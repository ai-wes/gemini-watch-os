import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var showHighPriorityFeed = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: LayoutTokens.spacing4) {
                    // Horizontal Cards
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: LayoutTokens.spacing4) {
                            // High Priority Card
                            DashboardCard(
                                title: "\(appState.highPriorityCount)",
                                subtitle: "critical",
                                detail: appState.highPriorityNotifications.first?.title ?? "No high priority notifications",
                                icon: "bell.badge.fill",
                                accentColor: .accentHigh
                            ) {
                                showHighPriorityFeed = true
                            }
                            
                            // Battery Forecast Card
                            DashboardCard(
                                title: "\(Int(appState.batteryData.estimatedHours)) h",
                                subtitle: "est.",
                                detail: "Last 24 h –↑3%",
                                icon: "bolt.fill",
                                accentColor: .accentMed
                            ) {
                                // Navigate to Battery tab
                            }
                        }
                        .padding(.horizontal, LayoutTokens.safePadding)
                    }
                    
                    // Today Section
                    VStack(alignment: .leading, spacing: LayoutTokens.spacing3) {
                        HStack {
                            Text("Today")
                                .font(.title)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, LayoutTokens.safePadding)
                        
                        // Chart placeholder - would use SwiftCharts in real implementation
                        ChartPlaceholderView(data: appState.todayNotificationCounts)
                            .frame(height: 120)
                            .padding(.horizontal, LayoutTokens.safePadding)
                    }
                    
                    // Recent High Priority Section
                    VStack(alignment: .leading, spacing: LayoutTokens.spacing3) {
                        HStack {
                            Text("Recent High")
                                .font(.title)
                                .foregroundColor(.white)
                            Spacer()
                            Button("View All") {
                                showHighPriorityFeed = true
                            }
                            .font(.footnote)
                            .foregroundColor(.accentMed)
                        }
                        .padding(.horizontal, LayoutTokens.safePadding)
                        
                        LazyVStack(spacing: LayoutTokens.spacing2) {
                            ForEach(Array(appState.highPriorityNotifications.prefix(3))) { notification in
                                NotificationRowView(notification: notification)
                                    .padding(.horizontal, LayoutTokens.safePadding)
                            }
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color.surfaceDark)
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showHighPriorityFeed) {
            HighPriorityFeedView()
        }
    }
}

struct DashboardCard: View {
    let title: String
    let subtitle: String
    let detail: String
    let icon: String
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: LayoutTokens.spacing3) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(accentColor)
                    Spacer()
                }
                
                HStack(alignment: .firstTextBaseline, spacing: LayoutTokens.spacing1) {
                    Text(title)
                        .font(.marbleNumber)
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(.accentLow)
                }
                
                Text(detail)
                    .font(.footnote)
                    .foregroundColor(.accentLow)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(LayoutTokens.spacing4)
            .frame(width: 168, height: LayoutTokens.cardHeight)
            .background(
                RoundedRectangle(cornerRadius: LayoutTokens.cornerRadius)
                    .fill(.thickMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutTokens.cornerRadius)
                            .stroke(accentColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NotificationRowView: View {
    let notification: NotificationItem
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: LayoutTokens.spacing3) {
            Image(systemName: notification.appIcon)
                .font(.title3)
                .foregroundColor(.accentMed)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.appName)
                    .font(.footnote)
                    .foregroundColor(.accentLow)
                
                Text(notification.title)
                    .font(.body)
                    .foregroundColor(.white)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack {
                Text(timeString(from: notification.timestamp))
                    .font(.caption)
                    .foregroundColor(.accentLow)
                Spacer()
            }
        }
        .padding(.vertical, LayoutTokens.spacing2)
        .contentShape(Rectangle())
        .onTapGesture {
            appState.markNotificationAsRead(notification)
        }
        .swipeActions(edge: .trailing) {
            Button("Archive") {
                appState.archiveNotification(notification)
            }
            .tint(.accentHigh)
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ChartPlaceholderView: View {
    let data: [HistoryDataPoint]
    
    var body: some View {
        VStack {
            HStack {
                Text("Notifications per hour")
                    .font(.footnote)
                    .foregroundColor(.accentLow)
                Spacer()
            }
            
            // Simple bar chart placeholder
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(data, id: \.id) { point in
                    Rectangle()
                        .fill(Color.accentMed) // Changed from .accentMed
                        .frame(width: 12, height: max(4, point.value * 3))
                        .cornerRadius(2)
                }
            }
            .frame(height: 80)
            
            HStack {
                Text("12 AM")
                    .font(.chartAxisLabel)
                    .foregroundColor(.accentLow)
                Spacer()
                Text("6 AM")
                    .font(.chartAxisLabel)
                    .foregroundColor(.accentLow)
                Spacer()
                Text("12 PM")
                    .font(.chartAxisLabel)
                    .foregroundColor(.accentLow)
                Spacer()
                Text("6 PM")
                    .font(.chartAxisLabel)
                    .foregroundColor(.accentLow)
                Spacer()
                Text("11 PM")
                    .font(.chartAxisLabel)
                    .foregroundColor(.accentLow)
            }
        }
        .padding(LayoutTokens.spacing4)
        .background(
            RoundedRectangle(cornerRadius: LayoutTokens.cornerRadius)
                .fill(Color.tileDark)
        )
    }
}

struct HighPriorityFeedView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(appState.highPriorityNotifications) { notification in
                    NotificationRowView(notification: notification)
                        .listRowBackground(Color.tileDark)
                }
            }
            .listStyle(PlainListStyle())
            .background(Color.surfaceDark)
            .navigationTitle("High Priority")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.accentMed)
                }
            }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
}
