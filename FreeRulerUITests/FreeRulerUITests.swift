import XCTest

final class FreeRulerUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchEnvironment["FREE_RULER_UI_TESTS"] = "1"
        app.launch()
        app.activate()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    func testRulerVisibilityKeyboardCommands() {
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 3))

        horizontalRuler.click()
        app.typeKey("h", modifierFlags: [])
        XCTAssertTrue(horizontalRuler.waitForNonExistence(timeout: 2))
        XCTAssertTrue(verticalRuler.exists)

        app.typeKey("h", modifierFlags: [])
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 2))

        verticalRuler.click()
        app.typeKey("v", modifierFlags: [])
        XCTAssertTrue(verticalRuler.waitForNonExistence(timeout: 2))
        XCTAssertTrue(horizontalRuler.exists)

        app.typeKey("v", modifierFlags: [])
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 2))
    }

    func testGroupedRulerToggleUngroupsAndHidesRequestedRuler() {
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 3))

        horizontalRuler.click()
        setGroupRulers(true)
        XCTAssertTrue(groupRulersEnabledInPreferences())

        horizontalRuler.click()
        app.typeKey("v", modifierFlags: [])

        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 2))
        XCTAssertTrue(verticalRuler.waitForNonExistence(timeout: 2))
        XCTAssertFalse(groupRulersEnabledInPreferences())
    }

    func testGroupRulersKeyboardCommandUngroupsOnFirstAttempt() {
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 3))

        horizontalRuler.click()
        setGroupRulers(true)
        XCTAssertTrue(groupRulersEnabledInPreferences())

        horizontalRuler.click()
        app.typeKey("g", modifierFlags: [])

        XCTAssertFalse(groupRulersEnabledInPreferences())

        setGroupRulers(true)
        XCTAssertTrue(groupRulersEnabledInPreferences())

        verticalRuler.click()
        app.typeKey("g", modifierFlags: [])

        XCTAssertFalse(groupRulersEnabledInPreferences())
    }

    func testPreferencesCloseWithCommandW() {
        app.typeKey(",", modifierFlags: .command)

        let preferences = app.windows["Free Ruler Preferences"]
        XCTAssertTrue(preferences.waitForExistence(timeout: 3))

        app.typeKey("w", modifierFlags: .command)
        XCTAssertTrue(preferences.waitForNonExistence(timeout: 2))
    }

    func testHiddenRulersCanBeRestoredAndResetRestoresVisibility() {
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 3))

        horizontalRuler.click()
        app.typeKey("h", modifierFlags: [])
        XCTAssertTrue(horizontalRuler.waitForNonExistence(timeout: 2))

        verticalRuler.click()
        app.typeKey("v", modifierFlags: [])
        XCTAssertTrue(verticalRuler.waitForNonExistence(timeout: 2))

        app.typeKey("h", modifierFlags: [])
        app.typeKey("v", modifierFlags: [])
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 2))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 2))

        horizontalRuler.click()
        app.typeKey("h", modifierFlags: [])
        XCTAssertTrue(horizontalRuler.waitForNonExistence(timeout: 2))

        app.typeKey("r", modifierFlags: .command)
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 2))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 2))
    }

    private var horizontalRuler: XCUIElement {
        app.dialogs["horizontal-ruler-window"]
    }

    private var verticalRuler: XCUIElement {
        app.dialogs["vertical-ruler-window"]
    }

    private var preferencesWindow: XCUIElement {
        app.windows["Free Ruler Preferences"]
    }

    private var groupRulersCheckbox: XCUIElement {
        app.checkBoxes["group-rulers-checkbox"]
    }

    private func openPreferences() {
        if !preferencesWindow.exists {
            app.typeKey(",", modifierFlags: .command)
            XCTAssertTrue(preferencesWindow.waitForExistence(timeout: 3))
        }
    }

    private func closePreferences() {
        if preferencesWindow.exists {
            preferencesWindow.click()
            app.typeKey("w", modifierFlags: .command)
            XCTAssertTrue(preferencesWindow.waitForNonExistence(timeout: 2))
        }
    }

    private func setGroupRulers(_ enabled: Bool) {
        openPreferences()

        if groupRulersCheckbox.isChecked != enabled {
            groupRulersCheckbox.click()
        }

        closePreferences()
    }

    private func groupRulersEnabledInPreferences() -> Bool {
        openPreferences()
        let enabled = groupRulersCheckbox.isChecked
        closePreferences()
        return enabled
    }
}

private extension XCUIElement {
    var isChecked: Bool {
        if let value = value as? String {
            return value == "1"
        }

        if let value = value as? NSNumber {
            return value.boolValue
        }

        return false
    }
}
