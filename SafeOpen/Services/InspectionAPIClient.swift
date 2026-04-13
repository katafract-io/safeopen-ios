import Foundation

/// Calls the SafeOpen backend using the app-level service token.
/// All users share this token; StoreKit (SafeOpenStore.isPro) is the
/// sole client-side gate for whether to call the backend at all.
struct InspectionAPIClient {

    static let baseURL = "https://api.katafract.com"
    private static let session = URLSession(configuration: .ephemeral)

    /// The app service token — authenticates the SafeOpen app to the backend.
    /// All Pro users share this token; rate limiting is enforced server-side.
    static let serviceToken = "3e27ee700e0b3ef336b4c7b5360af3fdb16410fb445e2b1889bf5da5b083b977"

    // MARK: - Prefetch

    func prefetchURL(_ url: URL, regionHint: String? = nil) async throws -> PrefetchResult {
        let endpoint = URL(string: "\(Self.baseURL)/v1/safe-open/prefetch")!
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("Bearer \(Self.serviceToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "url": url.absoluteString,
            "request_ephemeral": true,   // always request disposable IPv6 for Pro users
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

    // MARK: - Session provisioning (unused in current flow — prefetch covers inspection)

    func createSession(for url: URL, regionHint: String? = nil) async throws -> SafeOpenSession {
        let endpoint = URL(string: "\(Self.baseURL)/v1/safe-open/session")!
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("Bearer \(Self.serviceToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "url": url.absoluteString,
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
        case .planRequired:            return "SafeOpen Pro is required to open links in a clean session."
        case .rateLimited:             return "Too many active sessions. Try again in a moment."
        case .networkError(let e):     return e.localizedDescription
        case .serverError(_, let msg): return msg
        }
    }
}
