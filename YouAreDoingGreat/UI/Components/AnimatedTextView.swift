import SwiftUI

// MARK: - Animated Text View
// Renders text word-by-word with smooth fade-in animation
// Extracted for easy testing and reusability

struct AnimatedTextView: View {
    let text: String
    let font: Font
    let foregroundStyle: Color
    let multilineTextAlignment: TextAlignment
    let wordDelay: TimeInterval

    @State private var visibleWordCount: Int = 0

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
        // Build text with visible words only
        Text(buildVisibleText())
            .font(font)
            .foregroundStyle(foregroundStyle)
            .multilineTextAlignment(multilineTextAlignment)
            .animation(.easeIn(duration: 0.15), value: visibleWordCount)
            .task(id: text) {
                // Reset and restart animation when text changes
                visibleWordCount = 0
                await animateWords()
            }
    }

    private func buildVisibleText() -> String {
        guard visibleWordCount > 0 else { return "" }

        let visibleWords = words.prefix(visibleWordCount)
        return visibleWords.joined(separator: " ")
    }

    private func animateWords() async {
        // Guard against empty text to avoid runtime crash
        guard !words.isEmpty else { return }

        for index in 1...words.count {
            guard !Task.isCancelled else { break }

            visibleWordCount = index

            // Don't delay after the last word
            if index < words.count {
                try? await Task.sleep(nanoseconds: UInt64(wordDelay * 1_000_000_000))
            }
        }
    }
}

// MARK: - Alternative Implementation using HStack
// This version provides more explicit control but uses more layout computation

struct AnimatedTextViewHStack: View {
    let text: String
    let font: Font
    let foregroundStyle: Color
    let multilineTextAlignment: TextAlignment
    let wordDelay: TimeInterval

    @State private var visibleWordCount: Int = 0

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
        ViewThatFits {
            // Try single line first
            HStack(spacing: 4) {
                ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                    Text(word)
                        .opacity(index < visibleWordCount ? 1 : 0)
                }
            }

            // Fall back to wrapped layout
            wrappedWordsView
        }
        .font(font)
        .foregroundStyle(foregroundStyle)
        .multilineTextAlignment(multilineTextAlignment)
        .task(id: text) {
            visibleWordCount = 0
            await animateWords()
        }
    }

    private var wrappedWordsView: some View {
        // FlexBox-like layout for word wrapping
        // Using GeometryReader + manual layout calculation
        GeometryReader { geometry in
            let layout = calculateWordLayout(words: words, maxWidth: geometry.size.width)

            VStack(alignment: textAlignmentToHorizontalAlignment(multilineTextAlignment), spacing: 4) {
                ForEach(layout.indices, id: \.self) { lineIndex in
                    HStack(spacing: 4) {
                        ForEach(layout[lineIndex].indices, id: \.self) { wordIndex in
                            let globalIndex = layout[lineIndex][wordIndex]
                            Text(words[globalIndex])
                                .opacity(globalIndex < visibleWordCount ? 1 : 0)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: textAlignmentToAlignment(multilineTextAlignment))
        }
    }

    private func calculateWordLayout(words: [String], maxWidth: CGFloat) -> [[Int]] {
        // Simple word wrapping algorithm
        // Returns array of lines, where each line is an array of word indices
        var lines: [[Int]] = [[]]
        var currentLineWidth: CGFloat = 0
        let spaceWidth: CGFloat = 4 // Approximation

        for (index, word) in words.enumerated() {
            // Rough estimate of word width (more accurate would use UIFont)
            let wordWidth = CGFloat(word.count) * 10 // Approximation

            if currentLineWidth + wordWidth > maxWidth && !lines[lines.count - 1].isEmpty {
                // Start new line
                lines.append([index])
                currentLineWidth = wordWidth
            } else {
                // Add to current line
                lines[lines.count - 1].append(index)
                currentLineWidth += wordWidth + spaceWidth
            }
        }

        return lines
    }

    private func textAlignmentToHorizontalAlignment(_ alignment: TextAlignment) -> HorizontalAlignment {
        switch alignment {
        case .leading: return .leading
        case .trailing: return .trailing
        default: return .center
        }
    }

    private func textAlignmentToAlignment(_ alignment: TextAlignment) -> Alignment {
        switch alignment {
        case .leading: return .leading
        case .trailing: return .trailing
        default: return .center
        }
    }

    private func animateWords() async {
        // Guard against empty text for consistency
        guard !words.isEmpty else { return }

        for index in 0...words.count {
            guard !Task.isCancelled else { break }

            withAnimation(.easeIn(duration: 0.15)) {
                visibleWordCount = index
            }

            if index < words.count {
                try? await Task.sleep(nanoseconds: UInt64(wordDelay * 1_000_000_000))
            }
        }
    }
}

// MARK: - Preview

#Preview("Short Text") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            AnimatedTextView(
                text: "That's it. Small stuff adds up.",
                font: .appHeadline,
                foregroundStyle: Color.appPrimary
            )
            .padding()
        }
    }
}

#Preview("Long Text") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            AnimatedTextView(
                text: "You're making real progress here. Every single step you take matters, even when it doesn't feel like it. Keep going, you're doing amazing.",
                font: .appBody,
                foregroundStyle: .white.opacity(0.9)
            )
            .padding()
        }
    }
}

#Preview("Fast Animation") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            AnimatedTextView(
                text: "Look at you, doing things.",
                font: .appHeadline,
                foregroundStyle: Color.appPrimary,
                wordDelay: 0.05
            )
            .padding()
        }
    }
}

#Preview("Slow Animation") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            AnimatedTextView(
                text: "Progress isn't always loud.",
                font: .appHeadline,
                foregroundStyle: Color.appPrimary,
                wordDelay: 0.15
            )
            .padding()
        }
    }
}

#Preview("HStack Version") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            AnimatedTextViewHStack(
                text: "Nice. You're making moves.",
                font: .appHeadline,
                foregroundStyle: Color.appPrimary
            )
            .padding()
        }
    }
}

#Preview("Empty Text") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            Text("Empty text test:")
                .font(.appCaption)
                .foregroundStyle(.white)

            AnimatedTextView(
                text: "",
                font: .appHeadline,
                foregroundStyle: Color.appPrimary
            )
            .padding()
            .border(.red.opacity(0.3))

            Text("Whitespace text test:")
                .font(.appCaption)
                .foregroundStyle(.white)

            AnimatedTextView(
                text: "   ",
                font: .appHeadline,
                foregroundStyle: Color.appPrimary
            )
            .padding()
            .border(.red.opacity(0.3))
        }
    }
}
