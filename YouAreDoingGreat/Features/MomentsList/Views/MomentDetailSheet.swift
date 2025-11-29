import SwiftUI

// MARK: - Moment Detail Sheet
// Bottom sheet that displays full moment details with praise
// Includes action buttons for favorite and delete

struct MomentDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: MomentDetailViewModel
    let moment: Moment

    @State private var showMomentText = false
    @State private var showPraise = false
    @State private var showTags = false
    @State private var showButtons = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Cosmic background
                CosmicBackgroundView()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 32) {
                            // Moment text display (full text, no ellipsis)
                            VStack(spacing: 12) {
                                Text(moment.text)
                                    .font(.appTitle3)
                                    .foregroundStyle(.textPrimary)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(viewModel.timeDisplayText)
                                    .font(.appCaption)
                                    .foregroundStyle(.textTertiary)
                            }
                            .padding(.top, 24)
                            .opacity(showMomentText ? 1 : 0)

                            // Praise section
                            VStack(spacing: 16) {
                                // Offline praise (always shown)
                                Text(moment.offlinePraise)
                                    .font(.appHeadline)
                                    .foregroundStyle(.textHighlightOnePrimary)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)


                                // AI praise (shown when available)
                                if let aiPraise = moment.praise, !aiPraise.isEmpty {
                                    Text(aiPraise)
                                        .font(.appBody)
                                        .foregroundStyle(.textSecondary)
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                // Error message
                                if let error = moment.syncError, moment.isSynced == false {
                                    Text(error)
                                        .font(.appCaption)
                                        .foregroundStyle(.textTertiary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .opacity(showPraise ? 1 : 0)

                            // Tags section
                            if !moment.tags.isEmpty {
                                tagsSection
                                    .opacity(showTags ? 1 : 0)
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 120) // Add space for action buttons
                    }

                    // Action buttons fixed at bottom
                    VStack(spacing: 0) {
                        // Gradient fade for better visual separation
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color(red: 0.06, green: 0.07, blue: 0.11).opacity(0.95)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 20)

                        actionButtons
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                            .background(Color(red: 0.06, green: 0.07, blue: 0.11))
                            .opacity(showButtons ? 1 : 0)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                startAnimations()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
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

    // MARK: - Animations

    private func startAnimations() {
        withAnimation(.easeIn(duration: 0.6).delay(0.1)) {
            showMomentText = true
        }

        withAnimation(.easeIn(duration: 0.6).delay(0.4)) {
            showPraise = true
        }

        withAnimation(.easeIn(duration: 0.6).delay(0.7)) {
            showTags = true
        }

        withAnimation(.easeIn(duration: 0.6).delay(1.0)) {
            showButtons = true
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(moment.tags.enumerated()), id: \.offset) { index, tag in
                    Text("#\(tag.replacingOccurrences(of: "_", with: " "))")
                        .font(.appCaption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.appSecondary.opacity(0.6))
                        )
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Favorite button
            Button {
                Task {
                    await viewModel.toggleFavorite()
                    dismiss()
                }
            } label: {
                HStack {
                    Image(systemName: moment.isFavorite ? "star.fill" : "star")
                    Text(moment.isFavorite ? "Unfavorite" : "Favorite")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.08))
                .foregroundStyle(.textPrimary)
                .cornerRadius(12)
            }

            // Delete button
            Button(role: .destructive) {
                Task {
                    await viewModel.deleteMoment()
                    dismiss()
                }
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.08))
                .foregroundStyle(.red)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Preview

#Preview("Moment Detail Sheet") {
    let moment = Moment(
        text: "I finally cleaned my desk after three weeks",
        submittedAt: Date(),
        happenedAt: Date().addingTimeInterval(-3600),
        timezone: TimeZone.current.identifier,
        timeAgo: 3600,
        offlinePraise: "Nice. You're making moves."
    )
    moment.praise = "That's awesome! Taking care of your space is taking care of yourself."
    moment.tags = ["self_care", "productivity"]

    return MomentDetailSheet(
        viewModel: MomentDetailViewModel(
            moment: moment,
            onFavoriteToggle: { _ in },
            onDelete: { _ in }
        ),
        moment: moment
    )
    .preferredColorScheme(.dark)
}
