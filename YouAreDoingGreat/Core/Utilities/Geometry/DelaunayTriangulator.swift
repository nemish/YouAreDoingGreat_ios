import Foundation
import CoreGraphics

/// Delaunay triangulation implementation using Bowyer-Watson algorithm
/// Creates a triangular mesh connecting points with no overlapping circumcircles
struct DelaunayTriangulator {
    // MARK: - Triangle

    struct Triangle: Hashable {
        let p1: CGPoint
        let p2: CGPoint
        let p3: CGPoint

        /// Check if a point lies inside this triangle's circumcircle
        func inCircumcircle(_ point: CGPoint, debug: Bool = false) -> Bool {
            // Use the standard determinant formula for circumcircle test
            let ax = p1.x
            let ay = p1.y
            let bx = p2.x
            let by = p2.y
            let cx = p3.x
            let cy = p3.y
            let dx = point.x
            let dy = point.y

            let ax_dx = ax - dx
            let ay_dy = ay - dy
            let bx_dx = bx - dx
            let by_dy = by - dy
            let cx_dx = cx - dx
            let cy_dy = cy - dy

            let det = (ax_dx * ax_dx + ay_dy * ay_dy) * (bx_dx * cy_dy - cx_dx * by_dy)
                    - (bx_dx * bx_dx + by_dy * by_dy) * (ax_dx * cy_dy - cx_dx * ay_dy)
                    + (cx_dx * cx_dx + cy_dy * cy_dy) * (ax_dx * by_dy - bx_dx * ay_dy)

            if debug {
                print("    Circumcircle test: det=\(det), result=\(det > 0)")
            }

            return det > 0
        }

        var edges: [Edge] {
            [Edge(p1, p2), Edge(p2, p3), Edge(p3, p1)]
        }
    }

    // MARK: - Edge

    struct Edge: Hashable {
        let start: CGPoint
        let end: CGPoint

        init(_ start: CGPoint, _ end: CGPoint) {
            // Normalize edge direction for consistent hashing
            if start.x < end.x || (start.x == end.x && start.y < end.y) {
                self.start = start
                self.end = end
            } else {
                self.start = end
                self.end = start
            }
        }
    }

    // MARK: - Triangulation

    /// Compute Delaunay triangulation for a set of points
    /// - Parameter points: Array of points to triangulate
    /// - Returns: Set of edges forming the triangulation
    static func triangulate(points: [CGPoint]) -> Set<Edge> {
        guard points.count >= 3 else {
            print("⚠️ Triangulate: Less than 3 points")
            return []
        }

        print("🔺 Triangulating \(points.count) points")

        // 1. Create super-triangle containing all points
        let bounds = boundingBox(points: points)
        let superTriangle = createSuperTriangle(bounds: bounds)
        var triangulation: Set<Triangle> = [superTriangle]

        print("  Bounds: \(bounds)")
        print("  Super-triangle: \(superTriangle.p1), \(superTriangle.p2), \(superTriangle.p3)")

        // 2. Add each point incrementally (Bowyer-Watson)
        for (index, point) in points.enumerated() {
            var badTriangles: Set<Triangle> = []

            // Find triangles whose circumcircle contains the point
            for triangle in triangulation {
                if triangle.inCircumcircle(point, debug: index == 0) {
                    badTriangles.insert(triangle)
                }
            }

            if index == 0 {
                print("  Point 0: \(point), bad triangles: \(badTriangles.count)")
            }

            // Find boundary polygon (edges appearing in exactly one bad triangle)
            var polygon: Set<Edge> = []
            for triangle in badTriangles {
                for edge in triangle.edges {
                    if polygon.contains(edge) {
                        polygon.remove(edge)
                    } else {
                        polygon.insert(edge)
                    }
                }
            }

            if index == 0 {
                print("  Polygon edges: \(polygon.count)")
            }

            // Remove bad triangles
            triangulation.subtract(badTriangles)

            // Re-triangulate the polygon with new point
            for edge in polygon {
                let newTriangle = Triangle(
                    p1: edge.start,
                    p2: edge.end,
                    p3: point
                )
                triangulation.insert(newTriangle)
            }

            if index == 0 {
                print("  New triangulation size: \(triangulation.count)")
            }
        }

        print("  Triangulation before filter: \(triangulation.count) triangles")

        // 3. Remove triangles using super-triangle vertices
        let superVertices = Set([superTriangle.p1, superTriangle.p2, superTriangle.p3])
        let filteredTriangles = Set(triangulation.filter { triangle in
            !superVertices.contains(triangle.p1) &&
            !superVertices.contains(triangle.p2) &&
            !superVertices.contains(triangle.p3)
        })

        print("  Triangulation after filter: \(filteredTriangles.count) triangles")

        // 4. Extract unique edges
        var edges: Set<Edge> = []
        for triangle in filteredTriangles {
            edges.formUnion(triangle.edges)
        }

        print("  Final edges: \(edges.count)")

        return edges
    }

    // MARK: - Helper Methods

    private static func boundingBox(points: [CGPoint]) -> CGRect {
        let xs = points.map { $0.x }
        let ys = points.map { $0.y }

        return CGRect(
            x: xs.min()!,
            y: ys.min()!,
            width: xs.max()! - xs.min()!,
            height: ys.max()! - ys.min()!
        )
    }

    private static func createSuperTriangle(bounds: CGRect) -> Triangle {
        let margin = max(bounds.width, bounds.height) * 2

        // Counter-clockwise order: top -> bottom-right -> bottom-left
        return Triangle(
            p1: CGPoint(x: bounds.midX, y: bounds.minY - margin),
            p2: CGPoint(x: bounds.maxX + margin, y: bounds.maxY + margin),
            p3: CGPoint(x: bounds.minX - margin, y: bounds.maxY + margin)
        )
    }
}
