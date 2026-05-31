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

    /// Mock inspection result: danger phishing.
    /// This is the App Store HERO frame (frame 01). It must read instantly as a
    /// CAUGHT phishing threat: high-contrast "Do not open." verdict, a lookalike
    /// bank-login domain, and concrete reasons. Lead riskFactor is .punycodeHost
    /// so the banner stamp surfaces the phishing/lookalike-domain reason first.
    static let dangerResult = InspectionResult(
        id: UUID(),
        payload: ScannedPayload(
            id: UUID(),
            rawValue: "https://secure-chàse-login.xyz/verify-account",
            type: .url,
            normalizedValue: "https://secure-chàse-login.xyz/verify-account",
            scannedAt: Date().addingTimeInterval(-3600),
            source: .shareExtension
        ),
        title: "Phishing — Do Not Open",
        summary: "Phishing link. This domain imitates a real bank login page using lookalike characters and was registered days ago. Do not enter your credentials.",
        riskLevel: .high,
        riskFactors: [
            .punycodeHost,
            .suspiciousPathKeyword,
            .suspiciousEncoding
        ],
        recommendedAction: .block,
        finalURL: URL(string: "https://secure-chàse-login.xyz/verify-account?campaign=urgent"),
        redirectHops: [
            RedirectHop(
                id: UUID(),
                url: URL(string: "https://secure-chàse-login.xyz/verify-account")!,
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

    // MARK: - Prefetch preview mock

    /// Whether to present the PrefetchPreviewSheet in screenshot mode.
    static var presentPrefetch: PrefetchResult? {
        CommandLine.arguments.contains("-ScreenshotMode-prefetch") ? mockNYTPrefetch : nil
    }

    static let mockNYTPrefetch = PrefetchResult(
        originalUrl: "https://www.nytimes.com",
        finalUrl: "https://www.nytimes.com/",
        statusCode: 200,
        title: "The New York Times - Breaking News, U.S., World, Business",
        summary: "Reputable major news publication. No security risks detected. Analytics trackers present.",
        redirectChain: [],
        assignedIpv6: "2a01:4ff:f4:fb91::1:4b",
        ephemeral: true,
        sessionId: "screenshot-nyt-session",
        expiresAt: Date().addingTimeInterval(7200),
        trackers: [
            TrackerEntry(domain: "googletagmanager.com", category: "analytics"),
            TrackerEntry(domain: "googlesyndication.com", category: "advertising"),
            TrackerEntry(domain: "parsely.com",           category: "analytics"),
        ],
        hasSnapshot: true
    )

    /// Self-contained HTML served to SnapshotWebView during screenshot runs
    /// instead of a live API call.
    static let snapshotHTML = """
    <!DOCTYPE html>
    <html>
    <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
    *{margin:0;padding:0;box-sizing:border-box}
    body{font-family:-apple-system,'Georgia',serif;background:#fff;color:#121212}
    .mast{border-bottom:2px solid #121212;padding:10px 16px;text-align:center}
    .mast h1{font-size:24px;font-family:'Times New Roman',Georgia,serif;letter-spacing:-0.5px}
    .mast .dt{font-size:10px;color:#666;margin-top:2px;font-family:-apple-system,sans-serif}
    .nav{display:flex;gap:14px;padding:7px 16px;overflow-x:auto;border-bottom:1px solid #e2e2e2;scrollbar-width:none}
    .nav a{font-size:11px;color:#333;text-decoration:none;white-space:nowrap;font-family:-apple-system,sans-serif;font-weight:500}
    .feat{padding:14px 16px;border-bottom:2px solid #121212}
    .kick{font-size:10px;text-transform:uppercase;letter-spacing:1.2px;font-weight:700;color:#c0392b;font-family:-apple-system,sans-serif;margin-bottom:5px}
    .feat h2{font-size:26px;line-height:1.12;font-family:Georgia,serif;margin-bottom:7px}
    .feat .sum{font-size:13px;color:#444;margin-bottom:7px;line-height:1.5;font-family:Georgia,serif}
    .feat .by{font-size:10px;color:#777;font-family:-apple-system,sans-serif}
    .list{padding:4px 16px 8px}
    .item{border-bottom:1px solid #e8e8e8;padding:11px 0;display:flex;gap:10px;align-items:flex-start}
    .item h3{font-size:15px;line-height:1.25;font-family:Georgia,serif;flex:1}
    .item .cat{font-size:10px;color:#888;font-family:-apple-system,sans-serif;margin-top:3px}
    .thumb{width:56px;height:42px;background:#e8e8e8;border-radius:3px;flex-shrink:0}
    .thumb.b{background:#c8d4e0}
    .thumb.c{background:#d4c8c8}
    .thumb.d{background:#c8d4c8}
    </style>
    </head>
    <body>
    <div class="mast">
      <h1>The New York Times</h1>
      <div class="dt">Thursday, May 8, 2026 · Today's Paper</div>
    </div>
    <div class="nav">
      <a>World</a><a>U.S.</a><a>Politics</a><a>N.Y.</a><a>Business</a><a>Opinion</a><a>Tech</a><a>Science</a><a>Health</a><a>Sports</a><a>Arts</a>
    </div>
    <div class="feat">
      <div class="kick">Breaking News</div>
      <h2>Global Leaders Reach Landmark Climate Agreement at Emergency Summit</h2>
      <div class="sum">Delegates from 60 nations signed a binding accord early Thursday setting aggressive new emissions targets, capping a week of intense negotiations that nearly collapsed Tuesday.</div>
      <div class="by">By Sarah Mitchell and James Chen &nbsp;·&nbsp; 2 hours ago</div>
    </div>
    <div class="list">
      <div class="item">
        <div><h3>Federal Reserve Signals Rate Decision Ahead of Markets Open</h3><div class="cat">Business · 45 min ago</div></div>
        <div class="thumb b"></div>
      </div>
      <div class="item">
        <div><h3>Mediterranean Diet Linked to Sharply Lower Dementia Risk in Major Study</h3><div class="cat">Health · 1 hour ago</div></div>
        <div class="thumb c"></div>
      </div>
      <div class="item">
        <div><h3>Tech Giants Face New Antitrust Scrutiny in European Union</h3><div class="cat">Technology · 3 hours ago</div></div>
        <div class="thumb d"></div>
      </div>
      <div class="item">
        <div><h3>Broadway Season Opens With Record Attendance for Acclaimed Revival</h3><div class="cat">Arts · 4 hours ago</div></div>
        <div class="thumb b"></div>
      </div>
    </div>
    </body>
    </html>
    """


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
