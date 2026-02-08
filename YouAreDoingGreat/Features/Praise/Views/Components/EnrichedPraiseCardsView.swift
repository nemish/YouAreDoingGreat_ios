import SwiftUI

// MARK: - Enriched Praise Cards View
// Container that manages sequential card reveal animation

struct EnrichedPraiseCardsView: View {
    let enrichedPraise: EnrichedPraise
    let fastAnimation: Bool

    @State private var visibleCardCount: Int = 0
    @State private var connectorDotCounts: [Int: Int] = [:]  // connector index -> visible dot count

    // Animation constants - halved when fastAnimation is true
    private var initialDelay: UInt64 { fastAnimation ? 200_000_000 : 400_000_000 }
    private var dotDelay: UInt64 { fastAnimation ? 75_000_000 : 150_000_000 }
    private var postDotsDelay: UInt64 { fastAnimation ? 100_000_000 : 200_000_000 }

    init(enrichedPraise: EnrichedPraise, fastAnimation: Bool = false) {
        self.enrichedPraise = enrichedPraise
        self.fastAnimation = fastAnimation
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(enrichedPraise.cards.enumerated()), id: \.element.id) { index, card in
                if index < visibleCardCount {
                    PraiseCardView(
                        card: card,
                        isFirst: index == 0
                    )
                    .transition(
                        .asymmetric(
                            insertion: .opacity
                                .combined(with: .move(edge: .bottom))
                                .combined(with: .scale(scale: 0.95)),
                            removal: .opacity
                        )
                    )

                    // Constellation connector (between cards, not after last)
                    if index < enrichedPraise.cards.count - 1 {
                        ConstellationConnector(visibleDots: connectorDotCounts[index] ?? 0)
                    }
                }
            }
        }
        .task {
            await revealCardsSequentially()
        }
    }

    private func revealCardsSequentially() async {
        // Initial delay before first card
        try? await Task.sleep(nanoseconds: initialDelay)

        for index in enrichedPraise.cards.indices {
            guard !Task.isCancelled else { break }

            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                visibleCardCount = index + 1
            }

            // Play haptic for each card
            await HapticManager.shared.play(index == 0 ? .warmArrival : .gentleTap)

            // Animate connector dots one by one (if not last card)
            if index < enrichedPraise.cards.count - 1 {
                for dotIndex in 1...3 {
                    try? await Task.sleep(nanoseconds: dotDelay)
                    guard !Task.isCancelled else { break }

                    withAnimation(.easeOut(duration: 0.2)) {
                        connectorDotCounts[index] = dotIndex
                    }
                }

                // Brief pause after all dots before next card
                try? await Task.sleep(nanoseconds: postDotsDelay)
            }
        }
    }
}

// MARK: - Constellation Connector
// Vertical dots that appear one by one between cards

private struct ConstellationConnector: View {
    let visibleDots: Int

    var body: some View {
        VStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 3, height: 3)
                    .opacity(index < visibleDots ? 1 : 0)
                    .scaleEffect(index < visibleDots ? 1 : 0.3)
            }
        }
        .frame(height: 28)  // Fixed height to prevent layout jumps
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview("Enriched Praise Cards") {
    ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        ScrollView {
            EnrichedPraiseCardsView(
                enrichedPraise: EnrichedPraise(
                    version: 1,
                    cards: [
                        PraiseCard(
                            text: "You're doing amazing!",
                            highlights: [
                                PraiseHighlight(start: 0, end: 21, type: .action, emphasis: .primary)
                            ]
                        ),
                        PraiseCard(
                            text: "Your consistent effort over these past 3 days shows real dedication.",
                            highlights: [
                                PraiseHighlight(start: 0, end: 22, type: .action, emphasis: .primary),
                                PraiseHighlight(start: 39, end: 45, type: .number, emphasis: .secondary)
                            ]
                        ),
                        PraiseCard(
                            text: "Keep showing up for yourself.",
                            highlights: [
                                PraiseHighlight(start: 5, end: 16, type: .positive, emphasis: .primary)
                            ]
                        )
                    ]
                )
            )
            .padding()
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Single Card") {
    ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        EnrichedPraiseCardsView(
            enrichedPraise: EnrichedPraise(
                version: 1,
                cards: [
                    PraiseCard(
                        text: "That's a win worth celebrating!",
                        highlights: [
                            PraiseHighlight(start: 10, end: 13, type: .positive, emphasis: .primary)
                        ]
                    )
                ]
            )
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
