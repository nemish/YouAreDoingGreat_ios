import SwiftUI

// MARK: - iPad Content Width Modifier
// Constrains content to a readable width on iPad while remaining full-width on iPhone

struct iPadContentWidthModifier: ViewModifier {
    var maxWidth: CGFloat = 500

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - View Extension

extension View {
    /// Constrains content to a readable width on iPad (default 500pt) while remaining full-width on iPhone
    func iPadContentWidth(_ maxWidth: CGFloat = 500) -> some View {
        modifier(iPadContentWidthModifier(maxWidth: maxWidth))
    }
}
