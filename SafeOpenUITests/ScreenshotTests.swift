import XCTest

@MainActor
class ScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Frame 01: Home — URL paste prompt

    func testHome() {
        let app = launch(flags: defaultFlags)
        sleep(2)
        snapshot("01-home-paste")
    }

    // MARK: - Frame 02: Scanning state — URL being checked

    func testScanning() {
        let app = launch(flags: defaultFlags + ["--seed-data", "scanning"])
        sleep(2)
        snapshot("02-scanning")
    }

    // MARK: - Frame 03: Safe result — green verdict

    func testSafeResult() {
        let app = launch(flags: defaultFlags + ["--seed-data", "safe"])
        sleep(2)
        snapshot("03-safe-result")
    }

    // MARK: - Frame 04: Suspicious result — yellow warning

    func testSuspiciousResult() {
        let app = launch(flags: defaultFlags + ["--seed-data", "suspicious"])
        sleep(2)
        snapshot("04-suspicious-result")
    }

    // MARK: - Frame 05: Dangerous result — red warning with risk factors

    func testDangerResult() {
        let app = launch(flags: defaultFlags + ["--seed-data", "danger"])
        sleep(2)
        snapshot("05-danger-result")
    }

    // MARK: - Frame 06: Credit balance + IAP pack picker

    func testCreditsAndIAP() {
        let app = launch(flags: defaultFlags + ["--show-credits"])
        sleep(2)
        snapshot("06-credits-iap")
    }

    // MARK: - Helpers

    private var defaultFlags: [String] {
        ["--screenshots", "--skip-onboarding"]
    }

    private func launch(flags: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments += flags
        app.launch()
        return app
    }
}
