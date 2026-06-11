import AppKit
import XCTest
@testable import Free_Ruler

final class RulerCoreTests: XCTestCase {

    func testWindowAlphaValueConvertsPercentToAlpha() {
        XCTAssertEqual(windowAlphaValue(0), 0.0)
        XCTAssertEqual(windowAlphaValue(50), 0.5)
        XCTAssertEqual(windowAlphaValue(100), 1.0)
    }

    func testRulerStoresOrientationFrameAndAutosaveName() {
        let frame = NSRect(x: 10, y: 20, width: 300, height: 40)
        let ruler = Ruler(.horizontal, frame: frame, name: "test-ruler")

        XCTAssertEqual(ruler.orientation, .horizontal)
        XCTAssertEqual(ruler.frame, frame)
        XCTAssertEqual(ruler.name, "test-ruler")
    }

    func testMinAndMaxSizesMatchRulerOrientation() {
        let horizontal = Ruler(.horizontal, frame: NSRect(x: 0, y: 0, width: 300, height: 40))
        let vertical = Ruler(.vertical, frame: NSRect(x: 0, y: 0, width: 40, height: 300))

        XCTAssertEqual(getMinSize(ruler: horizontal), NSSize(width: 200, height: 40))
        XCTAssertEqual(getMaxSize(ruler: horizontal), NSSize(width: 4000, height: 40))
        XCTAssertEqual(getMinSize(ruler: vertical), NSSize(width: 40, height: 200))
        XCTAssertEqual(getMaxSize(ruler: vertical), NSSize(width: 40, height: 4000))
    }

    func testRulerTickLayoutMatchesUnitScales() {
        let pixels = RulerTickLayout(unit: .pixels, dpi: 144, dpmm: 4)
        XCTAssertEqual(pixels.tickScale, 1)
        XCTAssertEqual(pixels.textScale, 1)
        XCTAssertEqual(pixels.largeTicks, 50)
        XCTAssertEqual(pixels.mediumTicks, 10)
        XCTAssertEqual(pixels.smallTicks, 2)
        XCTAssertNil(pixels.tinyTicks)

        let millimeters = RulerTickLayout(unit: .millimeters, dpi: 144, dpmm: 4)
        XCTAssertEqual(millimeters.tickScale, 4)
        XCTAssertEqual(millimeters.textScale, 1)
        XCTAssertEqual(millimeters.largeTicks, 10)
        XCTAssertEqual(millimeters.mediumTicks, 5)
        XCTAssertEqual(millimeters.smallTicks, 1)
        XCTAssertNil(millimeters.tinyTicks)

        let inches = RulerTickLayout(unit: .inches, dpi: 144, dpmm: 4)
        XCTAssertEqual(inches.tickScale, 9)
        XCTAssertEqual(inches.textScale, 16)
        XCTAssertEqual(inches.largeTicks, 16)
        XCTAssertEqual(inches.mediumTicks, 8)
        XCTAssertEqual(inches.smallTicks, 4)
        XCTAssertEqual(inches.tinyTicks, 1)
    }

    func testDefaultRulerRectsUseExpectedShapeAndOffsets() {
        let screen = NSScreen.main?.frame
        let screenWidth = screen?.width ?? 1000
        let screenHeight = screen?.height ?? 800
        let horizontalLength = screenWidth / 2
        let verticalLength = horizontalLength / (screenWidth / screenHeight)

        let horizontal = getDefaultContentRect(orientation: .horizontal)
        let vertical = getDefaultContentRect(orientation: .vertical)

        XCTAssertEqual(horizontal.height, Ruler.thickness)
        XCTAssertEqual(vertical.width, Ruler.thickness)
        XCTAssertEqual(horizontal.width, horizontalLength, accuracy: 0.0001)
        XCTAssertEqual(vertical.height, verticalLength, accuracy: 0.0001)
        XCTAssertEqual(horizontal.minX, 69.0, accuracy: 0.0001)
        XCTAssertEqual(vertical.minX, 30.0, accuracy: 0.0001)
        XCTAssertEqual(horizontal.minY, screenHeight - 90.0, accuracy: 0.0001)
        XCTAssertEqual(vertical.maxY, horizontal.minY + 1.0, accuracy: 0.0001)
    }

