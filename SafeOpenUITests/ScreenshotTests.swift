import XCTest

@MainActor
class ScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--screenshots"]
        setupSnapshot(app)
        app.launch()
    }

    /// Home: enter-URL prompt, recent scans
    func testHome() throws {
        let app = XCUIApplication()
        snapshot("01-home")
    }

    /// Result: safe URL — green confirmation + redirect chain
    func testSafeResult() throws {
        let app = XCUIApplication()
        snapshot("02-safe-result")
    }

    /// Result: dangerous URL — red warning + reasons
    func testDangerResult() throws {
        let app = XCUIApplication()
        snapshot("03-danger-result")
    }

    /// Credit packs / IAP screen
    func testCredits() throws {
        let app = XCUIApplication()
        snapshot("04-credits")
    }

    /// Settings: integrations + privacy
    func testSettings() throws {
        let app = XCUIApplication()
        snapshot("05-settings")
    }
}
