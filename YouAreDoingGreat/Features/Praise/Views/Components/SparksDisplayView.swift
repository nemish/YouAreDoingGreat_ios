import SwiftUI
import UIKit

// MARK: - Particle Models

/// A particle orbiting the central orb in idle/pressing states
struct OrbitParticle: Identifiable {
    let id: Int
    let baseRadius: CGFloat    // Distance from center at rest (30-45pt)
    let angularSpeed: Double   // Radians per second
    let phase: Double          // Starting angle offset in radians
    let size: CGFloat          // Dot diameter (3-5pt)
    let opacity: Double        // Base opacity (0.6-1.0)
    let color: Color           // Amber or white-amber
}

/// A particle in the burst explosion on collection
struct BurstParticle: Identifiable {
    let id: Int
    let angle: Double          // Direction in radians
    let speed: CGFloat         // Points per second (250-500)
    let size: CGFloat          // Dot diameter (2-4pt)
    let color: Color
}

// MARK: - Constants

private enum SparksConstants {
    static let orbSize: CGFloat = 140          // Total orb frame (ambient halo)
    static let ringDiameter: CGFloat = 90      // Energy ring diameter
    static let ringStrokeWidth: CGFloat = 5    // Energy ring thickness
    static let pressDuration: Double = 1.0     // Long-press duration in seconds

    static let orbitParticleCount = 7
    static let burstParticleCount = 25

    // Glow
    static let glowMinOpacity: Double = 0.3
    static let glowMaxOpacity: Double = 0.6
    static let glowPressedOpacity: Double = 0.7
    static let breathingDuration: Double = 2.0

    // Haptic thresholds
    static let hapticThresholds: [Double] = [0.25, 0.5, 0.75, 1.0]

    static func makeOrbitParticles() -> [OrbitParticle] {
        (0..<orbitParticleCount).map { i in
            OrbitParticle(
                id: i,
                baseRadius: CGFloat.random(in: 30...45),
                angularSpeed: Double.random(in: 0.8...1.8) * (i.isMultiple(of: 2) ? 1 : -1),
                phase: Double(i) * (2 * .pi / Double(orbitParticleCount)),
                size: CGFloat.random(in: 3...5),
                opacity: Double.random(in: 0.6...1.0),
                color: i.isMultiple(of: 3) ? .white.opacity(0.9) : .appPrimary
            )
        }
    }
}

// MARK: - Sparks Display View

struct SparksDisplayView: View {
    let sparksAwarded: Int
    let onCollect: () -> Void

    // MARK: - State

    @State private var isRevealed = false
    @State private var glowOpacity: Double = SparksConstants.glowMinOpacity
    @State private var collectProgress: Double = 0
    @State private var isPressing = false
    @State private var isCollected = false
    @State private var pressStartTime: Date?
    @State private var lastHapticThreshold: Double = 0
    @State private var numberScale: CGFloat = 1.0
    @State private var numberWhiteFlash: Double = 0
    @State private var flashOpacity: Double = 0
    @State private var hintOffset: CGFloat = 0
    @State private var orbitParticles: [OrbitParticle] = SparksConstants.makeOrbitParticles()
    @State private var burstParticles: [BurstParticle] = []
    @State private var burstStartTime: Date?
    @State private var cancelStartTime: Date?
    @State private var cancelFromProgress: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Computed

    private var pressScale: CGFloat {
        1.0 + 0.08 * collectProgress
    }

