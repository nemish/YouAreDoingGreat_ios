import SwiftUI

// MARK: - Feedback Sheet
// Modal sheet for submitting user feedback with validation

struct FeedbackSheet: View {
    @Binding var isPresented: Bool
    @Binding var title: String
    @Binding var message: String
    let onSubmit: () async -> Void
    let isSubmitting: Bool
    let success: Bool

    @FocusState private var focusedField: Field?

    enum Field {
        case title, message
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.cosmic
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        if success {
                            successView
                        } else {
                            formView
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Contact Us")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.textSecondary)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Form View

    private var formView: some View {
        VStack(spacing: 24) {
            // Subject field
            VStack(alignment: .leading, spacing: 8) {
                Text("Subject")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)

                TextField("Brief description", text: $title)
                    .font(.appBody)
                    .foregroundStyle(.textPrimary)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.08))
                    )
                    .focused($focusedField, equals: .title)
                    .onChange(of: title) { _, newValue in
                        if newValue.count > 200 {
                            title = String(newValue.prefix(200))
                        }
                    }

                Text("\(title.count)/200")
                    .font(.appCaption)
                    .foregroundStyle(.textTertiary)
            }

            // Message field
            VStack(alignment: .leading, spacing: 8) {
                Text("Message")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)

                TextEditor(text: $message)
                    .font(.appBody)
                    .foregroundStyle(.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 150)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.08))
                    )
                    .focused($focusedField, equals: .message)
                    .onChange(of: message) { _, newValue in
                        if newValue.count > 5000 {
                            message = String(newValue.prefix(5000))
                        }
                    }

                Text("\(message.count)/5000")
                    .font(.appCaption)
                    .foregroundStyle(.textTertiary)
            }

            // Submit button
            PrimaryButton(title: "Send Feedback") {
                Task { await onSubmit() }
            }
            .disabled(isSubmitting || title.isEmpty || message.isEmpty)
            .opacity(isSubmitting || title.isEmpty || message.isEmpty ? 0.5 : 1)

            // Email fallback
            Link(destination: URL(string: "mailto:info@you-are-doing-great.com")!) {
                Text("Or email us directly")
                    .font(.appFootnote)
                    .foregroundStyle(.appSecondary)
            }
        }
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.appPrimary)

            Text("Feedback Sent!")
                .font(.appTitle2)
                .foregroundStyle(.textPrimary)

            Text("Thank you for your feedback. We'll get back to you soon.")
                .font(.appBody)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Preview

#Preview("Feedback Sheet") {
    FeedbackSheet(
        isPresented: .constant(true),
        title: .constant(""),
        message: .constant(""),
        onSubmit: { },
        isSubmitting: false,
        success: false
    )
    .preferredColorScheme(.dark)
}

#Preview("Feedback Sheet - Success") {
    FeedbackSheet(
        isPresented: .constant(true),
        title: .constant(""),
        message: .constant(""),
        onSubmit: { },
        isSubmitting: false,
        success: true
    )
    .preferredColorScheme(.dark)
}
