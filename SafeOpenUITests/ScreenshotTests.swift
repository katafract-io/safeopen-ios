import XCTest

final class ScreenshotTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false

        let app = XCUIApplication()
        // Launch with ScreenshotMode enabled and seedData flag
        app.launchArguments = ["-ScreenshotMode", "seedData"]
        setupSnapshot(app)
        app.launch()
    }

    /// Screenshot 1: Paste-link entry hero — identity lockup, kataIce card, pill CTA "Inspect"
    func testScreenshot1_PasteLinkHero() throws {
        let app = XCUIApplication()

        // Navigate to Paste tab (index 1)
        let tabBar = app.tabBars["Tab Bar"]
        let inspectTab = tabBar.buttons["Inspect"]
        inspectTab.tap()

        // Wait for view to stabilize
        sleep(1)

        // Trigger snapshot: identity lockup + input card visible
        snapshot("1_paste_link_hero")
    }

    /// Screenshot 2: Inspection result — SAFE verdict banner, URL preview, tracker count, summary
    func testScreenshot2_SafeResult() throws {
        let app = XCUIApplication()

        // Navigate to Paste tab
        let tabBar = app.tabBars["Tab Bar"]
        let inspectTab = tabBar.buttons["Inspect"]
        inspectTab.tap()

        sleep(1)

        // Paste a Google URL to trigger safe result
        let textField = app.textViews.firstMatch
        textField.tap()
        textField.typeText("https://www.google.com")

        // Tap Inspect button
        let inspectButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Inspect'")).firstMatch
        inspectButton.tap()

        // Wait for result view to appear
        sleep(2)

        // Take screenshot of safe result
        snapshot("2_safe_result_banner")
    }

    /// Screenshot 3: Inspection result — DANGER banner, suspicious URL, tracker breakdown expanded
    func testScreenshot3_DangerResult() throws {
        let app = XCUIApplication()

        // Navigate to Paste tab
        let tabBar = app.tabBars["Tab Bar"]
        let inspectTab = tabBar.buttons["Inspect"]
        inspectTab.tap()

        sleep(1)

        // Paste a phishing URL to trigger danger result
        let textField = app.textViews.firstMatch
        textField.tap()
        textField.typeText("https://example.top/verify-account")

        // Tap Inspect button
        let inspectButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Inspect'")).firstMatch
        inspectButton.tap()

        // Wait for result view to appear and expand
        sleep(2)

        // If expandable section, tap to expand risk factors
        let expandButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Risk'")).firstMatch
        if expandButton.exists {
            expandButton.tap()
            sleep(0.5)
        }

        // Take screenshot of danger result with expanded details
        snapshot("3_danger_result_expanded")
    }

    /// Screenshot 4: Credits view — 4 credit packs with prices
    func testScreenshot4_CreditsView() throws {
        let app = XCUIApplication()

        // Navigate to Account tab (index 3)
        let tabBar = app.tabBars["Tab Bar"]
        let accountTab = tabBar.buttons["Account"]
        accountTab.tap()

        sleep(1)

        // Scroll to find credits/paywall section
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(0.5)
        }

        // Take screenshot of credits view with all packs visible
        snapshot("4_credits_packs")
    }

    /// Screenshot 5: Paywall / Pro unlock view
    func testScreenshot5_ProUpgradeView() throws {
        let app = XCUIApplication()

        // Navigate to Account tab
        let tabBar = app.tabBars["Tab Bar"]
        let accountTab = tabBar.buttons["Account"]
        accountTab.tap()

        sleep(1)

        // Look for upgrade/paywall CTA
        let upgradeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Upgrade' OR label CONTAINS 'Pro' OR label CONTAINS 'Subscribe'")).firstMatch
        if upgradeButton.exists {
            upgradeButton.tap()
            sleep(1)
        }

        // Take screenshot of pro view
        snapshot("5_pro_upgrade_view")
    }

    // MARK: - iPad Variants (iPad Pro 13-inch M5)

    /// Screenshot 6 (iPad): Paste-link entry hero
    func testScreenshot6_iPad_PasteLinkHero() throws {
        let app = XCUIApplication()

        let tabBar = app.tabBars["Tab Bar"]
        let inspectTab = tabBar.buttons["Inspect"]
        inspectTab.tap()

        sleep(1)

        snapshot("6_ipad_paste_link_hero")
    }

    /// Screenshot 7 (iPad): Safe result on wider screen
    func testScreenshot7_iPad_SafeResult() throws {
        let app = XCUIApplication()

        let tabBar = app.tabBars["Tab Bar"]
        let inspectTab = tabBar.buttons["Inspect"]
        inspectTab.tap()

        sleep(1)

        let textField = app.textViews.firstMatch
        textField.tap()
        textField.typeText("https://www.google.com")

        let inspectButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Inspect'")).firstMatch
        inspectButton.tap()

        sleep(2)

        snapshot("7_ipad_safe_result")
    }

    /// Screenshot 8 (iPad): Credits view landscape
    func testScreenshot8_iPad_CreditsView() throws {
        let app = XCUIApplication()

        let tabBar = app.tabBars["Tab Bar"]
        let accountTab = tabBar.buttons["Account"]
        accountTab.tap()

        sleep(1)

        snapshot("8_ipad_credits_view")
    }
}
