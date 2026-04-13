import Foundation
import StoreKit

/// SafeOpen consumable credit pack store + balance tracking.
///
/// Three consumable IAPs grant scan credits redeemed against the backend ledger:
///   - credits_starter   : 100 credits  ($0.99)
///   - credits_standard  : 500 credits  ($2.99)
///   - credits_power     : 2500 credits ($9.99)
///
/// Every install starts with 10 free credits and gets 10 more every 30 days.
/// The authoritative balance lives on the backend, not in StoreKit.
@MainActor
final class SafeOpenStore: ObservableObject {

    static let shared = SafeOpenStore()

    static let starterID  = "com.katafract.safeopen.credits_starter"
    static let standardID = "com.katafract.safeopen.credits_standard"
    static let powerID    = "com.katafract.safeopen.credits_power"
    static let allProductIDs: Set<String> = [starterID, standardID, powerID]

    @Published var products: [Product] = []
    @Published var isPurchasing = false
    @Published var balance: Int = 0
    @Published var nextRefillAt: Date = .distantFuture
    @Published var totalConsumed: Int = 0
    @Published var error: String?

    var starter:  Product? { products.first { $0.id == Self.starterID  } }
    var standard: Product? { products.first { $0.id == Self.standardID } }
    var power:    Product? { products.first { $0.id == Self.powerID    } }

    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
        Task { await refreshBalance() }
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
            nextRefillAt = Date(timeIntervalSince1970: TimeInterval(snapshot.nextRefillAt))
            totalConsumed = snapshot.totalConsumed
        } catch {
            // Don't surface — the inspection flow itself shows credit errors when relevant.
        }
    }

    func redeem(transaction: Transaction) async {
        do {
            let snapshot = try await InspectionAPIClient().redeemTransaction(id: String(transaction.id))
            balance = snapshot.balance
        } catch {
            self.error = "Purchase succeeded but credit grant failed. Tap Restore Purchases to retry."
        }
    }

    /// Re-attempt redemption of every prior consumable purchase. Useful if a redemption
    /// failed mid-flight (e.g. backend down) — Apple still lets us see the txn IDs.
    func restorePurchases() async {
        isPurchasing = true
        defer { isPurchasing = false }
        for await result in Transaction.all {
            guard case .verified(let tx) = result,
                  Self.allProductIDs.contains(tx.productID),
                  tx.revocationDate == nil else { continue }
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
