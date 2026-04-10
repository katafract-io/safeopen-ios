import Foundation
import Security

struct InspectionAPIClient {

    private static let baseURL = "https://api.katafract.com"
    private static let session = URLSession(configuration: .ephemeral)

    // MARK: - Service token (SafeOpen service account on the platform)
    // This is a service-level API key, not a per-user credential.
    private static let serviceToken = "REDACTED_OLD_SERVICE_TOKEN"

    // MARK: - Device ID (stable UUID, persisted in Keychain)
    static var deviceID: String {
        let service = "com.katafract.safeopen"
        let account = "device_id"
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      service,
            kSecAttrAccount:      account,
            kSecReturnData:       true,
        ]
        var result: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
           let data = result as? Data,
           let id = String(data: data, encoding: .utf8) {
            return id
        }
        let newID = UUID().uuidString
        let addQuery: [CFString: Any] = [
            kSecClass:        kSecClassGenericPassword,
            kSecAttrService:  service,
            kSecAttrAccount:  account,
            kSecValueData:    Data(newID.utf8),
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
        return newID
    }

    // MARK: - Pro tier (set true after StoreKit purchase verification)
    static var isProUser: Bool {
        get { UserDefaults.standard.bool(forKey: "com.katafract.safeopen.isPro") }
        set { UserDefaults.standard.set(newValue, forKey: "com.katafract.safeopen.isPro") }
    }

    private func authorized(_ req: inout URLRequest) {
        req.setValue("Bearer \(Self.serviceToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    // MARK: - Prefetch (Phase C)

    func prefetchURL(_ url: URL, regionHint: String? = nil) async throws -> PrefetchResult {
        let endpoint = URL(string: "\(Self.baseURL)/v1/safe-open/prefetch")!
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        authorized(&req)

        var body: [String: Any] = [
            "url": url.absoluteString,
            "device_id": Self.deviceID,
            "request_ephemeral": Self.isProUser,
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

    // MARK: - Session provisioning (Phase D)

    func createSession(for url: URL, regionHint: String? = nil) async throws -> SafeOpenSession {
        let endpoint = URL(string: "\(Self.baseURL)/v1/safe-open/session")!
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        authorized(&req)

        var body: [String: Any] = [
            "url": url.absoluteString,
            "device_id": Self.deviceID,
            "request_ephemeral": Self.isProUser,
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

    // MARK: - Private

    private func checkStatus(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200...299: return
        case 401, 403:  throw InspectionAPIError.unauthorized
        case 402:       throw InspectionAPIError.planRequired
        case 429:       throw InspectionAPIError.rateLimited
        default:
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["detail"]
            throw InspectionAPIError.serverError(http.statusCode, msg ?? "Unknown error")
        }
    }
}

enum InspectionAPIError: LocalizedError {
    case unauthorized
    case planRequired
    case rateLimited
    case networkError(Error)
    case serverError(Int, String)

    var errorDescription: String? {
        switch self {
        case .unauthorized:            return "Service error. Please update the app."
        case .planRequired:            return "Safe Open requires a WraithVPN or Enclave plan."
        case .rateLimited:             return "Too many active sessions. Close an existing session and try again."
        case .networkError(let e):     return e.localizedDescription
        case .serverError(_, let msg): return msg
        }
    }
}
