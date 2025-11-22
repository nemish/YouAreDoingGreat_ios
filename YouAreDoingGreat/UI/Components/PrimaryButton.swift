import SwiftUI

// MARK: - Primary Button
// Dark mode only for v1

struct PrimaryButton: View {
    let title: String
    var showGlow: Bool = false
    let action: () -> Void

    // Haptic feedback
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        Button(action: handleTap) {
            Text(title)
                .font(.appHeadline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient.primaryButton
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(
                    color: Color.appPrimary.opacity(0.3),
                    radius: 12,
                    x: 0,
                    y: 6
                )
                .shadow(
                    color: showGlow ? .white.opacity(0.15) : .clear,
                    radius: 8,
                    x: 0,
                    y: 0
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func handleTap() {
        // Haptic feedback
        impactFeedback.impactOccurred()
        // Execute action
        action()
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Primary Button") {
    VStack(spacing: 20) {
        PrimaryButton(title: "Get started") {
            print("Button tapped")
        }
        .padding(.horizontal)

        PrimaryButton(title: "Save this moment") {
            print("Save tapped")
        }
        .padding(.horizontal)

        PrimaryButton(title: "Done") {
            print("Done tapped")
        }
        .padding(.horizontal)
    }
    .starfieldBackground()
}
