import Foundation

/// Stub — future backend-assisted inspection.
/// Phase 2+: calls platform API for redirect expansion, domain enrichment, reputation.
struct InspectionAPIClient {

    // MARK: - Future endpoints
    // POST /v1/inspect/url
    // POST /v1/inspect/qr
    // POST /v1/inspect/expand
    // POST /v1/safe-open/session

    func inspectURL(_ url: URL) async throws -> InspectionResult {
        // TODO: Phase 2 — call platform API
        throw InspectionAPIError.notImplemented
    }

    func expandShortURL(_ url: URL) async throws -> URL {
        // TODO: Phase 2 — redirect tracing via platform
        throw InspectionAPIError.notImplemented
    }

    func requestSafeOpenSession(for url: URL) async throws -> SafeOpenSession {
        // TODO: Phase C — Wraith integration
        throw InspectionAPIError.notImplemented
    }
}

struct SafeOpenSession: Codable {
    let sessionToken: String
    let assignedIPv6: String   // ephemeral sandbox IPv6 from Enclave pool
    let expiresAt: Date
}

enum InspectionAPIError: Error {
    case notImplemented
    case networkError(Error)
    case unauthorized
}
