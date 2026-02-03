import Foundation
import CoreGraphics

/// Configuration for spiral ring layout in the galaxy
/// Rings expand outward from center with increasing capacity
struct SpiralRingConfig {
    let ringIndex: Int          // 0 = center, 1, 2, 3...
    let radius: CGFloat         // Distance from canvas center
    let weekCapacity: Int       // Number of weeks this ring can hold
    let startWeekNumber: Int    // First week number in this ring

    // Constants
    static let clusterRadius: CGFloat = 150      // Half of 300x300 cluster
    static let baseRingRadius: CGFloat = 350     // Radius of first ring
    static let ringSpacing: CGFloat = 350        // Distance between rings

    /// Calculate which ring a given week belongs to
    /// - Parameter weekNumber: The week number (0-based)
    /// - Returns: Ring configuration for that week
    static func ring(for weekNumber: Int) -> SpiralRingConfig {
        // Week 0 is always at center
        if weekNumber == 0 {
            return SpiralRingConfig(
                ringIndex: 0,
                radius: 0,
                weekCapacity: 1,
                startWeekNumber: 0
            )
        }

        // Calculate ring for weeks 1+
        // Ring capacity grows: 4, 10, 16, 22... (adds 6 each ring)
        var cumulativeWeeks = 1  // Week 0 is in center
        var currentRing = 1

        while true {
            let ringCapacity = 4 + (currentRing - 1) * 6

            if weekNumber < cumulativeWeeks + ringCapacity {
                return SpiralRingConfig(
                    ringIndex: currentRing,
                    radius: baseRingRadius + (CGFloat(currentRing - 1) * ringSpacing),
                    weekCapacity: ringCapacity,
                    startWeekNumber: cumulativeWeeks
                )
            }

            cumulativeWeeks += ringCapacity
            currentRing += 1
        }
    }

    /// Calculate position for a specific week cluster on this ring
    /// - Parameters:
    ///   - weekNumber: The week number to position
    ///   - canvasCenter: Center point of the canvas
    /// - Returns: Position for the week cluster center
    func position(forWeek weekNumber: Int, canvasCenter: CGPoint) -> CGPoint {
        guard weekNumber >= startWeekNumber else {
            fatalError("Week \(weekNumber) not in ring \(ringIndex)")
        }

        // Week 0 at center
        if ringIndex == 0 {
            return canvasCenter
        }

        // Calculate angle for this week's position on the ring
        let weekIndexInRing = weekNumber - startWeekNumber
        let angleStep = (2 * .pi) / CGFloat(weekCapacity)
        let angle = angleStep * CGFloat(weekIndexInRing) - (.pi / 2)  // Start at top (12 o'clock)

        // Convert polar to cartesian coordinates
        let x = canvasCenter.x + cos(angle) * radius
        let y = canvasCenter.y + sin(angle) * radius

        return CGPoint(x: x, y: y)
    }
}
