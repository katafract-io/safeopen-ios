import Foundation

/// Checks if user has an active Enclave/Sovereign/Founder platform subscription from shared App Group.
/// Written by WraithVPN or Vaultyx on subscription purchase.
enum PlatformEntitlement {
    static let sharedGroup = "group.com.katafract.enclave"
    static let tokenKey = "enclave.sigil.token"
    static let planKey = "enclave.sigil.plan"

    /// Returns true if user has an active Enclave, Enclave Plus, or Sovereign subscription.
    /// SafeOpen subscribers skip credit costs for all features.
    static var isPlatformUnlocked: Bool {
        guard let defaults = UserDefaults(suiteName: sharedGroup),
              let plan = defaults.string(forKey: planKey) else { return false }
        return ["enclave", "enclave_annual", "enclave_plus", "enclave_plus_annual", "sovereign", "sovereign_annual", "founder"].contains(plan)
    }
}
