import SwiftUI

// MARK: - Tags View Component
// Displays tags in a horizontal scrollable list with overflow indicator

struct TagsView: View {
    let tags: [String]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(tags.prefix(3), id: \.self) { tag in
                Text("#\(tag.replacingOccurrences(of: "_", with: " "))")
                    .font(.appCaption)
                    .foregroundStyle(.appSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.appSecondary.opacity(0.2))
                    )
            }

            if tags.count > 3 {
                Text("+\(tags.count - 3)")
                    .font(.appCaption)
                    .foregroundStyle(.textTertiary)
            }
        }
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
