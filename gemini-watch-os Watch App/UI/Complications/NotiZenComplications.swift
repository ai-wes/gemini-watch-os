import WidgetKit
import SwiftUI

// PRD A1: Watch Face Complication
// This struct defines the complications widget.
struct NotiZenComplications: Widget {
    let kind: String = "NotiZenComplications"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            NotiZenComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("NotiZen Status")
        .description("See your notification and battery at a glance.")
        .supportedFamilies([.accessoryCorner, .accessoryCircular, .accessoryRectangular, .accessoryInline]) // Added more families
    }
}

// Data provider for the complication
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), unreadHighPriority: 3, unreadLowPriority: 12, batteryLevel: 0.75, relevance: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), unreadHighPriority: 2, unreadLowPriority: 8, batteryLevel: 0.6, relevance: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline entry for the current time
        // In a real app, you'd fetch this data from your AppState or a shared data source
        let currentDate = Date()
        // TODO: Fetch actual data from WatchAppState or a shared AppGroup UserDefaults
        let highCount = WatchAppState.sharedForComplications.unreadHighPriorityCount // Example static access
        let lowCount = WatchAppState.sharedForComplications.unreadLowPriorityCount   // Example static access
        let battery = WatchAppState.sharedForComplications.currentBatteryLevel     // Example static access

        let entry = SimpleEntry(date: currentDate, unreadHighPriority: highCount, unreadLowPriority: lowCount, batteryLevel: battery, relevance: TimelineEntryRelevance(score: 100.0))
        entries.append(entry)

        // Create a timeline that refreshes every 15 minutes, for example
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdateDate))
        completion(timeline)
    }
}

// Data model for the complication entry
struct SimpleEntry: TimelineEntry {
    let date: Date
    let unreadHighPriority: Int
    let unreadLowPriority: Int
    let batteryLevel: Float // 0.0 to 1.0
    let relevance: TimelineEntryRelevance?
}

// The view that renders the complication
struct NotiZenComplicationEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    @ViewBuilder
    var body: some View {
        switch family {
        case .accessoryCorner:
            AccessoryCornerView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        case .accessoryInline:
            AccessoryInlineView(entry: entry)
        default:
            // Fallback for other families if you add more later
            Text("N/A")
        }
    }
}

// MARK: - Complication Family Views

struct AccessoryCornerView: View {
    var entry: SimpleEntry
    var body: some View {
        // PRD A1: Small (corner): shield icon + red/green dot.
        // Using bell for notifications, color dot for high priority presence
        ZStack {
            Image(systemName: "shield.lefthalf.filled")
                .font(.title3) // Adjusted size
                .widgetAccentable()
            
            if entry.unreadHighPriority > 0 {
                Circle()
                    .fill(DesignTokens.Color.accentHigh) // Green dot for high priority
                    .frame(width: 6, height: 6)
                    .offset(x: 8, y: -8) // Position the dot
            } else {
                 Circle()
                    .fill(DesignTokens.Color.accentLow) // Grey dot if no high priority
                    .frame(width: 6, height: 6)
                    .offset(x: 8, y: -8)
            }
        }
        .widgetURL(URL(string: "notizen://dashboard")) // Deep link to dashboard
    }
}

struct AccessoryCircularView: View {
    var entry: SimpleEntry
    var body: some View {
        // Simple count of high priority for circular
        VStack {
            Image(systemName: "bell.badge.fill")
                .font(.title3)
                .foregroundColor(DesignTokens.Color.accentHigh)
            Text("\(entry.unreadHighPriority)")
                .font(.caption) // Smaller text for circular
        }
        .widgetURL(URL(string: "notizen://dashboard"))
    }
}

struct AccessoryRectangularView: View {
    var entry: SimpleEntry
    var body: some View {
        // PRD A1: Graphic Rect: sparkline of unread counts + “3 Hi / 12 Lo”.
        // Sparkline is complex for this stage, focusing on text.
        HStack {
            VStack(alignment: .leading) {
                Text("NotiZen")
                    .font(DesignTokens.Typography.watchCaption) // Using watch caption
                    .foregroundColor(DesignTokens.Color.accentMed)
                HStack(spacing: 4) {
                    Image(systemName: "bell.badge.fill")
                        .foregroundColor(DesignTokens.Color.accentHigh)
                    Text("\(entry.unreadHighPriority) Hi")
                }
                .font(DesignTokens.Typography.watchBody) // Using watch body
                HStack(spacing: 4) {
                    Image(systemName: "bell.slash")
                        .foregroundColor(DesignTokens.Color.accentLow)
                    Text("\(entry.unreadLowPriority) Lo")
                }
                .font(DesignTokens.Typography.watchBody) // Using watch body
            }
            Spacer(minLength: 0)
            // TODO: Add sparkline if time permits / complexity is manageable
        }
        .padding(.all, DesignTokens.Layout.spacing0_5) // Minimal padding
        .widgetURL(URL(string: "notizen://dashboard"))
    }
}

struct AccessoryInlineView: View {
    var entry: SimpleEntry
    var body: some View {
        // Simple text for inline
        Text("Hi: \(entry.unreadHighPriority) Lo: \(entry.unreadLowPriority)")
            .widgetURL(URL(string: "notizen://dashboard"))
    }
}


// MARK: - Preview
// Note: Previews for complications are best tested on a device or simulator.
// Xcode Previews for WidgetKit can be limited.
struct NotiZenComplications_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NotiZenComplicationEntryView(entry: SimpleEntry(date: Date(), unreadHighPriority: 3, unreadLowPriority: 12, batteryLevel: 0.75, relevance: nil))
                .previewContext(WidgetPreviewContext(family: .accessoryCorner))
                .previewDisplayName("Corner")

            NotiZenComplicationEntryView(entry: SimpleEntry(date: Date(), unreadHighPriority: 3, unreadLowPriority: 12, batteryLevel: 0.75, relevance: nil))
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .previewDisplayName("Circular")

            NotiZenComplicationEntryView(entry: SimpleEntry(date: Date(), unreadHighPriority: 2, unreadLowPriority: 8, batteryLevel: 0.6, relevance: nil))
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Rectangular")
            
            NotiZenComplicationEntryView(entry: SimpleEntry(date: Date(), unreadHighPriority: 2, unreadLowPriority: 8, batteryLevel: 0.6, relevance: nil))
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
                .previewDisplayName("Inline")
        }
    }
}

// Extension on WatchAppState for Complication Data
// This is a simplified way to access data. For robust sharing, use App Groups and UserDefaults.
extension WatchAppState {
    static var sharedForComplications: (
        unreadHighPriorityCount: Int,
        unreadLowPriorityCount: Int,
        currentBatteryLevel: Float
    ) {
        // In a real app, this data would be read from a shared data source
        // (e.g., UserDefaults in an App Group) that the main app writes to.
        // For now, returning placeholder data.
        // TODO: Replace with actual data fetching from a shared source.
        
        // Placeholder data:
        let defaults = UserDefaults(suiteName: "group.com.wesley.NotiZen") // Ensure this matches your App Group ID
        let highCount = defaults?.integer(forKey: "complicationUnreadHigh") ?? 2
        let lowCount = defaults?.integer(forKey: "complicationUnreadLow") ?? 5
        let battery = defaults?.float(forKey: "complicationBatteryLevel") ?? 0.70

        return (highCount, lowCount, battery)
    }

    // This method is now handled by WatchAppState.updateComplicationData()
}

