import Foundation

/// Mock data seeder for screenshot mode (--screenshots launch argument).
/// Provides sample suspicious URLs for link safety scanning.
struct MockDataSeeder {
    static func seedDataIfNeeded(_ appState: AppState) {
        guard CommandLine.arguments.contains("--screenshots") else { return }

        // Inject 3 mock InspectionResults matching the narrative:
        // 1. Safe result (katafract.com)
        // 2. Danger result (example.top phishing)
        // 3. Caution result (mixed signals)

        let results = [
            ScreenshotMode.safeResult,
            ScreenshotMode.dangerResult,
            ScreenshotMode.cautionResult
        ]

        for result in results {
            appState.record(result)
        }
    }
}
