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

    func testZeroCornerRawValuesPreservePersistedOrder() {
        XCTAssertEqual(ZeroCorner.topLeft.rawValue, 0)
        XCTAssertEqual(ZeroCorner.topRight.rawValue, 1)
        XCTAssertEqual(ZeroCorner.bottomLeft.rawValue, 2)
        XCTAssertEqual(ZeroCorner.bottomRight.rawValue, 3)
    }

    func testZeroCornerLoadsFromRawValue() {
        XCTAssertEqual(Prefs.zeroCorner(fromRawValue: ZeroCorner.topLeft.rawValue), .topLeft)
        XCTAssertEqual(Prefs.zeroCorner(fromRawValue: ZeroCorner.topRight.rawValue), .topRight)
        XCTAssertEqual(Prefs.zeroCorner(fromRawValue: ZeroCorner.bottomLeft.rawValue), .bottomLeft)
        XCTAssertEqual(Prefs.zeroCorner(fromRawValue: ZeroCorner.bottomRight.rawValue), .bottomRight)
    }

    func testZeroCornerDefaultsToTopLeftForUnknownRawValue() {
        XCTAssertEqual(Prefs.zeroCorner(fromRawValue: -1), .topLeft)
        XCTAssertEqual(Prefs.zeroCorner(fromRawValue: 99), .topLeft)
    }

    func testZeroCornerPreferencePersistsToUserDefaults() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .bottomRight

            XCTAssertEqual(
                UserDefaults.standard.integer(forKey: "zeroCorner"),
                ZeroCorner.bottomRight.rawValue
            )

            prefs.zeroCorner = .topRight

            XCTAssertEqual(
                UserDefaults.standard.integer(forKey: "zeroCorner"),
                ZeroCorner.topRight.rawValue
            )
        }
    }

    func testZeroCornerGeometryDerivesOrientationTraits() {
        let cases: [
            (
                zeroCorner: ZeroCorner,
                horizontalGrowth: RulerGrowthDirection,
                verticalGrowth: RulerGrowthDirection,
                horizontalTickSide: RulerSide,
                verticalTickSide: RulerSide,
                horizontalResizeSide: RulerSide,
                verticalResizeSide: RulerSide
            )
        ] = [
            (.topLeft, .positive, .negative, .bottom, .right, .right, .bottom),
            (.topRight, .negative, .negative, .bottom, .left, .left, .bottom),
            (.bottomLeft, .positive, .positive, .top, .right, .right, .top),
            (.bottomRight, .negative, .positive, .top, .left, .left, .top),
        ]

        for testCase in cases {
            let geometry = ZeroCornerGeometry(zeroCorner: testCase.zeroCorner)

            XCTAssertEqual(
                geometry.growthDirection(for: .horizontal),
                testCase.horizontalGrowth,
                "\(testCase.zeroCorner) horizontal growth"
            )
            XCTAssertEqual(
                geometry.growthDirection(for: .vertical),
                testCase.verticalGrowth,
                "\(testCase.zeroCorner) vertical growth"
            )
            XCTAssertEqual(
                geometry.tickSide(for: .horizontal),
                testCase.horizontalTickSide,
                "\(testCase.zeroCorner) horizontal tick side"
            )
            XCTAssertEqual(
                geometry.tickSide(for: .vertical),
                testCase.verticalTickSide,
                "\(testCase.zeroCorner) vertical tick side"
            )
            XCTAssertEqual(
                geometry.resizeSide(for: .horizontal),
                testCase.horizontalResizeSide,
                "\(testCase.zeroCorner) horizontal resize side"
            )
            XCTAssertEqual(
                geometry.resizeSide(for: .vertical),
                testCase.verticalResizeSide,
                "\(testCase.zeroCorner) vertical resize side"
            )
        }
    }

    func testZeroCornerGeometryPlacesFramesAroundSharedZeroPoint() {
        let zeroPoint = NSPoint(x: 200, y: 300)
        let horizontalSize = NSSize(width: 120, height: Ruler.thickness)
        let verticalSize = NSSize(width: Ruler.thickness, height: 160)
        let cases: [
            (
                zeroCorner: ZeroCorner,
                horizontalFrame: NSRect,
                verticalFrame: NSRect
            )
        ] = [
            (
                .topLeft,
                NSRect(x: 200, y: 299, width: 120, height: Ruler.thickness),
                NSRect(x: 161, y: 140, width: Ruler.thickness, height: 160)
            ),
            (
                .topRight,
                NSRect(x: 80, y: 299, width: 120, height: Ruler.thickness),
                NSRect(x: 200, y: 140, width: Ruler.thickness, height: 160)
            ),
            (
                .bottomLeft,
                NSRect(x: 200, y: 261, width: 120, height: Ruler.thickness),
                NSRect(x: 161, y: 300, width: Ruler.thickness, height: 160)
            ),
            (
                .bottomRight,
                NSRect(x: 80, y: 261, width: 120, height: Ruler.thickness),
                NSRect(x: 200, y: 300, width: Ruler.thickness, height: 160)
            ),
        ]

        for testCase in cases {
            let geometry = ZeroCornerGeometry(zeroCorner: testCase.zeroCorner)
            let horizontalFrame = geometry.frame(
                for: .horizontal,
                zeroPoint: zeroPoint,
                size: horizontalSize
            )
            let verticalFrame = geometry.frame(
                for: .vertical,
                zeroPoint: zeroPoint,
                size: verticalSize
            )

            XCTAssertEqual(horizontalFrame, testCase.horizontalFrame, "\(testCase.zeroCorner) horizontal frame")
            XCTAssertEqual(verticalFrame, testCase.verticalFrame, "\(testCase.zeroCorner) vertical frame")
            XCTAssertEqual(
                geometry.zeroPoint(in: horizontalFrame, for: .horizontal),
                zeroPoint,
                "\(testCase.zeroCorner) horizontal zero point"
            )
            XCTAssertEqual(
                geometry.zeroPoint(in: verticalFrame, for: .vertical),
                zeroPoint,
                "\(testCase.zeroCorner) vertical zero point"
            )
        }
    }

    func testZeroCornerGeometryDefaultFramesShareAZeroPointForEachCorner() {
        let screenFrame = NSRect(x: 0, y: 0, width: 1000, height: 800)

        for zeroCorner in [ZeroCorner.topLeft, .topRight, .bottomLeft, .bottomRight] {
            let geometry = ZeroCornerGeometry(zeroCorner: zeroCorner)
            let horizontalFrame = geometry.defaultFrame(for: .horizontal, screenFrame: screenFrame)
            let verticalFrame = geometry.defaultFrame(for: .vertical, screenFrame: screenFrame)

            XCTAssertEqual(horizontalFrame.width, 500, "\(zeroCorner) horizontal width")
            XCTAssertEqual(horizontalFrame.height, Ruler.thickness, "\(zeroCorner) horizontal height")
            XCTAssertEqual(verticalFrame.width, Ruler.thickness, "\(zeroCorner) vertical width")
            XCTAssertEqual(verticalFrame.height, 400, "\(zeroCorner) vertical height")
            XCTAssertEqual(
                geometry.zeroPoint(in: horizontalFrame, for: .horizontal),
                geometry.zeroPoint(in: verticalFrame, for: .vertical),
                "\(zeroCorner) shared zero point"
            )
        }
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

    func testRulerColorsDefaultToOriginalFillColor() {
        withRestoredRulerColorPreference {
            prefs.rulerColor = Prefs.defaultRulerFillColor

            assertColor(RulerColors().fill, equals: Prefs.defaultRulerFillColor)
        }
    }

    func testRulerColorsDeriveContrastingForegroundColors() {
        withRestoredRulerColorPreference {
            prefs.rulerColor = NSColor(calibratedWhite: 0.9, alpha: 1)
            let colorsOnLightFill = RulerColors()
            XCTAssertLessThan(relativeLuminance(colorsOnLightFill.ticks), relativeLuminance(colorsOnLightFill.fill))
            XCTAssertLessThan(relativeLuminance(colorsOnLightFill.numbers), relativeLuminance(colorsOnLightFill.fill))

            prefs.rulerColor = NSColor(calibratedWhite: 0.1, alpha: 1)
            let colorsOnDarkFill = RulerColors()
            XCTAssertGreaterThan(relativeLuminance(colorsOnDarkFill.ticks), relativeLuminance(colorsOnDarkFill.fill))
            XCTAssertGreaterThan(relativeLuminance(colorsOnDarkFill.numbers), relativeLuminance(colorsOnDarkFill.fill))
        }
    }

    func testRulerColorNormalizesUnconvertibleColorsInMemory() {
        withRestoredRulerColorPreference {
            prefs.rulerColor = NSColor(patternImage: NSImage(size: NSSize(width: 1, height: 1)))

            assertColor(prefs.rulerColor, equals: Prefs.defaultRulerFillColor)
        }
    }

    func testRulerColorNormalizesAlphaInMemory() {
        withRestoredRulerColorPreference {
            prefs.rulerColor = NSColor(deviceRed: 0.2, green: 0.4, blue: 0.6, alpha: 0.35)

            assertColor(prefs.rulerColor, equals: NSColor(deviceRed: 0.2, green: 0.4, blue: 0.6, alpha: 1))
        }
    }

    func testArchivedRulerColorNormalizesAlphaOnLoad() throws {
        let archivedColor = NSColor(deviceRed: 0.2, green: 0.4, blue: 0.6, alpha: 0.35)
        let data = try NSKeyedArchiver.archivedData(
            withRootObject: archivedColor,
            requiringSecureCoding: true
        )

        let loadedColor = Prefs.rulerFillColor(fromArchivedData: data)

        assertColor(loadedColor, equals: NSColor(deviceRed: 0.2, green: 0.4, blue: 0.6, alpha: 1))
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

    func testHorizontalResizeHandleFrameMathCanResizeFromLeftEdge() {
        let initialFrame = NSRect(x: 10, y: 20, width: 300, height: Ruler.thickness)
        let frame = resizedRulerFrame(
            orientation: .horizontal,
            zeroCorner: .topRight,
            initialFrame: initialFrame,
            delta: NSSize(width: 50, height: 25),
            minSize: NSSize(width: 200, height: Ruler.thickness),
            maxSize: NSSize(width: 4000, height: Ruler.thickness)
        )

        XCTAssertEqual(frame, NSRect(x: 60, y: 20, width: 250, height: Ruler.thickness))
        XCTAssertEqual(frame.maxX, initialFrame.maxX)
    }

    func testVerticalResizeHandleFrameMathCanResizeFromTopEdge() {
        let initialFrame = NSRect(x: 10, y: 20, width: Ruler.thickness, height: 300)
        let frame = resizedRulerFrame(
            orientation: .vertical,
            zeroCorner: .bottomLeft,
            initialFrame: initialFrame,
            delta: NSSize(width: 25, height: 50),
            minSize: NSSize(width: Ruler.thickness, height: 200),
            maxSize: NSSize(width: Ruler.thickness, height: 4000)
        )

        XCTAssertEqual(frame, NSRect(x: 10, y: 20, width: Ruler.thickness, height: 350))
        XCTAssertEqual(frame.minY, initialFrame.minY)
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

    func testHorizontalMouseTickLabelStopsBeforeResizeHandle() {
        let rule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))
        guard let resizeHandleFrame = rule.resizeHandleExclusionFrame else {
            return XCTFail("Expected horizontal ruler to install a resize handle")
        }
        let labelSize = CGSize(width: 30, height: 10)
        let rulerSize = rule.bounds.size
        let expectedMaxLabelRight = resizeHandleFrame.minX - rule.mouseTickLabelResizeHandleSpacing
        let pinnedLabelX = expectedMaxLabelRight - labelSize.width
        let mouseTickBeforePinnedLabel = pinnedLabelX - 2

        let labelRect = rule.mouseNumberLabelRect(
            number: mouseTickBeforePinnedLabel,
            labelSize: labelSize,
            rulerSize: rulerSize
        )

        XCTAssertGreaterThan(labelRect.minX, mouseTickBeforePinnedLabel)
        XCTAssertEqual(
            labelRect.maxX,
            expectedMaxLabelRight,
            accuracy: 0.0001
        )
    }

    func testHorizontalMouseTickLabelFlipsBeforeCollidingWithMouseTick() {
        let rule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))
        guard let resizeHandleFrame = rule.resizeHandleExclusionFrame else {
            return XCTFail("Expected horizontal ruler to install a resize handle")
        }
        let labelSize = CGSize(width: 30, height: 10)
        let rulerSize = rule.bounds.size
        let expectedMaxLabelRight = resizeHandleFrame.minX - rule.mouseTickLabelResizeHandleSpacing
        let mouseTickInsideResizeHandle = resizeHandleFrame.minX + 1

        let labelRect = rule.mouseNumberLabelRect(
            number: mouseTickInsideResizeHandle,
            labelSize: labelSize,
            rulerSize: rulerSize
        )

        XCTAssertGreaterThan(mouseTickInsideResizeHandle, resizeHandleFrame.minX)
        XCTAssertLessThan(labelRect.maxX, mouseTickInsideResizeHandle)
        XCTAssertEqual(
            labelRect.maxX,
            expectedMaxLabelRight,
            accuracy: 0.0001
        )
    }

    func testVerticalMouseTickLabelStopsBeforeResizeHandle() {
        let rule = VerticalRule(frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))
        guard let resizeHandleFrame = rule.resizeHandleExclusionFrame else {
            return XCTFail("Expected vertical ruler to install a resize handle")
        }

        let labelRect = rule.mouseNumberLabelRect(
            number: 290,
            labelSize: CGSize(width: 22, height: 10),
            rulerHeight: 300
        )

        XCTAssertEqual(
            labelRect.minY,
            resizeHandleFrame.maxY + rule.mouseTickLabelResizeHandleSpacing,
            accuracy: 0.0001
        )
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

    private func withRestoredRulerColorPreference(_ test: () throws -> Void) rethrows {
        let defaults = UserDefaults.standard
        let previousColor = prefs.rulerColor
        let domainName = Bundle.main.bundleIdentifier
        let previousDomainValue = domainName
            .flatMap { defaults.persistentDomain(forName: $0)?["rulerColor"] }

        defer {
            prefs.rulerColor = previousColor

            if let domainName = domainName {
                var domain = defaults.persistentDomain(forName: domainName) ?? [:]
                if let previousDomainValue = previousDomainValue {
                    domain["rulerColor"] = previousDomainValue
                } else {
                    domain.removeValue(forKey: "rulerColor")
                }
                defaults.setPersistentDomain(domain, forName: domainName)
            } else {
                if previousDomainValue == nil {
                    defaults.removeObject(forKey: "rulerColor")
                }
            }
        }

        try test()
    }

    private func withRestoredZeroCornerPreference(_ test: () throws -> Void) rethrows {
        let defaults = UserDefaults.standard
        let previousZeroCorner = prefs.zeroCorner
        let domainName = Bundle.main.bundleIdentifier
        let previousDomainValue = domainName
            .flatMap { defaults.persistentDomain(forName: $0)?["zeroCorner"] }
        let previousStandardValue = defaults.object(forKey: "zeroCorner")

        defer {
            prefs.zeroCorner = previousZeroCorner

            if let domainName = domainName {
                var domain = defaults.persistentDomain(forName: domainName) ?? [:]
                if let previousDomainValue = previousDomainValue {
                    domain["zeroCorner"] = previousDomainValue
                } else {
                    domain.removeValue(forKey: "zeroCorner")
                }
                defaults.setPersistentDomain(domain, forName: domainName)
            } else {
                if let previousStandardValue = previousStandardValue {
                    defaults.set(previousStandardValue, forKey: "zeroCorner")
                } else {
                    defaults.removeObject(forKey: "zeroCorner")
                }
            }
        }

        try test()
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

private func assertColor(
    _ actualColor: NSColor,
    equals expectedColor: NSColor,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let actual = actualColor.usingColorSpace(.deviceRGB) else {
        XCTFail("Could not convert actual color to device RGB", file: file, line: line)
        return
    }

    guard let expected = expectedColor.usingColorSpace(.deviceRGB) else {
        XCTFail("Could not convert expected color to device RGB", file: file, line: line)
        return
    }

    XCTAssertEqual(actual.redComponent, expected.redComponent, accuracy: 0.0001, file: file, line: line)
    XCTAssertEqual(actual.greenComponent, expected.greenComponent, accuracy: 0.0001, file: file, line: line)
    XCTAssertEqual(actual.blueComponent, expected.blueComponent, accuracy: 0.0001, file: file, line: line)
    XCTAssertEqual(actual.alphaComponent, expected.alphaComponent, accuracy: 0.0001, file: file, line: line)
}

private func relativeLuminance(
    _ color: NSColor,
    file: StaticString = #filePath,
    line: UInt = #line
) -> CGFloat {
    guard let color = color.usingColorSpace(.deviceRGB) else {
        XCTFail("Could not convert color to device RGB", file: file, line: line)
        return .nan
    }

    return (0.299 * color.redComponent)
        + (0.587 * color.greenComponent)
        + (0.114 * color.blueComponent)
}
