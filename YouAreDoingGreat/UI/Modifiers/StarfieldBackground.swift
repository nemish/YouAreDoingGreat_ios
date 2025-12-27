import SwiftUI

// MARK: - Multi-Point Star Path

/// Creates a star path with variable number of points (3-6)
/// - Parameters:
///   - center: Center point of the star
///   - outerRadius: Distance from center to star points
///   - innerRadius: Distance from center to inner corners (controls sharpness)
///   - points: Number of points (3-6)
///   - rotation: Rotation angle in radians
/// - Returns: A Path representing the star
private func starPath(
    center: CGPoint,
    outerRadius: CGFloat,
    innerRadius: CGFloat,
    points: Int,
    rotation: CGFloat = 0
) -> Path {
    let pointCount = max(3, min(6, points))
    let angleStep = .pi * 2 / CGFloat(pointCount)
    let halfStep = angleStep / 2

    return Path { path in
        // Start at first outer point (top, adjusted by rotation)
        let startAngle = -.pi / 2 + rotation
        path.move(to: CGPoint(
            x: center.x + outerRadius * cos(startAngle),
            y: center.y + outerRadius * sin(startAngle)
        ))

        for i in 0..<pointCount {
            let outerAngle = startAngle + CGFloat(i) * angleStep
            let innerAngle = outerAngle + halfStep
            let nextOuterAngle = outerAngle + angleStep

            // Inner corner
            path.addLine(to: CGPoint(
                x: center.x + innerRadius * cos(innerAngle),
                y: center.y + innerRadius * sin(innerAngle)
            ))

            // Next outer point
            path.addLine(to: CGPoint(
                x: center.x + outerRadius * cos(nextOuterAngle),
                y: center.y + outerRadius * sin(nextOuterAngle)
            ))
        }

        path.closeSubpath()
    }
}

// MARK: - Star Colors

/// Color palette for stars: light gold → white → light blue
private enum StarColor: CaseIterable {
    case warmGold      // Warm yellow-gold
    case paleGold      // Subtle gold tint
    case pureWhite     // Classic white
    case coolWhite     // Slightly blue-white
    case lightBlue     // Cool blue tint

    var color: Color {
        switch self {
        case .warmGold:  return Color(red: 1.0, green: 0.92, blue: 0.7)   // #FFEBB3
        case .paleGold:  return Color(red: 1.0, green: 0.96, blue: 0.85)  // #FFF5D9
        case .pureWhite: return Color.white
        case .coolWhite: return Color(red: 0.93, green: 0.95, blue: 1.0)  // #EDF2FF
        case .lightBlue: return Color(red: 0.8, green: 0.88, blue: 1.0)   // #CCE0FF
        }
    }

    static func random() -> StarColor {
        // Weighted distribution: more whites, fewer extreme colors
        let roll = Int.random(in: 0..<100)
        switch roll {
        case 0..<10:  return .warmGold    // 10%
        case 10..<25: return .paleGold    // 15%
        case 25..<60: return .pureWhite   // 35%
        case 60..<80: return .coolWhite   // 20%
        default:      return .lightBlue   // 20%
        }
    }
}

// MARK: - Shared Star Data
// Generated once at app launch, reused across all starfield instances

private enum StarfieldData {
    enum StarShape {
        case dot                       // Tiny stars - simple circles
        case pointed(Int, CGFloat)     // (pointCount: 3-6, sharpness: 0.25-0.5)
    }

    struct Star {
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double
        let shape: StarShape
        let rotation: CGFloat          // Random rotation in radians
        let color: StarColor
    }

    static let shared: [Star] = {
        var stars: [Star] = []
        let expandedRange: CGFloat = 1.5

        for _ in 0..<2000 {
            let x = CGFloat.random(in: 0...expandedRange)
            let y = CGFloat.random(in: 0...expandedRange)

            let sizeRoll = Int.random(in: 0..<100)
            let size: CGFloat
            let shape: StarShape
            let rotation = CGFloat.random(in: 0...(2 * .pi))
            let color = StarColor.random()

            if sizeRoll < 70 {
                // Small stars: dots (70%)
                size = CGFloat.random(in: 0.8...1.2)
                shape = .dot
            } else if sizeRoll < 90 {
                // Medium stars: 3-5 points, softer (20%)
                size = CGFloat.random(in: 1.2...2.0)
                let points = Int.random(in: 3...5)
                let sharpness = CGFloat.random(in: 0.4...0.5)  // Softer
                shape = .pointed(points, sharpness)
            } else {
                // Large stars: 4-6 points, sharper (10%)
                size = CGFloat.random(in: 2.0...3.5)
                let points = Int.random(in: 4...6)
                let sharpness = CGFloat.random(in: 0.25...0.4)  // Sharper
                shape = .pointed(points, sharpness)
            }

            let opacity = Double.random(in: 0.25...0.85)
            stars.append(Star(
                x: x, y: y, size: size, opacity: opacity,
                shape: shape, rotation: rotation, color: color
            ))
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
                let center = CGPoint(x: x, y: y)

                var starContext = context
                starContext.opacity = star.opacity

                switch star.shape {
                case .dot:
                    // Simple circle for tiny stars
                    starContext.fill(
                        Circle().path(in: CGRect(
                            x: x - star.size / 2,
                            y: y - star.size / 2,
                            width: star.size,
                            height: star.size
                        )),
                        with: .color(star.color.color)
                    )

                case .pointed(let points, let sharpness):
                    // Multi-point star with variable sharpness and rotation
                    let outerRadius = star.size
                    let innerRadius = star.size * sharpness
                    starContext.fill(
                        starPath(
                            center: center,
                            outerRadius: outerRadius,
                            innerRadius: innerRadius,
                            points: points,
                            rotation: star.rotation
                        ),
                        with: .color(star.color.color)
                    )
                }
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

                        // Use pre-rendered bitmap - no per-frame star iteration
                        Group {
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
            .accessibilityHidden(true)

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
