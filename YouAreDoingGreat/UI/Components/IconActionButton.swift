import SwiftUI

// MARK: - Icon Action Button
// Fixed-size icon button for secondary actions (Hug, Delete)
// Dark mode only for v1

struct IconActionButton: View {
    let icon: String
    var tint: Color = .textSecondary
    var backgroundColor: Color = .white.opacity(0.08)
    let action: () -> Void

    var body: some View {
        Button(action: handleTap) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 48, height: 48)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func handleTap() {
        Task { await HapticManager.shared.play(.gentleTap) }
        action()
    }
}

// MARK: - Preview

#Preview("Icon Action Buttons") {
    HStack(spacing: 12) {
        IconActionButton(icon: "heart", tint: .textSecondary) {
            print("Hug tapped")
        }

        IconActionButton(icon: "heart.fill", tint: .pink) {
            print("Unhug tapped")
        }

        IconActionButton(icon: "trash", tint: .red) {
            print("Delete tapped")
        }
    }
    .padding()
    .background(Color.background)
    .preferredColorScheme(.dark)
}
