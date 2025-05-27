import SwiftUI
import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Design Tokens for NotiZen
extension Color {
    // Color Palette
    static let surfaceDark = Color(hex: "0D0D0F")
    static let tileDark = Color(hex: "1A1A1D")
    static let accentHigh = Color(hex: "3DDC97")
    static let accentMed = Color(hex: "6F7DFC")
    static let accentLow = Color(hex: "8E8E93")
    static let errorColor = Color(hex: "FF453A")
    
    // Light mode variants
    static let surfaceLight = Color.white
    static let tileLight = Color(hex: "F2F2F7")
}

// MARK: - Color Hex Initializer
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
            (a, r, g, b) = (1, 1, 1, 0)
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

// MARK: - Typography Tokens
extension Font {
    // iPhone Typography
    static let largeTitle = Font.custom("SF Pro Display", size: 34, relativeTo: .largeTitle).weight(.bold)
    static let title = Font.custom("SF Pro Display", size: 22, relativeTo: .title).weight(.bold)
    static let body = Font.custom("SF Pro", size: 17, relativeTo: .body)
    static let footnote = Font.custom("SF Pro", size: 13, relativeTo: .footnote)
    static let cardHeadline = Font.custom("SF Pro", size: 22, relativeTo: .title).weight(.bold)
    static let marbleNumber = Font.custom("SF Pro Display", size: 28, relativeTo: .title).weight(.bold)
    static let chartAxisLabel = Font.custom("SF Pro", size: 11, relativeTo: .caption)
    
    // Watch Typography
    static let watchHeadline = Font.custom("SF Compact", size: 15, relativeTo: .headline).weight(.semibold)
    static let watchBody = Font.custom("SF Compact", size: 13, relativeTo: .body)
    static let watchCaption = Font.custom("SF Compact", size: 10, relativeTo: .caption)
}

// MARK: - Spacing & Layout Tokens
struct LayoutTokens {
    static let baseGrid: CGFloat = 4
    static let cornerRadius: CGFloat = 16
    static let cardHeight: CGFloat = 168
    static let safePadding: CGFloat = 20
    static let watchSafePadding: CGFloat = 2
    
    // Spacing based on 4pt grid
    static let spacing1 = baseGrid * 1  // 4
    static let spacing2 = baseGrid * 2  // 8
    static let spacing3 = baseGrid * 3  // 12
    static let spacing4 = baseGrid * 4  // 16
    static let spacing5 = baseGrid * 5  // 20
    static let spacing6 = baseGrid * 6  // 24
}

// MARK: - Shadow Tokens
struct ShadowTokens {
    static let cardShadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
        color: Color.tileDark.opacity(0.2),
        radius: 6,
        x: 0,
        y: 1
    )
    
    static let lightCardShadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
        color: Color.black.opacity(0.1),
        radius: 4,
        x: 0,
        y: 0
    )
}

// MARK: - Animation Tokens
struct AnimationTokens {
    static let cardAppear = Animation.spring(dampingFraction: 0.7)
    static let sliderCommit = Animation.spring(dampingFraction: 0.5)
    static let modeChange = Animation.easeInOut(duration: 0.25)
    static let digestSheet = Animation.spring()
}

// MARK: - Haptic Feedback
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func soft() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
        impactFeedback.impactOccurred()
        #endif
    }
    
    func rigid() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .rigid)
        impactFeedback.impactOccurred()
        #endif
    }
    
    func warning() {
        #if canImport(UIKit)
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
        #endif
    }
    
    func success() {
        #if canImport(UIKit)
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        #endif
    }
    
    func notification() {
        #if canImport(UIKit)
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
        #endif
    }
}
