import Foundation

struct SafeOpenSession: Codable {
    let sessionId: String
    let sessionToken: String
    let proxyHost: String
    let proxyPort: Int
    let assignedIPv6: String
    let ephemeral: Bool
    let expiresAt: Date

    var isExpired: Bool { Date() >= expiresAt }

    var proxyURL: URL? {
        URL(string: "http://\(proxyHost):\(proxyPort)")
    }

    var displayIPv6: String {
        // Truncate for display: fd10:cafe::a3b2 → a3b2
        assignedIPv6.components(separatedBy: ":").last ?? assignedIPv6
    }
}

struct PrefetchResult: Codable {
    let originalURL: String
    let finalURL: String
    let statusCode: Int
    let title: String?
    let redirectChain: [PrefetchHop]
    let assignedIPv6: String
    let ephemeral: Bool
    let sessionId: String
    let expiresAt: Date

    var resolvedURL: URL? { URL(string: finalURL) }

    struct PrefetchHop: Codable {
        let url: String
        let statusCode: Int
    }
}
