import StoreKit

@MainActor
final class SafeOpenStore: ObservableObject {

    static let shared = SafeOpenStore()

    static let monthlyID = "com.katafract.safeopen.pro_monthly"
    static let annualID  = "com.katafract.safeopen.pro_annual"

    private static let proKey = "com.katafract.safeopen.isPro"

    @Published var products: [Product] = []
    @Published var isPurchasing = false
    @Published var isPro: Bool = UserDefaults.standard.bool(forKey: proKey)
    @Published var error: String?

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
                await transaction.finish()
            case .userCancelled:
                // OS may have shown "already subscribed" — re-check entitlements
                await updateProStatus()
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

    // MARK: - Public refresh

    /// Sync with Apple then check entitlements. Called on view appear.
    func refreshProStatus() async {
        try? await AppStore.sync()   // ensure latest state from Apple
        await updateProStatus()
    }

    // MARK: - Debug

    struct StoreKitDiagnostic {
        var syncError: String?
        var currentEntitlements: [(id: String, revoked: Bool, expires: String)]  = []
        var allTransactions:     [(id: String, revoked: Bool, expires: String)]  = []
        var userDefaultsIsPro: Bool
        var inMemoryIsPro: Bool
        var monthlyID: String
        var annualID:  String
    }

    func diagnose() async -> StoreKitDiagnostic {
        var d = StoreKitDiagnostic(
            userDefaultsIsPro: UserDefaults.standard.bool(forKey: Self.proKey),
            inMemoryIsPro: isPro,
            monthlyID: Self.monthlyID,
            annualID:  Self.annualID
        )
        do {
            try await AppStore.sync()
        } catch {
            d.syncError = error.localizedDescription
        }
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let tx):
                let exp = tx.expirationDate.map { "\($0)" } ?? "none"
                d.currentEntitlements.append((tx.productID, tx.revocationDate != nil, exp))
            case .unverified(let tx, _):
                d.currentEntitlements.append(("\(tx.productID) [UNVERIFIED]", false, "?"))
            @unknown default: break
            }
        }
        for await result in Transaction.all {
            switch result {
            case .verified(let tx):
                let exp = tx.expirationDate.map { "\($0)" } ?? "none"
                d.allTransactions.append((tx.productID, tx.revocationDate != nil, exp))
            case .unverified(let tx, _):
                d.allTransactions.append(("\(tx.productID) [UNVERIFIED]", false, "?"))
            @unknown default: break
            }
        }
        return d
    }

    // MARK: - Private

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
        var hasRevocation = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result,
                  tx.productID == Self.monthlyID || tx.productID == Self.annualID else { continue }
            if tx.revocationDate != nil { hasRevocation = true } else { hasPro = true; break }
        }

        // Fallback when currentEntitlements is empty: check all past transactions.
        // Covers cases where StoreKit is slow or the sub just renewed.
        // Any verified, non-revoked purchase for our products = Pro.
        if !hasPro && !hasRevocation {
            for await result in Transaction.all {
                guard case .verified(let tx) = result,
                      (tx.productID == Self.monthlyID || tx.productID == Self.annualID),
                      tx.revocationDate == nil else { continue }
                hasPro = true
                break
            }
        }

        if hasPro {
            UserDefaults.standard.set(true, forKey: Self.proKey)
            isPro = true
        } else if hasRevocation {
            UserDefaults.standard.set(false, forKey: Self.proKey)
            isPro = false
        }
        // Empty = preserve cached state (network/StoreKit delay, offline).
    }
}

enum StoreError: Error {
    case failedVerification
}
