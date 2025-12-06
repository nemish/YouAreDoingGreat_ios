import SwiftUI

// MARK: - Profile View
// Full-screen profile/settings view with account info, stats, subscription, and support

struct ProfileView: View {
    @State private var viewModel: ProfileViewModel
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    // Observe subscription service for real-time premium status updates
    private var subscriptionService = SubscriptionService.shared

    init(viewModel: ProfileViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var isPremium: Bool {
        subscriptionService.hasActiveSubscription
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

                        // Account Info Section - Always shown
                        if let profile = viewModel.userProfile {
                            accountInfoSection(profile: profile)
                        } else {
                            accountInfoLoadingSection
                        }

                        // Stats Section - Always shown
                        if let stats = viewModel.userStats {
                            statsSection(stats: stats)
                        } else {
                            statsLoadingSection
                        }

                        // Subscription Section
                        subscriptionSection

                        // Help & Support Section
                        helpSection

                        // Developer Section (DEBUG only)
                        developerSection

                        // Legal Links
                        legalSection

                        Spacer(minLength: 40)
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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
            .confirmationDialog(
                "Clear Local Database?",
                isPresented: $viewModel.showClearDatabaseConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear All Moments", role: .destructive) {
                    Task { await viewModel.clearLocalDatabase() }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will delete all moments from local storage. This action cannot be undone.")
            }
            .confirmationDialog(
                "Reset User Journey?",
                isPresented: $viewModel.showResetJourneyConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset Everything", role: .destructive) {
                    Task {
                        await viewModel.resetUserJourney {
                            withAnimation {
                                hasCompletedOnboarding = false
                            }
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will delete all moments, generate a new user ID, and return to the welcome screen. This action cannot be undone.")
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

    private var accountInfoLoadingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account")
                .font(.appHeadline)
                .foregroundStyle(.textSecondary)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("User ID")
                        .font(.appFootnote)
                        .foregroundStyle(.textSecondary)

                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(height: 20)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
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

    private var statsLoadingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stats")
                .font(.appHeadline)
                .foregroundStyle(.textSecondary)

            // Total Moments loading
            HStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 28))
                    .foregroundStyle(.appPrimary)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Moments")
                        .font(.appFootnote)
                        .foregroundStyle(.textSecondary)

                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(height: 20)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
            )

            // Today loading
            HStack(spacing: 16) {
                Image(systemName: "calendar")
                    .font(.system(size: 28))
                    .foregroundStyle(.appPrimary)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Today")
                        .font(.appFootnote)
                        .foregroundStyle(.textSecondary)

                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(height: 20)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
            )
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
                        Text(isPremium ? "Premium" : "Free Plan")
                            .font(.appHeadline)
                            .foregroundStyle(.textPrimary)

                        Text(isPremium ? "Enjoy 50 moments per day and advanced analytics" : "Limited to 3 moments per day")
                            .font(.appFootnote)
                            .foregroundStyle(.textSecondary)
                    }

                    Spacer()

                    if isPremium {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.appPrimary)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                )

                if !isPremium {
                    PrimaryButton(title: "Upgrade to Premium") {
                        viewModel.showPaywall()
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

    // MARK: - Developer Section

    @ViewBuilder
    private var developerSection: some View {
        if AppConfig.isDebugBuild {
            VStack(alignment: .leading, spacing: 16) {
                Text("Developer")
                    .font(.appHeadline)
                    .foregroundStyle(.textSecondary)

                Button {
                    viewModel.resetDailyLimit()
                } label: {
                    settingsRow(
                        icon: "clock.arrow.circlepath",
                        title: "Reset Daily Limit",
                        subtitle: "Clear daily moment limit restriction"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.showClearDatabaseConfirmation = true
                } label: {
                    settingsRow(
                        icon: "trash.fill",
                        title: "Clear Local Database",
                        subtitle: "Delete all moments from local storage"
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isClearingDatabase)
                .opacity(viewModel.isClearingDatabase ? 0.5 : 1.0)

                Button {
                    SubscriptionService.shared.setHasActiveSubscription(true)
                } label: {
                    settingsRow(
                        icon: "crown.fill",
                        title: "Simulate Premium",
                        subtitle: "Toggle premium state for testing"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    Task {
                        await SubscriptionService.shared.refreshSubscriptionStatus()
                    }
                } label: {
                    settingsRow(
                        icon: "arrow.clockwise",
                        title: "Refresh Subscription",
                        subtitle: "Re-fetch status from RevenueCat"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.showResetJourneyConfirmation = true
                } label: {
                    settingsRow(
                        icon: "arrow.counterclockwise.circle.fill",
                        title: "Reset User Journey",
                        subtitle: "New user ID, clear data, back to welcome"
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isResettingJourney)
                .opacity(viewModel.isResettingJourney ? 0.5 : 1.0)
            }
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

private func makePreviewViewModel() -> ProfileViewModel {
    let apiClient = DefaultAPIClient()
    let userService = UserService(apiClient: apiClient)
    let viewModel = ProfileViewModel(userService: userService)

    // Mock data for preview
    // Note: isPremium is based on SubscriptionService.shared.hasActiveSubscription
    viewModel.userProfile = UserDTO(
        id: "123",
        userId: "user_1234567890abcdef",
        status: .newcomer
    )
    viewModel.userStats = UserStatsDTO(
        totalMoments: 127,
        momentsToday: 3,
        momentsYesterday: 5,
        currentStreak: 7,
        longestStreak: 14,
        lastMomentDate: "2025-11-28"
    )

    return viewModel
}

#Preview("Profile View") {
    ProfileView(viewModel: makePreviewViewModel())
        .preferredColorScheme(.dark)
}

#Preview("Profile View - Premium") {
    // Note: To preview premium state, SubscriptionService.shared.hasActiveSubscription
    // needs to be true (requires actual subscription or mock)
    ProfileView(viewModel: makePreviewViewModel())
        .preferredColorScheme(.dark)
        .onAppear {
            // For preview purposes, manually set premium state
            SubscriptionService.shared.setHasActiveSubscription(true)
        }
}
