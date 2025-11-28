import SwiftUI

// MARK: - Animated Blob Orb
// Organic morphing blob shapes with elliptical particle orbits
// Inspired by Siri's visual design

struct AnimatedBlobOrb: View {
    @State private var startTime: Date = Date()
    @State private var pulseScale: CGFloat = 1.0
    @State private var rippleScale: CGFloat = 1.0
    @State private var rippleOpacity: Double = 0.0

    var body: some View {
        ZStack {
            // Main animated orb
            TimelineView(.animation) { timeline in
                let elapsed = timeline.date.timeIntervalSince(startTime)
                let animationPhase = CGFloat(elapsed.truncatingRemainder(dividingBy: 1000))

                meshGradientOrb(phase: animationPhase)
            }
            .scaleEffect(pulseScale)

            // Expanding ripple circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.appPrimary.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 100, height: 100)
                .scaleEffect(rippleScale)
                .opacity(rippleOpacity)
        }
        .onAppear {
            startTime = Date()
        }
        .onTapGesture {
            triggerPulse()
        }
    }

    // MARK: - Pulse Animation

    private func triggerPulse() {
        // Blob pulse: scale up then back to normal
        withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
            pulseScale = 1.30
        }

        // Return to normal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(duration: 0.5, bounce: 0.4)) {
                pulseScale = 1.0
            }
        }

        // Ripple animation: expand and fade out
        rippleScale = 1.0
        rippleOpacity = 1.0

        withAnimation(.easeOut(duration: 1.0)) {
            rippleScale = 3.0
            rippleOpacity = 0.0
        }

        // Add haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Mesh Gradient Orb

    private func meshGradientOrb(phase: CGFloat) -> some View {
        ZStack {
            backgroundGlow(phase: phase)
            mainBlobLayers(phase: phase)
            shimmerOverlay(phase: phase)
            sparkles(phase: phase)
        }
        .frame(width: 200, height: 200)
    }

    private func backgroundGlow(phase: CGFloat) -> some View {
        ForEach(0..<2, id: \.self) { index in
            AnimatedBlobShape(
                phase: phase + Double(index) * 0.3,
                complexity: 6 + index * 2
            )
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.3),
                        Color.appPrimary.opacity(0.2),
                        Color.appPrimary.opacity(0.1),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 100
                )
            )
            .frame(width: 140 + CGFloat(index) * 30, height: 140 + CGFloat(index) * 30)
            .blur(radius: 20 + CGFloat(index) * 10)
            .opacity(0.7)
            .rotationEffect(.degrees(phase * 8 * CGFloat(index == 0 ? 1 : -1)))
        }
    }

    private func mainBlobLayers(phase: CGFloat) -> some View {
        ZStack {
            primaryBlob(phase: phase)
            secondaryBlob(phase: phase)
            accentBlob(phase: phase)
        }
        .blur(radius: 3)
    }

    private func primaryBlob(phase: CGFloat) -> some View {
        AnimatedBlobShape(phase: phase, complexity: 8)
            .fill(
                RadialGradient(
                    colors: [
                        Color.white,
                        Color.white.opacity(0.95),
                        Color.white.opacity(0.7),
                        Color.appPrimary.opacity(0.4),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 60
                )
            )
            .frame(width: 110, height: 110)
            .rotationEffect(.degrees(phase * 12))
    }

    private func secondaryBlob(phase: CGFloat) -> some View {
        AnimatedBlobShape(phase: phase + 0.5, complexity: 7)
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.9),
                        Color.white.opacity(0.8),
                        Color.appPrimary.opacity(0.5),
                        Color.appPrimary.opacity(0.3),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 50
                )
            )
            .frame(width: 100, height: 100)
            .rotationEffect(.degrees(-phase * 16))
            .blendMode(.screen)
    }

    private func accentBlob(phase: CGFloat) -> some View {
        AnimatedBlobShape(phase: phase + 0.25, complexity: 6)
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.85),
                        Color.white.opacity(0.7),
                        Color.appPrimary.opacity(0.4),
                        Color.appPrimary.opacity(0.2),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 45
                )
            )
            .frame(width: 90, height: 90)
            .rotationEffect(.degrees(phase * 20))
            .blendMode(.screen)
    }

    private func shimmerOverlay(phase: CGFloat) -> some View {
        AnimatedBlobShape(phase: phase * 2, complexity: 10)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.6),
                        Color.appPrimary.opacity(0.4),
                        Color.clear,
                        Color.appPrimary.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 2
            )
            .frame(width: 95, height: 95)
            .blur(radius: 4)
            .rotationEffect(.degrees(phase * -24))
    }

    private func sparkles(phase: CGFloat) -> some View {
        ZStack {
            // Each sparkle has its own elliptical orbit
            orbitingSparkle(phase: phase, index: 0, semiMajorAxis: 45, semiMinorAxis: 30, speed: 0.2, startPhase: 0)
            orbitingSparkle(phase: phase, index: 1, semiMajorAxis: 38, semiMinorAxis: 25, speed: -0.3, startPhase: 2.1)
            orbitingSparkle(phase: phase, index: 2, semiMajorAxis: 50, semiMinorAxis: 35, speed: 0.4, startPhase: 4.2)
        }
    }

    private func orbitingSparkle(
        phase: CGFloat,
        index: Int,
        semiMajorAxis: CGFloat,
        semiMinorAxis: CGFloat,
        speed: Double,
        startPhase: Double
    ) -> some View {
        // Calculate elliptical orbit position
        let angle = phase * .pi * 2 * speed + startPhase
        let offsetX = cos(angle) * semiMajorAxis
        let offsetY = sin(angle) * semiMinorAxis

        // Vary sparkle size based on position (depth illusion)
        let depthFactor = (sin(angle) + 1) / 2 // 0 to 1
        let sparkleSize = 2.0 + depthFactor * 2.0 // 2 to 4

        return Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.8),
                        Color.white.opacity(0.3)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: sparkleSize / 2
                )
            )
            .frame(width: sparkleSize, height: sparkleSize)
            .offset(x: offsetX, y: offsetY)
            .blur(radius: 0.5 + depthFactor * 0.5)
            .opacity(0.6 + depthFactor * 0.3)
    }

}

