import SwiftUI

// MARK: - Tab Swipe Control
/// Shared flag to disable tab-level horizontal swipe when a child view
/// needs its own horizontal gesture (e.g., MonthNavigationView).
///
/// Uses singleton instead of `@Environment` because `SwipeableTabContainer`
/// lives above the NavigationStack that hosts the month view, so passing
/// state down via environment would require threading a binding through
/// MainTabView → SwipeableTabContainer → NavigationStack → JourneyView.
/// A shared observable keeps the coupling minimal and the flag easy to
/// set/clear from any depth in the view hierarchy.
///
/// Thread-safe for UI use: `@MainActor` ensures all reads/writes happen
/// on the main thread.

@MainActor
@Observable
final class TabSwipeControl {
    static let shared = TabSwipeControl()

    /// When true, tab swiping is disabled (e.g., month view is active)
    var isSwipeDisabled: Bool = false

    private init() {}
}
