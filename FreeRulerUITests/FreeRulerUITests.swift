import XCTest

final class FreeRulerUITests: XCTestCase {

    private let opaqueColorPanelValue = "ruler-color-panel-alpha-hidden"

    private var app: XCUIApplication!
    private var uiTestSupport: UITestSupport!

    override func setUpWithError() throws {
        continueAfterFailure = false

        uiTestSupport = UITestSupport.prepareForLaunch()
        uiTestSupport.resetStateFiles()

        app = XCUIApplication()
        app.launchEnvironment.merge(uiTestSupport.launchEnvironment) { _, newValue in newValue }
        app.launch()
        app.activate()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
        uiTestSupport.removeStateFiles()
        uiTestSupport = nil
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
        XCTAssertTrue(waitForPreference("groupRulers", equals: true))

        horizontalRuler.click()
        app.typeKey("v", modifierFlags: [])

        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 2))
        XCTAssertTrue(verticalRuler.waitForNonExistence(timeout: 2))
        XCTAssertTrue(waitForPreference("groupRulers", equals: false))
    }

    func testGroupRulersKeyboardCommandUngroupsOnFirstAttempt() {
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(waitForPreference("groupRulers", equals: true))

        horizontalRuler.click()
        app.typeKey("g", modifierFlags: [])
        XCTAssertTrue(waitForPreference("groupRulers", equals: false))

        app.typeKey("g", modifierFlags: [])
        XCTAssertTrue(waitForPreference("groupRulers", equals: true))

        verticalRuler.click()
        app.typeKey("g", modifierFlags: [])
        XCTAssertTrue(waitForPreference("groupRulers", equals: false))
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
            colorPanel.waitForVisibleFrame(timeout: 1),
            "The ruler color panel should be visible."
        )
        XCTAssertEqual(
            colorPanel.value as? String,
            opaqueColorPanelValue,
            "The ruler color panel should be configured for opaque color picking."
        )
        XCTAssertEqual(
            visibleSliderCount(in: colorPanel),
            1,
            "The ruler color panel should show the color slider, but not an opacity slider."
        )
    }

    func testClosingPreferencesClosesRulerColorPanel() {
        openRulerColorPanel()

        preferencesWindow.click()
        app.typeKey("w", modifierFlags: .command)

        XCTAssertTrue(preferencesWindow.waitForNonExistence(timeout: 2))
        XCTAssertTrue(colorPanel.waitForNonExistence(timeout: 2))
    }

    func testRulerColorPanelDoesNotReopenAfterRelaunch() {
        openRulerColorPanel()

        app.terminate()
        app.launch()
        app.activate()

        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 3))
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
        XCTAssertTrue(waitForPreference("floatRulers", equals: true))
        XCTAssertTrue(waitForPreference("rulerShadow", equals: false))

        horizontalRuler.click()
        app.typeKey("f", modifierFlags: [])
        XCTAssertTrue(waitForPreference("floatRulers", equals: false))

        app.typeKey("f", modifierFlags: [])
        XCTAssertTrue(waitForPreference("floatRulers", equals: true))

        app.typeKey("s", modifierFlags: [])
        XCTAssertTrue(waitForPreference("rulerShadow", equals: true))

        app.typeKey("s", modifierFlags: [])
        XCTAssertTrue(waitForPreference("rulerShadow", equals: false))

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
        XCTAssertTrue(waitForPreference("groupRulers", equals: true))

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

    private var rulerColorWell: XCUIElement {
        app.colorWells["ruler-color-well"]
    }

    private var colorPanel: XCUIElement {
        app.windows["ruler-color-panel"]
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

    private func openRulerColorPanel() {
        openPreferences()

        if colorPanel.exists {
            colorPanel.click()
            app.typeKey("w", modifierFlags: .command)
            XCTAssertTrue(colorPanel.waitForNonExistence(timeout: 2))
        }

        rulerColorWell.click()
        XCTAssertTrue(colorPanel.waitForExistence(timeout: 3))
    }

    private func isolateHorizontalRulerByUngroupingWithVerticalToggle() {
        horizontalRuler.click()
        app.typeKey("v", modifierFlags: [])

        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 2))
        XCTAssertTrue(verticalRuler.waitForNonExistence(timeout: 2))
        XCTAssertTrue(waitForPreference("groupRulers", equals: false))
    }

    private func assertCursorSequence(on ruler: XCUIElement, label: String) {
        hover(over: ruler)
        assertCursor("open-hand", after: "mouseover \(label)")

        pressAndRelease(in: ruler, assertingCursorDuringPress: "closed-hand")
        assertCursor("open-hand", after: "mousedown and mouseup inside \(label)")

        hover(over: pointOutside(ruler))
        assertCursor("crosshair", after: "mouseout \(label)")
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
        let cursorStateURL = uiTestSupport.cursorStateURL

        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.15) {
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
        return try? String(contentsOf: uiTestSupport.cursorStateURL, encoding: .utf8)
    }

    private func waitForPreference(
        _ key: String,
        equals expectedValue: Bool,
        timeout: TimeInterval = 2
    ) -> Bool {
        return waitForPreference(
            key,
            equals: expectedValue ? "true" : "false",
            timeout: timeout
        )
    }

    private func waitForPreference(
        _ key: String,
        equals expectedValue: String,
        timeout: TimeInterval = 2
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if readPreferenceState()[key] == expectedValue {
                return true
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }

        return readPreferenceState()[key] == expectedValue
    }

    private func readPreferenceState() -> [String: String] {
        guard let data = try? Data(contentsOf: uiTestSupport.preferencesStateURL),
              let state = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return [:]
        }

        return state
    }

    private func visibleSliderCount(in element: XCUIElement) -> Int {
        return element.sliders.allElementsBoundByIndex.filter(\.hasVisibleFrame).count
    }
}

private extension XCUIElement {
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    func waitForVisibleFrame(timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if hasVisibleFrame {
                return true
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }

        return hasVisibleFrame
    }

    var hasVisibleFrame: Bool {
        return exists && !frame.isEmpty && !frame.isNull
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
}
