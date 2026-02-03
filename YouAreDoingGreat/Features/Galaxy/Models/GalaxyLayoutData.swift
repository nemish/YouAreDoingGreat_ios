import Foundation
import CoreGraphics

/// Represents a week cluster containing moments
struct WeekCluster: Identifiable {
    let weekNumber: Int
    let centerPosition: CGPoint
    let momentIds: [UUID]

    var id: Int { weekNumber }

    /// Cluster bounds (300x300 square)
    var bounds: CGRect {
        CGRect(
            x: centerPosition.x - 150,
            y: centerPosition.y - 150,
            width: 300,
            height: 300
        )
    }
}

/// Complete layout data for the galaxy view
struct GalaxyLayoutData {
    let canvasSize: CGSize
    let canvasCenter: CGPoint
    let weekClusters: [WeekCluster]
    let constellationLines: [Int: Set<DelaunayTriangulator.Edge>]
    let epochDate: Date

    var totalWeeks: Int {
        weekClusters.count
    }
}
