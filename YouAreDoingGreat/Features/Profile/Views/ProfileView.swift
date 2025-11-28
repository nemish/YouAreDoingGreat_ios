import SwiftUI

// MARK: - Profile View
// Full-screen profile/settings view with account info, stats, subscription, and support

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ProfileViewModel

    init(viewModel: ProfileViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background - cosmic gradient
                LinearGradient.cosmic
                    .ignoresSafeArea()

                // Content
                ScrollView {
                    VStack(spacing: 32) {
                        // Profile header
//                        profileHeader

                        // Account Info Section
                        if let profile = viewModel.userProfile {
                            accountInfoSection(profile: profile)
                        }

                        // Stats Section
                        if let stats = viewModel.userStats {
                            statsSection(stats: stats)
                        }

                        // Subscription Section
                        subscriptionSection

                        // Help & Support Section
                        helpSection

                        // Legal Links
                        legalSection

                        Spacer(minLength: 40)
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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
            .task {
                await viewModel.loadProfile()
            }
            .sheet(isPresented: $viewModel.showFeedbackSheet) {
                FeedbackSheet(
                    isPresented: $viewModel.showFeedbackSheet,
                    title: $viewModel.feedbackTitle,
                    message: $viewModel.feedbackMessage,
                    onSubmit: { await viewModel.submitFeedback() },
                    isSubmitting: viewModel.isSubmittingFeedback,
                    success: viewModel.feedbackSuccess
                )
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.error ?? "An error occurred")
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.appPrimary)

            Text("Profile")
                .font(.appTitle2)
                .foregroundStyle(.textPrimary)
        }
        .padding(.top, 20)
    }

    // MARK: - Account Info Section

    private func accountInfoSection(profile: UserDTO) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account")
                .font(.appHeadline)
                .foregroundStyle(.textSecondary)

            InfoRow(
                label: "User ID",
                value: viewModel.maskedUserID,
                copyable: true,
                onCopy: { viewModel.copyUserID() }
            )
        }
    }

    // MARK: - Stats Section

    private func statsSection(stats: UserStatsDTO) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stats")
                .font(.appHeadline)
                .foregroundStyle(.textSecondary)

            StatCard(
                icon: "sparkles",
                label: "Total Moments",
                value: "\(stats.totalMoments)"
            )

            StatCard(
                icon: "calendar",
                label: "Today",
                value: "\(stats.momentsToday)"
            )
//
//            StatCard(
//                icon: "flame.fill",
//                label: "Current Streak",
//                value: "\(stats.currentStreak) days"
//            )
        }
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Subscription")
                .font(.appHeadline)
                .foregroundStyle(.textSecondary)

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.isPremium ? "Premium" : "Free Plan")
                            .font(.appHeadline)
                            .foregroundStyle(.textPrimary)

                        Text(viewModel.planDescription)
                            .font(.appFootnote)
                            .foregroundStyle(.textSecondary)
                    }

                    Spacer()

                    if viewModel.isPremium {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.appPrimary)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                )

                if !viewModel.isPremium {
                    PrimaryButton(title: "Upgrade to Premium") {
                        viewModel.showPaywall()
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Help & Support Section

    private var helpSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Help & Support")
                .font(.appHeadline)
                .foregroundStyle(.textSecondary)

            Button {
                viewModel.showFeedbackSheet = true
            } label: {
                settingsRow(
                    icon: "envelope.fill",
                    title: "Contact Us",
                    subtitle: "Send us your feedback"
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Legal")
                .font(.appHeadline)
                .foregroundStyle(.textSecondary)

            Link(destination: URL(string: "https://you-are-doing-great.com/privacy")!) {
                settingsRow(
                    icon: "hand.raised.fill",
                    title: "Privacy Policy",
                    subtitle: "How we handle your data"
                )
            }
            .buttonStyle(.plain)

            Link(destination: URL(string: "https://you-are-doing-great.com/terms")!) {
                settingsRow(
                    icon: "doc.text.fill",
                    title: "Terms of Service",
                    subtitle: "Terms and conditions"
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Settings Row

    private func settingsRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(.appPrimary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)

                Text(subtitle)
                    .font(.appFootnote)
                    .foregroundStyle(.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.textTertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
}

// MARK: - Preview

#Preview("Profile View") {
    let apiClient = DefaultAPIClient()
    let userService = UserService(apiClient: apiClient)
    let viewModel = ProfileViewModel(userService: userService)

    // Mock data for preview
    viewModel.userProfile = UserDTO(
        id: "123",
        userId: "user_1234567890abcdef",
        status: .paywallNeeded
    )
    viewModel.userStats = UserStatsDTO(
        totalMoments: 127,
        momentsToday: 3,
        momentsYesterday: 5,
        currentStreak: 7,
        longestStreak: 14,
        lastMomentDate: "2025-11-28"
    )

    return ProfileView(viewModel: viewModel)
        .preferredColorScheme(.dark)
}

#Preview("Profile View - Premium") {
    let apiClient = DefaultAPIClient()
    let userService = UserService(apiClient: apiClient)
    let viewModel = ProfileViewModel(userService: userService)

    // Mock premium user
    viewModel.userProfile = UserDTO(
        id: "123",
        userId: "user_1234567890abcdef",
        status: .premium
    )
    viewModel.userStats = UserStatsDTO(
        totalMoments: 450,
        momentsToday: 12,
        momentsYesterday: 15,
        currentStreak: 28,
        longestStreak: 45,
        lastMomentDate: "2025-11-28"
    )

    return ProfileView(viewModel: viewModel)
        .preferredColorScheme(.dark)
}
