import SwiftUI

// MARK: - Tag Pill Component
// Reusable tag pill component with optional tap handler
// Displays formatted tag with accessibility support

struct TagPill: View {
    let tag: String
    var onTap: ((String) -> Void)? = nil

    var body: some View {
        let formattedTag = tag.replacingOccurrences(of: "_", with: " ")
        let content = Text("#\(formattedTag)")
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

        if let onTap = onTap {
            Button {
                Task { await HapticManager.shared.play(.gentleTap) }
                onTap(tag)
            } label: {
                content
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Tag: \(formattedTag)")
            .accessibilityHint("Double tap to filter moments by this tag")
        } else {
            content
                .accessibilityLabel("Tag: \(formattedTag)")
        }
    }
}

// MARK: - Preview

#Preview("Tag Pills") {
    ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        VStack(spacing: 16) {
            TagPill(tag: "productivity")
            TagPill(tag: "self_care")
            TagPill(tag: "work", onTap: { tag in
                print("Tapped: \(tag)")
            })
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
