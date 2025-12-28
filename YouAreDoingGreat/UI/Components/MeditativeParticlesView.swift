import SwiftUI

// MARK: - Meditative Particles View
// Calm, ambient particle system layered on top of starfield
// Creates a meditative, ethereal atmosphere with breathing motion

// MARK: - Particle Types

private enum ParticleType {
    case orb    // Large, soft glowing circles
    case dust   // Tiny floating dots
}

// MARK: - Particle Color

private enum ParticleColor: CaseIterable {
    case lavender   // Purple/secondary
    case warmGold   // Primary accent
    case coolWhite  // Soft white

    var color: Color {
        switch self {
        case .lavender:  return Color.appSecondary
        case .warmGold:  return Color.appPrimary.opacity(0.6)
        case .coolWhite: return Color.white.opacity(0.9)
        }
    }

    static func randomOrb() -> ParticleColor {
        let roll = Int.random(in: 0..<100)
        switch roll {
        case 0..<40:  return .lavender   // 40%
        case 40..<65: return .warmGold   // 25%
        default:      return .coolWhite  // 35%
        }
    }
}

// MARK: - Particle Data

private struct MeditativeParticle {
    let id: UUID
    let type: ParticleType

    // Position (normalized 0-1, with buffer for edge spawning)
    let x: CGFloat
    let y: CGFloat

    // Visual properties
    let size: CGFloat
    let color: Color
    let baseOpacity: Double
    let blurRadius: CGFloat

    // Animation parameters (randomized per particle)
    let breathDuration: Double    // 5-8 seconds
    let breathPhase: Double       // 0-2π (stagger timing)
    let driftSpeedX: CGFloat      // points/second
    let driftSpeedY: CGFloat      // points/second
    let driftPhaseX: Double       // phase offset for X drift
    let driftPhaseY: Double       // phase offset for Y drift
    let driftAmplitudeX: CGFloat  // max drift distance X
    let driftAmplitudeY: CGFloat  // max drift distance Y
}

// MARK: - Depth Layer (parallax effect - bigger = closer to viewer)

private enum DepthLayer {
    case distant    // Far away - tiny, subtle
    case mid        // Middle distance
    case near       // Close - large, soft
    case foreground // Right in front of eyes - huge, very blurred, slow

    var sizeRange: ClosedRange<CGFloat> {
        switch self {
        case .distant:    return 20...40
        case .mid:        return 50...100
        case .near:       return 120...200
        case .foreground: return 220...350
        }
    }

    var opacityRange: ClosedRange<Double> {
        switch self {
        case .distant:    return 0.035...0.07
        case .mid:        return 0.03...0.06
        case .near:       return 0.025...0.045
        case .foreground: return 0.02...0.035
        }
    }

    var blurRange: ClosedRange<CGFloat> {
        switch self {
        case .distant:    return 15...25
        case .mid:        return 30...50
        case .near:       return 60...90
        case .foreground: return 100...150  // Very soft, out of focus
        }
    }

    // Very slow drift for meditative feel
    var driftSpeedRange: ClosedRange<CGFloat> {
        switch self {
        case .distant:    return 0.008...0.015
        case .mid:        return 0.005...0.01
        case .near:       return 0.003...0.006
        case .foreground: return 0.0015...0.003  // Very slow, dreamy float
        }
    }

    // Larger amplitude for closer particles
    var driftAmplitudeRange: ClosedRange<CGFloat> {
        switch self {
        case .distant:    return 30...60
        case .mid:        return 50...100
        case .near:       return 80...150
        case .foreground: return 150...280  // Large, languid movement across screen
        }
    }

    // Slower breathing for closer particles - 2x slower
    var breathDurationRange: ClosedRange<Double> {
        switch self {
        case .distant:    return 8...12
        case .mid:        return 10...16
        case .near:       return 14...20
        case .foreground: return 20...28  // Slow, meditative breath
        }
    }
}

// MARK: - Particle Generator

private enum ParticleGenerator {