    func testRulerCursorControllerChoosesCursorForActiveRulerEvents() {
        var appliedCursors: [RulerCursorController.CursorStyle] = []
        let controller = RulerCursorController { appliedCursors.append($0) }

        controller.applicationDidBecomeActive()
        controller.mouseEnteredRuler()
        controller.mouseDownInRuler()
        controller.mouseUpInRuler(mouseIsInsideRuler: true)
        controller.mouseExitedRuler()

        XCTAssertEqual(appliedCursors, [
            .crosshair,
            .openHand,
            .closedHand,
            .openHand,
            .crosshair,
        ])
    }

    func testRulerCursorControllerReturnsToCrosshairWhenDragEndsOutsideRuler() {
        var appliedCursors: [RulerCursorController.CursorStyle] = []
        let controller = RulerCursorController { appliedCursors.append($0) }

        controller.applicationDidBecomeActive()
        controller.mouseEnteredRuler()
        controller.mouseDownInRuler()
        controller.mouseExitedRuler()
        controller.mouseUpInRuler(mouseIsInsideRuler: false)

        XCTAssertEqual(appliedCursors, [
            .crosshair,
            .openHand,
            .closedHand,
            .crosshair,
        ])
    }

    func testRulerCursorControllerResetsWhenAppResignsActive() {
        var appliedCursors: [RulerCursorController.CursorStyle] = []
        let controller = RulerCursorController { appliedCursors.append($0) }

        controller.applicationDidBecomeActive()
        controller.mouseEnteredRuler()
        controller.mouseDownInRuler()
        controller.applicationDidResignActive()
        controller.applicationDidBecomeActive()

        XCTAssertEqual(appliedCursors, [
            .crosshair,
            .openHand,
            .closedHand,
            .arrow,
            .crosshair,
        ])
    }

    func testRulerCursorControllerTracksMouseOverMouseDownAndMouseOutActions() {
        var appliedCursors: [RulerCursorController.CursorStyle] = []
        let controller = RulerCursorController { appliedCursors.append($0) }

        func assertCursor(
            after actionName: String,
            _ action: () -> Void,
            is expectedCursor: RulerCursorController.CursorStyle,
            file: StaticString = #filePath,
            line: UInt = #line
        ) {
            action()
            XCTAssertEqual(controller.currentCursor, expectedCursor, actionName, file: file, line: line)
            XCTAssertEqual(appliedCursors.last, expectedCursor, actionName, file: file, line: line)
        }

        controller.applicationDidBecomeActive()
        XCTAssertEqual(controller.currentCursor, .crosshair)

        assertCursor(after: "mouse over ruler", {
            controller.mouseEnteredRuler()
        }, is: .openHand)

        assertCursor(after: "mouse down inside ruler", {
            controller.mouseDownInRuler()
        }, is: .closedHand)

        let appliedCursorCountBeforeMouseOut = appliedCursors.count
        controller.mouseExitedRuler()
        XCTAssertEqual(controller.currentCursor, .closedHand, "mouse out while dragging")
        XCTAssertEqual(appliedCursors.count, appliedCursorCountBeforeMouseOut, "mouse out while dragging")

        assertCursor(after: "mouse up outside ruler", {
            controller.mouseUpInRuler(mouseIsInsideRuler: false)
        }, is: .crosshair)

        assertCursor(after: "mouse over ruler again", {
            controller.mouseEnteredRuler()
        }, is: .openHand)

        assertCursor(after: "mouse down inside ruler again", {
            controller.mouseDownInRuler()
        }, is: .closedHand)

        assertCursor(after: "mouse up inside ruler", {
            controller.mouseUpInRuler(mouseIsInsideRuler: true)
        }, is: .openHand)

        assertCursor(after: "mouse out after release", {
            controller.mouseExitedRuler()
        }, is: .crosshair)
    }

    func testMouseTickTimerPolicyRunsOnlyWhenRulersAreVisible() {
        let policy = MouseTickTimerPolicy(foregroundInterval: 1 / 60, backgroundInterval: 1 / 30)

        policy.applicationDidBecomeActive()
        XCTAssertNil(policy.desiredInterval)

        policy.updateVisibleRulers(true)
        XCTAssertEqual(policy.desiredInterval, 1 / 60)

        policy.applicationDidResignActive()
        XCTAssertEqual(policy.desiredInterval, 1 / 30)

        policy.updateVisibleRulers(false)
        XCTAssertNil(policy.desiredInterval)
    }

    func testMouseTickTimerPolicySuspendsUntilAllOwnersResume() {
        let policy = MouseTickTimerPolicy(foregroundInterval: 1 / 60, backgroundInterval: 1 / 30)
        let firstOwner = NSObject()
        let secondOwner = NSObject()

        policy.applicationDidBecomeActive()
        policy.updateVisibleRulers(true)

        policy.suspend(owner: firstOwner)
        policy.suspend(owner: secondOwner)
        XCTAssertNil(policy.desiredInterval)

        policy.resume(owner: firstOwner)
        XCTAssertNil(policy.desiredInterval)

        policy.resume(owner: secondOwner)
        XCTAssertEqual(policy.desiredInterval, 1 / 60)
    }

