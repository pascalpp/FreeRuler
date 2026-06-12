import XCTest
import Darwin

final class FreeRulerUITests: XCTestCase {

    private var app: XCUIApplication!
    private var cursorStateURL: URL!

    override func setUpWithError() throws {
        continueAfterFailure = false

        let cursorStateName = "FreeRulerUITests-\(UUID().uuidString).cursor"
        let homeDirectory = currentUserHomeDirectory()
        cursorStateURL = URL(fileURLWithPath: homeDirectory)
            .appendingPathComponent("Library/Containers/com.pascal.freeruler/Data/tmp", isDirectory: true)
            .appendingPathComponent(cursorStateName)
        try? FileManager.default.createDirectory(
            at: cursorStateURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? FileManager.default.removeItem(at: cursorStateURL)

        app = XCUIApplication()
        app.launchEnvironment["FREE_RULER_UI_TESTS"] = "1"
        app.launchEnvironment["FREE_RULER_UI_TEST_CURSOR_STATE_NAME"] = cursorStateName
        app.launch()
        app.activate()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
        try? FileManager.default.removeItem(at: cursorStateURL)
        cursorStateURL = nil
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

    func testRulerColorPanelHidesOpacityControl() {
        openRulerColorPanel()
        XCTAssertTrue(
            colorPanel.buttons["Color Palettes"].waitForVisibleExistence(timeout: 1),
            "The color panel should expose its picker controls."
        )
        XCTAssertTrue(
            colorPanel.staticTexts["Opacity"].waitForNonVisibility(timeout: 1),
            "The ruler color panel should not expose alpha controls."
        )
    }

    func testClosingPreferencesClosesRulerColorPanel() {
        openRulerColorPanel()

        app.typeKey("w", modifierFlags: .command)

        XCTAssertTrue(preferencesWindow.waitForNonExistence(timeout: 2))
        XCTAssertTrue(colorPanel.waitForNonExistence(timeout: 2))
    }

    func testRulerColorPanelDoesNotReopenAfterRelaunch() {
        openRulerColorPanel()

        app.terminate()
        app.launch()
        app.activate()

        XCTAssertTrue(colorPanel.waitForNonExistence(timeout: 2))
    }

    func testRulerCloseWithCommandW() {
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 3))

        horizontalRuler.click()
        app.typeKey("w", modifierFlags: .command)

        XCTAssertTrue(horizontalRuler.waitForNonExistence(timeout: 2))
        XCTAssertTrue(verticalRuler.exists)
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

    func testOptionHotkeysShowStatusBezel() {
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 3))

        horizontalRuler.click()
        app.typeKey("f", modifierFlags: [])
        XCTAssertTrue(waitForHotkeyBezel("Rulers unfloated"))

        app.typeKey("f", modifierFlags: [])
        XCTAssertTrue(waitForHotkeyBezel("Rulers floated"))

        app.typeKey("s", modifierFlags: [])
        XCTAssertTrue(waitForHotkeyBezel("Shadow enabled"))

        app.typeKey("s", modifierFlags: [])
        XCTAssertTrue(waitForHotkeyBezel("Shadow disabled"))

        app.typeKey("g", modifierFlags: [])
        XCTAssertTrue(waitForHotkeyBezel("Rulers ungrouped"))

        app.typeKey("g", modifierFlags: [])
        XCTAssertTrue(waitForHotkeyBezel("Rulers grouped"))

        app.typeKey("u", modifierFlags: [])
        XCTAssertTrue(waitForHotkeyBezel("Units: mm"))

        app.typeKey("u", modifierFlags: [])
        XCTAssertTrue(waitForHotkeyBezel("Units: in"))

        app.typeKey("u", modifierFlags: [])
        XCTAssertTrue(waitForHotkeyBezel("Units: px"))
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

