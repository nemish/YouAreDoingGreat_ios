import SwiftUI

// MARK: - Log Moment View
// Dark mode only for v1

struct LogMomentView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: Int
    @State private var viewModel: LogMomentViewModel
    @FocusState private var isTextFieldFocused: Bool

    // Haptic feedback
    private let mediumFeedback = UIImpactFeedbackGenerator(style: .medium)

    // Praise state (inline, not separate sheet)
    @State private var showPraise = false
    @State private var praiseViewModel: PraiseViewModel?

    // Paywall state
    @State private var showPaywall = false

    // Callbacks
    var onSave: (() -> Void)?

    init(isFirstLog: Bool = false, selectedTab: Binding<Int>, onSave: (() -> Void)? = nil) {
        _viewModel = State(initialValue: LogMomentViewModel(isFirstLog: isFirstLog))
        _selectedTab = selectedTab
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                backgroundGradient
                    .ignoresSafeArea()

                if showPraise, let praiseVM = praiseViewModel {
                    // Praise content (replaces log form)
                    praiseContent(viewModel: praiseVM)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .offset(y: 20)),
                            removal: .opacity.combined(with: .scale(scale: 1.05))
                        ))
                } else {
                    // Log moment form
                    logFormContent
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: -20)),
                            removal: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .offset(y: -30))
                        ))
                }
            }
            .animation(.spring(duration: 0.4, bounce: 0.15), value: showPraise)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $viewModel.showTimePicker) {
                TimePickerSheet(
                    selectedSeconds: viewModel.timeAgoSeconds ?? 300,
                    onSelect: { seconds in
                        viewModel.setTimeAgo(seconds)
                    },
                    onSetJustNow: {
                        viewModel.setJustNow()
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Log Form Content

    private var logFormContent: some View {
        ZStack {
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    titleSection

                    // Text input
                    momentTextInput

                    // Time selector
                    timeSelector

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }

            // Bottom CTA
            VStack {
                Spacer()
                saveButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Praise Content

    private func praiseContent(viewModel praiseVM: PraiseViewModel) -> some View {
        PraiseContentView(viewModel: praiseVM, selectedTab: $selectedTab) {
            onSave?()
            dismiss()
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            // Base dark gradient
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.12, blue: 0.18),
                    Color(red: 0.06, green: 0.07, blue: 0.11)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Pattern overlay
//            Image("bg1")
            GeometryReader { geometry in
//                Image("bg2")
                Image("bg8")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
            .blendMode(.multiply)
            .opacity(0.4)

            // Top accent glow (purple)
            RadialGradient(
                colors: [
                    Color.appSecondary.opacity(0.2),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )

            // Subtle bottom accent (warm)
            RadialGradient(
                colors: [
                    Color.appPrimary.opacity(0.05),
                    Color.clear
                ],
                center: .bottom,
                startRadius: 0,
                endRadius: 300
            )
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        Text("Nice — that counts.\nWhat did you do?")
            .font(.appTitle2)
            .foregroundStyle(.textHighlightOnePrimary)
            .multilineTextAlignment(.center)
            .padding(.top, 16)
    }

    // MARK: - Text Input

    private var momentTextInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                // Placeholder text
                if viewModel.momentText.isEmpty {
                    Text(viewModel.placeholderText)
                        .font(.appBody)
                        .foregroundStyle(.textTertiary)
                        .padding(16)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }

                // Text editor
                TextEditor(text: $viewModel.momentText)
                    .font(.appBody)
                    .foregroundStyle(.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .padding(16)
                    .focused($isTextFieldFocused)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        Color.white.opacity(0.15),
                        lineWidth: 1
                    )
            )
            .disabled(viewModel.isSubmitting)
            .opacity(viewModel.isSubmitting ? 0.5 : 1)

            // Character count
            HStack {
                Spacer()
                Text("\(viewModel.momentText.count)/200")
                    .font(.appCaption)
                    .foregroundStyle(.textTertiary)
            }
        }
    }

    // MARK: - Time Selector

    private var timeSelector: some View {
        VStack(spacing: 12) {
            // Toggle buttons
            HStack(spacing: 0) {
                // Just now button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.setJustNow()
                    }
                } label: {
                    Text("Just now")
                        .font(.appSubheadline)
                        .foregroundStyle(viewModel.isJustNow ? .textPrimary : .textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(viewModel.isJustNow ? Color.white.opacity(0.1) : Color.clear)
                        )
                }
                .buttonStyle(.plain)

                // Earlier button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if viewModel.isJustNow {
                            viewModel.setTimeAgo(300) // Default 5 minutes
                        }
                    }
                } label: {
                    Text("Earlier")
                        .font(.appSubheadline)
                        .foregroundStyle(!viewModel.isJustNow ? .textPrimary : .textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(!viewModel.isJustNow ? Color.white.opacity(0.1) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.05))
            )

            // Show selected time if not "just now"
            if !viewModel.isJustNow {
                Button {
                    viewModel.showTimePicker = true
                } label: {
                    HStack {
                        Image(systemName: "clock")
                            .font(.system(size: 16))
                        Text(viewModel.timeDisplayText)
                            .font(.appSubheadline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.textSecondary)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Save Button

    private var saveButtonTitle: String {
        viewModel.momentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Keep it secret"
            : "That's it"
    }

    private var saveButton: some View {
        PrimaryButton(title: saveButtonTitle) {
            // Check if daily limit is reached before proceeding
            if PaywallService.shared.shouldBlockMomentCreation() {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showPaywall = true
                return
            }

            Task {
                isTextFieldFocused = false
                let success = await viewModel.submit()
                if success {
                    mediumFeedback.impactOccurred()
                    // Create praise view model with submitted data
                    let text = viewModel.momentText.trimmingCharacters(in: .whitespacesAndNewlines)
                    let momentText = text.isEmpty ? "Secret" : text

                    // Calculate happenedAt
                    let submittedAt = Date()
                    let happenedAt: Date
                    if let timeAgo = viewModel.timeAgoSeconds {
                        happenedAt = submittedAt.addingTimeInterval(-Double(timeAgo))
                    } else {
                        happenedAt = submittedAt
                    }

                    praiseViewModel = PraiseViewModel(
                        momentText: momentText,
                        happenedAt: happenedAt,
                        timeAgoSeconds: viewModel.timeAgoSeconds,
                        offlinePraise: nil,
                        clientId: UUID(),
                        submittedAt: submittedAt,
                        timezone: TimeZone.current.identifier
                    )
                    // Transition to praise content
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showPraise = true
                    }
                }
            }
        }
        .disabled(viewModel.isSubmitting)
        .opacity(viewModel.isSubmitting ? 0.7 : 1)
        .fullScreenCover(isPresented: $showPaywall, onDismiss: {
            // Always clear the service flag when paywall is dismissed
            // This handles both programmatic dismissal and interactive gestures
            PaywallService.shared.dismissPaywall()
        }) {
            PaywallView {
                // This closure only runs for programmatic dismissal (button taps)
                showPaywall = false
            }
        }
    }
}

// MARK: - Preview

#Preview("Log Moment") {
    LogMomentView(selectedTab: .constant(0))
        .preferredColorScheme(.dark)
}

#Preview("Log Moment - First Log") {
    LogMomentView(isFirstLog: true, selectedTab: .constant(0))
        .preferredColorScheme(.dark)
}
