import Foundation
import SwiftUI

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

struct PrefetchResult: Codable, Identifiable {
    var id: String { sessionId }
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
    let trackers: [TrackerEntry]
    let hasSnapshot: Bool

    var resolvedURL: URL? { URL(string: finalUrl) }

    struct PrefetchHop: Codable {
        let url: String
        let statusCode: Int
    }
}

struct TrackerEntry: Codable, Identifiable {
    var id: String { domain }
    let domain: String
    let category: String  // analytics | advertising | social | fingerprinting

    var displayCategory: String {
        switch category {
        case "analytics":      return "Analytics"
        case "advertising":    return "Advertising"
        case "social":         return "Social"
        case "fingerprinting": return "Fingerprinting"
        default:               return category.capitalized
        }
    }

    var categoryColor: Color {
        switch category {
        case "analytics":      return .orange
        case "advertising":    return .red
        case "social":         return Color(red: 0.4, green: 0.5, blue: 1)
        case "fingerprinting": return .purple
        default:               return .secondary
        }
    }
}
