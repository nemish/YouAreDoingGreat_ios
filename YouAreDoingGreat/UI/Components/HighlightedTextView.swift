import SwiftUI

// MARK: - Highlighted Text View
// Renders text with styled highlights using AttributedString

struct HighlightedTextView: View {
    let text: String
    let highlights: [PraiseHighlight]
    let baseFont: Font
    let isFirst: Bool
    let alignment: TextAlignment

    // Primary emphasis: warm gold + bold
    private let primaryColor = Color.appPrimary

    init(
        text: String,
        highlights: [PraiseHighlight],
        baseFont: Font,
        isFirst: Bool,
        alignment: TextAlignment = .center
    ) {
        self.text = text
        self.highlights = highlights
        self.baseFont = baseFont
        self.isFirst = isFirst
        self.alignment = alignment
    }

    var body: some View {
        Text(buildAttributedString())
            .multilineTextAlignment(alignment)
            .shadow(
                color: isFirst ? Color.black.opacity(0.3) : Color.clear,
                radius: isFirst ? 2 : 0,
                x: 0,
                y: isFirst ? 1 : 0
            )
    }

    private func buildAttributedString() -> AttributedString {
        var result = AttributedString(text)

        // Set base styling
        result.font = baseFont
        result.foregroundColor = isFirst ? Color.textHighlightOnePrimary : Color.white.opacity(0.85)

        // Apply highlights (process in reverse to maintain indices)
        let sortedHighlights = highlights.sorted { $0.start < $1.start }

        for highlight in sortedHighlights {
            // Validate range
            guard highlight.start >= 0,
                  highlight.end <= text.count,
                  highlight.start < highlight.end else { continue }

            // Convert Int offsets to AttributedString indices
            let startIdx = result.index(result.startIndex, offsetByCharacters: highlight.start)
            let endIdx = result.index(result.startIndex, offsetByCharacters: highlight.end)
            let range = startIdx..<endIdx

            switch highlight.emphasis {
            case .primary:
                // Bold + warm gold color + slight letter spacing
                result[range].foregroundColor = primaryColor
                result[range].font = isFirst ? .comfortaa(20, weight: .bold) : .comfortaa(17, weight: .bold)
                result[range].kern = 0.5  // Slightly looser tracking for emphasis

            case .secondary:
                // Bold only (keep base color)
                result[range].font = isFirst ? .comfortaa(20, weight: .bold) : .comfortaa(17, weight: .bold)
            }
        }

        return result
    }
}

// MARK: - Preview

#Preview("Highlighted Text - First Card") {
    ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        HighlightedTextView(
            text: "You're doing amazing!",
            highlights: [
                PraiseHighlight(start: 0, end: 21, type: .action, emphasis: .primary)
            ],
            baseFont: .comfortaa(20, weight: .bold),
            isFirst: true
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("Highlighted Text - Secondary Card") {
    ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        HighlightedTextView(
            text: "Your consistent effort over these past 3 days shows real dedication.",
            highlights: [
                PraiseHighlight(start: 0, end: 22, type: .action, emphasis: .primary),
                PraiseHighlight(start: 39, end: 45, type: .number, emphasis: .secondary)
            ],
            baseFont: .comfortaa(17, weight: .semibold),
            isFirst: false
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
