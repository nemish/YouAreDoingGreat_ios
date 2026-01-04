import SwiftUI

// MARK: - Floating Toast
// Lightweight toast notification that floats above the tab bar
// Dark mode only for v1

struct FloatingToast: View {
    let toast: ToastMessage

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 10) {
            // Icon
            Image(systemName: toast.style.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(toast.style.iconColor)

            // Message
            Text(toast.message)
                .font(.appBody)
                .foregroundStyle(.textPrimary)
                .lineLimit(2)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.22, green: 0.23, blue: 0.28))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.5), radius: 16, y: 6)
        )
        .frame(maxWidth: 340)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(toast.message)
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Toast Container Modifier
// Use this modifier on the root view to display toasts

struct ToastContainerModifier: ViewModifier {
    @State private var toastService = ToastService.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let toast = toastService.currentToast {
                    FloatingToast(toast: toast)
                        .transition(reduceMotion
                            ? .opacity
                            : .asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            )
                        )
                        .padding(.bottom, 70) // Above tab bar
                        .padding(.horizontal, 24)
                        .onTapGesture {
                            toastService.dismiss()
                        }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: toastService.currentToast)
    }
}

extension View {
    /// Adds toast notification support to the view
    func toastContainer() -> some View {
        modifier(ToastContainerModifier())
    }
}

// MARK: - Previews

#Preview("Toast Styles") {
    ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        VStack(spacing: 16) {
            FloatingToast(toast: ToastMessage(message: "Moment deleted", style: .deleted))
            FloatingToast(toast: ToastMessage(message: "Changes saved", style: .success))
            FloatingToast(toast: ToastMessage(message: "Connection error", style: .error))
            FloatingToast(toast: ToastMessage(message: "Syncing in background", style: .info))
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Toast Interactive") {
    struct InteractivePreview: View {
        var body: some View {
            ZStack {
                LinearGradient.cosmic
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Button("Show Deleted Toast") {
                        ToastService.shared.showDeleted()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Show Success Toast") {
                        ToastService.shared.showSuccess("Changes saved")
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Show Error Toast") {
                        ToastService.shared.showError("Something went wrong")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .toastContainer()
        }
    }

    return InteractivePreview()
        .preferredColorScheme(.dark)
}
