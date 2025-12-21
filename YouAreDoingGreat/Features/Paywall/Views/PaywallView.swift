import SwiftUI
import RevenueCat

// MARK: - Paywall View
// Full-screen modal shown when daily limit is reached
// Dark mode only for v1
// Adapted from old React Native app design

// Inspirational quotes pool
private let quotes = [
    Quote(text: "The small things matter. That's where life hides.", author: "Jon Kabat-Zinn"),
    Quote(text: "The day you plant the seed is not the day you eat the fruit.", author: "Fabienne Fredrickson"),
    Quote(text: "It always seems impossible until it is done.", author: "Nelson Mandela"),
    Quote(text: "There is no such thing as a small act of kindness.", author: "Aesop"),
    Quote(text: "Do what you can, with what you have, where you are.", author: "Theodore Roosevelt"),
    Quote(text: "A journey of a thousand miles begins with a single step.", author: "Lao Tzu")
]

private struct Quote {
    let text: String
    let author: String
}

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showContent = false
    @State private var showQuote = false
    @State private var showPlans = false
    @State private var pulseAnimation = false
    @State private var viewModel: PaywallViewModel

    let onDismiss: () -> Void

    // Random quote selection
    private let randomQuote = quotes.randomElement() ?? quotes[0]

    // Limit state based on trigger
    private var isDailyLimitReached: Bool {
        PaywallService.shared.paywallTrigger == .dailyLimitReached
    }

    private var isTotalLimitReached: Bool {
        PaywallService.shared.paywallTrigger == .totalLimitReached
    }

    private var isAnyLimitReached: Bool {
        isDailyLimitReached || isTotalLimitReached
    }

    init(viewModel: PaywallViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.textTertiary)
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 20)
                }

                // Limit banner (if applicable)
                if isAnyLimitReached {
                    limitBanner
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                }

                Spacer(minLength: isAnyLimitReached ? 32 : 80)

                // Main content
                VStack(spacing: 32) {
                    // Main title and subtitle
                    VStack(spacing: 32) {
                        Text("You've been doing the hard part already")
                            .font(.appTitle2)
                            .foregroundStyle(.textPrimary)
                            .multilineTextAlignment(.center)
                            .opacity(showContent ? 1 : 0)

                        Text("This is just to keep the light on.")
                            .font(.appBody)
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .opacity(showContent ? 1 : 0)
                    }
                    .padding(.horizontal, 24)

                    // Inspirational quote with laurels
                    quoteSection
                        .opacity(showQuote ? 1 : 0)
                        .offset(y: showQuote ? 0 : 20)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 40)

                // Plans and CTA section
                VStack(spacing: 24) {
                    // Header
                    Text("Unlock up to 10 moments per day")
                        .font(.appHeadline)
                        .foregroundStyle(Color(red: 0.75, green: 0.85, blue: 1.0))
                        .multilineTextAlignment(.center)
                        .opacity(showPlans ? 1 : 0)

                    // Plan options
                    planSelection
                        .opacity(showPlans ? 1 : 0)

                    // Premium CTA
                    PrimaryButton(
                        title: viewModel.isPurchasing ? "Processing..." : "Start 7-Day Free Trial",
                        showGlow: !viewModel.isPurchasing && pulseAnimation
                    ) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        handleUpgrade()
                    }
                    .disabled(viewModel.isPurchasing || viewModel.isRestoring || !viewModel.hasOfferings)
                    .opacity(showPlans ? 1 : 0)

                    // Footer links
                    VStack(spacing: 16) {
                        HStack(spacing: 40) {
                            Button("Terms of service") {
                                // TODO: Open terms URL
                            }
                            .font(.appFootnote)
                            .foregroundStyle(.white.opacity(0.5))

                            Button("Privacy policy") {
                                // TODO: Open privacy URL
                            }
                            .font(.appFootnote)
                            .foregroundStyle(.white.opacity(0.5))
                        }

                        Button(viewModel.isRestoring ? "Restoring..." : "Restore purchases") {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            handleRestorePurchases()
                        }
                        .font(.appFootnote)
                        .foregroundStyle(.white.opacity(0.5))
                        .disabled(viewModel.isPurchasing || viewModel.isRestoring)
                    }
                    .opacity(showPlans ? 1 : 0)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 32)
            }
        }
        .background {
            ZStack {
                // Cosmic linear gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.12, blue: 0.18),
                        Color(red: 0.06, green: 0.07, blue: 0.11)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // bg7 overlay
                GeometryReader { geometry in
                    Image("bg7")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
                .blendMode(.colorDodge)
                .opacity(0.2)
                .ignoresSafeArea()

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
                .ignoresSafeArea()

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
                .ignoresSafeArea()
            }
        }
        .task {
            await viewModel.loadOfferings()
            await playEntranceAnimation()
            startPulseAnimation()
        }
        .onDisappear {
            // Safety measure: Always clear service flag when view disappears
            // This ensures the flag is cleared even if parent's onDismiss fails
            PaywallService.shared.dismissPaywall()
        }
        .overlay {
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.6)
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.appPrimary)
                        Text("Loading subscription options...")
                            .font(.appBody)
                            .foregroundStyle(.white)
                    }
                }
                .ignoresSafeArea()
            }
        }
        .overlay {
            if let errorMessage = viewModel.errorMessage {
                ZStack {
                    Color.black.opacity(0.8)
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.appPrimary)

                        Text("Oops, something went wrong")
                            .font(.appTitle2)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text(errorMessage)
                            .font(.appBody)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        PrimaryButton(title: "Try Again") {
                            viewModel.clearError()
                            Task {
                                await viewModel.loadOfferings()
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                    .padding(.vertical, 40)
                }
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - Limit Banner

    private var limitBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color(red: 0.86, green: 0.93, blue: 1.0)) // blue-50

            Text(limitBannerText)
                .font(.appBody)
                .fontWeight(.semibold)
                .foregroundStyle(Color(red: 0.86, green: 0.93, blue: 1.0))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.37, green: 0.64, blue: 0.95)) // blue-400
        )
        .scaleEffect(showContent ? 1 : 0.8)
        .opacity(showContent ? 1 : 0)
    }

    private var limitBannerText: String {
        if isTotalLimitReached {
            return "Wow! You've logged 10 moments. Go premium to keep celebrating your wins."
        } else {
            return "Daily limit reached. Go premium to continue without interruptions."
        }
    }

    // MARK: - Quote Section

    private var quoteSection: some View {
        HStack(spacing: 0) {
            // Left laurel (flipped)
            Image(systemName: "laurel.leading")
                .font(.system(size: 64))
                .foregroundStyle(.appPrimary)
                .rotationEffect(.degrees(0))
                .frame(width: 80)

            // Quote text
            VStack(spacing: 12) {
                Text(randomQuote.text)
                    .font(.appBody)
                    .foregroundStyle(Color(red: 0.75, green: 0.85, blue: 1.0))
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text(randomQuote.author)
                    .font(.appCaption)
                    .foregroundStyle(Color(red: 0.75, green: 0.85, blue: 1.0).opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            // Right laurel
            Image(systemName: "laurel.trailing")
                .font(.system(size: 64))
                .foregroundStyle(.appPrimary)
                .frame(width: 80)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Plan Selection

    private var planSelection: some View {
        VStack(spacing: 12) {
            // Monthly plan
            if let monthly = viewModel.monthlyPackage {
                packageOption(
                    package: monthly,
                    isSelected: viewModel.selectedPackage?.identifier == monthly.identifier
                )
            }

            // Yearly plan
            if let annual = viewModel.annualPackage {
                packageOption(
                    package: annual,
                    isSelected: viewModel.selectedPackage?.identifier == annual.identifier
                )
            }
        }
    }

    private func packageOption(package: Package, isSelected: Bool) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            viewModel.selectPackage(package)
        } label: {
            HStack {
                // Left: Radio button + Label
                HStack(spacing: 12) {
                    // Radio button
                    ZStack {
                        Circle()
                            .strokeBorder(
                                isSelected ? Color.appPrimary : Color.white.opacity(0.5),
                                lineWidth: 2
                            )
                            .frame(width: 20, height: 20)

                        if isSelected {
                            Circle()
                                .fill(Color.appPrimary)
                                .frame(width: 10, height: 10)
                        }
                    }

                    Text(package.storeProduct.localizedTitle)
                        .font(.appHeadline)
                        .foregroundStyle(.white)

                    // "save XX%" badge for yearly subscription
                    savingsBadge(for: package)
                }

                Spacer()

                // Right: Price
                Text(package.storeProduct.localizedPriceString)
                    .font(.appHeadline)
                    .foregroundStyle(.white)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? Color.appPrimary : Color.white.opacity(0.3),
                        lineWidth: 2
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isSelected ? Color.appPrimary.opacity(0.1) : Color.clear)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Savings Badge

    @ViewBuilder
    private func savingsBadge(for package: Package) -> some View {
        let isYearly = package.storeProduct.subscriptionPeriod?.unit == .year

        if isYearly, let monthly = viewModel.monthlyPackage {
            let monthlyCost = NSDecimalNumber(decimal: monthly.storeProduct.price).doubleValue
            let annualCost = NSDecimalNumber(decimal: package.storeProduct.price).doubleValue
            let monthlyCostAnnualized = monthlyCost * 12
            let savings = ((monthlyCostAnnualized - annualCost) / monthlyCostAnnualized) * 100
            let savingsInt = Int(savings.rounded())

            if savingsInt > 0 {
                Text("save \(savingsInt)%")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.appPrimary.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.appPrimary.opacity(0.2))
                    )
            }
        }
    }

    // MARK: - Animations

    private func playEntranceAnimation() async {
        // Content animation (title + subtitle)
        try? await Task.sleep(nanoseconds: 200_000_000)
        withAnimation(.easeOut(duration: 0.5)) {
            showContent = true
        }

        // Quote animation
        try? await Task.sleep(nanoseconds: 800_000_000)
        withAnimation(.easeOut(duration: 0.5)) {
            showQuote = true
        }

        // Plans animation
        try? await Task.sleep(nanoseconds: 700_000_000)
        withAnimation(.easeOut(duration: 0.5)) {
            showPlans = true
        }
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
    }

    // MARK: - Actions

    private func handleUpgrade() {
        guard !viewModel.isPurchasing else { return }

        Task {
            let success = await viewModel.purchaseSelectedPackage()

            if success {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                PaywallService.shared.resetAllLimits()
                dismiss()
                onDismiss()
            } else if viewModel.errorMessage != nil {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }

    private func handleRestorePurchases() {
        guard !viewModel.isRestoring else { return }

        Task {
            let success = await viewModel.restorePurchases()

            if success {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                PaywallService.shared.resetAllLimits()
                dismiss()
                onDismiss()
            } else if viewModel.errorMessage != nil {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }
}

// MARK: - Plan Option Model

enum PlanOption: String {
    case monthly = "monthly"
    case yearly = "yearly"

    var label: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }

    var priceDisplay: String {
        switch self {
        case .monthly: return "$4.99"
        case .yearly: return "$39.99"
        }
    }
}

// MARK: - Preview

#Preview("Paywall") {
    PaywallView(
        viewModel: PaywallViewModel(subscriptionService: SubscriptionService.shared)
    ) {
        print("Dismissed")
    }
    .preferredColorScheme(.dark)
}

#Preview("Paywall - Limit Reached") {
    let service = PaywallService.shared
    service.markDailyLimitReached()

    return PaywallView(
        viewModel: PaywallViewModel(subscriptionService: SubscriptionService.shared)
    ) {
        print("Dismissed")
        service.resetDailyLimit()
    }
    .preferredColorScheme(.dark)
}
