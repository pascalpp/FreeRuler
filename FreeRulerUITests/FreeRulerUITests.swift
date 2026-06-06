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

    func testFloatShadowAndUnitKeyboardCommands() {
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 3))

        horizontalRuler.click()
        XCTAssertTrue(floatRulersEnabledInPreferences())

        horizontalRuler.click()
        app.typeKey("f", modifierFlags: [])
        XCTAssertFalse(floatRulersEnabledInPreferences())

        horizontalRuler.click()
        app.typeKey("f", modifierFlags: [])
        XCTAssertTrue(floatRulersEnabledInPreferences())

        horizontalRuler.click()
        XCTAssertFalse(rulerShadowEnabledInPreferences())

        horizontalRuler.click()
        app.typeKey("s", modifierFlags: [])
        XCTAssertTrue(rulerShadowEnabledInPreferences())

        horizontalRuler.click()
        app.typeKey("s", modifierFlags: [])
        XCTAssertFalse(rulerShadowEnabledInPreferences())

        horizontalRuler.click()
        XCTAssertEqual(horizontalRulerView.value as? String, "px")

        app.typeKey("u", modifierFlags: [])
        XCTAssertEqual(horizontalRulerView.value as? String, "mm")

        app.typeKey("u", modifierFlags: [])
        XCTAssertEqual(horizontalRulerView.value as? String, "in")

        app.typeKey("u", modifierFlags: [])
        XCTAssertEqual(horizontalRulerView.value as? String, "px")
    }

    func testAlignRulersAtMouseLocationKeyboardCommand() {
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 3))

        let originalHorizontalFrame = horizontalRuler.frame
        let originalVerticalFrame = verticalRuler.frame

        verticalRuler.click()
        app.typeKey("o", modifierFlags: [])

        XCTAssertTrue(horizontalRuler.waitForFrameChange(from: originalHorizontalFrame, timeout: 2))
        XCTAssertTrue(verticalRuler.waitForFrameChange(from: originalVerticalFrame, timeout: 2))
    }

    private var horizontalRuler: XCUIElement {
        app.dialogs["horizontal-ruler-window"]
    }

    private var verticalRuler: XCUIElement {
        app.dialogs["vertical-ruler-window"]
    }

    private var horizontalRulerView: XCUIElement {
        app.otherElements["horizontal-ruler-view"]
    }

    private var preferencesWindow: XCUIElement {
        app.windows["Free Ruler Preferences"]
    }

    private var floatRulersCheckbox: XCUIElement {
        app.checkBoxes["float-rulers-checkbox"]
    }

    private var groupRulersCheckbox: XCUIElement {
        app.checkBoxes["group-rulers-checkbox"]
    }

    private var rulerShadowCheckbox: XCUIElement {
        app.checkBoxes["ruler-shadow-checkbox"]
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

    private func floatRulersEnabledInPreferences() -> Bool {
        openPreferences()
        let enabled = floatRulersCheckbox.isChecked
        closePreferences()
        return enabled
    }

    private func rulerShadowEnabledInPreferences() -> Bool {
        openPreferences()
        let enabled = rulerShadowCheckbox.isChecked
        closePreferences()
        return enabled
    }
}

private extension XCUIElement {
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    func waitForFrameChange(from originalFrame: CGRect, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if !frame.equalTo(originalFrame) {
                return true
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }

        return !frame.equalTo(originalFrame)
    }

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
