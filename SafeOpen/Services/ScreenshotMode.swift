import Foundation

/// ScreenshotMode: seed synthetic inspection results for fastlane snapshot CI.
///
/// Activated via launch argument: `-ScreenshotMode seedData`
/// When active, bypasses live API calls and injects canned safe/danger results.
struct ScreenshotMode {
    static let isEnabled = CommandLine.arguments.contains("-ScreenshotMode")
    static let seedData = CommandLine.arguments.contains("seedData")

    /// Mock inspection result: safe Google.com
    static let safeResult = InspectionResult(
        id: UUID(),
        payload: ScannedPayload(type: .url, content: "https://www.google.com"),
        title: "Google Search",
        summary: "Google Search is a trusted search engine. No malicious indicators detected.",
        riskLevel: .low,
        riskFactors: [],
        recommendedAction: .open,
        finalURL: URL(string: "https://www.google.com/search?q=example"),
        redirectHops: [
            RedirectHop(
                id: UUID(),
                url: URL(string: "https://www.google.com")!,
                statusCode: 200,
                resolvedLocally: true
            )
        ],
        canOpenSafely: true
    )

    /// Mock inspection result: danger phishing
    static let dangerResult = InspectionResult(
        id: UUID(),
        payload: ScannedPayload(type: .url, content: "https://example.top/verify-account"),
        title: "Suspicious Link",
        summary: "Suspicious URL with phishing indicators. Domain registered recently. Avoid clicking.",
        riskLevel: .high,
        riskFactors: [
            .suspiciousPathKeyword,
            .suspiciousEncoding,
            .trackingParameters
        ],
        recommendedAction: .block,
        finalURL: URL(string: "https://example.top/verify-account?campaign=urgent"),
        redirectHops: [
            RedirectHop(
                id: UUID(),
                url: URL(string: "https://example.top/verify-account")!,
                statusCode: 200,
                resolvedLocally: false
            )
        ],
        canOpenSafely: false
    )
}
