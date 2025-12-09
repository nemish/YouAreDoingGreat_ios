import Foundation
import RevenueCat
import Observation
import OSLog

private let logger = Logger(subsystem: "com.youaredoinggreat", category: "subscription")

// MARK: - Subscription Service
// Manages RevenueCat subscriptions and entitlement state

@MainActor
@Observable
final class SubscriptionService {
    // Singleton instance
    static let shared = SubscriptionService()

    // Published state
    private(set) var hasActiveSubscription: Bool = false
    private(set) var currentOfferings: Offerings?
    private(set) var isLoadingOfferings: Bool = false
    private(set) var offeringsError: Error?

    private init() {
        observeCustomerInfo()
    }

    // MARK: - Public API

    /// Fetch available offerings from RevenueCat
    func fetchOfferings() async throws -> Offerings {
        isLoadingOfferings = true
        offeringsError = nil

        do {
            let offerings = try await Purchases.shared.offerings()
            currentOfferings = offerings
            isLoadingOfferings = false
            logger.info("Fetched offerings successfully")
            return offerings
        } catch {
            offeringsError = error
            isLoadingOfferings = false
            logger.error("Failed to fetch offerings: \(error.localizedDescription)")
            throw error
        }
    }

    /// Purchase a package
    func purchase(package: Package) async throws -> CustomerInfo {
        logger.info("Initiating purchase for package: \(package.identifier)")

        do {
            let result = try await Purchases.shared.purchase(package: package)
            let customerInfo = result.customerInfo
            logger.info("Purchase completed successfully")
            updateSubscriptionState(from: customerInfo)
            return customerInfo
        } catch let error as ErrorCode {
            logger.error("Purchase failed: \(error.localizedDescription)")
            throw error
        } catch {
            logger.error("Purchase failed with unexpected error: \(error.localizedDescription)")
            throw error
        }
    }

    /// Restore previous purchases
    func restorePurchases() async throws -> CustomerInfo {
        logger.info("Restoring purchases")

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            logger.info("Restore completed successfully")
            updateSubscriptionState(from: customerInfo)
            return customerInfo
        } catch {
            logger.error("Restore failed: \(error.localizedDescription)")
            throw error
        }
    }

    /// Refresh subscription status from RevenueCat
    func refreshSubscriptionStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateSubscriptionState(from: customerInfo)
        } catch {
            logger.error("Failed to refresh subscription status: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    /// Observe customer info stream for real-time updates
    private func observeCustomerInfo() {
        Task {
            for await customerInfo in Purchases.shared.customerInfoStream {
                updateSubscriptionState(from: customerInfo)
            }
        }
    }

    /// Update subscription state from customer info
    private func updateSubscriptionState(from customerInfo: CustomerInfo) {
        let isPremium = customerInfo.entitlements["Premium"]?.isActive == true

        if hasActiveSubscription != isPremium {
            hasActiveSubscription = isPremium
            logger.info("Subscription status updated: \(isPremium)")

            if isPremium {
                // Reset daily limit when premium activates
                PaywallService.shared.resetDailyLimit()
            }
        }
    }

    // MARK: - Preview Helpers

    #if DEBUG
    /// Set subscription state manually (for previews/testing only)
    func setHasActiveSubscription(_ value: Bool) {
        hasActiveSubscription = value
    }
    #endif
}
