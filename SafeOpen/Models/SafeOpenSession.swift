import Foundation

struct SafeOpenSession: Codable {
    let sessionId: String
    let sessionToken: String
    let proxyHost: String
    let proxyPort: Int
    let assignedIpv6: String
    let ephemeral: Bool
    let expiresAt: Date

    var isExpired: Bool { Date() >= expiresAt }

    var proxyURL: URL? {
        URL(string: "http://\(proxyHost):\(proxyPort)")
    }

    var displayIpv6: String {
        assignedIpv6.components(separatedBy: ":").last ?? assignedIpv6
    }
}

struct PrefetchResult: Codable {
    let originalUrl: String
    let finalUrl: String
    let statusCode: Int
    let title: String?
    let summary: String?
    let redirectChain: [PrefetchHop]
    let assignedIpv6: String
    let ephemeral: Bool
    let sessionId: String
    let expiresAt: Date

    var resolvedURL: URL? { URL(string: finalUrl) }

    struct PrefetchHop: Codable {
        let url: String
        let statusCode: Int
    }
}
