import SwiftUI

// MARK: - Gradients
// All colors use auto-generated symbols from Assets.xcassets
// e.g., "AppPrimary" → Color.appPrimary, "Background" → Color.background

extension LinearGradient {
    /// Cosmic background gradient
    static var cosmic: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.backgroundTertiary, .background]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Primary button gradient
    static var primaryButton: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.appPrimary, .appPrimary.opacity(0.8)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
