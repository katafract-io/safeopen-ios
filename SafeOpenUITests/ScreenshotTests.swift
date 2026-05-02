import XCTest

@MainActor
class ScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Frame 01: Empty paste (default Inspect tab, home state)

    func testCapture01PasteEmpty() {
        let app = launch(flags: ["-ScreenshotMode", "seedData"])
        sleep(4)
        snapshot("01-paste-empty")
    }

    // MARK: - Frame 02: Safe result (verdicts inspection)

    func testCapture02ResultSafe() {
        let app = launch(flags: [
            "-ScreenshotMode", "seedData",
            "-ScreenshotMode-result", "safe"
        ])
        sleep(4)
        snapshot("02-result-safe")
    }

    // MARK: - Frame 03: Dangerous result (phishing warning)

    func testCapture03ResultDanger() {
        let app = launch(flags: [
            "-ScreenshotMode", "seedData",
            "-ScreenshotMode-result", "danger"
        ])
        sleep(4)
        snapshot("03-result-danger")
    }

    // MARK: - Frame 04: History (tab 2, populated with 4 results)

    func testCapture04History() {
        let app = launch(flags: [
            "-ScreenshotMode", "seedData",
            "-ScreenshotMode-tab", "2"
        ])
        sleep(4)
        snapshot("04-history")
    }

    // MARK: - Frame 05: Account (tab 3, with balance display)

    func testCapture05Account() {
        let app = launch(flags: [
            "-ScreenshotMode", "seedData",
            "-ScreenshotMode-tab", "3",
            "-ScreenshotMode-balance", "247"
        ])
        sleep(4)
        snapshot("05-account-balance")
    }

    // MARK: - Frame 06: Upgrade sheet (buy credits, zero balance)

    func testCapture06UpgradeSheet() {
        let app = launch(flags: [
            "-ScreenshotMode", "seedData",
            "-ScreenshotMode-upgrade",
            "-ScreenshotMode-balance", "0"
        ])
        sleep(4)
        snapshot("06-upgrade-sheet")
    }

    // MARK: - Helpers

    private func launch(flags: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments += flags
        app.launch()
        return app
    }
}
