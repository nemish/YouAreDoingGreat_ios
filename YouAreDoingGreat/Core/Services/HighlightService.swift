import Foundation
import SwiftUI

// MARK: - Highlight Service
// Manages highlighting of newly created moments in the list

@MainActor
@Observable
final class HighlightService {
    static let shared = HighlightService()

    var highlightedMomentId: UUID?

    private init() {}

    func highlightMoment(_ id: UUID) {
        highlightedMomentId = id

        // Auto-clear after animation completes
        Task {
            try? await Task.sleep(for: .seconds(2))
            if highlightedMomentId == id {
                highlightedMomentId = nil
            }
        }
    }

    func clearHighlight() {
        highlightedMomentId = nil
    }
}