// MARK: - Animated Blob Shape

private struct AnimatedBlobShape: Shape {
    var phase: CGFloat
    var complexity: Int

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        // Create organic blob shape with multiple control points
        let angleStep = (2 * .pi) / CGFloat(complexity)

        for i in 0..<complexity {
            let angle = angleStep * CGFloat(i)
            let nextAngle = angleStep * CGFloat(i + 1)

            // Add variation to radius for organic feel
            let variation1 = sin(angle * 3 + phase * .pi * 2) * 0.15
            let variation2 = cos(angle * 2 - phase * .pi * 2) * 0.1
            let currentRadius = radius * (1 + variation1 + variation2)

            let variation3 = sin(nextAngle * 3 + phase * .pi * 2) * 0.15
            let variation4 = cos(nextAngle * 2 - phase * .pi * 2) * 0.1
            let nextRadius = radius * (1 + variation3 + variation4)

            // Calculate points
            let currentPoint = CGPoint(
                x: center.x + cos(angle) * currentRadius,
                y: center.y + sin(angle) * currentRadius
            )

            let nextPoint = CGPoint(
                x: center.x + cos(nextAngle) * nextRadius,
                y: center.y + sin(nextAngle) * nextRadius
            )

            if i == 0 {
                path.move(to: currentPoint)
            }

            // Create smooth curves with control points
            let controlAngle = angle + angleStep / 2
            let controlVariation = sin(controlAngle * 2.5 + phase * .pi * 2) * 0.12
            let controlRadius = radius * (1 + controlVariation)

            let controlPoint1 = CGPoint(
                x: center.x + cos(angle + angleStep * 0.3) * controlRadius,
                y: center.y + sin(angle + angleStep * 0.3) * controlRadius
            )

            let controlPoint2 = CGPoint(
                x: center.x + cos(angle + angleStep * 0.7) * controlRadius,
                y: center.y + sin(angle + angleStep * 0.7) * controlRadius
            )

            path.addCurve(to: nextPoint, control1: controlPoint1, control2: controlPoint2)
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview("Animated Blob Orb") {
    ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        AnimatedBlobOrb()
    }
    .preferredColorScheme(.dark)
}
