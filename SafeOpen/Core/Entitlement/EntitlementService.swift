import Foundation
import StoreKit

/// 3-tier entitlement model:
/// - Free: 3 scans/day, URL check only (no AI preview)
/// - 99¢ Unlock: unlimited scans, URL check only (no AI preview)
/// - Enclave/Sovereign: unlimited scans + AI preview from hermes
@MainActor
final class EntitlementService: ObservableObject {
    static let shared = EntitlementService()

    @Published var hasOnDeviceUnlock: Bool = false
    @Published var hasEnclaveEntitlement: Bool = false
    @Published var scansUsedToday: Int = 0

    let freeDailyLimit = 3
    let unlockProductID = "com.katafract.safeopen.unlock"
    let appGroupID = "group.com.katafract.enclave"
    let dailyCounterKey = "safeopen.dailyCounter"
    let dailyDateKey = "safeopen.dailyDate"

    // Computed properties
    var canScan: Bool {
        hasEnclaveEntitlement || hasOnDeviceUnlock || scansUsedToday < freeDailyLimit
    }

    var canSeeAIPreview: Bool {
        hasEnclaveEntitlement
    }

    var scansRemainingToday: Int {
        if hasEnclaveEntitlement || hasOnDeviceUnlock { return Int.max }
        return max(0, freeDailyLimit - scansUsedToday)
    }

    var currentTier: EntitlementTier {
        if hasEnclaveEntitlement { return .enclave }
        if hasOnDeviceUnlock { return .unlock }
        return .free
    }

    init() {
        Task {
            await refresh()
        }
    }

    // MARK: - Lifecycle

    func refresh() async {
        await syncFromStoreKit()
        syncFromAppGroup()
        loadDailyCounter()
    }

    private func syncFromStoreKit() async {
        hasOnDeviceUnlock = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == unlockProductID,
               !transaction.isUpgraded {
                hasOnDeviceUnlock = true
                return
            }
        }
    }

    private func syncFromAppGroup() {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            hasEnclaveEntitlement = false
            return
        }

        // Check for enclave_token (JWT from WraithVPN/Vaultyx)
        if let token = defaults.string(forKey: "enclave_token"), !token.isEmpty {
            hasEnclaveEntitlement = isTokenValid(token)
        } else {
            hasEnclaveEntitlement = false
        }
    }

    private func isTokenValid(_ jwt: String) -> Bool {
        // Local sanity check: decode claims, verify exp
        // Don't validate signature (done server-side on scan)
        do {
            let parts = jwt.split(separator: ".")
            guard parts.count == 3 else { return false }

            // Decode payload (second part)
            let payloadString = String(parts[1])
            let paddingNeeded = (4 - (payloadString.count % 4)) % 4
            let paddedPayload = payloadString + String(repeating: "=", count: paddingNeeded)

            guard let data = Data(base64Encoded: paddedPayload),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let exp = json["exp"] as? Double else {
                return false
            }

            let expiryDate = Date(timeIntervalSince1970: exp)
            return Date() < expiryDate
        } catch {
            return false
        }
    }

    private func loadDailyCounter() {
        let today = Calendar.current.startOfDay(for: Date())
        let savedDate = UserDefaults.standard.object(forKey: dailyDateKey) as? Date

        if savedDate != today {
            scansUsedToday = 0
            UserDefaults.standard.set(today, forKey: dailyDateKey)
            UserDefaults.standard.set(0, forKey: dailyCounterKey)
        } else {
            scansUsedToday = UserDefaults.standard.integer(forKey: dailyCounterKey)
        }
    }

    // MARK: - Actions

    func incrementScanCounter() {
        guard !hasEnclaveEntitlement && !hasOnDeviceUnlock else { return }
        scansUsedToday += 1
        UserDefaults.standard.set(scansUsedToday, forKey: dailyCounterKey)
    }

    func purchaseUnlock() async throws {
        let products = try await Product.products(for: [unlockProductID])
        guard let product = products.first else {
            throw EntitlementError.productNotFound
        }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            if case .verified = verification {
                await syncFromStoreKit()
            } else {
                throw EntitlementError.verificationFailed
            }
        case .userCancelled:
            throw EntitlementError.userCancelled
        case .pending:
            throw EntitlementError.pending
        @unknown default:
            throw EntitlementError.unknown
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await refresh()
    }
}

enum EntitlementTier {
    case free
    case unlock
    case enclave
}

enum EntitlementError: Error, LocalizedError {
    case productNotFound
    case verificationFailed
    case userCancelled
    case pending
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Unlock product not found."
        case .verificationFailed:
            return "Purchase verification failed."
        case .userCancelled:
            return "Purchase was cancelled."
        case .pending:
            return "Purchase is pending."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
