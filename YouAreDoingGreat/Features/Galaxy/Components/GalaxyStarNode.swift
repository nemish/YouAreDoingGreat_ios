import SwiftUI
import SwiftData

struct GalaxyStarNode: View {
    let moment: Moment
    let position: CGPoint
    let colorIndex: Int
    let isHighlighted: Bool
    let onTap: () -> Void

    @State private var opacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    // MARK: - Star Appearance
    private var starSize: CGFloat {
        moment.isFavorite ? 20 : 12
    }

    private var starBrightness: Double {
        moment.isFavorite ? 1.0 : 0.6
    }

    private var starColor: Color {
        let colors: [Color] = [
            .appPrimary,
            .appSecondary,
            .blue,
            .purple,
            .pink,
            .cyan
        ]
        return colors[abs(colorIndex) % colors.count]
    }

    // MARK: - Text Truncation
    private var truncatedText: String {
        let words = moment.text.components(separatedBy: .whitespaces)
        if words.count <= 5 {
            return moment.text
        }
        return words.prefix(5).joined(separator: " ") + "..."
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            // Highlight ring (pulsing)
            if isHighlighted {
                Circle()
                    .strokeBorder(starColor, lineWidth: 3)
                    .frame(width: starSize * 3, height: starSize * 3)
                    .scaleEffect(pulseScale)
                    .opacity(0.8 / pulseScale) // Fade as it expands
                    .onAppear {
                        withAnimation(
                            .easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true)
                        ) {
                            pulseScale = 1.5
                        }
                    }
            }

            // Star and text
            VStack(spacing: -2) {
                // Realistic star visual
                RealisticStarView(
                    size: starSize,
                    color: starColor,
                    brightness: isHighlighted ? 1.2 : starBrightness,
                    seed: colorIndex
                )

                // Moment text (max 5 words)
                Text(truncatedText)
                    .font(.system(size: 6))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(2)
                    .frame(maxWidth: 50)
                    .multilineTextAlignment(.center)
            }
        }
        .position(position)
        .opacity(opacity)
        .onTapGesture(perform: onTap)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1
            }
        }
    }
}

// MARK: - Preview
#Preview {
    let moment = Moment(
        text: "Completed a great workout session",
        submittedAt: Date(),
        happenedAt: Date(),
        timezone: TimeZone.current.identifier,
        timeAgo: nil,
        offlinePraise: "Nice — that counts!"
    )

    ZStack {
        Color.black
            .ignoresSafeArea()

        GalaxyStarNode(
            moment: moment,
            position: CGPoint(x: 200, y: 200),
            colorIndex: 0,
            isHighlighted: true,
            onTap: {}
        )
    }
}