    func testMouseTickTimerPolicyKeepsSuspensionAcrossVisibilityChanges() {
        let policy = MouseTickTimerPolicy(foregroundInterval: 1 / 60, backgroundInterval: 1 / 30)
        let owner = NSObject()

        policy.applicationDidBecomeActive()
        policy.updateVisibleRulers(true)
        policy.suspend(owner: owner)

        policy.updateVisibleRulers(false)
        XCTAssertNil(policy.desiredInterval)

        policy.updateVisibleRulers(true)
        XCTAssertNil(policy.desiredInterval)

        policy.resume(owner: owner)
        XCTAssertEqual(policy.desiredInterval, 1 / 60)
    }

    func testMouseTickTimerPolicyClearsSuspensionWhenOwnerDeallocates() {
        let policy = MouseTickTimerPolicy(foregroundInterval: 1 / 60, backgroundInterval: 1 / 30)

        policy.applicationDidBecomeActive()
        policy.updateVisibleRulers(true)

        autoreleasepool {
            let owner = NSObject()
            policy.suspend(owner: owner)
            XCTAssertNil(policy.desiredInterval)
        }

        XCTAssertEqual(policy.desiredInterval, 1 / 60)
    }

    func testHorizontalResizeHandleFrameMathResizesOnlyWidthFromRightEdge() {
        let initialFrame = NSRect(x: 10, y: 20, width: 300, height: Ruler.thickness)
        let frame = resizedRulerFrame(
            orientation: .horizontal,
            initialFrame: initialFrame,
            delta: NSSize(width: 50, height: 25),
            minSize: NSSize(width: 200, height: Ruler.thickness),
            maxSize: NSSize(width: 4000, height: Ruler.thickness)
        )

        XCTAssertEqual(frame, NSRect(x: 10, y: 20, width: 350, height: Ruler.thickness))
    }

    func testHorizontalResizeHandleFrameMathClampsWidth() {
        let initialFrame = NSRect(x: 10, y: 20, width: 300, height: Ruler.thickness)
        let frame = resizedRulerFrame(
            orientation: .horizontal,
            initialFrame: initialFrame,
            delta: NSSize(width: -250, height: 0),
            minSize: NSSize(width: 200, height: Ruler.thickness),
            maxSize: NSSize(width: 4000, height: Ruler.thickness)
        )

        XCTAssertEqual(frame, NSRect(x: 10, y: 20, width: 200, height: Ruler.thickness))
    }

    func testVerticalResizeHandleFrameMathResizesOnlyHeightFromBottomEdge() {
        let initialFrame = NSRect(x: 10, y: 20, width: Ruler.thickness, height: 300)
        let frame = resizedRulerFrame(
            orientation: .vertical,
            initialFrame: initialFrame,
            delta: NSSize(width: 25, height: -50),
            minSize: NSSize(width: Ruler.thickness, height: 200),
            maxSize: NSSize(width: Ruler.thickness, height: 4000)
        )

        XCTAssertEqual(frame, NSRect(x: 10, y: -30, width: Ruler.thickness, height: 350))
        XCTAssertEqual(frame.maxY, initialFrame.maxY)
    }

    func testVerticalResizeHandleFrameMathClampsHeightWhileKeepingTopEdgeFixed() {
        let initialFrame = NSRect(x: 10, y: 20, width: Ruler.thickness, height: 300)
        let frame = resizedRulerFrame(
            orientation: .vertical,
            initialFrame: initialFrame,
            delta: NSSize(width: 0, height: 250),
            minSize: NSSize(width: Ruler.thickness, height: 200),
            maxSize: NSSize(width: Ruler.thickness, height: 4000)
        )

        XCTAssertEqual(frame, NSRect(x: 10, y: 120, width: Ruler.thickness, height: 200))
        XCTAssertEqual(frame.maxY, initialFrame.maxY)
    }

