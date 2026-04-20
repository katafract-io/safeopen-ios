import Foundation

/// Simplified URL inspection for Share Extension (free tier only)
actor ShareExtensionInspector {
    static let shared = ShareExtensionInspector()

    func inspect(url: URL) async -> InspectionResult {
        let payload = ScannedPayload(rawValue: url.absoluteString, type: .url)

        // Perform basic risk assessment (no backend call)
        let riskFactors = assessRiskFactors(url: url)
        let riskLevel = computeRiskLevel(factors: riskFactors)

        return InspectionResult(
            id: UUID(),
            payload: payload,
            title: url.host ?? "Link",
            summary: summarizeRisk(riskLevel),
            riskLevel: riskLevel,
            riskFactors: riskFactors,
            recommendedAction: .openSafely,
            finalURL: url,
            redirectHops: [],
            canOpenSafely: true
        )
    }

    private func assessRiskFactors(url: URL) -> [RiskFactor] {
        var factors: [RiskFactor] = []

        // Check for suspicious TLDs
        if let host = url.host?.lowercased() {
            if host.hasSuffix(".tk") || host.hasSuffix(".ml") || host.hasSuffix(".ga") {
                factors.append(RiskFactor(
                    category: "suspicious_tld",
                    severity: .medium,
                    explanation: "Uses a free/suspicious TLD"
                ))
            }

            // Check for homograph attacks (Cyrillic 'а' vs Latin 'a')
            if host.contains("а") || host.contains("е") || host.contains("о") ||
               host.contains("р") || host.contains("с") || host.contains("у") ||
               host.contains("х") || host.contains("у") {
                factors.append(RiskFactor(
                    category: "homograph_attack",
                    severity: .high,
                    explanation: "May use homograph characters to impersonate a domain"
                ))
            }

            // Check for IP addresses (less trustworthy)
            if url.host?.first?.isNumber == true {
                factors.append(RiskFactor(
                    category: "ip_address",
                    severity: .low,
                    explanation: "Link points directly to an IP address instead of a domain"
                ))
            }
        }

        // Check for mixed content indicators in the URL
        if url.scheme == "http" {
            factors.append(RiskFactor(
                category: "insecure_scheme",
                severity: .medium,
                explanation: "Uses unencrypted HTTP instead of HTTPS"
            ))
        }

        // Check for suspicious query parameters (common phishing indicators)
        if let query = url.query {
            let suspicious = ["login", "signin", "auth", "verify", "confirm", "password", "update"]
            for param in suspicious {
                if query.lowercased().contains(param) {
                    factors.append(RiskFactor(
                        category: "suspicious_params",
                        severity: .medium,
                        explanation: "URL contains suspicious parameter names"
                    ))
                    break
                }
            }
        }

        return factors
    }

    private func computeRiskLevel(factors: [RiskFactor]) -> RiskLevel {
        let highCount = factors.filter { $0.severity == .high }.count
        let mediumCount = factors.filter { $0.severity == .medium }.count

        if highCount > 0 {
            return .high
        } else if mediumCount >= 2 {
            return .caution
        } else if mediumCount == 1 {
            return .caution
        } else {
            return .low
        }
    }

    private func summarizeRisk(_ level: RiskLevel) -> String {
        switch level {
        case .low:     return "This link appears safe to open"
        case .caution: return "This link has some risk factors worth checking"
        case .high:    return "This link shows signs of being dangerous"
        case .unknown: return "Unable to fully assess this link"
        }
    }
}
