import StoreKit

@MainActor
final class SafeOpenStore: ObservableObject {

    static let shared = SafeOpenStore()

    static let monthlyID = "com.katafract.safeopen.pro_monthly"
    static let annualID  = "com.katafract.safeopen.pro_annual"

    @Published var products: [Product] = []
    @Published var isPurchasing = false
    @Published var isPro: Bool = InspectionAPIClient.isProUser
    @Published var error: String?
    @Published var isUpgrading = false

    var monthly: Product? { products.first { $0.id == Self.monthlyID } }
    var annual:  Product? { products.first { $0.id == Self.annualID } }

    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
        Task { await updateProStatus() }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load products

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: [Self.monthlyID, Self.annualID])
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            self.error = "Could not load products: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        isPurchasing = true
        error = nil
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateProStatus()
                isUpgrading = true
                await DeviceTokenManager.shared.upgradeWithTransaction(transaction)
                isUpgrading = false
                await transaction.finish()
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
            await updateProStatus()
        } catch {
            self.error = "Restore failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Internal

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in Transaction.updates {
                do {
                    let tx = try self.checkVerified(result)
                    await self.updateProStatus()
                    await tx.finish()
                } catch {
                    // Unverified transaction — ignore
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):  return value
        case .unverified:           throw StoreError.failedVerification
        }
    }

    private func updateProStatus() async {
        var hasPro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               (tx.productID == Self.monthlyID || tx.productID == Self.annualID),
               tx.revocationDate == nil {
                hasPro = true
                break
            }
        }
        InspectionAPIClient.isProUser = hasPro
        isPro = hasPro
    }
}

enum StoreError: Error {
    case failedVerification
}
