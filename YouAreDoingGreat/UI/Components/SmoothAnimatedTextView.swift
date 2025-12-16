import SwiftUI

// MARK: - Smooth Animated Text View
// Renders text word-by-word with smooth fade-in animation
// Pre-reserves space to avoid layout jumps during animation

struct SmoothAnimatedTextView: View {
    let text: String
    let font: Font
    let foregroundStyle: Color
    let multilineTextAlignment: TextAlignment
    let wordDelay: TimeInterval

    @State private var wordOpacities: [Double] = []

    private var words: [String] {
        text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
    }

    init(
        text: String,
        font: Font = .appBody,
        foregroundStyle: Color = .white,
        multilineTextAlignment: TextAlignment = .center,
        wordDelay: TimeInterval = 0.08
    ) {
        self.text = text
        self.font = font
        self.foregroundStyle = foregroundStyle
        self.multilineTextAlignment = multilineTextAlignment
        self.wordDelay = wordDelay
    }

    var body: some View {
        ZStack {
            // Invisible placeholder - establishes full layout/height immediately
            Text(text)
                .font(font)
                .multilineTextAlignment(multilineTextAlignment)
                .opacity(0)

            // Visible text with per-word opacity via AttributedString
            Text(attributedText)
                .font(font)
                .multilineTextAlignment(multilineTextAlignment)
        }
        .task(id: text) {
            await animateWordsIn()
        }
    }

    // Build AttributedString with individual word opacities
    private var attributedText: AttributedString {
        var result = AttributedString()

        for (index, word) in words.enumerated() {
            var wordAttr = AttributedString(word)
            let opacity = wordOpacities.indices.contains(index) ? wordOpacities[index] : 0
            wordAttr.foregroundColor = foregroundStyle.opacity(opacity)
            result.append(wordAttr)

            // Add space after each word except the last
            if index < words.count - 1 {
                var space = AttributedString(" ")
                // Space inherits opacity from current word for smoother look
                space.foregroundColor = foregroundStyle.opacity(opacity)
                result.append(space)
            }
        }

        return result
    }

    private func animateWordsIn() async {
        guard !words.isEmpty else { return }

        // Initialize all words as invisible
        wordOpacities = Array(repeating: 0, count: words.count)

        // Small initial delay to let the container settle
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms

        for index in words.indices {
            guard !Task.isCancelled else { break }

            // Animate this word's opacity to 1
            withAnimation(.easeIn(duration: 0.15)) {
                wordOpacities[index] = 1.0
            }

            // Delay before next word (except for last word)
            if index < words.count - 1 {
                try? await Task.sleep(nanoseconds: UInt64(wordDelay * 1_000_000_000))
            }
        }
    }
}

// MARK: - Preview

#Preview("Smooth - Short Text") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            SmoothAnimatedTextView(
                text: "That's it. Small stuff adds up.",
                font: .appHeadline,
                foregroundStyle: Color.appPrimary
            )
            .padding()
        }
    }
}

#Preview("Smooth - Long Text") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            SmoothAnimatedTextView(
                text: "You're making real progress here. Every single step you take matters, even when it doesn't feel like it. Keep going, you're doing amazing.",
                font: .appBody,
                foregroundStyle: .white.opacity(0.9)
            )
            .padding()
        }
    }
}

#Preview("Smooth - Comparison") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 60) {
            VStack(spacing: 8) {
                Text("Old (AnimatedTextView):")
                    .font(.appCaption)
                    .foregroundStyle(.gray)

                AnimatedTextView(
                    text: "Progress isn't always loud. Sometimes it's quiet and steady.",
                    font: .appBody,
                    foregroundStyle: .white
                )
                .padding()
                .border(.red.opacity(0.3))
            }

            VStack(spacing: 8) {
                Text("New (SmoothAnimatedTextView):")
                    .font(.appCaption)
                    .foregroundStyle(.gray)

                SmoothAnimatedTextView(
                    text: "Progress isn't always loud. Sometimes it's quiet and steady.",
                    font: .appBody,
                    foregroundStyle: .white
                )
                .padding()
                .border(.green.opacity(0.3))
            }
        }
        .padding()
    }
}
