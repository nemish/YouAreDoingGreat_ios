import SwiftUI

// MARK: - Action Button Row
// Shared button layout for PraiseView and MomentDetailSheet
// Nice button fills remaining width, Hug and Delete are icon-width
// Dark mode only for v1

struct ActionButtonRow: View {
    // Configuration
    let primaryTitle: String
    let isHugged: Bool
    let showDelete: Bool

    // Actions
    let onPrimary: () -> Void
    let onHug: () -> Void
    let onDelete: (() -> Void)?

    // State
    var isPrimaryDisabled: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Nice button (primary) - fills remaining space
            PrimaryButton(title: primaryTitle, action: onPrimary)
                .disabled(isPrimaryDisabled)

            // Hug button - fixed width with animation
            HugButton(isHugged: isHugged, action: onHug)

            // Delete button - fixed width (optional)
            if showDelete, let onDelete {
                IconActionButton(
                    icon: "trash",
                    tint: .red,
                    action: onDelete
                )
                .accessibilityLabel("Delete moment")
                .accessibilityHint("Double tap to delete this moment")
            }
        }
    }
}

// MARK: - Preview

#Preview("Action Button Row - Praise") {
    VStack(spacing: 20) {
        // Not hugged
        ActionButtonRow(
            primaryTitle: "Nice",
            isHugged: false,
            showDelete: false,
            onPrimary: { print("Nice") },
            onHug: { print("Hug") },
            onDelete: nil
        )

        // Hugged
        ActionButtonRow(
            primaryTitle: "Nice",
            isHugged: true,
            showDelete: false,
            onPrimary: { print("Nice") },
            onHug: { print("Unhug") },
            onDelete: nil
        )
    }
    .padding(.horizontal, 24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.background)
    .preferredColorScheme(.dark)
}

#Preview("Action Button Row - Detail") {
    VStack(spacing: 20) {
        // Not hugged with delete
        ActionButtonRow(
            primaryTitle: "Nice",
            isHugged: false,
            showDelete: true,
            onPrimary: { print("Nice") },
            onHug: { print("Hug") },
            onDelete: { print("Delete") }
        )

        // Hugged with delete
        ActionButtonRow(
            primaryTitle: "Nice",
            isHugged: true,
            showDelete: true,
            onPrimary: { print("Nice") },
            onHug: { print("Unhug") },
            onDelete: { print("Delete") }
        )
    }
    .padding(.horizontal, 24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.background)
    .preferredColorScheme(.dark)
}
