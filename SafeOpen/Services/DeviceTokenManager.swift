import Foundation
import Security
import StoreKit
import UIKit

/// Manages the platform device token lifecycle.
/// Token is stored in Keychain under service "com.katafract.safeopen" / account "device_token".
@MainActor
final class DeviceTokenManager: ObservableObject {
    static let shared = DeviceTokenManager()

    private static let baseURL    = "https://api.katafract.com"
    private static let keychainService = "com.katafract.safeopen"
    private static let tokenAccount    = "device_token"
    private static let deviceIDAccount = "device_id"
    private static let session = URLSession(configuration: .ephemeral)

    /// Stable per-install device ID stored in Keychain (survives app updates, lost on reinstall).
    static var deviceID: String {
        if let stored = keychainLoad(account: deviceIDAccount) { return stored }
        let id = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        keychainSave(id, account: deviceIDAccount)
        return id
    }

    private static func keychainLoad(account: String) -> String? {
        let q: [CFString: Any] = [kSecClass: kSecClassGenericPassword,
                                  kSecAttrService: keychainService,
                                  kSecAttrAccount: account,
                                  kSecReturnData: true]
        var ref: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &ref) == errSecSuccess,
              let d = ref as? Data else { return nil }
        return String(data: d, encoding: .utf8)
    }

    private static func keychainSave(_ value: String, account: String) {
        let data = Data(value.utf8)
        let q: [CFString: Any] = [kSecClass: kSecClassGenericPassword,
                                  kSecAttrService: keychainService,
                                  kSecAttrAccount: account]
        if SecItemUpdate(q as CFDictionary, [kSecValueData: data] as CFDictionary) == errSecItemNotFound {
            var add = q; add[kSecValueData] = data
            SecItemAdd(add as CFDictionary, nil)
        }
    }

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
            "device_id":   Self.deviceID,
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

    // MARK: - Keychain (token)

    private func loadFromKeychain() -> String? {
        Self.keychainLoad(account: Self.tokenAccount)
    }

    private func saveToKeychain(_ tok: String) {
        Self.keychainSave(tok, account: Self.tokenAccount)
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
