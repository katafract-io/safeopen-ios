import XCTest

@MainActor
class ScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Frame 01 (HERO): Caught phishing threat
    //
    // App Store search shows frame 01. It MUST sell, not show an empty paste box.
    // This seeds a malicious lookalike-bank URL and presents the danger verdict:
    // high-contrast "Do not open." banner + phishing reasons (punycode lookalike
    // host, suspicious path, encoding). This is the converting hero.
    // Caption overlay (added later): "Know if a link is a scam before you tap".

    func testCapture01HeroDanger() {
        let app = launch(flags: [
            "-ScreenshotMode", "seedData",
            "-ScreenshotMode-tab", "1",
            "-ScreenshotMode-result", "danger"
        ])
        sleep(4)
        snapshot("01-hero-danger-phishing")
    }

    // MARK: - Frame 02: Caution verdict (scam gift-card link)
    //
    // A second populated verdict — a "Free Gift Card" scam flagged as caution.
    // Demonstrates the on-device check catching a softer scam, not just hard
    // phishing. (Camera scanner is intentionally NOT used as a frame: in the
    // simulator / screenshot mode it renders the camera-permission wall, which
    // is exactly the empty-state frame the ASO doctrine forbids.)
    // Caption overlay: "QR codes and links, checked on-device".

    func testCapture02ResultCaution() {
        let app = launch(flags: [
            "-ScreenshotMode", "seedData",
            "-ScreenshotMode-tab", "1",
            "-ScreenshotMode-result", "medium"
        ])
        sleep(4)
        snapshot("02-result-caution")
    }

    // MARK: - Frame 03: Safe verdict (the reassuring counterpart)
    //
    // Caption overlay: "See the threat. Then decide.".

    func testCapture03ResultSafe() {
        let app = launch(flags: [
            "-ScreenshotMode", "seedData",
            "-ScreenshotMode-tab", "1",
            "-ScreenshotMode-result", "safe"
        ])
        sleep(4)
        snapshot("03-result-safe")
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

    // MARK: - Frame 05: Safe preview sheet (web snapshot + trackers)

    func testCapture05PreviewSheet() {
        let app = launch(flags: [
            "-ScreenshotMode", "seedData",
            "-ScreenshotMode-tab", "1",
            "-ScreenshotMode-prefetch"
        ])
        sleep(5)
        snapshot("05-preview-sheet")
    }

    // MARK: - Frame 06: Account (tab 3, with balance display)

    func testCapture06Account() {
        let app = launch(flags: [
            "-ScreenshotMode", "seedData",
            "-ScreenshotMode-tab", "3",
            "-ScreenshotMode-balance", "247"
        ])
        sleep(4)
        snapshot("06-account-balance")
    }

    // MARK: - Helpers

    @discardableResult
    private func launch(flags: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments += flags
        app.launch()
        XCTAssertTrue(
            app.wait(for: .runningForeground, timeout: 30),
            "App did not reach foreground within 30s — aborting to avoid silent 39-min 0-PNG run"
        )
        // Force portrait — the simulator can boot landscape, which produced
        // rotated (landscape) App Store screenshots. Lock to portrait so the
        // capture has the correct portrait dimensions.
        XCUIDevice.shared.orientation = .portrait
        return app
    }
}
