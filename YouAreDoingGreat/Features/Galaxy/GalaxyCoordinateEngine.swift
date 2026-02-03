import Foundation
import SwiftUI

/// Seeded random number generator for deterministic positioning
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(truncatingIfNeeded: seed)
    }

    mutating func next() -> UInt64 {
        // Linear congruential generator (LCG) with constants from Numerical Recipes
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

/// Manages week-based spiral layout and constellation generation for galaxy view
struct GalaxyCoordinateEngine {
    private let clusterRadius: CGFloat = 150

    init(screenSize: CGSize) {
        // Screen size no longer used - canvas is dynamic based on week count
    }

    // MARK: - Main Layout Calculation

    /// Calculate complete galaxy layout from moments
    func calculateLayout(moments: [Moment]) -> GalaxyLayoutData {
        guard !moments.isEmpty else {
            return GalaxyLayoutData(
                canvasSize: CGSize(width: 800, height: 800),
                canvasCenter: CGPoint(x: 400, y: 400),
                weekClusters: [],
                constellationLines: [:],
                epochDate: Date()
            )
        }

        // 1. Determine epoch (first moment's date)
        let sortedMoments = moments.sorted { $0.happenedAt < $1.happenedAt }
        let epochDate = sortedMoments.first!.happenedAt

        // 2. Group moments by week
        let weekCalculator = WeekCalculator(epochDate: epochDate)
        let momentsByWeek = Dictionary(grouping: sortedMoments) { moment in
            weekCalculator.weekNumber(for: moment.happenedAt)
        }

        let totalWeeks = (momentsByWeek.keys.max() ?? 0) + 1

        // 3. Calculate canvas size and center
        let canvasSize = GalaxyCanvasCalculator.calculateCanvasSize(totalWeeks: totalWeeks)
        let canvasCenter = GalaxyCanvasCalculator.canvasCenter(canvasSize: canvasSize)

        // 4. Position week clusters on spiral rings
        var weekClusters: [WeekCluster] = []
        for weekNumber in 0..<totalWeeks {
            let ring = SpiralRingConfig.ring(for: weekNumber)
            let clusterCenter = ring.position(forWeek: weekNumber, canvasCenter: canvasCenter)
            let momentIds = momentsByWeek[weekNumber]?.map { $0.clientId } ?? []

            weekClusters.append(WeekCluster(
                weekNumber: weekNumber,
                centerPosition: clusterCenter,
                momentIds: momentIds
            ))
        }

        // 5. Calculate constellation lines per cluster (Delaunay triangulation)
        var constellationLines: [Int: Set<DelaunayTriangulator.Edge>] = [:]
        for cluster in weekClusters where cluster.momentIds.count >= 3 {
            let clusterMoments = cluster.momentIds.compactMap { id in
                moments.first { $0.clientId == id }
            }

            let starPositions = clusterMoments.map { moment in
                starPosition(for: moment, in: cluster)
            }

            print("🌌 Week \(cluster.weekNumber): \(cluster.momentIds.count) moments")
            print("   Cluster moments: \(clusterMoments.count)")
            print("   Star positions: \(starPositions.count)")
            if starPositions.count >= 2 {
                print("   First 2 positions: \(starPositions[0]), \(starPositions[1])")
            }

            let edges = DelaunayTriangulator.triangulate(points: starPositions)
            constellationLines[cluster.weekNumber] = edges

            print("   Triangulation returned: \(edges.count) edges")
            if !edges.isEmpty {
                print("   First edge: \(Array(edges)[0].start) -> \(Array(edges)[0].end)")
            } else {
                print("   ⚠️ NO EDGES GENERATED!")
            }
        }

        return GalaxyLayoutData(
            canvasSize: canvasSize,
            canvasCenter: canvasCenter,
            weekClusters: weekClusters,
            constellationLines: constellationLines,
            epochDate: epochDate
        )
    }

    // MARK: - Star Position Within Cluster

    /// Calculate deterministic position for a star within its week cluster
    /// Uses seeded random distribution within cluster bounds
    func starPosition(for moment: Moment, in cluster: WeekCluster) -> CGPoint {
        var generator = SeededRandomNumberGenerator(seed: moment.clientId.hashValue)

        // Generate random position within cluster bounds (300x300)
        let localX = CGFloat.random(in: 0...300, using: &generator)
        let localY = CGFloat.random(in: 0...300, using: &generator)

        // Convert to canvas coordinates
        let canvasX = cluster.bounds.minX + localX
        let canvasY = cluster.bounds.minY + localY

        return CGPoint(x: canvasX, y: canvasY)
    }

    // MARK: - Public API

    /// Get position for a moment (finds its cluster first)
    func position(for momentId: UUID, layoutData: GalaxyLayoutData, moments: [Moment]) -> CGPoint {
        guard let moment = moments.first(where: { $0.clientId == momentId }) else {
            return .zero
        }

        let weekCalculator = WeekCalculator(epochDate: layoutData.epochDate)
        let weekNumber = weekCalculator.weekNumber(for: moment.happenedAt)

        guard let cluster = layoutData.weekClusters.first(where: { $0.weekNumber == weekNumber }) else {
            return .zero
        }

        return starPosition(for: moment, in: cluster)
    }

    /// Get color index for a moment (unchanged from original)
    func colorIndex(for momentId: UUID) -> Int {
        var generator = SeededRandomNumberGenerator(seed: momentId.hashValue)
        // Generate a few random numbers to get different distribution than position
        _ = generator.next()
        _ = generator.next()
        // Use bitwise AND to safely convert to Int range
        return Int(generator.next() & 0x7FFFFFFF)
    }

    /// Get canvas size from layout data
    var canvasSize: CGSize {
        // This is now accessed from layoutData in ViewModel
        CGSize(width: 800, height: 800)  // Fallback, should not be used
    }
}
