//
//  SubscriptionManager.swift
//  Screen Fare
//
//  Manages StoreKit 2 subscriptions for Screen Fare Pro
//

import Foundation
import StoreKit
import Combine

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    // MARK: - Published Properties

    @Published private(set) var isProSubscriber: Bool = false
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .notSubscribed
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseInProgress: Bool = false

    // MARK: - Product IDs

    private let productIDs = [
        "esong.screenfare.pro.monthly",
        "esong.screenfare.pro.annual"
    ]

    // MARK: - Transaction Listener

    private var transactionListener: Task<Void, Error>?

    // MARK: - Subscription Status

    enum SubscriptionStatus {
        case notSubscribed
        case subscribed(plan: SubscriptionPlan, expiresDate: Date?)
        case inTrial(plan: SubscriptionPlan, trialEndsDate: Date)
        case expired

        var isActive: Bool {
            switch self {
            case .subscribed, .inTrial:
                return true
            case .notSubscribed, .expired:
                return false
            }
        }
    }

    enum SubscriptionPlan: String {
        case monthly = "esong.screenfare.pro.monthly"
        case annual = "esong.screenfare.pro.annual"

        var displayName: String {
            switch self {
            case .monthly: return "Monthly"
            case .annual: return "Annual"
            }
        }

        var price: String {
            switch self {
            case .monthly: return "$4.99"
            case .annual: return "$49.99"
            }
        }

        var period: String {
            switch self {
            case .monthly: return "/mo"
            case .annual: return "/yr"
            }
        }
    }

    // MARK: - Initialization

    private init() {
        // Start listening for transactions
        transactionListener = listenForTransactions()

        Task {
            // Load products on init
            await loadProducts()

            // Check current subscription status
            await updateSubscriptionStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let loadedProducts = try await Product.products(for: productIDs)
            products = loadedProducts.sorted { product1, product2 in
                // Sort annual first (it's the recommended plan)
                product1.id.contains("annual")
            }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Transaction? {
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            // Verify the transaction
            let transaction = try checkVerified(verification)

            // Update subscription status
            await updateSubscriptionStatus()

            // Finish the transaction
            await transaction.finish()

            return transaction

        case .userCancelled:
            return nil

        case .pending:
            // Transaction is pending (e.g., Ask to Buy)
            return nil

        @unknown default:
            return nil
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async throws {
        try await AppStore.sync()
        await updateSubscriptionStatus()
    }

    // MARK: - Check Subscription Status

    func updateSubscriptionStatus() async {
        var highestTransaction: Transaction?
        var highestProduct: Product?

        // Check all current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Check if this transaction is for our subscription group
                guard productIDs.contains(transaction.productID) else {
                    continue
                }

                // Keep track of the most recent transaction
                if highestTransaction == nil ||
                   transaction.purchaseDate > highestTransaction!.purchaseDate {
                    highestTransaction = transaction

                    // Find the matching product
                    highestProduct = products.first { $0.id == transaction.productID }
                }
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }

        // Update status based on findings
        if let transaction = highestTransaction,
           let product = highestProduct {

            // Check if in trial period
            if let subscriptionInfo = transaction.subscriptionGroupID != nil ?
               try? await product.subscription?.status.first?.state : nil {

                switch subscriptionInfo {
                case .subscribed:
                    // Check if in trial
                    if let renewalInfo = try? await product.subscription?.status.first?.renewalInfo,
                       let isInTrial = try? renewalInfo.payloadValue.willAutoRenew,
                       isInTrial,
                       let expirationDate = transaction.expirationDate,
                       expirationDate > Date() {

                        let plan = SubscriptionPlan(rawValue: product.id) ?? .monthly
                        subscriptionStatus = .inTrial(plan: plan, trialEndsDate: expirationDate)
                        isProSubscriber = true
                    } else {
                        // Regular subscription
                        let plan = SubscriptionPlan(rawValue: product.id) ?? .monthly
                        subscriptionStatus = .subscribed(plan: plan, expiresDate: transaction.expirationDate)
                        isProSubscriber = true
                    }

                default:
                    subscriptionStatus = .notSubscribed
                    isProSubscriber = false
                }
            } else {
                // Fallback: if we have a valid transaction, consider them subscribed
                let plan = SubscriptionPlan(rawValue: product.id) ?? .monthly
                subscriptionStatus = .subscribed(plan: plan, expiresDate: transaction.expirationDate)
                isProSubscriber = true
            }
        } else {
            subscriptionStatus = .notSubscribed
            isProSubscriber = false
        }

        // Save to UserDefaults and App Group
        UserDefaults.standard.set(isProSubscriber, forKey: "isProSubscriber")
        UserDefaults.appGroup?.set(isProSubscriber, forKey: "isProSubscriber")
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Listen for transaction updates
            for await result in Transaction.updates {
                do {
                    // checkVerified is not actor-isolated, so we can call it directly
                    let transaction = try await Self.checkVerifiedDetached(result)

                    // Update subscription status on main actor
                    await SubscriptionManager.shared.updateSubscriptionStatus()

                    // Finish the transaction
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // Non-isolated version for use in Task.detached
    private static func checkVerifiedDetached<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Helper Methods

    func getProduct(for plan: SubscriptionPlan) -> Product? {
        return products.first { $0.id == plan.rawValue }
    }

    var monthlyProduct: Product? {
        return getProduct(for: .monthly)
    }

    var annualProduct: Product? {
        return getProduct(for: .annual)
    }
}

// MARK: - Errors

enum SubscriptionError: Error {
    case failedVerification
    case purchaseFailed
    case unknownError

    var localizedDescription: String {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        case .purchaseFailed:
            return "Purchase failed"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}
