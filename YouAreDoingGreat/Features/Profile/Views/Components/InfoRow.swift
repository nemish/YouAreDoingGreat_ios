import SwiftUI

// MARK: - Info Row Component
// Reusable row for displaying account information with optional copy button

struct InfoRow: View {
    let label: String
    let value: String
    let copyable: Bool
    var onCopy: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.appFootnote)
                    .foregroundStyle(.textSecondary)

                Text(value)
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
            }

            Spacer()

            if copyable {
                Button {
                    onCopy?()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 18))
                        .foregroundStyle(.appPrimary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
}

// MARK: - Preview

#Preview("Info Row") {
    VStack(spacing: 12) {
        InfoRow(
            label: "User ID",
            value: "1234...5678",
            copyable: true,
            onCopy: {
                print("Copied!")
            }
        )

        InfoRow(
            label: "Email",
            value: "user@example.com",
            copyable: false
        )
    }
    .padding(24)
    .starfieldBackground()
    .preferredColorScheme(.dark)
}