    func testResizeHandleCursorsUseCustomCenteredImages() {
        let horizontalCursor = windowResizeCursor(for: .horizontal)
        let verticalCursor = windowResizeCursor(for: .vertical)

        XCTAssertEqual(horizontalCursor.image.size, NSSize(width: 21, height: 15))
        XCTAssertEqual(verticalCursor.image.size, NSSize(width: 15, height: 21))
        XCTAssertEqual(horizontalCursor.hotSpot, NSPoint(x: 10, y: 7))
        XCTAssertEqual(verticalCursor.hotSpot, NSPoint(x: 7, y: 10))
        XCTAssertFalse(horizontalCursor.image.isTemplate)
        XCTAssertFalse(verticalCursor.image.isTemplate)
    }

    func testResizeHandleDisablesWindowBackgroundDraggingDuringResizeDrag() {
        let ruler = Ruler(.horizontal, frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))
        let window = RulerWindow(ruler)
        guard let resizeHandle = window.rule.subviews.first(where: { $0 is ResizeHandleView }) as? ResizeHandleView else {
            return XCTFail("Expected horizontal ruler to install a resize handle")
        }

        XCTAssertTrue(window.isMovableByWindowBackground)

        let mouseDownEvent = NSEvent.mouseEvent(
            with: .leftMouseDown,
            location: resizeHandle.convert(NSPoint(x: 1, y: 1), to: nil),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: window.windowNumber,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 1
        )!
        let mouseUpEvent = NSEvent.mouseEvent(
            with: .leftMouseUp,
            location: resizeHandle.convert(NSPoint(x: 1, y: 1), to: nil),
            modifierFlags: [],
            timestamp: 0.1,
            windowNumber: window.windowNumber,
            context: nil,
            eventNumber: 1,
            clickCount: 1,
            pressure: 0
        )!

        resizeHandle.mouseDown(with: mouseDownEvent)
        XCTAssertFalse(window.isMovableByWindowBackground)

