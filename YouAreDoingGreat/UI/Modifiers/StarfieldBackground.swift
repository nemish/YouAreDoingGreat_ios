import SwiftUI

// MARK: - Starfield Background ViewModifier
// Dark mode only for v1

struct StarfieldBackground: ViewModifier {
    @State private var animate = false

    func body(content: Content) -> some View {
        ZStack {
            // Cosmic gradient background
            LinearGradient.cosmic
                .ignoresSafeArea()

            // Animated stars
            GeometryReader { geometry in
                ForEach(0..<50, id: \.self) { index in
                    Circle()
                        .fill(Color.starfield)
                        .frame(width: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .opacity(animate ? 0.3 : 1.0)
                        .animation(
                            .easeInOut(duration: Double.random(in: 2...4))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...2)),
                            value: animate
                        )
                }
            }
            .ignoresSafeArea()

            // Content on top
            content
        }
        .onAppear {
            animate = true
        }
    }
}

// MARK: - View Extension

extension View {
    /// Applies cosmic gradient background with animated starfield
    func starfieldBackground() -> some View {
        modifier(StarfieldBackground())
    }
}

// MARK: - Preview

#Preview("Starfield Background", traits: .fixedLayout(width: 400, height: 600)) {
    VStack {
        Text("You Are Doing Great")
            .font(.largeTitle.weight(.bold))
            .foregroundStyle(Color.appTextPrimary)

        Text("Beautiful cosmic atmosphere")
            .font(.body)
            .foregroundStyle(Color.appTextSecondary)
    }
    .starfieldBackground()
}
