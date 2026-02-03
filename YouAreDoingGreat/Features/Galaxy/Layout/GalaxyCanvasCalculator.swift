import Foundation
import CoreGraphics

/// Calculates dynamic canvas size based on number of weeks in the galaxy
struct GalaxyCanvasCalculator {
    /// Calculate canvas size needed to fit all week clusters
    /// - Parameter totalWeeks: Total number of weeks (0-based count + 1)
    /// - Returns: Canvas size (square dimensions)
    static func calculateCanvasSize(totalWeeks: Int) -> CGSize {
        guard totalWeeks > 0 else {
            // Empty state: minimum canvas size
            return CGSize(width: 800, height: 800)
        }

        // Find the outermost ring
        let outermostRing = SpiralRingConfig.ring(for: totalWeeks - 1)

        // Canvas size = center + outermost radius + cluster radius + padding
        let halfSize = outermostRing.radius +
                       SpiralRingConfig.clusterRadius +
                       200  // Extra padding

        let dimension = halfSize * 2

        return CGSize(width: dimension, height: dimension)
    }

    /// Calculate center point of canvas
    /// - Parameter canvasSize: The canvas size
    /// - Returns: Center point coordinates
    static func canvasCenter(canvasSize: CGSize) -> CGPoint {
        CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
    }
}