        resizeHandle.mouseUp(with: mouseUpEvent)
        XCTAssertTrue(window.isMovableByWindowBackground)
    }

    func testResizeHandleDetachesChildWindowsAttachedWhileBecomingKey() {
        let childWindow = RulerWindow(
            Ruler(.vertical, frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))
        )
        let window = ChildAttachingRulerWindow(
            ruler: Ruler(.horizontal, frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness)),
            childWindow: childWindow
        )
        guard let resizeHandle = window.rule.subviews.first(where: { $0 is ResizeHandleView }) as? ResizeHandleView else {
            return XCTFail("Expected horizontal ruler to install a resize handle")
        }
        let location = resizeHandle.convert(NSPoint(x: 1, y: 1), to: nil)

        resizeHandle.mouseDown(with: mouseEvent(
            type: .leftMouseDown,
            location: location,
            windowNumber: window.windowNumber,
            timestamp: 0
        ))

        XCTAssertFalse(window.childWindows?.contains(childWindow) ?? false)

        resizeHandle.mouseUp(with: mouseEvent(
            type: .leftMouseUp,
            location: location,
            windowNumber: window.windowNumber,
            timestamp: 0.1
        ))

        XCTAssertTrue(window.childWindows?.contains(childWindow) ?? false)
    }

    func testHorizontalResizeHandleDragKeepsLeftAndTopEdgesFixed() {
        let initialFrame = NSRect(x: 100, y: 200, width: 300, height: Ruler.thickness)
        let ruler = Ruler(.horizontal, frame: initialFrame)
        let window = RulerWindow(ruler)
        guard let resizeHandle = window.rule.subviews.first(where: { $0 is ResizeHandleView }) as? ResizeHandleView else {
            return XCTFail("Expected horizontal ruler to install a resize handle")
        }

        let startLocation = resizeHandle.convert(
            NSPoint(x: resizeHandle.bounds.minX + 1, y: resizeHandle.bounds.midY),
            to: nil
        )
        let mouseDownEvent = mouseEvent(
            type: .leftMouseDown,
            location: startLocation,
            windowNumber: window.windowNumber,
            timestamp: 0
        )

        resizeHandle.mouseDown(with: mouseDownEvent)

        let dragOffsets = [
            NSSize(width: -40, height: 0),
            NSSize(width: 80, height: 0),
            NSSize(width: 0, height: 30),
            NSSize(width: 0, height: -30),
        ]

        for (index, offset) in dragOffsets.enumerated() {
            let dragEvent = mouseEvent(
                type: .leftMouseDragged,
                location: NSPoint(x: startLocation.x + offset.width, y: startLocation.y + offset.height),
                windowNumber: window.windowNumber,
                timestamp: TimeInterval(index + 1) * 0.1
            )

            resizeHandle.mouseDragged(with: dragEvent)

            XCTAssertEqual(window.frame.minX, initialFrame.minX, "left edge moved for drag offset \(offset)")
            XCTAssertEqual(window.frame.maxY, initialFrame.maxY, "top edge moved for drag offset \(offset)")
        }

        let mouseUpEvent = mouseEvent(
            type: .leftMouseUp,
            location: startLocation,
            windowNumber: window.windowNumber,
            timestamp: 1
        )
        resizeHandle.mouseUp(with: mouseUpEvent)
    }

    func testRulerControllerKeepsMouseTicksHiddenWhileDragging() {
        let ruler = Ruler(.horizontal, frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))
        let controller = RulerController(ruler: ruler)
        let mouseDownEvent = NSEvent.mouseEvent(
            with: .leftMouseDown,
            location: NSPoint(x: 10, y: 10),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: controller.rulerWindow.windowNumber,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 1
        )!
        let mouseUpEvent = NSEvent.mouseEvent(
            with: .leftMouseUp,
            location: NSPoint(x: 10, y: 10),
            modifierFlags: [],
            timestamp: 0.1,
            windowNumber: controller.rulerWindow.windowNumber,
            context: nil,
            eventNumber: 1,
            clickCount: 1,
            pressure: 0
        )!

        controller.mouseDown(with: mouseDownEvent)
        controller.windowDidMove(Notification(name: NSWindow.didMoveNotification, object: controller.rulerWindow))
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))

        XCTAssertFalse(controller.rulerWindow.rule.showMouseTick)

        controller.mouseUp(with: mouseUpEvent)
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))

        XCTAssertTrue(controller.rulerWindow.rule.showMouseTick)
    }

    func testRulerControllerResumesMouseTicksWhenWindowDragLoopEnds() {
        let ruler = Ruler(.horizontal, frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))
        let controller = RulerController(ruler: ruler)
        let otherWindow = RulerWindow(Ruler(.vertical, frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300)))
        controller.otherWindow = otherWindow
        let mouseDownEvent = NSEvent.mouseEvent(
            with: .leftMouseDown,
            location: NSPoint(x: 10, y: 10),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: controller.rulerWindow.windowNumber,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 1
        )!

        controller.mouseDown(with: mouseDownEvent)
        controller.windowDidMove(Notification(name: NSWindow.didMoveNotification, object: controller.rulerWindow))
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))

        XCTAssertFalse(controller.rulerWindow.rule.showMouseTick)
        XCTAssertFalse(otherWindow.rule.showMouseTick)

        controller.finishMouseDrag(with: mouseDownEvent)
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))

        XCTAssertTrue(controller.rulerWindow.rule.showMouseTick)
        XCTAssertTrue(otherWindow.rule.showMouseTick)
    }

    func testGroupedChildMoveDoesNotResumeMouseTicksDuringDrag() {
        let draggedController = RulerController(
            ruler: Ruler(.horizontal, frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))
        )
        let groupedChildController = RulerController(
            ruler: Ruler(.vertical, frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))
        )
        draggedController.otherWindow = groupedChildController.rulerWindow
        groupedChildController.otherWindow = draggedController.rulerWindow
        groupedChildController.isLeftMouseButtonPressed = { true }
        let mouseDownEvent = NSEvent.mouseEvent(
            with: .leftMouseDown,
            location: NSPoint(x: 10, y: 10),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: draggedController.rulerWindow.windowNumber,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 1
        )!

        draggedController.mouseDown(with: mouseDownEvent)
        groupedChildController.windowDidMove(
            Notification(name: NSWindow.didMoveNotification, object: groupedChildController.rulerWindow)
        )
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))

        XCTAssertFalse(draggedController.rulerWindow.rule.showMouseTick)
        XCTAssertFalse(groupedChildController.rulerWindow.rule.showMouseTick)
    }

    private func mouseEvent(
        type: NSEvent.EventType,
        location: NSPoint,
        windowNumber: Int,
        timestamp: TimeInterval
    ) -> NSEvent {
        return NSEvent.mouseEvent(
            with: type,
            location: location,
            modifierFlags: [],
            timestamp: timestamp,
            windowNumber: windowNumber,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: type == .leftMouseUp ? 0 : 1
        )!
    }
}

private final class ChildAttachingRulerWindow: RulerWindow {
    private let childWindowToAttach: NSWindow

    init(ruler: Ruler, childWindow: NSWindow) {
        self.childWindowToAttach = childWindow
        super.init(ruler: ruler)
    }

    override func makeKey() {
        super.makeKey()
        addChildWindow(childWindowToAttach, ordered: .below)
    }
}