    static func generateParticles() -> [MeditativeParticle] {
        var particles: [MeditativeParticle] = []

        // Foreground orbs (1-2) - huge, floating in front of eyes
        let foregroundCount = Int.random(in: 1...2)
        for _ in 0..<foregroundCount {
            particles.append(createOrbParticle(depth: .foreground))
        }

        // Near orbs (2-3) - large and soft
        let nearCount = Int.random(in: 2...3)
        for _ in 0..<nearCount {
            particles.append(createOrbParticle(depth: .near))
        }

        // Mid orbs (3-4) - medium sized
        let midCount = Int.random(in: 3...4)
        for _ in 0..<midCount {
            particles.append(createOrbParticle(depth: .mid))
        }

        // Distant orbs (4-6) - small and subtle
        let distantCount = Int.random(in: 4...6)
        for _ in 0..<distantCount {
            particles.append(createOrbParticle(depth: .distant))
        }

        // Generate dust particles (10-15)
        let dustCount = Int.random(in: 10...15)
        for _ in 0..<dustCount {
            particles.append(createDustParticle())
        }

        return particles
    }

    private static func createOrbParticle(depth: DepthLayer) -> MeditativeParticle {
        MeditativeParticle(
            id: UUID(),
            type: .orb,
            x: CGFloat.random(in: -0.2...1.2),
            y: CGFloat.random(in: -0.2...1.2),
            size: CGFloat.random(in: depth.sizeRange),
            color: ParticleColor.randomOrb().color,
            baseOpacity: Double.random(in: depth.opacityRange),
            blurRadius: CGFloat.random(in: depth.blurRange),
            breathDuration: Double.random(in: depth.breathDurationRange),
            breathPhase: Double.random(in: 0...(2 * .pi)),
            driftSpeedX: CGFloat.random(in: depth.driftSpeedRange),
            driftSpeedY: CGFloat.random(in: depth.driftSpeedRange),
            driftPhaseX: Double.random(in: 0...(2 * .pi)),
            driftPhaseY: Double.random(in: 0...(2 * .pi)),
            driftAmplitudeX: CGFloat.random(in: depth.driftAmplitudeRange),
            driftAmplitudeY: CGFloat.random(in: depth.driftAmplitudeRange.lowerBound * 0.7...depth.driftAmplitudeRange.upperBound * 0.8)
        )
    }

    private static func createDustParticle() -> MeditativeParticle {
        MeditativeParticle(
            id: UUID(),
            type: .dust,
            x: CGFloat.random(in: 0...1),
            y: CGFloat.random(in: 0...1),
            size: CGFloat.random(in: 2...6),
            color: Bool.random() ? .white : Color.appPrimary.opacity(0.8),
            baseOpacity: Double.random(in: 0.08...0.15),
            blurRadius: CGFloat.random(in: 1...4),
            breathDuration: Double.random(in: 6...12),
            breathPhase: Double.random(in: 0...(2 * .pi)),
            driftSpeedX: CGFloat.random(in: 0.006...0.015),
            driftSpeedY: CGFloat.random(in: 0.004...0.01),
            driftPhaseX: Double.random(in: 0...(2 * .pi)),
            driftPhaseY: Double.random(in: 0...(2 * .pi)),
            driftAmplitudeX: CGFloat.random(in: 8...20),
            driftAmplitudeY: CGFloat.random(in: 6...15)
        )
    }
}

// MARK: - Meditative Particles View

struct MeditativeParticlesView: View {
    var isPaused: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var particles: [MeditativeParticle] = []
    @State private var startTime: Date = Date()
    @State private var pausedTime: TimeInterval = 0
    @State private var timeOffset: TimeInterval = 0

