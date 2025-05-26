import SwiftUI
import Foundation
import WatchKit

// MARK: - Design Tokens for NotiZen (WatchOS)

// Note: This is a watchOS-specific version.
// Some tokens might be shared with iOS, others might be watch-specific.

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

// MARK: - Design Tokens Namespace
struct DesignTokens {
    // MARK: - Color Tokens
    struct Color {
        static let surfaceDark = SwiftUI.Color(hex: "0D0D0F")
        static let tileDark = SwiftUI.Color(hex: "1A1A1D")
        static let accentHigh = SwiftUI.Color(hex: "3DDC97")
        static let accentMed = SwiftUI.Color(hex: "6F7DFC")
        static let accentLow = SwiftUI.Color(hex: "8E8E93")
        static let error = SwiftUI.Color(hex: "FF453A")
    }
    
    // MARK: - Typography Tokens
    struct Typography {
        static let watchBody = Font.system(.body, design: .rounded)
        static let watchHeadline = Font.system(.headline, design: .rounded).weight(.semibold)
        static let watchCaption = Font.system(.caption, design: .rounded)
        static let watchTitle = Font.system(.title3, design: .rounded).weight(.bold)
        static let watchFootnote = Font.system(.footnote, design: .rounded)
    }
    
    // MARK: - Layout Tokens
    struct Layout {
        static let spacing0_5: CGFloat = 1
        static let spacing1: CGFloat = 2
        static let spacing2: CGFloat = 4
        static let spacing3: CGFloat = 6
        static let cornerRadius: CGFloat = 8
        static let cornerRadiusSmall: CGFloat = 6
        static let cornerRadiusMedium: CGFloat = 10
        static let safeAreaInset: CGFloat = 4
        static let watchSafePadding: CGFloat = 8
    }
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


// It's crucial to ensure that any custom fonts are correctly added to the
// watchOS app target and listed in its Info.plist under "Fonts provided by application".
// For system fonts, using .system(size:weight:design:) is generally more robust.
// The .compactRounded design is often suitable for watchOS.