    private var currentGlowOpacity: Double {
        if isPressing {
            return SparksConstants.glowMinOpacity + (SparksConstants.glowPressedOpacity - SparksConstants.glowMinOpacity) * collectProgress
        }
        return glowOpacity
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            TimelineView(.animation(minimumInterval: nil, paused: reduceMotion && !isPressing && cancelStartTime == nil)) { timeline in
                ZStack {
                    ambientHalo

                    if !reduceMotion {
                        orbitingParticlesView(date: timeline.date)
                    }

                    energyRing
                    numberDisplay

                    // Collection flash
                    if flashOpacity > 0 {
                        Circle()
                            .fill(Color.white)
                            .frame(width: SparksConstants.ringDiameter, height: SparksConstants.ringDiameter)
                            .opacity(flashOpacity)
                    }

                    // Burst particles via Canvas
                    if let burstStart = burstStartTime {
                        burstCanvas(date: timeline.date, startTime: burstStart)
                    }
                }
                .scaleEffect(pressScale)
                .onChange(of: timeline.date) { _, newDate in
                    updateProgress(currentDate: newDate)
                }
            }

            hintText
        }
        .scaleEffect(isRevealed ? 1 : 0.8)
        .opacity(isRevealed ? 1 : 0)
        .onAppear { startEntrance() }
        .onLongPressGesture(minimumDuration: SparksConstants.pressDuration) {
            // Gesture recognized — but we handle completion via timer
        } onPressingChanged: { pressing in
            if pressing {
                handlePressStart()
            } else {
                handlePressEnd()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("+\(sparksAwarded) sparks earned")
        .accessibilityHint("Long press to collect sparks")
    }

    // MARK: - Ambient Halo (Layered Orb)

    private var ambientHalo: some View {
        ZStack {
            // Outer halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.appPrimary.opacity(currentGlowOpacity * 0.3),
                            Color.appPrimary.opacity(0)
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 80
                    )
                )
                .frame(width: SparksConstants.orbSize, height: SparksConstants.orbSize)

            // Middle ring
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.appPrimary.opacity(currentGlowOpacity * 0.5),
                            Color.appPrimary.opacity(0)
                        ],
                        center: .center,
                        startRadius: 5,
                        endRadius: 55
                    )
                )
                .frame(width: 110, height: 110)

            // Inner core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.appPrimary.opacity(currentGlowOpacity * 0.8),
                            Color.appPrimary.opacity(currentGlowOpacity * 0.2),
                            Color.appPrimary.opacity(0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 35
                    )
                )
                .frame(width: 70, height: 70)
        }
    }

    // MARK: - Orbiting Particles

    private func orbitingParticlesView(date: Date) -> some View {
        let elapsed = date.timeIntervalSinceReferenceDate

        return ZStack {
            ForEach(orbitParticles) { particle in
                let angle = particle.phase + elapsed * particle.angularSpeed
                // Spiral inward proportional to collectProgress
                let radius = particle.baseRadius * (1.0 - collectProgress * 0.9)

                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .shadow(color: particle.color.opacity(0.6), radius: 3)
                    .offset(
                        x: cos(angle) * radius,
                        y: sin(angle) * radius
                    )
                    .opacity(particle.opacity)
            }
        }
        .frame(width: SparksConstants.orbSize, height: SparksConstants.orbSize)
    }

    // MARK: - Energy Ring

    private var energyRing: some View {
        Circle()
            .trim(from: 0, to: collectProgress)
            .stroke(
                AngularGradient(
                    colors: [
                        Color.appPrimary,
                        Color.appPrimary,
                        Color.white.opacity(0.8)
                    ],
                    center: .center,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360 * collectProgress)
                ),
                style: StrokeStyle(
                    lineWidth: SparksConstants.ringStrokeWidth,
                    lineCap: .round
                )
            )
            .frame(
                width: SparksConstants.ringDiameter,
                height: SparksConstants.ringDiameter
            )
            .rotationEffect(.degrees(-90))
            .shadow(
                color: Color.appPrimary.opacity(collectProgress > 0 ? 0.5 : 0),
                radius: 6
            )
    }

    // MARK: - Number Display

    private var numberDisplay: some View {
        VStack(spacing: 2) {
            Text("+\(sparksAwarded)")
                .font(.comfortaa(32, weight: .bold))
                .foregroundStyle(
                    Color.appPrimary
                        .opacity(1.0 - numberWhiteFlash * 0.5)
                )
                .overlay(
                    Text("+\(sparksAwarded)")
                        .font(.comfortaa(32, weight: .bold))
                        .foregroundStyle(Color.white)
                        .opacity(numberWhiteFlash)
                )
                .scaleEffect(numberScale)

            Text("sparks")
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
        }
    }

    // MARK: - Hint Text

    private var hintText: some View {
        Text("hold to collect")
            .font(.appFootnote)
            .foregroundStyle(.textTertiary)
            .opacity(isPressing ? 0 : 0.7)
            .offset(y: hintOffset)
            .padding(.bottom, 16)
    }

    // MARK: - Burst Particles

    private func burstCanvas(date: Date, startTime: Date) -> some View {
        let elapsed = date.timeIntervalSince(startTime)
        let burstDuration: Double = 0.6

        return Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            for particle in burstParticles {
                let t = min(1.0, elapsed / burstDuration)
                let distance = particle.speed * CGFloat(elapsed)
                let x = center.x + cos(particle.angle) * distance
                let y = center.y + sin(particle.angle) * distance
                let opacity = max(0, 1.0 - t)
                let particleSize = particle.size * (1.0 - CGFloat(t) * 0.5)

                let rect = CGRect(
                    x: x - particleSize / 2,
                    y: y - particleSize / 2,
                    width: particleSize,
                    height: particleSize
                )
                context.opacity = opacity
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(particle.color)
                )
            }
        }
        .frame(width: 300, height: 300)
        .allowsHitTesting(false)
    }

    // MARK: - Entrance

    private func startEntrance() {
        if !reduceMotion {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.2)) {
                isRevealed = true
            }
            // Breathing glow
            withAnimation(.easeInOut(duration: SparksConstants.breathingDuration).repeatForever(autoreverses: true)) {
                glowOpacity = SparksConstants.glowMaxOpacity
            }
            // Hint float
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                hintOffset = -2
            }
        } else {
            isRevealed = true
        }
    }

    // MARK: - Press Handling

    private func handlePressStart() {
        isPressing = true
        pressStartTime = Date()
        lastHapticThreshold = 0
        // Cancel any ongoing rewind
        cancelStartTime = nil
    }

    private func handlePressEnd() {
        isPressing = false
        pressStartTime = nil

        if collectProgress >= 1.0 {
            triggerCollection()
        } else {
            // Start timer-driven rewind so particles drift back smoothly
            cancelFromProgress = collectProgress
            cancelStartTime = Date()
        }
    }

    private func updateProgress(currentDate: Date) {
        // Handle cancel rewind (timer-driven so TimelineView sees intermediate values)
        if let cancelStart = cancelStartTime {
            let cancelDuration: Double = 0.3
            let elapsed = currentDate.timeIntervalSince(cancelStart)
            let t = min(1.0, elapsed / cancelDuration)
            // easeOut curve: 1 - (1-t)^2
            let eased = 1.0 - (1.0 - t) * (1.0 - t)
            collectProgress = cancelFromProgress * (1.0 - eased)
            if t >= 1.0 {
                collectProgress = 0
                cancelStartTime = nil
            }
            return
        }

        guard isPressing, let startTime = pressStartTime else { return }

        let elapsed = currentDate.timeIntervalSince(startTime)
        let newProgress = min(1.0, elapsed / SparksConstants.pressDuration)
        collectProgress = newProgress

        // Haptic ramp: fire at each threshold crossing
        for threshold in SparksConstants.hapticThresholds {
            if newProgress >= threshold && lastHapticThreshold < threshold {
                lastHapticThreshold = threshold
                let style: UIImpactFeedbackGenerator.FeedbackStyle = threshold >= 1.0 ? .medium : .light
                let generator = UIImpactFeedbackGenerator(style: style)
                generator.impactOccurred()
            }
        }

        // Auto-complete at 1.0
        if newProgress >= 1.0 && isPressing {
            isPressing = false
            pressStartTime = nil
            triggerCollection()
        }
    }

    // MARK: - Collection

    private func triggerCollection() {
        isCollected = true

        // Flash
        withAnimation(.easeOut(duration: 0.08)) {
            flashOpacity = 0.6
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 80_000_000)
            withAnimation(.easeOut(duration: 0.07)) {
                flashOpacity = 0
            }
        }

        // Number punch
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            numberScale = 1.2
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                numberScale = 1.0
                numberWhiteFlash = 0
            }
        }
        numberWhiteFlash = 1.0

        // Spawn burst particles
        spawnBurstParticles()

        // Fire callback after 0.3s delay
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000)
            onCollect()
        }
    }

    private func spawnBurstParticles() {
        burstStartTime = Date()
        burstParticles = (0..<SparksConstants.burstParticleCount).map { i in
            BurstParticle(
                id: i,
                angle: Double.random(in: 0...(2 * .pi)),
                speed: CGFloat.random(in: 250...500),
                size: CGFloat.random(in: 2...4),
                color: [Color.appPrimary, .white, Color.appPrimary.opacity(0.6)].randomElement()!
            )
        }

        // Clean up burst after animation completes
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)
            burstStartTime = nil
            burstParticles = []
        }
    }
}

// MARK: - Previews

#Preview("Sparks Display - Idle") {
    ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        SparksDisplayView(sparksAwarded: 51) {
            print("Collected!")
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Sparks Display - High Count") {
    ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        SparksDisplayView(sparksAwarded: 128) {
            print("Collected!")
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Sparks Display - Single Spark") {
    ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        SparksDisplayView(sparksAwarded: 1) {
            print("Collected!")
        }
    }
    .preferredColorScheme(.dark)
}
