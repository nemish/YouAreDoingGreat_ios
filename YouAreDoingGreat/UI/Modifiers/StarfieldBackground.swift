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

        for _ in 0..<2000 {
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

    // Pre-rendered starfield image (rendered once at launch)
    @MainActor
    static let renderedImage: Image? = {
        let expandedRange: CGFloat = 1.5
        let imageSize = CGSize(width: 1600, height: 1200) // Larger for better quality

        let canvas = Canvas { context, size in
            for star in shared {
                let x = star.x / expandedRange * size.width
                let y = star.y / expandedRange * size.height

                var starContext = context
                starContext.opacity = star.opacity
                starContext.fill(
                    Circle().path(in: CGRect(
                        x: x - star.size / 2,
                        y: y - star.size / 2,
                        width: star.size,
                        height: star.size
                    )),
                    with: .color(.white)
                )
            }
        }
        .frame(width: imageSize.width, height: imageSize.height)

        let renderer = ImageRenderer(content: canvas)
        renderer.scale = 1.0

        guard let cgImage = renderer.cgImage else { return nil }
        return Image(decorative: cgImage, scale: 1.0)
    }()
}

// MARK: - Starfield Background ViewModifier
// Dark mode only for v1

struct StarfieldBackground: ViewModifier {
    var isPaused: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
        ZStack {
            // Background layers
            GeometryReader { geometry in
                let expandedSize = calculateExpandedSize(for: geometry.size)
                let centerOffsetX = (geometry.size.width - expandedSize.width) / 2
                let centerOffsetY = (geometry.size.height - expandedSize.height) / 2

                ZStack {
                    // Cosmic gradient background
                    LinearGradient.cosmic

                    // Animated transforms applied to pre-rendered starfield bitmap
                    TimelineView(.animation(paused: isPaused || reduceMotion)) { timeline in
                        let elapsed = (isPaused || reduceMotion) ? pausedTime : timeline.date.timeIntervalSince(StarfieldData.startTime) + timeOffset

                        // Calculate animated values (static when reduce motion is enabled)
                        let driftProgress = reduceMotion ? 0 : animationProgress(elapsed: elapsed, duration: 40)
                        let rotationProgress = reduceMotion ? 0 : animationProgress(elapsed: elapsed, duration: 60)
                        let scaleProgress = reduceMotion ? 0 : animationProgress(elapsed: elapsed, duration: 50)
                        let fog1Progress = reduceMotion ? 0 : animationProgress(elapsed: elapsed, duration: 20)
                        let fog2Progress = reduceMotion ? 0 : animationProgress(elapsed: elapsed, duration: 20)

                        ZStack {
                            // Use pre-rendered bitmap - no per-frame star iteration
                            if let starfieldImage = StarfieldData.renderedImage {
                                starfieldImage
                                    .resizable()
                                    .frame(width: expandedSize.width, height: expandedSize.height)
                                    .offset(
                                        x: centerOffsetX + CGFloat(8 * driftProgress),
                                        y: centerOffsetY - CGFloat(5 * driftProgress)
                                    )
                                    .rotationEffect(.degrees(30 * rotationProgress), anchor: .center)
                                    .scaleEffect(1.0 + 0.1 * scaleProgress, anchor: .center)
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .overlay {
                            // Fog/nebula layers on top (not transformed)
                            fogLayer(fog1Progress: fog1Progress, fog2Progress: fog2Progress)
                        }
                    }
                }
            }
            .ignoresSafeArea()

            // Content on top
            content
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
        }
    }

    // MARK: - Calculate Expanded Size
    
    private func calculateExpandedSize(for size: CGSize) -> CGSize {
        // 2x screen height, centered
        return CGSize(
            width: size.height * 2,
            height: size.height * 1.5
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
