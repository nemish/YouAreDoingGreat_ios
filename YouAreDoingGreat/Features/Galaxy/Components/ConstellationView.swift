import SwiftUI

/// Renders constellation lines connecting stars within a week cluster
/// Uses Delaunay triangulation edges for natural-looking connections
struct ConstellationView: View {
    let edges: Set<DelaunayTriangulator.Edge>
    let canvasSize: CGSize

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Render edges as absolute positioned paths
            ForEach(Array(edges).indices, id: \.self) { index in
                let edge = Array(edges)[index]
                Path { path in
                    path.move(to: edge.start)
                    path.addLine(to: edge.end)
                }
                .stroke(Color.white.opacity(0.7), lineWidth: 2.0)
            }
        }
    }
}
