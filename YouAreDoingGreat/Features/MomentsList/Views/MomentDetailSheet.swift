import SwiftUI
import SwiftData

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

    private var timeOfDay: TimeOfDay {
        TimeOfDay(from: moment.happenedAt)
    }

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
                                // Time-of-day icon
                                Image(systemName: timeOfDay.iconName)
                                    .font(.system(size: 32))
                                    .foregroundStyle(timeOfDay.accentColor)
                                    .padding(.bottom, 8)

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

                                // Loading indicator for AI praise (enrichment in progress)
                                if viewModel.isLoadingAIPraise {
                                    MomentSyncLoadingView()
                                        .transition(.asymmetric(
                                            insertion: .opacity.combined(with: .scale(scale: 0.8)),
                                            removal: .opacity.combined(with: .scale(scale: 0.8))
                                        ))
                                }

                                // AI praise (shown when available)
                                if let aiPraise = moment.praise, !aiPraise.isEmpty {
                                    Text(aiPraise)
                                        .font(.appBody)
                                        .foregroundStyle(.textSecondary)
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                // Sync error with retry button
                                if moment.syncError != nil, !moment.isSynced {
                                    VStack(spacing: 12) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "exclamationmark.icloud.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(.orange)
                                                .accessibilityHidden(true)

                                            Text("Not synced")
                                                .font(.appCaption)
                                                .foregroundStyle(.textSecondary)
                                        }
                                        .accessibilityElement(children: .combine)
                                        .accessibilityLabel("Moment not synced due to limit")

                                        Button {
                                            Task {
                                                await viewModel.retrySyncMoment()
                                            }
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: "arrow.clockwise")
                                                    .font(.system(size: 12, weight: .semibold))
                                                Text("Retry Sync")
                                                    .font(.appCaption)
                                                    .fontWeight(.semibold)
                                            }
                                            .foregroundStyle(.appPrimary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .strokeBorder(Color.appPrimary.opacity(0.5), lineWidth: 1)
                                            )
                                        }
                                        .accessibilityLabel("Retry syncing moment")
                                        .accessibilityHint("Double tap to try syncing this moment again")
                                    }
                                    .transition(.opacity)
                                }
                            }
                            .animation(.easeInOut(duration: 0.5), value: viewModel.isLoadingAIPraise)
                            .animation(.easeInOut(duration: 0.5), value: moment.praise)
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
        ActionButtonRow(
            primaryTitle: "Nice",
            isHugged: moment.isFavorite,
            showDelete: true,
            onPrimary: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                dismiss()
            },
            onHug: {
                Task { await viewModel.toggleHug() }
            },
            onDelete: {
                Task {
                    await viewModel.deleteMoment()
                    dismiss()
                }
            }
        )
    }
}

// MARK: - Preview

#Preview("Moment Detail Sheet") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Moment.self, configurations: config)
    let context = container.mainContext

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
    context.insert(moment)

    let repository = SwiftDataMomentRepository(modelContext: context)

    return MomentDetailSheet(
        viewModel: MomentDetailViewModel(
            moment: moment,
            repository: repository,
            onFavoriteToggle: { _ in },
            onDelete: { _ in }
        ),
        moment: moment
    )
    .preferredColorScheme(.dark)
    .modelContainer(container)
}
