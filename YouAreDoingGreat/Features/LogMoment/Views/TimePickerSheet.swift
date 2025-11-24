import SwiftUI

// MARK: - Time Picker Sheet
// Dark mode only for v1

struct TimePickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let selectedSeconds: Int
    let onSelect: (Int) -> Void
    let onSetJustNow: () -> Void

    @State private var tempSelectedSeconds: Int

    init(selectedSeconds: Int, onSelect: @escaping (Int) -> Void, onSetJustNow: @escaping () -> Void) {
        self.selectedSeconds = selectedSeconds
        self.onSelect = onSelect
        self.onSetJustNow = onSetJustNow
        _tempSelectedSeconds = State(initialValue: selectedSeconds)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Title
                Text("When did it happen?")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                    .padding(.top, 16)

                // Picker
                Picker("Time ago", selection: $tempSelectedSeconds) {
                    ForEach(LogMomentViewModel.timeAgoOptions) { option in
                        Text(option.label)
                            .tag(option.seconds)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)

                // "ago" label
                Text("ago")
                    .font(.appBody)
                    .foregroundStyle(.textSecondary)

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    PrimaryButton(title: "Done") {
                        onSelect(tempSelectedSeconds)
                        dismiss()
                    }

                    Button {
                        onSetJustNow()
                        dismiss()
                    } label: {
                        Text("Set to just now")
                            .font(.appSubheadline)
                            .foregroundStyle(.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(LinearGradient.cosmic.ignoresSafeArea())
        }
    }
}

// MARK: - Preview

#Preview("Time Picker Sheet") {
    TimePickerSheet(
        selectedSeconds: 300,
        onSelect: { seconds in
            print("Selected: \(seconds) seconds")
        },
        onSetJustNow: {
            print("Set to just now")
        }
    )
    .preferredColorScheme(.dark)
}
