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
        XCTAssertTrue(rulerWindow.waitForExistence(timeout: 3))
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 3))

        horizontalRuler.click()
        app.typeKey("h", modifierFlags: [])
        XCTAssertTrue(horizontalRuler.waitForNonExistence(timeout: 2))
        XCTAssertTrue(verticalRuler.exists)
        XCTAssertTrue(rulerWindow.exists)

        app.typeKey("h", modifierFlags: [])
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 2))

        verticalRuler.click()
        app.typeKey("v", modifierFlags: [])
        XCTAssertTrue(verticalRuler.waitForNonExistence(timeout: 2))
        XCTAssertTrue(horizontalRuler.exists)
        XCTAssertTrue(rulerWindow.exists)

        app.typeKey("v", modifierFlags: [])
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 2))
    }

    func testRulerWindowToggleHidesRequestedWingWithoutChangingGroupedDragging() {
        XCTAssertTrue(rulerWindow.waitForExistence(timeout: 3))
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(waitForPreference("groupRulers", equals: true))

        horizontalRuler.click()
        app.typeKey("v", modifierFlags: [])

        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 2))
        XCTAssertTrue(verticalRuler.waitForNonExistence(timeout: 2))
        XCTAssertTrue(rulerWindow.exists)
        assertFrame(
            rulerWindow.frame,
            matches: horizontalRuler.frame,
            message: "Ruler window should shrink to the visible horizontal ruler frame"
        )
        XCTAssertTrue(waitForPreference("groupRulers", equals: true))

        app.typeKey("v", modifierFlags: [])
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 2))

        verticalRuler.click()
        app.typeKey("h", modifierFlags: [])

        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 2))
        XCTAssertTrue(horizontalRuler.waitForNonExistence(timeout: 2))
        XCTAssertTrue(rulerWindow.exists)
        assertFrame(
            rulerWindow.frame,
            matches: verticalRuler.frame,
            message: "Ruler window should shrink to the visible vertical ruler frame"
        )
        XCTAssertTrue(waitForPreference("groupRulers", equals: true))
    }

    func testGroupRulersKeyboardCommandTogglesGroupedDraggingWithoutChangingRulerWindow() {
        XCTAssertTrue(rulerWindow.waitForExistence(timeout: 3))
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(waitForPreference("groupRulers", equals: true))

        let originalFrame = rulerWindow.frame

        horizontalRuler.click()
        app.typeKey("g", modifierFlags: [])
        XCTAssertTrue(waitForPreference("groupRulers", equals: false))
        XCTAssertTrue(rulerWindow.waitForExistence(timeout: 2))
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 2))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 2))
        assertFrame(
            rulerWindow.frame,
            matches: originalFrame,
            message: "Toggling grouped dragging should not replace or resize the ruler window"
        )

        app.typeKey("g", modifierFlags: [])
        XCTAssertTrue(waitForPreference("groupRulers", equals: true))
        XCTAssertTrue(rulerWindow.waitForExistence(timeout: 2))
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 2))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 2))

        verticalRuler.click()
        app.typeKey("g", modifierFlags: [])
        XCTAssertTrue(waitForPreference("groupRulers", equals: false))
        XCTAssertTrue(rulerWindow.waitForExistence(timeout: 2))
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 2))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 2))
    }

    func testPreferencesCloseWithCommandW() {
        openPreferencesShortcut()

        XCTAssertTrue(preferencesWindow.waitForExistence(timeout: 3))

        app.typeKey("w", modifierFlags: .command)
        XCTAssertTrue(preferencesWindow.waitForNonExistence(timeout: 2))
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

        XCTAssertTrue(rulerWindow.waitForExistence(timeout: 3))
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(colorPanel.waitForNonExistence(timeout: 2))
    }

    func testRulerCloseWithCommandW() {
        XCTAssertTrue(rulerWindow.waitForExistence(timeout: 3))
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 3))

        rulerWindow.click()
        app.typeKey("w", modifierFlags: .command)

        XCTAssertTrue(rulerWindow.waitForNonExistence(timeout: 2))
        XCTAssertTrue(horizontalRuler.waitForNonExistence(timeout: 2))
        XCTAssertTrue(verticalRuler.waitForNonExistence(timeout: 2))
    }

    func testLastVisibleWingStaysVisibleAndResetRestoresBothWings() {
        XCTAssertTrue(rulerWindow.waitForExistence(timeout: 3))
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 3))

        horizontalRuler.click()
        app.typeKey("h", modifierFlags: [])
        XCTAssertTrue(horizontalRuler.waitForNonExistence(timeout: 2))

        verticalRuler.click()
        app.typeKey("v", modifierFlags: [])
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 2))
        XCTAssertTrue(rulerWindow.waitForExistence(timeout: 2))

        app.typeKey("h", modifierFlags: [])
        XCTAssertTrue(rulerWindow.waitForExistence(timeout: 2))
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 2))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 2))

        horizontalRuler.click()
        app.typeKey("h", modifierFlags: [])
        XCTAssertTrue(horizontalRuler.waitForNonExistence(timeout: 2))

        app.typeKey("r", modifierFlags: .command)
        XCTAssertTrue(rulerWindow.waitForExistence(timeout: 2))
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 2))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 2))
    }

    func testFloatShadowAndUnitKeyboardCommands() {
        XCTAssertTrue(rulerWindow.waitForExistence(timeout: 3))
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(waitForPreference("activeFloatRulers", equals: true))
        XCTAssertTrue(waitForPreference("activeRulerShadow", equals: false))

        horizontalRuler.click()
        app.typeKey("f", modifierFlags: [])
        XCTAssertTrue(waitForPreference("activeFloatRulers", equals: false))

        app.typeKey("f", modifierFlags: [])
        XCTAssertTrue(waitForPreference("activeFloatRulers", equals: true))

        app.typeKey("s", modifierFlags: [])
        XCTAssertTrue(waitForPreference("activeRulerShadow", equals: true))

        app.typeKey("s", modifierFlags: [])
        XCTAssertTrue(waitForPreference("activeRulerShadow", equals: false))

        XCTAssertEqual(horizontalRulerView.value as? String, "px")

        app.typeKey("u", modifierFlags: [])
        XCTAssertTrue(waitForPreference("activeUnit", equals: "mm"))
        XCTAssertEqual(horizontalRulerView.value as? String, "mm")

        app.typeKey("u", modifierFlags: [])
        XCTAssertTrue(waitForPreference("activeUnit", equals: "in"))
        XCTAssertEqual(horizontalRulerView.value as? String, "in")

        app.typeKey("u", modifierFlags: [])
        XCTAssertTrue(waitForPreference("activeUnit", equals: "px"))
        XCTAssertEqual(horizontalRulerView.value as? String, "px")
    }

    func testOptionHotkeysShowStatusBezel() {
        XCTAssertTrue(rulerWindow.waitForExistence(timeout: 3))
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 3))

        horizontalRuler.click()
        app.typeKey("f", modifierFlags: [])
        XCTAssertTrue(waitForHotkeyBezel("Ruler unfloated"))

        app.typeKey("f", modifierFlags: [])
        XCTAssertTrue(waitForHotkeyBezel("Ruler floated"))

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
        XCTAssertTrue(rulerWindow.waitForExistence(timeout: 3))
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 3))

        let originalHorizontalFrame = horizontalRuler.frame
        let originalVerticalFrame = verticalRuler.frame

        verticalRuler.click()
        app.typeKey("o", modifierFlags: [])

        XCTAssertTrue(horizontalRuler.waitForFrameChange(from: originalHorizontalFrame, timeout: 2))
        XCTAssertTrue(verticalRuler.waitForFrameChange(from: originalVerticalFrame, timeout: 2))
    }

    func testRulerCursorsForVisibleWings() {
        XCTAssertTrue(rulerWindow.waitForExistence(timeout: 3))
        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 3))
        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 3))

        XCTContext.runActivity(named: "horizontal-only ruler cursor") { _ in
            resetRulerCursorScenario()
            isolateHorizontalWing()

            assertCursorSequence(on: horizontalRuler, label: "horizontal-only ruler")
        }

        XCTContext.runActivity(named: "vertical-only ruler cursor") { _ in
            resetRulerCursorScenario()
            isolateVerticalWing()

            assertCursorSequence(on: verticalRuler, label: "vertical-only ruler")
        }

        XCTContext.runActivity(named: "both wings visible with horizontal key ruler") { _ in
            resetRulerCursorScenario()

            horizontalRuler.click()
            assertCursorSequence(on: horizontalRulerView, label: "key horizontal ruler")
            assertCursorSequence(on: verticalRulerView, label: "vertical ruler")
        }

        XCTContext.runActivity(named: "both wings visible with vertical key ruler") { _ in
            resetRulerCursorScenario()

            verticalRuler.click()
            assertCursorSequence(on: verticalRulerView, label: "key vertical ruler")
            assertCursorSequence(on: horizontalRulerView, label: "horizontal ruler")
        }
    }

    private var horizontalRuler: XCUIElement {
        horizontalRulerView
    }

    private var verticalRuler: XCUIElement {
        verticalRulerView
    }

    private var rulerWindow: XCUIElement {
        app.dialogs["ruler-window"]
    }

    private var horizontalRulerView: XCUIElement {
        app.otherElements["horizontal-ruler-view"]
    }

    private var verticalRulerView: XCUIElement {
        app.otherElements["vertical-ruler-view"]
    }

    private var preferencesWindow: XCUIElement {
        app.windows["preferences-window"]
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
            openPreferencesShortcut()
            XCTAssertTrue(preferencesWindow.waitForExistence(timeout: 3))
        }
    }

    private func openPreferencesShortcut() {
        app.typeKey(",", modifierFlags: [.command, .option])
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

    private func isolateHorizontalWing() {
        horizontalRuler.click()
        app.typeKey("v", modifierFlags: [])

        XCTAssertTrue(horizontalRuler.waitForExistence(timeout: 2))
        XCTAssertTrue(verticalRuler.waitForNonExistence(timeout: 2))
        XCTAssertTrue(waitForPreference("groupRulers", equals: true))
    }

    private func isolateVerticalWing() {
        verticalRuler.click()
        app.typeKey("h", modifierFlags: [])

        XCTAssertTrue(verticalRuler.waitForExistence(timeout: 2))
        XCTAssertTrue(horizontalRuler.waitForNonExistence(timeout: 2))
        XCTAssertTrue(waitForPreference("groupRulers", equals: true))
    }

    private func resetRulerCursorScenario() {
        app.typeKey("r", modifierFlags: .command)

        XCTAssertTrue(rulerWindow.waitForVisibleFrame(timeout: 1))
        XCTAssertTrue(horizontalRuler.waitForVisibleFrame(timeout: 1))
        XCTAssertTrue(verticalRuler.waitForVisibleFrame(timeout: 1))
        XCTAssertTrue(waitForPreference("groupRulers", equals: true))
    }

    private func assertCursorSequence(on ruler: XCUIElement, label: String) {
        hover(over: ruler)
        assertCursor("open-hand", after: "mouseover \(label)")

        pressAndRelease(in: ruler, assertingCursorDuringPress: "closed-hand")
        assertCursor("open-hand", after: "mousedown and mouseup inside \(label)")

        hover(over: pointOutside(ruler))
        assertCursor("crosshair", after: "mouseout \(label)")
    }

    private func assertFrame(
        _ actual: CGRect,
        matches expected: CGRect,
        accuracy: CGFloat = 1,
        message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(actual.minX, expected.minX, accuracy: accuracy, message, file: file, line: line)
        XCTAssertEqual(actual.minY, expected.minY, accuracy: accuracy, message, file: file, line: line)
        XCTAssertEqual(actual.width, expected.width, accuracy: accuracy, message, file: file, line: line)
        XCTAssertEqual(actual.height, expected.height, accuracy: accuracy, message, file: file, line: line)
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
        coordinate.press(forDuration: 0.2)
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
