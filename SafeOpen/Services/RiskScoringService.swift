import Foundation

/// Deterministic, local-only risk scoring. No network calls.
struct RiskScoringService {

    private static let suspiciousPathKeywords = [
        "login", "signin", "sign-in", "reset", "password", "verify",
        "confirm", "account", "payment", "checkout", "billing", "admin"
    ]

    private static let commonShorteners = PayloadClassifier.knownShorteners

    func score(url: URL, type: PayloadType) -> (level: RiskLevel, factors: [RiskFactor]) {
        var factors: [RiskFactor] = []

        if type == .shortURL {
            factors.append(.shortenedLink)
        }

        guard let host = url.host else {
            return (.unknown, [.unknownDestination])
        }

        // Insecure transport
        if url.scheme == "http" {
            factors.append(.insecureTransport)
        }

        // Raw IP address
        if isRawIP(host) {
            factors.append(.rawIPAddress)
        }

        // Punycode / IDN homograph
        if host.contains("xn--") {
            factors.append(.punycodeHost)
        }

        // Unusual port
        if let port = url.port, !isCommonPort(port) {
            factors.append(.unusualPort)
        }

        // Suspicious path keywords
        let path = url.path.lowercased()
        if Self.suspiciousPathKeywords.contains(where: { path.contains($0) }) {
            factors.append(.suspiciousPathKeyword)
        }

        // Excessive query params
        if let query = url.query {
            let params = query.components(separatedBy: "&")
            if params.count > 8 {
                factors.append(.excessiveQueryParams)
            }
            // Tracking params
            let trackingKeys = ["utm_", "fbclid", "gclid", "mc_eid", "ref", "affiliate", "click_id"]
            if trackingKeys.contains(where: { query.lowercased().contains($0) }) {
                factors.append(.trackingParameters)
            }
        }

        // Suspicious encoding density
        let raw = url.absoluteString
        let encodedCount = raw.components(separatedBy: "%").count - 1
        if encodedCount > 5 {
            factors.append(.suspiciousEncoding)
        }

        // Extremely long URL
        if raw.count > 500 {
            factors.append(.extremelyLongURL)
        }

        let level = riskLevel(factors: factors)
        return (level, factors)
    }

    // MARK: - Private

    private func riskLevel(factors: [RiskFactor]) -> RiskLevel {
        if factors.isEmpty { return .low }
        // Immediate high-risk signals
        let highRisk: Set<RiskFactor> = [.rawIPAddress, .punycodeHost, .suspiciousEncoding, .unusualPort]
        if factors.contains(where: { highRisk.contains($0) }) { return .high }
        // HTTP credential/action page — classic phishing pattern
        if factors.contains(.insecureTransport) && factors.contains(.suspiciousPathKeyword) { return .high }
        // Two or more softer signals together
        if factors.count >= 2 { return .caution }
        if factors.contains(.shortenedLink) { return .caution }
        if factors.contains(.extremelyLongURL) { return .caution }
        return .low
    }

    private func isRawIP(_ host: String) -> Bool {
        // IPv4
        let ipv4 = host.split(separator: ".").count == 4 &&
            host.split(separator: ".").allSatisfy({ Int($0) != nil })
        // IPv6 (rough check)
        let ipv6 = host.hasPrefix("[") && host.hasSuffix("]")
        return ipv4 || ipv6
    }

    private func isCommonPort(_ port: Int) -> Bool {
        return [80, 443, 8080, 8443].contains(port)
    }
}
