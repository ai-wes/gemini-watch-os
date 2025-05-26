import SwiftUI
import Foundation

// MARK: - Design Tokens for NotiZen (WatchOS)

// Note: This is a watchOS-specific version.
// Some tokens might be shared with iOS, others might be watch-specific.

extension Color {
    // Color Palette (Shared or adapted for watch)
    static let surfaceDark = Color(hex: "0D0D0F") // Typically black for watchOS
    static let tileDark = Color(hex: "1A1A1D")    // Dark gray for elements
    static let accentHigh = Color(hex: "3DDC97")  // Green for positive actions/info
    static let accentMed = Color(hex: "6F7DFC")   // Blue for neutral actions/info
    static let accentLow = Color(hex: "8E8E93")   // Gray for secondary info/controls
    static let errorColor = Color(hex: "FF453A")  // Red for errors

    // Light mode variants (Less common on watchOS, but good for completeness)
    // For watchOS, these might be adapted for "always on display" low-power states
    // or if a light theme is explicitly offered.
    static let surfaceLight = Color.white // Or a very light gray
    static let tileLight = Color(hex: "F2F2F7") // Light gray for elements in a light theme
}

// MARK: - Color Hex Initializer (Shared)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            // Return a clear color for invalid hex strings
            (a, r, g, b) = (0, 0, 0, 0) // Changed to clear for better error visibility
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography Tokens (WatchOS Specific)
extension Font {
    // Watch Typography - using system fonts is generally preferred for accessibility and dynamic type.
    // Custom fonts are possible but ensure they are bundled with the watchOS target.
    // These definitions assume "SF Compact" is the desired custom font.
    // If using system fonts, prefer .system(size:weight:design:) with .compactRounded design.

    static let watchTitle = Font.system(.title3, design: .rounded).weight(.bold) // Adjusted for typical watch title
    static let watchHeadline = Font.system(.headline, design: .rounded).weight(.semibold)
    static let watchBody = Font.system(.body, design: .rounded)
    static let watchCallout = Font.system(.callout, design: .rounded)
    static let watchSubheadline = Font.system(.subheadline, design: .rounded)
    static let watchFootnote = Font.system(.footnote, design: .rounded)
    static let watchCaption = Font.system(.caption, design: .rounded)
    static let watchCaption2 = Font.system(.caption2, design: .rounded)
    
    // Example of a custom font if "SF Compact" was bundled and registered
    // static let customWatchHeadline = Font.custom("SF Compact Semibold", size: 15, relativeTo: .headline)
}

// MARK: - Spacing & Layout Tokens (WatchOS Specific)
struct LayoutTokens {
    static let baseGrid: CGFloat = 2 // WatchOS often uses tighter spacing
    static let cornerRadiusSmall: CGFloat = 6 // For smaller elements
    static let cornerRadiusMedium: CGFloat = 10 // For cards or larger elements
    static let cornerRadiusLarge: CGFloat = 12 // For full-width buttons or sheets
    
    static let cardHeightSmall: CGFloat = 60 // Example for a small info card
    static let cardHeightMedium: CGFloat = 90 // Example for a medium content card
    
    static let screenPadding: CGFloat = 4 // Padding from screen edges
    static let listRowPaddingVertical: CGFloat = 6
    static let listRowPaddingHorizontal: CGFloat = 8
    
    // Spacing based on grid
    static let spacing1 = baseGrid * 1  // 2
    static let spacing2 = baseGrid * 2  // 4
    static let spacing3 = baseGrid * 3  // 6
    static let spacing4 = baseGrid * 4  // 8
    static let spacing5 = baseGrid * 5  // 10
    static let spacing6 = baseGrid * 6  // 12
    static let spacing8 = baseGrid * 8  // 16
}

// MARK: - Shadow Tokens (Generally less common/subtle on watchOS due to dark UIs)
struct ShadowTokens {
    // Shadows should be used sparingly and be very subtle on watchOS.
    // Often, depth is conveyed by layering and material effects rather than strong shadows.
    static let subtleShadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
        color: Color.black.opacity(0.4), // Darker, more transparent for subtlety
        radius: 2,
        x: 0,
        y: 1
    )
}

// MARK: - Animation Tokens (WatchOS Specific)
struct AnimationTokens {
    static let defaultAnimation = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let fastAnimation = Animation.spring(response: 0.25, dampingFraction: 0.8)
    static let gentleAnimation = Animation.easeInOut(duration: 0.4)
    
    // Consider specific animations for list updates, view transitions, etc.
    // static let listItemAppear = Animation.interpolatingSpring(stiffness: 150, damping: 15)
}

// MARK: - Haptic Feedback (WatchOS Specific)
// watchOS has its own haptic engine, WKHapticType
// This manager provides a simplified interface.
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func play(_ type: WKHapticType) {
        WKInterfaceDevice.current().play(type)
    }
    
    // Convenience methods for common haptic types
    func notification() { play(.notification) }
    func success() { play(.success) }
    func failure() { play(.failure) }
    func start() { play(.start) }
    func stop() { play(.stop) }
    func click() { play(.click) }
    func directionUp() { play(.directionUp) }
    func directionDown() { play(.directionDown) }
    // Add more as needed based on WKHapticType enum
}

// Add this to the DesignTokens namespace
extension DesignTokens {
    struct Color {
        static let surfaceDark = SwiftUI.Color(hex: "0D0D0F")
        static let tileDark = SwiftUI.Color(hex: "1A1A1D")
        static let accentHigh = SwiftUI.Color(hex: "3DDC97")
        static let accentMed = SwiftUI.Color(hex: "6F7DFC")
        static let accentLow = SwiftUI.Color(hex: "8E8E93")
        static let error = SwiftUI.Color(hex: "FF453A")
    }
    
    struct Typography {
        static let watchBody = Font.system(.body, design: .rounded)
        static let watchHeadline = Font.system(.headline, design: .rounded).weight(.semibold)
        static let watchCaption = Font.system(.caption, design: .rounded)
        static let watchTitle = Font.system(.title3, design: .rounded).weight(.bold)
        static let watchFootnote = Font.system(.footnote, design: .rounded)
    }
    
    struct Layout {
        static let spacing0_5: CGFloat = 1
        static let spacing1: CGFloat = 2
        static let spacing2: CGFloat = 4
        static let spacing3: CGFloat = 6
        static let cornerRadiusSmall: CGFloat = 6
        static let cornerRadiusMedium: CGFloat = 10
        static let safeAreaInset: CGFloat = 4
    }
}

// It's crucial to ensure that any custom fonts are correctly added to the
// watchOS app target and listed in its Info.plist under "Fonts provided by application".
// For system fonts, using .system(size:weight:design:) is generally more robust.
// The .compactRounded design is often suitable for watchOS.