    func testHorizontalRulerCursorForMouseoverMousedownAndMouseoutActions() {
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 3))

        isolateHorizontalRulerByUngroupingWithVerticalToggle()

        assertCursorSequence(on: horizontalRuler, label: "ungrouped horizontal ruler")
    }

    func testVerticalRulerCursorForMouseoverMousedownAndMouseoutActions() {
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 3))

        isolateHorizontalRulerByUngroupingWithVerticalToggle()

        app.typeKey("h", modifierFlags: [])
        XCTAssertTrue(horizontalRuler.waitForNonExistence(timeout: 2))
        app.typeKey("v", modifierFlags: [])
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 2))

        assertCursorSequence(on: verticalRuler, label: "ungrouped vertical ruler")
    }

    func testGroupedRulerCursorsForKeyAndChildWindows() {
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 3))

        setGroupRulers(true)
        XCTAssertTrue(groupRulersEnabledInPreferences())
        closePreferences()

        horizontalRuler.click()
        assertCursorSequence(on: horizontalRulerView, label: "grouped key horizontal ruler")
        assertCursorSequence(on: verticalRulerView, label: "grouped child vertical ruler")

        verticalRuler.click()
        assertCursorSequence(on: verticalRulerView, label: "grouped key vertical ruler")
        assertCursorSequence(on: horizontalRulerView, label: "grouped child horizontal ruler")
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

    private var verticalRulerView: XCUIElement {
        app.otherElements["vertical-ruler-view"]
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

    private var rulerColorWell: XCUIElement {
        app.colorWells["ruler-color-well"]
    }

    private var colorPanel: XCUIElement {
        app.windows["Colors"]
    }

    private var hotkeyBezelLabel: XCUIElement {
        app.staticTexts["hotkey-bezel-label"]
    }

    private var hotkeyBezel: XCUIElement {
        app.otherElements["hotkey-bezel"]
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

    private func openRulerColorPanel() {
        openPreferences()

        rulerColorWell.click()
        if !colorPanel.waitForExistence(timeout: 1) {
            rulerColorWell.click()
        }

        XCTAssertTrue(colorPanel.waitForExistence(timeout: 3))
    }

    private func setGroupRulers(_ enabled: Bool) {
        openPreferences()

        if groupRulersCheckbox.isChecked != enabled {
            groupRulersCheckbox.click()
        }
    }

    private func groupRulersEnabledInPreferences() -> Bool {
        openPreferences()
        return groupRulersCheckbox.isChecked
    }

    private func floatRulersEnabledInPreferences() -> Bool {
        openPreferences()
        return floatRulersCheckbox.isChecked
    }

    private func rulerShadowEnabledInPreferences() -> Bool {
        openPreferences()
        return rulerShadowCheckbox.isChecked
    }

    private func isolateHorizontalRulerByUngroupingWithVerticalToggle() {
        horizontalRuler.click()
        app.typeKey("v", modifierFlags: [])

        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 2))
        XCTAssertTrue(verticalRuler.waitForNonExistence(timeout: 2))
        XCTAssertFalse(groupRulersEnabledInPreferences())
        closePreferences()
    }

    private func assertCursorSequence(on ruler: XCUIElement, label: String) {
        hover(over: ruler)
        assertCursor("open-hand", after: "mouseover \(label)")

        pressAndRelease(in: ruler, assertingCursorDuringPress: "closed-hand")
        assertCursor("open-hand", after: "mousedown and mouseup inside \(label)")

        hover(over: pointOutside(ruler))
        assertCursor("crosshair", after: "mouseout \(label)")

        hover(over: ruler)
        assertCursor("open-hand", after: "mouseover \(label) again")

        pressAndRelease(in: ruler, assertingCursorDuringPress: "closed-hand")
        assertCursor("open-hand", after: "mousedown and mouseup inside \(label) again")

        hover(over: pointOutside(ruler))
        assertCursor("crosshair", after: "mouseout \(label) again")
    }

    private func waitForHotkeyBezel(_ expectedLabel: String, timeout: TimeInterval = 2) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if hotkeyBezel.exists && hotkeyBezel.value as? String == expectedLabel {
                return true
            }

            if hotkeyBezelLabel.exists && hotkeyBezelLabel.label == expectedLabel {
                return true
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }

        return (hotkeyBezel.exists && hotkeyBezel.value as? String == expectedLabel)
            || (hotkeyBezelLabel.exists && hotkeyBezelLabel.label == expectedLabel)
    }

    private func hover(over element: XCUIElement) {
        hover(over: interactionPoint(in: element))
    }

    private func hover(over coordinate: XCUICoordinate) {
        coordinate.hover()
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    private func pressAndRelease(in element: XCUIElement, assertingCursorDuringPress expectedCursor: String) {
        let expectation = expectationForCursor(expectedCursor, after: "mousedown inside \(element.identifier)")
        let coordinate = interactionPoint(in: element)
        coordinate.press(forDuration: 0.4)
        wait(for: [expectation], timeout: 1)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    private func pointOutside(_ element: XCUIElement) -> XCUICoordinate {
        let yOffset = isVerticalRulerElement(element) ? 0.75 : 1.5
        return element.coordinate(withNormalizedOffset: CGVector(dx: 1.5, dy: yOffset))
    }

    private func interactionPoint(in element: XCUIElement) -> XCUICoordinate {
        let yOffset = isVerticalRulerElement(element) ? 0.75 : 0.5
        return element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: yOffset))
    }

    private func isVerticalRulerElement(_ element: XCUIElement) -> Bool {
        return element.identifier.contains("vertical-ruler")
    }

    private func expectationForCursor(_ expectedCursor: String, after action: String) -> XCTestExpectation {
        let expectation = expectation(description: "Expected cursor \(expectedCursor) after \(action)")

        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.15) { [cursorStateURL] in
            guard let cursorStateURL = cursorStateURL else { return }

            let deadline = Date().addingTimeInterval(1.5)

            while Date() < deadline {
                let cursor = try? String(contentsOf: cursorStateURL, encoding: .utf8)

                if cursor == expectedCursor {
                    expectation.fulfill()
                    return
                }

                Thread.sleep(forTimeInterval: 0.025)
            }
        }

        return expectation
    }

    private func assertCursor(
        _ expectedCursor: String,
        after action: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            waitForCursor(expectedCursor, timeout: 2),
            "Expected cursor \(expectedCursor) after \(action); actual cursor was \(readCursorState() ?? "nil")",
            file: file,
            line: line
        )
    }

    private func waitForCursor(_ expectedCursor: String, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if readCursorState() == expectedCursor {
                return true
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }

        return readCursorState() == expectedCursor
    }

    private func readCursorState() -> String? {
        return try? String(contentsOf: cursorStateURL, encoding: .utf8)
    }

    private func currentUserHomeDirectory() -> String {
        guard let passwd = getpwuid(getuid()) else {
            return NSHomeDirectory()
        }

        return String(cString: passwd.pointee.pw_dir)
    }
}

private extension XCUIElement {
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    func waitForNonVisibility(timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if !exists || !isHittable {
                return true
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }

        return !exists || !isHittable
    }

    func waitForVisibleExistence(timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if exists && isHittable {
                return true
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }

        return exists && isHittable
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
