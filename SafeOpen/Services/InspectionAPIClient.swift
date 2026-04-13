import Foundation
import Security

/// Calls the SafeOpen backend using the app-level service token plus a per-install
/// anonymous device UUID stored in the Keychain. The device ID is what the backend
/// uses to track scan-credit balance for this install.
struct InspectionAPIClient {

    static let baseURL = "https://api.katafract.com"
    private static let session = URLSession(configuration: .ephemeral)

    /// The app service token. Authenticates the SafeOpen client to the backend.
    /// Per-install authorization is the device ID below; this token only proves
    /// the request came from a SafeOpen build.
    static let serviceToken = "3e27ee700e0b3ef336b4c7b5360af3fdb16410fb445e2b1889bf5da5b083b977"

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

    func prefetchURL(_ url: URL, regionHint: String? = nil) async throws -> PrefetchResult {
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
        if let r = regionHint { body["region_hint"] = r }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await Self.session.data(for: req)
        try checkStatus(response, data: data)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(PrefetchResult.self, from: data)
    }

    // MARK: - Session provisioning

    func createSession(for url: URL, regionHint: String? = nil) async throws -> SafeOpenSession {
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
        if let r = regionHint { body["region_hint"] = r }
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
        req.setValue("Bearer \(Self.serviceToken)", forHTTPHeaderField: "Authorization")
        _ = try? await Self.session.data(for: req)
    }

    // MARK: - Credits

    struct CreditSnapshot: Decodable {
        let balance: Int
        let welcomeCredits: Int
        let monthlyRefill: Int
        let nextRefillAt: Int
        let totalConsumed: Int
    }

    func getCredits() async throws -> CreditSnapshot {
        let endpoint = URL(string: "\(Self.baseURL)/v1/safeopen/credits")!
        var req = URLRequest(url: endpoint)
        req.httpMethod = "GET"
        req.setValue("Bearer \(Self.serviceToken)", forHTTPHeaderField: "Authorization")
        req.setValue(Self.deviceID, forHTTPHeaderField: "X-Device-ID")
        let (data, response) = try await Self.session.data(for: req)
        try checkStatus(response, data: data)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(CreditSnapshot.self, from: data)
    }

    struct RedeemResponse: Decodable {
        let balance: Int
        let granted: Int
        let productId: String
    }

    func redeemTransaction(id transactionId: String) async throws -> RedeemResponse {
        let endpoint = URL(string: "\(Self.baseURL)/v1/safeopen/credits/redeem")!
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("Bearer \(Self.serviceToken)", forHTTPHeaderField: "Authorization")
        req.setValue(Self.deviceID, forHTTPHeaderField: "X-Device-ID")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["transaction_id": transactionId])
        let (data, response) = try await Self.session.data(for: req)
        try checkStatus(response, data: data)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(RedeemResponse.self, from: data)
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
