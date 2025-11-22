import SwiftUI

// MARK: - Starfield Background ViewModifier
// Dark mode only for v1

struct StarfieldBackground: ViewModifier {
    // Star data structure
    private struct Star {
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double
    }

    @State private var stars: [Star] = []
    @State private var offsetX: CGFloat = 0
    @State private var offsetY: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0

    // Fog/nebula positions
    @State private var fog1Offset: CGSize = .zero
    @State private var fog2Offset: CGSize = .zero

    func body(content: Content) -> some View {
        ZStack {
            // Cosmic gradient background
            LinearGradient.cosmic
                .ignoresSafeArea()

            // Fog/nebula layers (radial gradients)
            fogLayer

            // Static starfield layer with group animation
            GeometryReader { geometry in
                let expandedSize = calculateExpandedSize(for: geometry.size)
                // Stars are generated in range 0 to 1.5, map to expanded size
                let expandedRange: CGFloat = 1.5
                // Center the expanded starfield over the original geometry
                let centerOffset = CGSize(
                    width: (expandedSize.width - geometry.size.width) / 2,
                    height: (expandedSize.height - geometry.size.height) / 2
                )
                
                ZStack {
                    ForEach(0..<stars.count, id: \.self) { index in
                        let star = stars[index]
                        Circle()
                            .fill(Color.star)
                            .frame(width: star.size, height: star.size)
                            .opacity(star.opacity)
                            .position(
                                x: star.x / expandedRange * expandedSize.width - centerOffset.width,
                                y: star.y / expandedRange * expandedSize.height - centerOffset.height
                            )
                    }
                }
                .offset(x: offsetX, y: offsetY)
                .rotationEffect(.degrees(rotation))
                .scaleEffect(scale)
            }
            .ignoresSafeArea()

            // Content on top
            content
        }
        .onAppear {
            if stars.isEmpty {
                generateStars()
            }
            startAnimations()
        }
    }

    // MARK: - Fog Layer

    private var fogLayer: some View {
        ZStack {
            // Fog 1 - Purple tint
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.appSecondary.opacity(0.15),
                    Color.clear
                ]),
                center: .topTrailing,
                startRadius: 10,
                endRadius: 300
            )
            .offset(fog1Offset)
            .ignoresSafeArea()

            // Fog 2 - Softer purple
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.appSecondary.opacity(0.1),
                    Color.clear
                ]),
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 250
            )
            .offset(fog2Offset)
            .ignoresSafeArea()
        }
    }

    // MARK: - Calculate Expanded Size
    
    private func calculateExpandedSize(for size: CGSize) -> CGSize {
        // Calculate expanded bounds to account for rotation (30°) and scale (1.05)
        // When rotating a rectangle, the bounding box becomes larger
        // For 30° rotation: cos(30°) ≈ 0.866, sin(30°) = 0.5
        // Expanded size ≈ original * (|cos| + |sin|) * maxScale
        let maxRotation = 30.0
        let maxScale: CGFloat = 1.05
        let cosAngle = abs(cos(maxRotation * .pi / 180))
        let sinAngle = abs(sin(maxRotation * .pi / 180))
        let expansionFactor = (cosAngle + sinAngle) * maxScale
        
        // Add some padding to be safe
        let safeExpansionFactor: CGFloat = expansionFactor * 1.1
        
        return CGSize(
            width: size.width * safeExpansionFactor,
            height: size.height * safeExpansionFactor
        )
    }

    // MARK: - Generate Stars

    private func generateStars() {
        var newStars: [Star] = []

        // Generate stars in expanded normalized range to cover rotated/scaled area
        // Using range 0 to 1.5 provides 50% padding to ensure coverage when rotated
        let expandedRange: CGFloat = 1.5

        // Generate 100 static stars with varied properties
        for _ in 0..<500 {
            // Generate stars in expanded area (normalized, but extended range)
            let x = CGFloat.random(in: 0...expandedRange)
            let y = CGFloat.random(in: 0...expandedRange)

            // Varied sizes: mostly tiny, some small, few medium
            let sizeRoll = Int.random(in: 0..<100)
            let size: CGFloat
            if sizeRoll < 70 {
                size = CGFloat.random(in: 0.8...1.2) // tiny
            } else if sizeRoll < 90 {
                size = CGFloat.random(in: 1.2...2.0) // small
            } else {
                size = CGFloat.random(in: 2.0...3.0) // medium
            }

            // Varied opacity for depth
            let opacity = Double.random(in: 0.3...0.8)

            newStars.append(Star(x: x, y: y, size: size, opacity: opacity))
        }

        stars = newStars
    }

    // MARK: - Animations

    private func startAnimations() {
        // Slow drift animation for star layer
        withAnimation(
            .easeInOut(duration: 20)
            .repeatForever(autoreverses: true)
        ) {
            offsetX = 8
            offsetY = -5
        }

        // Very slow rotation
        withAnimation(
            .linear(duration: 60)
            .repeatForever(autoreverses: true)
        ) {
            rotation = 30
        }

        // Subtle zoom in/out
        withAnimation(
            .easeInOut(duration: 25)
            .repeatForever(autoreverses: true)
        ) {
            scale = 1.1
        }

        // Fog animations
        withAnimation(
            .easeInOut(duration: 30)
            .repeatForever(autoreverses: true)
        ) {
            fog1Offset = CGSize(width: 50, height: -50)
        }

        withAnimation(
            .easeInOut(duration: 35)
            .repeatForever(autoreverses: true)
        ) {
            fog2Offset = CGSize(width: -50, height: 50)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Applies cosmic gradient background with calm animated starfield and fog
    func starfieldBackground() -> some View {
        modifier(StarfieldBackground())
    }
}

// MARK: - Preview

#Preview("Starfield Background", traits: .fixedLayout(width: 400, height: 600)) {
    VStack {
        Text("You Are Doing Great")
            .font(.largeTitle.weight(.bold))
            .foregroundStyle(.textPrimary)

        Text("Beautiful cosmic atmosphere")
            .font(.body)
            .foregroundStyle(.textSecondary)
    }
    .starfieldBackground()
    .preferredColorScheme(.dark)
}
