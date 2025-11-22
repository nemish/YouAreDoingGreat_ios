import SwiftUI

// MARK: - Shared Star Data
// Generated once at app launch, reused across all starfield instances

private enum StarfieldData {
    struct Star {
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double
    }

    static let shared: [Star] = {
        var stars: [Star] = []
        let expandedRange: CGFloat = 1.5

        for _ in 0..<2500 {
            let x = CGFloat.random(in: 0...expandedRange)
            let y = CGFloat.random(in: 0...expandedRange)

            let sizeRoll = Int.random(in: 0..<100)
            let size: CGFloat
            if sizeRoll < 70 {
                size = CGFloat.random(in: 0.8...1.2)
            } else if sizeRoll < 90 {
                size = CGFloat.random(in: 1.2...2.0)
            } else {
                size = CGFloat.random(in: 2.0...3.0)
            }

            let opacity = Double.random(in: 0.3...0.8)
            stars.append(Star(x: x, y: y, size: size, opacity: opacity))
        }

        return stars
    }()

    static let startTime = Date()
}

// MARK: - Starfield Background ViewModifier
// Dark mode only for v1

struct StarfieldBackground: ViewModifier {
    var isPaused: Bool = false

    @State private var pausedTime: TimeInterval = 0
    @State private var timeOffset: TimeInterval = 0

    // Easing function for smooth animation
    private func easeInOut(_ t: Double) -> Double {
        t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
    }

    // Calculate animation progress (0 to 1, back to 0)
    private func animationProgress(elapsed: TimeInterval, duration: Double) -> Double {
        let cycle = elapsed.truncatingRemainder(dividingBy: duration * 2)
        let normalized = cycle / duration
        if normalized < 1 {
            return easeInOut(normalized)
        } else {
            return easeInOut(2 - normalized)
        }
    }

    func body(content: Content) -> some View {
        TimelineView(.animation(paused: isPaused)) { timeline in
            let elapsed = isPaused ? pausedTime : timeline.date.timeIntervalSince(StarfieldData.startTime) + timeOffset

            // Calculate animated values
            let driftProgress = animationProgress(elapsed: elapsed, duration: 20)
            let rotationProgress = animationProgress(elapsed: elapsed, duration: 60)
            let scaleProgress = animationProgress(elapsed: elapsed, duration: 25)
            let fog1Progress = animationProgress(elapsed: elapsed, duration: 30)
            let fog2Progress = animationProgress(elapsed: elapsed, duration: 35)

            ZStack {
                // Cosmic gradient background
                LinearGradient.cosmic
                    .ignoresSafeArea()

                // Fog/nebula layers (radial gradients)
                fogLayer(fog1Progress: fog1Progress, fog2Progress: fog2Progress)

                // Static starfield layer with group animation
                GeometryReader { geometry in
                    let expandedSize = calculateExpandedSize(for: geometry.size)
                    let expandedRange: CGFloat = 1.5
                    let centerOffset = CGSize(
                        width: (expandedSize.width - geometry.size.width) / 2,
                        height: (expandedSize.height - geometry.size.height) / 2
                    )

                    ZStack {
                        ForEach(0..<StarfieldData.shared.count, id: \.self) { index in
                            let star = StarfieldData.shared[index]
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
                    .offset(x: 8 * driftProgress, y: -5 * driftProgress)
                    .rotationEffect(.degrees(30 * rotationProgress))
                    .scaleEffect(1.0 + 0.1 * scaleProgress)
                    .drawingGroup()
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)

                // Content on top
                content
            }
        }
        .onChange(of: isPaused) { _, paused in
            if paused {
                pausedTime = Date().timeIntervalSince(StarfieldData.startTime) + timeOffset
            } else {
                timeOffset = pausedTime - Date().timeIntervalSince(StarfieldData.startTime)
            }
        }
    }

    // MARK: - Fog Layer

    private func fogLayer(fog1Progress: Double, fog2Progress: Double) -> some View {
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
            .offset(x: 50 * fog1Progress, y: -50 * fog1Progress)
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
            .offset(x: -50 * fog2Progress, y: 50 * fog2Progress)
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

}

// MARK: - View Extension

extension View {
    /// Applies cosmic gradient background with calm animated starfield and fog
    func starfieldBackground(isPaused: Bool = false) -> some View {
        modifier(StarfieldBackground(isPaused: isPaused))
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
