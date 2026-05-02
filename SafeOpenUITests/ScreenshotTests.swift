import XCTest

@MainActor
class ScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Frame 01: Home — URL paste prompt, empty state

    func testHome() {
        let app = launch(flags: defaultFlags)
        sleep(2)
        snapshot("01-home-paste")
    }

    // MARK: - Frame 02: Home — with placeholder text visible

    func testHomeWithPlaceholder() {
        let app = launch(flags: defaultFlags)
        sleep(2)
        snapshot("02-home-placeholder")
    }

    // MARK: - Frame 03: Home — URL pasted (interaction state)

    func testHomeWithURL() {
        let app = launch(flags: defaultFlags)
        sleep(1)
        let textEditor = app.textEditors.firstMatch
        if textEditor.waitForExistence(timeout: 3) {
            textEditor.tap()
            textEditor.typeText("https://www.google.com")
            sleep(1)
        }
        snapshot("03-home-with-url")
    }

    // MARK: - Frame 04: SafeOpen header + branding

    func testHeader() {
        let app = launch(flags: defaultFlags)
        sleep(2)
        // Scroll to top to ensure header is visible
        app.scrollView.swipeUp()
        sleep(1)
        snapshot("04-header-branding")
    }

    // MARK: - Frame 05: Controls (Paste button, Clear button)

    func testControls() {
        let app = launch(flags: defaultFlags)
        sleep(1)
        let textEditor = app.textEditors.firstMatch
        if textEditor.waitForExistence(timeout: 3) {
            textEditor.tap()
            textEditor.typeText("https://example.com")
            sleep(1)
        }
        snapshot("05-controls-paste-clear")
    }

    // MARK: - Frame 06: Check Safety button (primary CTA)

    func testCheckSafetyButton() {
        let app = launch(flags: defaultFlags)
        sleep(2)
        // Show button in disabled state, then enable by adding text
        let textEditor = app.textEditors.firstMatch
        if textEditor.waitForExistence(timeout: 3) {
            textEditor.tap()
            textEditor.typeText("https://www.apple.com")
            sleep(1)
        }
        snapshot("06-check-safety-button")
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
