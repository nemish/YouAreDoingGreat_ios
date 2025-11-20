import SwiftUI

// MARK: - Asset Catalog Colors
extension Color {
    // MARK: Primary Colors

    /// Warm amber/gold accent
    /// Light: #E59500, Dark: #FFB84C
    static let primary = Color("Primary")

    /// Soft purple/lavender
    /// Light: #8A63D2, Dark: #A88BFA
    static let secondary = Color("Secondary")

    // MARK: Background Colors

    /// Main background
    /// Light: #FAFAFC, Dark: #0F111C (deep navy)
    static let appBackground = Color("Background")

    /// Cards and elevated surfaces
    /// Light: #FFFFFF, Dark: #191C2A
    static let appBackgroundSecondary = Color("BackgroundSecondary")

    /// Subtle elevations
    /// Light: #F2F2F7, Dark: #232634
    static let appBackgroundTertiary = Color("BackgroundTertiary")

    // MARK: Text Colors

    /// Subtitles and captions
    /// Light: #636366, Dark: #98989D
    static let appTextSecondary = Color("TextSecondary")

    /// Placeholders and disabled text
    /// Light: #AEAEB2, Dark: #636366
    static let appTextTertiary = Color("TextTertiary")

    // MARK: Special Purpose

    /// Starfield animation
    /// Light: Purple 30% opacity, Dark: White 80% opacity
    static let starfield = Color("Star")

    /// Success states
    /// Light: #34C759, Dark: #30D158
    static let appSuccess = Color("Success")

    /// Error states
    /// Light: #FF3B30, Dark: #FF453A
    static let appError = Color("Error")

    /// Warning states
    /// Light: #FF9500, Dark: #FF9F0A
    static let appWarning = Color("Warning")
}

// MARK: - Gradients
extension LinearGradient {
    /// Cosmic background gradient
    /// Uses BackgroundTertiary → Background
    static var cosmic: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.appBackgroundTertiary, .appBackground]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Primary button gradient
    /// Uses Primary with slight variations
    static var primaryButton: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.primary, .primary.opacity(0.8)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
