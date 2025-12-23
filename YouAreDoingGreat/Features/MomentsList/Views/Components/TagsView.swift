import SwiftUI

// MARK: - Tags View Component
// Displays tags in a wrapping flow layout with overflow indicator

struct TagsView: View {
    let tags: [String]

    private let horizontalSpacing: CGFloat = 6
    private let verticalSpacing: CGFloat = 6

    var body: some View {
        FlowLayout(horizontalSpacing: horizontalSpacing, verticalSpacing: verticalSpacing) {
            ForEach(tags.prefix(3), id: \.self) { tag in
                TagPill(tag: tag)
            }

            if tags.count > 3 {
                Text("+\(tags.count - 3)")
                    .font(.appCaption)
                    .foregroundStyle(.textTertiary)
            }
        }
    }
}

// MARK: - Tag Pill Component

private struct TagPill: View {
    let tag: String

    var body: some View {
        Text("#\(tag.replacingOccurrences(of: "_", with: " "))")
            .font(.appCaption)
            .foregroundStyle(.appSecondary)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.appSecondary.opacity(0.2))
            )
    }
}

// MARK: - Flow Layout
// A custom layout that wraps content to the next line when it exceeds available width

struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat = 6
    var verticalSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(subviews[index].sizeThatFits(.unspecified))
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            // Check if we need to wrap to next line
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + verticalSpacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + horizontalSpacing
            totalWidth = max(totalWidth, currentX - horizontalSpacing)
        }

        let totalHeight = currentY + lineHeight
        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}

// MARK: - Preview

#Preview("Tags View") {
    ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        VStack(spacing: 16) {
            TagsView(tags: ["productivity", "work", "achievement"])
            TagsView(tags: ["self_care", "health"])
            TagsView(tags: ["creative", "art", "music", "design", "inspiration"])
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
