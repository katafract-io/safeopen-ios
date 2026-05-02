import Foundation

/// ScreenshotMode: seed synthetic inspection results for fastlane snapshot CI.
///
/// Activated via launch argument: `-ScreenshotMode seedData`
/// When active, bypasses live API calls and injects canned safe/danger results.
struct ScreenshotMode {
    static let isEnabled = CommandLine.arguments.contains("-ScreenshotMode")
    static let seedData = CommandLine.arguments.contains("seedData")

    /// Initial tab to display (0=Scan, 1=Inspect, 2=History, 3=Account).
    /// Parsed from `-ScreenshotMode-tab <0|1|2|3>`. Defaults to nil (no override).
    static var initialTab: Int? {
        if let idx = CommandLine.arguments.firstIndex(of: "-ScreenshotMode-tab"),
           idx + 1 < CommandLine.arguments.count,
           let tab = Int(CommandLine.arguments[idx + 1]) {
            return tab
        }
        return nil
    }

    /// Inspection result to present directly as a sheet.
    /// Parsed from `-ScreenshotMode-result <safe|danger|medium|risky>`.
    static var presentResult: InspectionResult? {
        guard let idx = CommandLine.arguments.firstIndex(of: "-ScreenshotMode-result"),
              idx + 1 < CommandLine.arguments.count else { return nil }
        let kind = CommandLine.arguments[idx + 1].lowercased()
        switch kind {
        case "safe": return safeResult
        case "danger": return dangerResult
        case "medium": return mediumRiskResult
        case "risky": return riskyResult
        default: return nil
        }
    }

    /// Whether to present the Buy Credits sheet.
    /// Parsed from `-ScreenshotMode-upgrade` flag.
    static var presentUpgradeSheet: Bool {
        CommandLine.arguments.contains("-ScreenshotMode-upgrade")
    }

    /// Mock credit balance for screenshot.
    /// Parsed from `-ScreenshotMode-balance <int>`. Defaults to nil (use live balance).
    static var mockBalance: Int? {
        if let idx = CommandLine.arguments.firstIndex(of: "-ScreenshotMode-balance"),
           idx + 1 < CommandLine.arguments.count,
           let balance = Int(CommandLine.arguments[idx + 1]) {
            return balance
        }
        return nil
    }

    /// History seed: array of 4 inspection results (safe, danger, medium, risky).
    static var seedHistory: [InspectionResult] {
        [safeResult, dangerResult, mediumRiskResult, riskyResult]
    }

    /// Mock inspection result: safe CNN
    static let safeResult = InspectionResult(
        id: UUID(),
        payload: ScannedPayload(
            id: UUID(),
            rawValue: "https://www.cnn.com",
            type: .url,
            normalizedValue: "https://www.cnn.com",
            scannedAt: Date(),
            source: .shareExtension
        ),
        title: "CNN News",
        summary: "CNN is a reputable news outlet. No malicious indicators detected.",
        riskLevel: .low,
        riskFactors: [],
        recommendedAction: .open,
        finalURL: URL(string: "https://www.cnn.com/"),
        redirectHops: [
            RedirectHop(
                id: UUID(),
                url: URL(string: "https://www.cnn.com")!,
                statusCode: 200,
                resolvedLocally: true
            )
        ],
        canOpenSafely: true
    )

    /// Mock inspection result: danger phishing
    static let dangerResult = InspectionResult(
        id: UUID(),
        payload: ScannedPayload(
            id: UUID(),
            rawValue: "https://suspicious-bank-login.xyz/verify-account",
            type: .url,
            normalizedValue: "https://suspicious-bank-login.xyz/verify-account",
            scannedAt: Date().addingTimeInterval(-3600),
            source: .shareExtension
        ),
        title: "Suspicious Link",
        summary: "Suspicious URL with phishing indicators. Domain registered recently. Avoid clicking.",
        riskLevel: .high,
        riskFactors: [
            .suspiciousPathKeyword,
            .suspiciousEncoding,
            .trackingParameters
        ],
        recommendedAction: .block,
        finalURL: URL(string: "https://suspicious-bank-login.xyz/verify-account?campaign=urgent"),
        redirectHops: [
            RedirectHop(
                id: UUID(),
                url: URL(string: "https://suspicious-bank-login.xyz/verify-account")!,
                statusCode: 200,
                resolvedLocally: false
            )
        ],
        canOpenSafely: false
    )

    /// Mock inspection result: medium risk
    static let mediumRiskResult = InspectionResult(
        id: UUID(),
        payload: ScannedPayload(
            id: UUID(),
            rawValue: "https://free-gift-card-prize.site/claim",
            type: .url,
            normalizedValue: "https://free-gift-card-prize.site/claim",
            scannedAt: Date().addingTimeInterval(-7200),
            source: .shareExtension
        ),
        title: "Free Gift Card Offer",
        summary: "Domain age and content pattern suggests potential scam. Proceed with caution.",
        riskLevel: .caution,
        riskFactors: [
            .suspiciousPathKeyword,
            .trackingParameters
        ],
        recommendedAction: .caution,
        finalURL: URL(string: "https://free-gift-card-prize.site/claim?ref=social"),
        redirectHops: [
            RedirectHop(
                id: UUID(),
                url: URL(string: "https://free-gift-card-prize.site/claim")!,
                statusCode: 200,
                resolvedLocally: false
            )
        ],
        canOpenSafely: false
    )

    /// Mock inspection result: risky (different safe URL)
    static let riskyResult = InspectionResult(
        id: UUID(),
        payload: ScannedPayload(
            id: UUID(),
            rawValue: "https://www.wikipedia.org",
            type: .url,
            normalizedValue: "https://www.wikipedia.org",
            scannedAt: Date().addingTimeInterval(-10800),
            source: .shareExtension
        ),
        title: "Wikipedia",
        summary: "Wikipedia is a trusted reference source. No malicious indicators detected.",
        riskLevel: .low,
        riskFactors: [],
        recommendedAction: .open,
        finalURL: URL(string: "https://www.wikipedia.org/"),
        redirectHops: [
            RedirectHop(
                id: UUID(),
                url: URL(string: "https://www.wikipedia.org")!,
                statusCode: 200,
                resolvedLocally: true
            )
        ],
        canOpenSafely: true
    )
}