    var body: some View {
        TimelineView(.animation(paused: isPaused || reduceMotion)) { timeline in
            let elapsed = (isPaused || reduceMotion)
                ? pausedTime
                : timeline.date.timeIntervalSince(startTime) + timeOffset

            Canvas { context, size in
                for particle in particles {
                    drawParticle(particle, context: context, size: size, elapsed: elapsed)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            // Generate new random particles each time the view appears
            particles = ParticleGenerator.generateParticles()
            startTime = Date()
            timeOffset = 0
            pausedTime = 0
        }
        .onChange(of: isPaused) { _, paused in
            if paused {
                pausedTime = Date().timeIntervalSince(startTime) + timeOffset
            } else {
                timeOffset = pausedTime - Date().timeIntervalSince(startTime)
            }
        }
    }

    // MARK: - Drawing

    private func drawParticle(
        _ particle: MeditativeParticle,
        context: GraphicsContext,
        size: CGSize,
        elapsed: TimeInterval
    ) {
        // Calculate breathing animation (scale oscillation)
        let breathProgress = sin((elapsed / particle.breathDuration + particle.breathPhase) * 2 * .pi)
        let scale: CGFloat
        let opacityMultiplier: Double

        if reduceMotion {
            // Static when reduce motion is enabled
            scale = 1.0
            opacityMultiplier = 1.0
        } else {
            scale = 1.0 + 0.15 * breathProgress
            // Opacity pulses slightly out of phase with scale for glow effect
            opacityMultiplier = 0.85 + 0.15 * sin((elapsed / particle.breathDuration + particle.breathPhase + 0.25) * 2 * .pi)
        }

        // Calculate drift position
        let driftX: CGFloat
        let driftY: CGFloat

        if reduceMotion {
            driftX = 0
            driftY = 0
        } else {
            driftX = sin((elapsed * particle.driftSpeedX + particle.driftPhaseX) * 2 * .pi) * particle.driftAmplitudeX
            driftY = sin((elapsed * particle.driftSpeedY + particle.driftPhaseY) * 2 * .pi) * particle.driftAmplitudeY
        }

        // Calculate final position
        let baseX = particle.x * size.width
        let baseY = particle.y * size.height
        let finalX = baseX + driftX
        let finalY = baseY + driftY

        // Calculate final size
        let finalSize = particle.size * scale

        // Calculate final opacity
        let finalOpacity = particle.baseOpacity * opacityMultiplier

        // Create the particle shape
        let rect = CGRect(
            x: finalX - finalSize / 2,
            y: finalY - finalSize / 2,
            width: finalSize,
            height: finalSize
        )

        // Apply context transformations
        var particleContext = context
        particleContext.opacity = finalOpacity

        // Draw based on particle type
        switch particle.type {
        case .orb:
            drawOrbParticle(
                context: particleContext,
                rect: rect,
                color: particle.color,
                blurRadius: particle.blurRadius * scale
            )

        case .dust:
            drawDustParticle(
                context: particleContext,
                rect: rect,
                color: particle.color,
                blurRadius: particle.blurRadius
            )
        }
    }

    private func drawOrbParticle(
        context: GraphicsContext,
        rect: CGRect,
        color: Color,
        blurRadius: CGFloat
    ) {
        // Simple solid circle - opacity is handled by context
        context.fill(
            Circle().path(in: rect),
            with: .color(color)
        )
    }

    private func drawDustParticle(
        context: GraphicsContext,
        rect: CGRect,
        color: Color,
        blurRadius: CGFloat
    ) {
        // Draw simple soft dot
        var blurredContext = context
        blurredContext.addFilter(.blur(radius: blurRadius))

        blurredContext.fill(
            Circle().path(in: rect),
            with: .color(color)
        )
    }
}

// MARK: - Preview

#Preview("Meditative Particles", traits: .fixedLayout(width: 400, height: 600)) {
    ZStack {
        LinearGradient.cosmic
        MeditativeParticlesView()
    }
    .ignoresSafeArea()
    .preferredColorScheme(.dark)
}

#Preview("With Starfield", traits: .fixedLayout(width: 400, height: 600)) {
    VStack {
        Text("Meditative Atmosphere")
            .font(.appLargeTitle)
            .foregroundStyle(.textPrimary)
    }
    .starfieldBackground()
    .preferredColorScheme(.dark)
}
