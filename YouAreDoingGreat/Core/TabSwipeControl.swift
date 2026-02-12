import SwiftUI

// MARK: - Tab Swipe Control
// Singleton to control whether tab swiping is enabled
// Used to disable tab swiping when month view is active

@MainActor
@Observable
final class TabSwipeControl {
    static let shared = TabSwipeControl()

    /// When true, tab swiping is disabled (e.g., month view is active)
    var isSwipeDisabled: Bool = false

    private init() {}
}
