import Foundation
import Security
import StoreKit

/// Manages the platform device token lifecycle.
/// Token is stored in Keychain under service "com.katafract.safeopen" / account "device_token".
@MainActor
final class DeviceTokenManager: ObservableObject {
    static let shared = DeviceTokenManager()

    private static let baseURL    = "https://api.katafract.com"
    private static let keychainService = "com.katafract.safeopen"
    private static let tokenAccount    = "device_token"
    private static let session = URLSession(configuration: .ephemeral)

    /// The current bearer token. Nil until registration succeeds.
    @Published private(set) var token: String? = nil

    private init() {
        token = loadFromKeychain()
    }

    // MARK: - Registration

    /// Call once on app launch. No-op if a valid token is already stored.
    func registerIfNeeded() async {
        if token != nil { return }
        await register()
    }

    func register() async {
        let body: [String: Any] = [
            "device_id":   InspectionAPIClient.deviceID,
            "platform":    "ios",
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        ]
        guard let tok = await post(path: "/v1/tokens/device", body: body, token: nil) else { return }
        saveToKeychain(tok)
        token = tok
    }

    // MARK: - StoreKit upgrade

    /// Call after a successful StoreKit 2 purchase to upgrade the device token's plan.
    func upgradeWithTransaction(_ transaction: Transaction) async {
        guard let current = token else { await register(); return }
        let body: [String: Any] = [
            "bundle_id":      "com.katafract.safeopen",
            "product_id":     transaction.productID,
            "transaction_id": String(transaction.id),
            "token":          current
        ]
        if let upgraded = await post(path: "/v1/token/validate/apple", body: body, token: current) {
            saveToKeychain(upgraded)
            token = upgraded
        }
    }

    // MARK: - Keychain

    private func loadFromKeychain() -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: Self.keychainService,
            kSecAttrAccount: Self.tokenAccount,
            kSecReturnData:  true,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func saveToKeychain(_ tok: String) {
        let data = Data(tok.utf8)
        // Try update first, then add
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: Self.keychainService,
            kSecAttrAccount: Self.tokenAccount,
        ]
        let update: [CFString: Any] = [kSecValueData: data]
        if SecItemUpdate(query as CFDictionary, update as CFDictionary) == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData] = data
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    // MARK: - HTTP

    private func post(path: String, body: [String: Any], token: String?) async -> String? {
        guard let url = URL(string: Self.baseURL + path),
              let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let t = token {
            req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = bodyData
        guard let (data, resp) = try? await Self.session.data(for: req),
              let http = resp as? HTTPURLResponse,
              (200...299).contains(http.statusCode),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tok = json["token"] as? String else { return nil }
        return tok
    }
}
