import SwiftUI
import SwiftData

// MARK: - Filtered Moments Sheet
// Bottom sheet for displaying moments filtered by tag
// Reusable pattern consistent with MomentDetailSheet

struct FilteredMomentsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Moment.happenedAt, order: .reverse) private var allMoments: [Moment]

    let tag: String

    @State private var showHeader = false
    @State private var showContent = false

    // Filter moments by tag
    private var moments: [Moment] {
        allMoments.filter { $0.tags.contains(tag) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Cosmic background
                CosmicBackgroundView()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    if moments.isEmpty {
                        emptyState
                    } else {
                        momentsList
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                startAnimations()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    tagHeader
                        .opacity(showHeader ? 1 : 0)
                }

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

    // MARK: - Components

    private var tagHeader: some View {
        VStack(spacing: 4) {
            Text("#\(tag.replacingOccurrences(of: "_", with: " "))")
                .font(.appTitle3)
                .foregroundStyle(.white)

            Text("\(moments.count) moment\(moments.count == 1 ? "" : "s")")
                .font(.appFootnote)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.top, 24)
        .padding(.bottom, 20)
    }

    private var momentsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(moments) { moment in
                    MomentCard(moment: moment)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity
                        ))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .opacity(showContent ? 1 : 0)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tag.slash")
                .font(.system(size: 48))
                .foregroundStyle(.textTertiary)

            Text("No moments with this tag")
                .font(.appHeadline)
                .foregroundStyle(.textSecondary)

            Text("You haven't logged any moments tagged with \"\(tag.replacingOccurrences(of: "_", with: " "))\" yet.")
                .font(.appBody)
                .foregroundStyle(.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .opacity(showContent ? 1 : 0)
    }

    // MARK: - Animations

    private func startAnimations() {
        withAnimation(.easeIn(duration: 0.4).delay(0.1)) {
            showHeader = true
        }

        withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
            showContent = true
        }
    }
}

// MARK: - Preview

#Preview("Filtered Moments - With Results") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Moment.self, configurations: config)
    let context = container.mainContext

    // Create test moments with "self_care" tag
    let moment1 = Moment(
        text: "Took a relaxing bath with candles",
        submittedAt: Date(),
        happenedAt: Date().addingTimeInterval(-3600),
        timezone: TimeZone.current.identifier,
        timeAgo: 3600,
        offlinePraise: "Nice. You're making moves."
    )
    moment1.tags = ["self_care", "relaxation"]
    context.insert(moment1)

    let moment2 = Moment(
        text: "Went for a peaceful morning walk",
        submittedAt: Date().addingTimeInterval(-86400),
        happenedAt: Date().addingTimeInterval(-86400),
        timezone: TimeZone.current.identifier,
        timeAgo: 0,
        offlinePraise: "That's it. Small stuff adds up."
    )
    moment2.tags = ["self_care", "exercise"]
    context.insert(moment2)

    let moment3 = Moment(
        text: "Made my favorite tea and read a book",
        submittedAt: Date().addingTimeInterval(-172800),
        happenedAt: Date().addingTimeInterval(-172800),
        timezone: TimeZone.current.identifier,
        timeAgo: 0,
        offlinePraise: "Look at you showing up."
    )
    moment3.tags = ["self_care", "mindfulness"]
    context.insert(moment3)

    return FilteredMomentsSheet(tag: "self_care")
        .preferredColorScheme(.dark)
        .modelContainer(container)
}

#Preview("Filtered Moments - Empty State") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Moment.self, configurations: config)

    return FilteredMomentsSheet(tag: "productivity")
        .preferredColorScheme(.dark)
        .modelContainer(container)
}
