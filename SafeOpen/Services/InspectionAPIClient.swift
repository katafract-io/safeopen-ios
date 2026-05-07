import Foundation
import Security

/// Calls the SafeOpen backend using the app-level service token plus a per-install
/// anonymous device UUID stored in the Keychain. The device ID is what the backend
/// uses to track scan-credit balance for this install.
struct InspectionAPIClient {

    static let baseURL = "https://api.katafract.com"
    private static let serviceToken = "3e27ee700e0b3ef336b4c7b5360af3fdb16410fb445e2b1889bf5da5b083b977"
    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    // MARK: - Device ID (anonymous, persisted in Keychain)

    static var deviceID: String {
        let service = "com.katafract.safeopen"
        let account = "device_id"
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData:  true,
        ]
        var result: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
           let data = result as? Data,
           let id = String(data: data, encoding: .utf8) {
            return id
        }
        let id = UUID().uuidString
        let add: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData:   Data(id.utf8),
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemAdd(add as CFDictionary, nil)
        return id
    }

    // MARK: - Prefetch

    func prefetchURL(_ url: URL) async throws -> PrefetchResult {
        let endpoint = URL(string: "\(Self.baseURL)/v1/safe-open/prefetch")!
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("Bearer \(Self.serviceToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "url": url.absoluteString,
            "device_id": Self.deviceID,
            "request_ephemeral": true,
        ]
        if PlatformEntitlement.isPlatformUnlocked,
           let token = UserDefaults(suiteName: PlatformEntitlement.sharedGroup)?.string(forKey: PlatformEntitlement.tokenKey) {
            body["enclave_token"] = token
        }
        await Self.attachAttestFields(to: &body)
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await Self.session.data(for: req)
        try checkStatus(response, data: data)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(PrefetchResult.self, from: data)
    }

    // MARK: - Session provisioning

    func createSession(for url: URL) async throws -> SafeOpenSession {
        let endpoint = URL(string: "\(Self.baseURL)/v1/safe-open/session")!
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("Bearer \(Self.serviceToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "url": url.absoluteString,
            "device_id": Self.deviceID,
            "request_ephemeral": true,
        ]
        if PlatformEntitlement.isPlatformUnlocked,
           let token = UserDefaults(suiteName: PlatformEntitlement.sharedGroup)?.string(forKey: PlatformEntitlement.tokenKey) {
            body["enclave_token"] = token
        }
        await Self.attachAttestFields(to: &body)
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await Self.session.data(for: req)
        try checkStatus(response, data: data)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(SafeOpenSession.self, from: data)
    }

    // MARK: - Revoke session

    func revokeSession(_ sessionId: String) async {
        let endpoint = URL(string: "\(Self.baseURL)/v1/safe-open/session/\(sessionId)")!
        var req = URLRequest(url: endpoint)
        req.httpMethod = "DELETE"
        _ = try? await Self.session.data(for: req)
    }

    // MARK: - Credits

    struct CreditSnapshot: Decodable {
        let balance:          Int
        let freeBalance:      Int
        let freeBalanceCap:   Int
        let welcomeCredits:   Int
        let monthlyRefill:    Int
        let nextRefillAt:     Int
        let totalConsumed:    Int
    }

    func getCredits() async throws -> CreditSnapshot {
        let endpoint = URL(string: "\(Self.baseURL)/v1/safeopen/credits")!
        var req = URLRequest(url: endpoint)
        req.httpMethod = "GET"
        req.setValue("Bearer \(Self.serviceToken)", forHTTPHeaderField: "Authorization")
        req.setValue(Self.deviceID, forHTTPHeaderField: "X-Device-ID")
        if PlatformEntitlement.isPlatformUnlocked,
           let token = UserDefaults(suiteName: PlatformEntitlement.sharedGroup)?.string(forKey: PlatformEntitlement.tokenKey) {
            req.setValue(token, forHTTPHeaderField: "X-Enclave-Token")
        }
        let (data, response) = try await Self.session.data(for: req)
        try checkStatus(response, data: data)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(CreditSnapshot.self, from: data)
    }

    // MARK: - Offers (loyalty bonuses)

    struct Offer: Decodable, Identifiable {
        let productId:     String
        let baseCredits:   Int
        let bonusCredits:  Int
        let bonusType:     String   // "", "upgrade", "repurchase"
        let totalCredits:  Int

        var id: String { productId }
    }

    private struct OffersResponse: Decodable {
        let offers: [Offer]
    }

    func getOffers() async throws -> [Offer] {
        let endpoint = URL(string: "\(Self.baseURL)/v1/safeopen/credits/offers")!
        var req = URLRequest(url: endpoint)
        req.httpMethod = "GET"
        req.setValue("Bearer \(Self.serviceToken)", forHTTPHeaderField: "Authorization")
        req.setValue(Self.deviceID, forHTTPHeaderField: "X-Device-ID")
        if PlatformEntitlement.isPlatformUnlocked,
           let token = UserDefaults(suiteName: PlatformEntitlement.sharedGroup)?.string(forKey: PlatformEntitlement.tokenKey) {
            req.setValue(token, forHTTPHeaderField: "X-Enclave-Token")
        }
        let (data, response) = try await Self.session.data(for: req)
        try checkStatus(response, data: data)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(OffersResponse.self, from: data).offers
    }

    // MARK: - Redeem

    struct RedeemResponse: Decodable {
        let balance:       Int
        let granted:       Int
        let productId:     String
        let bonusCredits:  Int?
        let bonusType:     String?
    }

    func redeemTransaction(id transactionId: String) async throws -> RedeemResponse {
        let endpoint = URL(string: "\(Self.baseURL)/v1/safeopen/credits/redeem")!
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("Bearer \(Self.serviceToken)", forHTTPHeaderField: "Authorization")
        req.setValue(Self.deviceID, forHTTPHeaderField: "X-Device-ID")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if PlatformEntitlement.isPlatformUnlocked,
           let token = UserDefaults(suiteName: PlatformEntitlement.sharedGroup)?.string(forKey: PlatformEntitlement.tokenKey) {
            req.setValue(token, forHTTPHeaderField: "X-Enclave-Token")
        }
        var body: [String: Any] = ["transaction_id": transactionId]
        await Self.attachAttestFields(to: &body)
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await Self.session.data(for: req)
        try checkStatus(response, data: data)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(RedeemResponse.self, from: data)
    }

    // MARK: - App Attest glue

    /// Fetch fresh App Attest headers and merge them into a mutating-request body.
    /// No-ops if App Attest is unavailable or key isn't bootstrapped — the backend
    /// accepts nil during dark launch.
    private static func attachAttestFields(to body: inout [String: Any]) async {
        guard let headers = await AppAttestClient.shared.getAttestHeaders() else {
            return
        }
        body["attest_key_id"]    = headers.keyId
        body["attest_assertion"] = headers.assertion
        body["attest_challenge"] = headers.challenge
    }

    // MARK: - Private

    private func checkStatus(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200...299: return
        case 401, 403:  throw InspectionAPIError.unauthorized
        case 402:
            if let detail = try? JSONDecoder().decode(ErrorEnvelope.self, from: data),
               detail.detail.code == "credits_required" {
                throw InspectionAPIError.creditsRequired
            }
            throw InspectionAPIError.creditsRequired
        case 429:       throw InspectionAPIError.rateLimited
        default:
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["detail"]
            throw InspectionAPIError.serverError(http.statusCode, msg ?? "Unknown error")
        }
    }

    private struct ErrorEnvelope: Decodable {
        struct Detail: Decodable { let code: String; let message: String }
        let detail: Detail
    }
}

enum InspectionAPIError: LocalizedError {
    case unauthorized
    case creditsRequired
    case rateLimited
    case networkError(Error)
    case serverError(Int, String)

    var errorDescription: String? {
        switch self {
        case .unauthorized:            return "Service error. Please update the app."
        case .creditsRequired:         return "You're out of scan credits. Tap to buy a credit pack."
        case .rateLimited:             return "Too many active sessions. Try again in a moment."
        case .networkError(let e):     return e.localizedDescription
        case .serverError(_, let msg): return msg
        }
    }
}
