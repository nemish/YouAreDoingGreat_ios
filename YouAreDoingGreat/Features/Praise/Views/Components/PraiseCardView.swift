import SwiftUI

// MARK: - Praise Card View
// A single floating card displaying highlighted praise text

struct PraiseCardView: View {
    let card: PraiseCard
    let isFirst: Bool

    // Typography based on position
    private var font: Font {
        isFirst ? .comfortaa(20, weight: .bold) : .comfortaa(17, weight: .semibold)
    }

    var body: some View {
        HighlightedTextView(
            text: card.text,
            highlights: card.highlights,
            baseFont: font,
            isFirst: isFirst
        )
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(
            color: Color.appPrimary.opacity(0.15),
            radius: 12,
            x: 0,
            y: 4
        )
    }

    private var cardBackground: some View {
        ZStack {
            // Background fill - warm gradient for first card, frosted glass for others
            if isFirst {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.appPrimary.opacity(0.15),
                                Color.appPrimary.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } else {
                // Blue-tinted frosted glass for secondary cards
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.3, green: 0.4, blue: 0.6).opacity(0.15),
                                Color(red: 0.2, green: 0.3, blue: 0.5).opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Gradient stroke border - more pronounced for first card
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isFirst ? 0.3 : 0.2),
                            Color.white.opacity(isFirst ? 0.08 : 0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isFirst ? 1.5 : 1
                )
        }
    }
}

// MARK: - Preview

#Preview("Praise Card - First") {
    ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        PraiseCardView(
            card: PraiseCard(
                text: "You're doing amazing!",
                highlights: [
                    PraiseHighlight(start: 0, end: 21, type: .action, emphasis: .primary)
                ]
            ),
            isFirst: true
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("Praise Card - Secondary") {
    ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        PraiseCardView(
            card: PraiseCard(
                text: "Your consistent effort over these past 3 days shows real dedication.",
                highlights: [
                    PraiseHighlight(start: 0, end: 22, type: .action, emphasis: .primary),
                    PraiseHighlight(start: 39, end: 45, type: .number, emphasis: .secondary)
                ]
            ),
            isFirst: false
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
