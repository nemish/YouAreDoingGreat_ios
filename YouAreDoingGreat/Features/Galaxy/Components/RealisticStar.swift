import SwiftUI

/// A realistic star shape that mimics stars seen in the night sky
/// Features random number of points and varying lengths for a natural appearance
struct RealisticStar: Shape {
    let points: Int
    let smoothness: CGFloat

    func path(in rect: CGRect) -> Path {
        guard points >= 4 else { return Path() }

        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let angleIncrement = (2.0 * .pi) / CGFloat(points * 2)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * smoothness

        var path = Path()

        for i in 0..<(points * 2) {
            let angle = angleIncrement * CGFloat(i) - .pi / 2
            let radius = i % 2 == 0 ? outerRadius : innerRadius

            let x = center.x + cos(angle) * radius
            let y = center.y + sin(angle) * radius

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        path.closeSubpath()
        return path
    }
}

/// View component for a realistic galaxy star with glow effect
struct RealisticStarView: View {
    let size: CGFloat
    let color: Color
    let brightness: Double
    let seed: Int

    // Deterministic random properties based on seed
    private var pointCount: Int {
        let counts = [4, 6, 8]  // Removed 5-pointed stars
        return counts[abs(seed) % counts.count]
    }

    private var smoothness: CGFloat {
        // Lower values = narrower body, longer edges
        let variations: [CGFloat] = [0.2, 0.25, 0.3, 0.35]
        return variations[abs(seed * 7) % variations.count]
    }

    private var rotationAngle: Double {
        // Random rotation for variety
        Double(abs(seed * 13) % 360)
    }

    var body: some View {
        ZStack {
            // Outer glow (large, soft)
            RealisticStar(points: pointCount, smoothness: smoothness)
                .fill(color.opacity(0.2))
                .frame(width: size * 2.5, height: size * 2.5)
                .blur(radius: size * 0.4)

            // Middle glow
            RealisticStar(points: pointCount, smoothness: smoothness)
                .fill(color.opacity(0.5))
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: size * 0.2)

            // Core star with soft corners
            RealisticStar(points: pointCount, smoothness: smoothness)
                .fill(color)
                .frame(width: size, height: size)
                .blur(radius: size * 0.05)  // Soft corners
                .brightness(brightness)

            // Inner blurred circle (bright center)
            Circle()
                .fill(color.opacity(0.9))
                .frame(width: size * 0.3, height: size * 0.3)
                .blur(radius: size * 0.15)
                .brightness(brightness * 0.5)
        }
        .rotationEffect(.degrees(rotationAngle))
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            HStack(spacing: 40) {
                RealisticStarView(size: 20, color: .white, brightness: 0.6, seed: 1)
                RealisticStarView(size: 20, color: .cyan, brightness: 0.6, seed: 2)
                RealisticStarView(size: 20, color: .blue, brightness: 0.6, seed: 3)
            }

            HStack(spacing: 40) {
                RealisticStarView(size: 32, color: .yellow, brightness: 1.0, seed: 4)
                RealisticStarView(size: 32, color: .purple, brightness: 1.0, seed: 5)
                RealisticStarView(size: 32, color: .pink, brightness: 1.0, seed: 6)
            }
        }
    }
}
