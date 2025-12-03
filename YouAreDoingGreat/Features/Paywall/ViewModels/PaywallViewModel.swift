import Foundation
import RevenueCat
import Observation
import OSLog

private let logger = Logger(subsystem: "com.youaredoinggreat", category: "paywall")

// MARK: - Paywall ViewModel
// Manages paywall UI state, offerings, and purchase/restore flows

@MainActor
@Observable
final class PaywallViewModel {
    // State
    private(set) var offerings: Offerings?
    private(set) var selectedPackage: Package?
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    private(set) var isPurchasing: Bool = false
    private(set) var isRestoring: Bool = false

    // Dependencies
    private let subscriptionService: SubscriptionService

    init(subscriptionService: SubscriptionService) {
        self.subscriptionService = subscriptionService
    }

    // MARK: - Public API

    /// Load offerings from RevenueCat
    func loadOfferings() async {
        isLoading = true
        errorMessage = nil

        do {
            offerings = try await subscriptionService.fetchOfferings()

            // Auto-select annual package (matches current hardcoded default)
            if let annual = offerings?.current?.annual {
                selectedPackage = annual
            } else if let monthly = offerings?.current?.monthly {
                selectedPackage = monthly
            }

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = formatErrorMessage(error)
        }
    }

    /// Select a package
    func selectPackage(_ package: Package) {
        selectedPackage = package
    }

    /// Purchase the selected package
    func purchaseSelectedPackage() async -> Bool {
        guard let package = selectedPackage else {
            errorMessage = "Please select a subscription plan"
            return false
        }

        isPurchasing = true
        errorMessage = nil

        do {
            _ = try await subscriptionService.purchase(package: package)
            isPurchasing = false
            return true
        } catch let error as ErrorCode {
            isPurchasing = false

            switch error {
            case .purchaseCancelledError:
                // User cancelled - not an error, don't show message
                return false
            case .paymentPendingError:
                errorMessage = "Payment is pending. Your subscription will activate when payment completes."
                return false
            case .receiptAlreadyInUseError:
                errorMessage = "This purchase is already in use. Please contact support."
                return false
            default:
                errorMessage = formatErrorMessage(error)
                return false
            }
        } catch {
            isPurchasing = false
            errorMessage = formatErrorMessage(error)
            return false
        }
    }

    /// Restore previous purchases
    func restorePurchases() async -> Bool {
        isRestoring = true
        errorMessage = nil

        do {
            let customerInfo = try await subscriptionService.restorePurchases()
            isRestoring = false

            if customerInfo.entitlements["premium"]?.isActive == true {
                return true
            } else {
                errorMessage = "No previous purchases found for this account."
                return false
            }
        } catch {
            isRestoring = false
            errorMessage = formatErrorMessage(error)
            return false
        }
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Computed Properties

    var monthlyPackage: Package? {
        offerings?.current?.monthly
    }

    var annualPackage: Package? {
        offerings?.current?.annual
    }

    var hasOfferings: Bool {
        offerings?.current != nil
    }

    // MARK: - Private Helpers

    private func formatErrorMessage(_ error: Error) -> String {
        if let error = error as? ErrorCode {
            return error.localizedDescription
        }
        return "Something went wrong. Please try again."
    }
}
