import Foundation
import StoreKit

/// SafeOpen consumable credit pack store + balance tracking.
///
/// Canonical credit SKUs (new signups):
///   - com.katafract.safeopen.credits.100   : 100 credits  ($0.99)
///   - com.katafract.safeopen.credits.500   : 500 credits  ($4.99)
///   - com.katafract.safeopen.credits.2500  : 2500 credits ($19.99)
///
/// Legacy IDs (grandfathered for existing user balances, not offered in UI):
///   - com.katafract.safeopen.credits_starter  : 100 credits  ($0.99)
///   - com.katafract.safeopen.credits_standard : 100 credits  ($5.00)
///   - com.katafract.safeopen.credits_power    : 2500 credits ($9.99)
///
/// Every install starts with 10 free credits and gets 10 more every 30 days.
/// The authoritative balance lives on the backend, not in StoreKit.
@MainActor
final class SafeOpenStore: ObservableObject {

    static let shared = SafeOpenStore()

    // Active canonical SKUs
    static let credits100ID  = "com.katafract.safeopen.credits.100"
    static let credits500ID  = "com.katafract.safeopen.credits.500"
    static let credits2500ID = "com.katafract.safeopen.credits.2500"

    // Legacy grandfathered IDs (for existing user balance migration only)
    static let starterID     = "com.katafract.safeopen.credits_starter"
    static let standardID    = "com.katafract.safeopen.credits_standard"
    static let powerID       = "com.katafract.safeopen.credits_power"

    // All product IDs to look up from StoreKit (active + legacy)
    static let allProductIDs: Set<String> = [
        credits100ID, credits500ID, credits2500ID,
        starterID, standardID, powerID
    ]

    @Published var products: [Product] = []
    @Published var isPurchasing = false
    @Published var balance: Int = 0
    @Published var freeBalance: Int = 0
    @Published var freeBalanceCap: Int = 20
    @Published var nextRefillAt: Date = .distantFuture
    @Published var totalConsumed: Int = 0
    @Published var offers: [InspectionAPIClient.Offer] = []
    @Published var error: String?

    /// True after the most recent refreshBalance() failed to reach the backend.
    /// UI should treat `balance` as stale and show an offline indicator.
    @Published var balanceIsStale: Bool = false
    @Published var lastBalanceFetchAt: Date?

    // Canonical products (active)
    var credits100:  Product? { products.first { $0.id == Self.credits100ID  } }
    var credits500:  Product? { products.first { $0.id == Self.credits500ID  } }
    var credits2500: Product? { products.first { $0.id == Self.credits2500ID } }

    // Legacy products (fallback for existing users)
    var starter:  Product? { products.first { $0.id == Self.starterID  } }
    var standard: Product? { products.first { $0.id == Self.standardID } }
    var power:    Product? { products.first { $0.id == Self.powerID    } }

    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts() }

        // Screenshot mode: mock balance if specified
        if ScreenshotMode.isEnabled && ScreenshotMode.seedData,
           let mockBalance = ScreenshotMode.mockBalance {
            self.balance = mockBalance
            self.freeBalance = 5
            self.freeBalanceCap = 10
            self.balanceIsStale = false
        } else {
            Task { await refreshBalance() }
            // Automatic retry of any past consumable purchase whose server-side redemption
            // failed mid-flight. Apple rule 3.1.1 prohibits user-facing "Restore Purchases"
            // UI for consumable-only apps — so we do this silently on every launch instead.
            Task { await retryPendingRedemptions() }
        }
    }

    deinit { transactionListener?.cancel() }

    // MARK: - StoreKit

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: Self.allProductIDs)
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            self.error = "Could not load products: \(error.localizedDescription)"
        }
    }

    func purchase(_ product: Product) async {
        isPurchasing = true
        error = nil
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await redeem(transaction: transaction)
                await transaction.finish()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in Transaction.updates {
                do {
                    let tx = try await self.checkVerifiedAsync(result)
                    await self.redeem(transaction: tx)
                    await tx.finish()
                } catch {
                    // Unverified — drop
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): return value
        case .unverified:          throw StoreError.failedVerification
        }
    }

    private func checkVerifiedAsync<T>(_ result: VerificationResult<T>) async throws -> T {
        switch result {
        case .verified(let value): return value
        case .unverified:          throw StoreError.failedVerification
        }
    }

    // MARK: - Backend balance + redemption

    func refreshBalance() async {
        do {
            let snapshot = try await InspectionAPIClient().getCredits()
            balance = snapshot.balance
            freeBalance = snapshot.freeBalance
            freeBalanceCap = snapshot.freeBalanceCap
            nextRefillAt = Date(timeIntervalSince1970: TimeInterval(snapshot.nextRefillAt))
            totalConsumed = snapshot.totalConsumed
            balanceIsStale = false
            lastBalanceFetchAt = Date()
        } catch {
            balanceIsStale = true
        }
    }

    func refreshOffers() async {
        do {
            offers = try await InspectionAPIClient().getOffers()
        } catch {
            // Offer display is non-critical — fall back to base credits.
        }
    }

    func redeem(transaction: Transaction) async {
        do {
            let snapshot = try await InspectionAPIClient().redeemTransaction(id: String(transaction.id))
            balance = snapshot.balance
        } catch {
            self.error = "Purchase succeeded but credit grant didn't go through. We'll retry automatically — if credits don't appear shortly, contact support."
        }
    }

    /// Silently re-attempts redemption of past consumable purchases whose backend grant
    /// failed mid-flight (e.g. backend was down at the moment of purchase). Runs
    /// automatically on app launch — NOT user-initiated.
    ///
    /// Apple rule 3.1.1: consumable-only apps MUST NOT expose a user-facing "Restore
    /// Purchases" affordance. The retry mechanism itself is legitimate because the user
    /// already paid; we just didn't successfully deliver. Doing it silently on launch
    /// satisfies both sides: the user's credits get delivered, and we don't violate the
    /// UI rule.
    func retryPendingRedemptions() async {
        for await result in Transaction.all {
            guard case .verified(let tx) = result else { continue }
            // Redeem any credit pack: canonical IDs or legacy IDs
            let isCreditProduct = Self.allProductIDs.contains(tx.productID)
            guard isCreditProduct, tx.revocationDate == nil else { continue }
            await redeem(transaction: tx)
        }
        await refreshBalance()
    }

    /// Local optimistic decrement after the backend acknowledged a 1-credit consumption.
    func applyLocalDebit(newBalance: Int) {
        balance = newBalance
        totalConsumed += 1
    }
}

enum StoreError: Error {
    case failedVerification
}
