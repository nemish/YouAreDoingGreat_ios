import SwiftUI

// MARK: - Journey View Mode
// Enum for switching between timeline and month views

enum JourneyViewMode: String, CaseIterable {
    case timeline = "Timeline"
    case month = "Month"

    var iconName: String {
        switch self {
        case .timeline: return "list.bullet"
        case .month: return "calendar"
        }
    }
}

// MARK: - Journey View Mode Toggle
// Capsule-style toggle for switching between timeline and month views

struct JourneyViewModeToggle: View {
    @Binding var selectedMode: JourneyViewMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(JourneyViewMode.allCases, id: \.self) { mode in
                Button {
                    handleModeChange(mode)
                } label: {
                    Image(systemName: mode.iconName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(selectedMode == mode ? .white : .textTertiary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            selectedMode == mode
                                ? Capsule().fill(Color.appPrimary.opacity(0.8))
                                : Capsule().fill(Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
    }

    private func handleModeChange(_ mode: JourneyViewMode) {
        guard mode != selectedMode else { return }

        Task { await HapticManager.shared.play(.gentleTap) }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedMode = mode
        }
    }
}

// MARK: - Preview

#Preview("View Mode Toggle") {
    struct PreviewWrapper: View {
        @State private var mode: JourneyViewMode = .timeline

        var body: some View {
            ZStack {
                LinearGradient.cosmic
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    Text("Current: \(mode.rawValue)")
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)

                    JourneyViewModeToggle(selectedMode: $mode)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    return PreviewWrapper()
}
