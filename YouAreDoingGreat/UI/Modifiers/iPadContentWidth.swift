import SwiftUI

// MARK: - Layout Constants

extension CGFloat {
    /// Maximum content width for iPad layouts (buttons, forms, etc.)
    static let iPadContentMaxWidth: CGFloat = 500
}

// MARK: - iPad Content Width Modifier
// Constrains content to a readable width on iPad while remaining full-width on iPhone

struct iPadContentWidthModifier: ViewModifier {
    var maxWidth: CGFloat = .iPadContentMaxWidth

    func body(content: Content) -> some View {
        HStack {
            Spacer(minLength: 0)
            content
                .frame(maxWidth: maxWidth)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Constrains content to a readable width on iPad (default 500pt) while remaining full-width on iPhone
    func iPadContentWidth(_ maxWidth: CGFloat = .iPadContentMaxWidth) -> some View {
        modifier(iPadContentWidthModifier(maxWidth: maxWidth))
    }
}
