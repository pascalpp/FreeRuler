import AppKit
import Carbon.HIToolbox
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

    func testDefaultZeroCornerMatchesTopLeft() {
        XCTAssertEqual(Prefs.defaultZeroCorner, .topLeft)
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
                horizontalTickSide: RulerVerticalSide,
                verticalTickSide: RulerHorizontalSide,
                horizontalResizeSide: RulerHorizontalSide,
                verticalResizeSide: RulerVerticalSide
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
                geometry.horizontalTickSide,
                testCase.horizontalTickSide,
                "\(testCase.zeroCorner) horizontal tick side"
            )
            XCTAssertEqual(
                geometry.verticalTickSide,
                testCase.verticalTickSide,
                "\(testCase.zeroCorner) vertical tick side"
            )
            XCTAssertEqual(
                geometry.horizontalResizeSide,
                testCase.horizontalResizeSide,
                "\(testCase.zeroCorner) horizontal resize side"
            )
            XCTAssertEqual(
                geometry.verticalResizeSide,
                testCase.verticalResizeSide,
                "\(testCase.zeroCorner) vertical resize side"
            )
        }
    }

    func testZeroCornerGeometryDerivesAxisSpecificCornerPlacements() {
        let cases: [
            (
                zeroCorner: ZeroCorner,
                unitLabelPlacement: RulerCornerPlacement,
                horizontalResizePlacement: RulerCornerPlacement,
                verticalResizePlacement: RulerCornerPlacement
            )
        ] = [
            (
                .topLeft,
                RulerCornerPlacement(xSide: .left, ySide: .top),
                RulerCornerPlacement(xSide: .right, ySide: .top),
                RulerCornerPlacement(xSide: .left, ySide: .bottom)
            ),
            (
                .topRight,
                RulerCornerPlacement(xSide: .right, ySide: .top),
                RulerCornerPlacement(xSide: .left, ySide: .top),
                RulerCornerPlacement(xSide: .right, ySide: .bottom)
            ),
            (
                .bottomLeft,
                RulerCornerPlacement(xSide: .left, ySide: .bottom),
                RulerCornerPlacement(xSide: .right, ySide: .bottom),
                RulerCornerPlacement(xSide: .left, ySide: .top)
            ),
            (
                .bottomRight,
                RulerCornerPlacement(xSide: .right, ySide: .bottom),
                RulerCornerPlacement(xSide: .left, ySide: .bottom),
                RulerCornerPlacement(xSide: .right, ySide: .top)
            ),
        ]

        for testCase in cases {
            let geometry = ZeroCornerGeometry(zeroCorner: testCase.zeroCorner)

            XCTAssertEqual(
                geometry.unitLabelPlacement(for: .horizontal),
                testCase.unitLabelPlacement,
                "\(testCase.zeroCorner) horizontal unit label placement"
            )
            XCTAssertEqual(
                geometry.unitLabelPlacement(for: .vertical),
                testCase.unitLabelPlacement,
                "\(testCase.zeroCorner) vertical unit label placement"
            )
            XCTAssertEqual(
                geometry.resizeHandlePlacement(for: .horizontal),
                testCase.horizontalResizePlacement,
                "\(testCase.zeroCorner) horizontal resize handle placement"
            )
            XCTAssertEqual(
                geometry.resizeHandlePlacement(for: .vertical),
                testCase.verticalResizePlacement,
                "\(testCase.zeroCorner) vertical resize handle placement"
            )
        }
    }

    func testZeroCornerFlipsAlongSelectedAxis() {
        XCTAssertEqual(ZeroCorner.topLeft.flipped(along: .horizontal), .topRight)
        XCTAssertEqual(ZeroCorner.topRight.flipped(along: .horizontal), .topLeft)
        XCTAssertEqual(ZeroCorner.bottomLeft.flipped(along: .horizontal), .bottomRight)
        XCTAssertEqual(ZeroCorner.bottomRight.flipped(along: .horizontal), .bottomLeft)

        XCTAssertEqual(ZeroCorner.topLeft.flipped(along: .vertical), .bottomLeft)
        XCTAssertEqual(ZeroCorner.topRight.flipped(along: .vertical), .bottomRight)
        XCTAssertEqual(ZeroCorner.bottomLeft.flipped(along: .vertical), .topLeft)
        XCTAssertEqual(ZeroCorner.bottomRight.flipped(along: .vertical), .topRight)
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

    func testHorizontalRuleDrawingHelpersFollowZeroCornerGeometry() {
        let rule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))

        XCTAssertEqual(
            rule.tickX(forOffset: 50, rulerWidth: 300, growthDirection: .positive),
            50
        )
        XCTAssertEqual(
            rule.tickX(forOffset: 50, rulerWidth: 300, growthDirection: .negative),
            250
        )
        XCTAssertEqual(
            rule.mouseTickLineX(forTickX: 1, growthDirection: .positive),
            1
        )
        XCTAssertEqual(
            rule.mouseTickLineX(forTickX: 299, growthDirection: .negative),
            298
        )

        let bottomTick = rule.tickLine(forX: 50, length: 10, rulerHeight: 40, tickSide: .bottom)
        XCTAssertEqual(bottomTick.start, CGPoint(x: 50, y: 1))
        XCTAssertEqual(bottomTick.end, CGPoint(x: 50, y: 10))

        let topTick = rule.tickLine(forX: 250, length: 10, rulerHeight: 40, tickSide: .top)
        XCTAssertEqual(topTick.start, CGPoint(x: 250, y: 39))
        XCTAssertEqual(topTick.end, CGPoint(x: 250, y: 30))

        XCTAssertEqual(
            rule.tickLabelRect(
                forX: 250,
                labelSize: NSSize(width: 50, height: 20),
                rulerHeight: 40,
                tickSide: .top
            ),
            CGRect(x: 225.5, y: 19, width: 50, height: 20)
        )
    }

    func testHorizontalRuleMouseAndUnitLabelsMirrorForRightZeroCorner() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .bottomRight
            let rule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))

            XCTAssertEqual(rule.mouseNumber(forTickX: 260, rulerWidth: 300), 40)
            XCTAssertEqual(
                rule.unitLabelRect(labelSize: NSSize(width: 12, height: 10), rulerSize: NSSize(width: 300, height: 40)),
                CGRect(x: 280, y: 0, width: 20, height: 19)
            )
        }
    }

    func testVerticalRuleDrawingHelpersFollowZeroCornerGeometry() {
        let rule = VerticalRule(frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))

        XCTAssertEqual(
            rule.tickY(forOffset: 50, rulerHeight: 300, growthDirection: .negative),
            250
        )
        XCTAssertEqual(
            rule.tickY(forOffset: 50, rulerHeight: 300, growthDirection: .positive),
            50
        )
        XCTAssertEqual(
            rule.mouseTickLineY(forTickY: 299, growthDirection: .negative),
            299
        )
        XCTAssertEqual(
            rule.mouseTickLineY(forTickY: 1, growthDirection: .positive),
            2
        )

        let rightTick = rule.tickLine(forY: 250, length: 10, rulerWidth: 40, tickSide: .right)
        XCTAssertEqual(rightTick.start, CGPoint(x: 39, y: 250))
        XCTAssertEqual(rightTick.end, CGPoint(x: 30, y: 250))

        let leftTick = rule.tickLine(forY: 50, length: 10, rulerWidth: 40, tickSide: .left)
        XCTAssertEqual(leftTick.start, CGPoint(x: 1, y: 50))
        XCTAssertEqual(leftTick.end, CGPoint(x: 10, y: 50))

        XCTAssertEqual(
            rule.tickLabelRect(
                forY: 50,
                labelSize: NSSize(width: 50, height: 20),
                rulerWidth: 40,
                tickSide: .left
            ),
            CGRect(x: 13, y: 46, width: 50, height: 20)
        )
    }

    func testVerticalRuleMouseAndUnitLabelsMirrorForBottomZeroCorner() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .bottomRight
            let rule = VerticalRule(frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))

            XCTAssertEqual(rule.mouseNumber(forTickY: 40, rulerHeight: 300), 40)
            XCTAssertEqual(
                rule.unitLabelRect(labelSize: NSSize(width: 12, height: 10), rulerSize: NSSize(width: 40, height: 300)),
                CGRect(x: 20, y: 0, width: 20, height: 19)
            )
        }
    }

    func testVerticalMouseNumberLabelBackgroundCoversWideLabels() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topRight

            let rule = VerticalRule(frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))
            let wideLabelSize = NSSize(width: 32, height: 10)
            let labelRect = rule.mouseNumberLabelRect(
                tickY: 150,
                labelSize: wideLabelSize,
                rulerSize: rule.bounds.size
            )
            let backgroundRect = rule.mouseNumberLabelBackgroundRect(
                tickY: 150,
                labelSize: wideLabelSize,
                rulerSize: rule.bounds.size
            )

            XCTAssertTrue(backgroundRect.contains(labelRect))
            XCTAssertLessThan(labelRect.minX, 10)
            XCTAssertEqual(backgroundRect.minX, labelRect.minX, accuracy: 0.0001)
            XCTAssertEqual(backgroundRect.maxX, rule.bounds.maxX, accuracy: 0.0001)
        }
    }

    func testResizeHandlesAreVisuallyObscuredFromLeadingEdgeToRulerEnd() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topLeft
            let horizontalRule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))
            let verticalRule = VerticalRule(frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))
            guard let horizontalHandle = horizontalRule.subviews.first(where: { $0 is ResizeHandleView }) as? ResizeHandleView else {
                return XCTFail("Expected horizontal ruler to install a resize handle")
            }
            guard let verticalHandle = verticalRule.subviews.first(where: { $0 is ResizeHandleView }) as? ResizeHandleView else {
                return XCTFail("Expected vertical ruler to install a resize handle")
            }

            horizontalRule.mouseTickX = horizontalHandle.frame.midX
            XCTAssertFalse(horizontalHandle.isHidden)
            XCTAssertEqual(horizontalHandle.alphaValue, 0)

            horizontalRule.mouseTickX = horizontalHandle.frame.maxX
            XCTAssertEqual(horizontalHandle.alphaValue, 0)

            horizontalRule.mouseTickX = horizontalHandle.frame.minX - 1
            XCTAssertEqual(horizontalHandle.alphaValue, 1)

            verticalRule.mouseTickY = verticalHandle.frame.midY
            XCTAssertFalse(verticalHandle.isHidden)
            XCTAssertEqual(verticalHandle.alphaValue, 0)

            verticalRule.mouseTickY = verticalHandle.frame.minY
            XCTAssertEqual(verticalHandle.alphaValue, 0)

            verticalRule.mouseTickY = verticalHandle.frame.maxY + 1
            XCTAssertEqual(verticalHandle.alphaValue, 1)

            verticalRule.mouseTickY = verticalHandle.frame.midY
            verticalRule.showMouseTick = false
            XCTAssertEqual(verticalHandle.alphaValue, 1)

            prefs.zeroCorner = .topRight
            let leftEdgeRule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))
            guard let leftEdgeHandle = leftEdgeRule.subviews.first(where: { $0 is ResizeHandleView }) as? ResizeHandleView else {
                return XCTFail("Expected horizontal ruler to install a resize handle")
            }

            leftEdgeRule.mouseTickX = leftEdgeHandle.frame.maxX
            XCTAssertEqual(leftEdgeHandle.alphaValue, 0)

            leftEdgeRule.mouseTickX = leftEdgeHandle.frame.maxX + 1
            XCTAssertEqual(leftEdgeHandle.alphaValue, 1)

            leftEdgeRule.mouseTickX = leftEdgeHandle.frame.minX
            XCTAssertEqual(leftEdgeHandle.alphaValue, 0)

            prefs.zeroCorner = .bottomLeft
            let topEdgeRule = VerticalRule(frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))
            guard let topEdgeHandle = topEdgeRule.subviews.first(where: { $0 is ResizeHandleView }) as? ResizeHandleView else {
                return XCTFail("Expected vertical ruler to install a resize handle")
            }

            topEdgeRule.mouseTickY = topEdgeHandle.frame.maxY
            XCTAssertEqual(topEdgeHandle.alphaValue, 0)

            topEdgeRule.mouseTickY = topEdgeHandle.frame.minY - 1
            XCTAssertEqual(topEdgeHandle.alphaValue, 1)
        }
    }

    func testUnitLabelSubviewsFollowNearOppositeCornerAfterZeroCornerChange() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topLeft
            let horizontalRule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))
            let verticalRule = VerticalRule(frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))
            prefs.zeroCorner = .bottomRight

            horizontalRule.redrawForPreferenceChange()
            verticalRule.redrawForPreferenceChange()

            let horizontalLabelSize = unitLabelSize(for: horizontalRule)
            let verticalLabelSize = unitLabelSize(for: verticalRule)

            XCTAssertEqual(
                horizontalRule.unitLabelFrame,
                horizontalRule.unitLabelRect(labelSize: horizontalLabelSize, rulerSize: horizontalRule.bounds.size)
            )
            XCTAssertEqual(
                verticalRule.unitLabelFrame,
                verticalRule.unitLabelRect(labelSize: verticalLabelSize, rulerSize: verticalRule.bounds.size)
            )
        }
    }

    func testChildViewGeometryUsesRuleZeroCornerOverride() throws {
        try withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topLeft
            let rule = TestableZeroCornerHorizontalRule(
                frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness)
            )
            rule.testZeroCorner = .bottomRight

            rule.redrawForPreferenceChange()

            let unitLabel = try XCTUnwrap(rule.subviews.first { $0 is UnitLabelView } as? UnitLabelView)
            let resizeHandle = try XCTUnwrap(
                rule.subviews.first { $0 is ResizeHandleView } as? ResizeHandleView
            )
            let labelSize = unitLabelSize(for: rule)

            XCTAssertEqual(unitLabel.zeroCorner, .bottomRight)
            XCTAssertEqual(resizeHandle.zeroCorner, .bottomRight)
            XCTAssertEqual(
                rule.unitLabelFrame,
                UnitLabelView.labelFrame(
                    labelSize: labelSize,
                    rulerSize: rule.bounds.size,
                    orientation: .horizontal,
                    zeroCorner: .bottomRight
                )
            )
        }
    }

    func testUnitLabelsAreHiddenFromInnerEdgeToZero() throws {
        try withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topLeft
            let leftZeroRule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))
            let leftZeroLabel = try XCTUnwrap(leftZeroRule.subviews.first { $0 is UnitLabelView })
            let leftZeroFrame = try XCTUnwrap(leftZeroRule.unitLabelFrame)

            leftZeroRule.mouseTickX = leftZeroFrame.maxX
            XCTAssertTrue(leftZeroLabel.isHidden)
            leftZeroRule.mouseTickX = leftZeroFrame.maxX + 1
            XCTAssertFalse(leftZeroLabel.isHidden)
            leftZeroRule.mouseTickX = leftZeroRule.bounds.minX
            XCTAssertTrue(leftZeroLabel.isHidden)

            prefs.zeroCorner = .topRight
            let rightZeroRule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))
            let rightZeroLabel = try XCTUnwrap(rightZeroRule.subviews.first { $0 is UnitLabelView })
            let rightZeroFrame = try XCTUnwrap(rightZeroRule.unitLabelFrame)

            rightZeroRule.mouseTickX = rightZeroFrame.minX
            XCTAssertTrue(rightZeroLabel.isHidden)
            rightZeroRule.mouseTickX = rightZeroFrame.minX - 1
            XCTAssertFalse(rightZeroLabel.isHidden)
            rightZeroRule.mouseTickX = rightZeroRule.bounds.maxX
            XCTAssertTrue(rightZeroLabel.isHidden)

            prefs.zeroCorner = .topLeft
            let topZeroRule = VerticalRule(frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))
            let topZeroLabel = try XCTUnwrap(topZeroRule.subviews.first { $0 is UnitLabelView })
            let topZeroFrame = try XCTUnwrap(topZeroRule.unitLabelFrame)

            topZeroRule.mouseTickY = topZeroFrame.minY
            XCTAssertTrue(topZeroLabel.isHidden)
            topZeroRule.mouseTickY = topZeroFrame.minY - 1
            XCTAssertFalse(topZeroLabel.isHidden)
            topZeroRule.mouseTickY = topZeroRule.bounds.maxY
            XCTAssertTrue(topZeroLabel.isHidden)

            prefs.zeroCorner = .bottomLeft
            let bottomZeroRule = VerticalRule(frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))
            let bottomZeroLabel = try XCTUnwrap(bottomZeroRule.subviews.first { $0 is UnitLabelView })
            let bottomZeroFrame = try XCTUnwrap(bottomZeroRule.unitLabelFrame)

            bottomZeroRule.mouseTickY = bottomZeroFrame.maxY
            XCTAssertTrue(bottomZeroLabel.isHidden)
            bottomZeroRule.mouseTickY = bottomZeroFrame.maxY + 1
            XCTAssertFalse(bottomZeroLabel.isHidden)
            bottomZeroRule.mouseTickY = bottomZeroRule.bounds.minY
            XCTAssertTrue(bottomZeroLabel.isHidden)
        }
    }

    func testMouseNumberLabelsRespectUnitsAfterZeroCornerFlip() {
        withRestoredZeroCornerPreference {
            let previousUnit = prefs.unit
            defer { prefs.unit = previousUnit }

            prefs.zeroCorner = .bottomRight
            let horizontalRule = HorizontalRule(
                frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness)
            )
            let verticalRule = VerticalRule(
                frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300)
            )
            let horizontalNumber = horizontalRule.mouseNumber(forTickX: 260, rulerWidth: 300)
            let verticalNumber = verticalRule.mouseNumber(forTickY: 40, rulerHeight: 300)
            let horizontalDpmm = horizontalRule.screen?.dpmm.width ?? NSScreen.defaultDpmm
            let verticalDpmm = verticalRule.screen?.dpmm.width ?? NSScreen.defaultDpmm
            let horizontalDpi = horizontalRule.screen?.dpi.width ?? NSScreen.defaultDpi
            let verticalDpi = verticalRule.screen?.dpi.width ?? NSScreen.defaultDpi

            prefs.unit = .pixels
            XCTAssertEqual(horizontalRule.getMouseNumberLabel(horizontalNumber), "40")
            XCTAssertEqual(verticalRule.getMouseNumberLabel(verticalNumber), "40")

            prefs.unit = .millimeters
            XCTAssertEqual(
                horizontalRule.getMouseNumberLabel(horizontalNumber),
                String(format: "%.1f", horizontalNumber / horizontalDpmm)
            )
            XCTAssertEqual(
                verticalRule.getMouseNumberLabel(verticalNumber),
                String(format: "%.1f", verticalNumber / verticalDpmm)
            )

            prefs.unit = .inches
            XCTAssertEqual(
                horizontalRule.getMouseNumberLabel(horizontalNumber),
                String(format: "%.3f", horizontalNumber / horizontalDpi)
            )
            XCTAssertEqual(
                verticalRule.getMouseNumberLabel(verticalNumber),
                String(format: "%.3f", verticalNumber / verticalDpi)
            )
        }
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
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1000, height: 800)
        let screenWidth = screenFrame.width
        let screenHeight = screenFrame.height
        let horizontalLength = screenWidth / 2
        let verticalLength = horizontalLength / (screenWidth / screenHeight)

        let horizontal = getDefaultContentRect(orientation: .horizontal)
        let vertical = getDefaultContentRect(orientation: .vertical)

        XCTAssertEqual(horizontal.height, Ruler.thickness)
        XCTAssertEqual(vertical.width, Ruler.thickness)
        XCTAssertEqual(horizontal.width, horizontalLength, accuracy: 0.0001)
        XCTAssertEqual(vertical.height, verticalLength, accuracy: 0.0001)
        XCTAssertEqual(horizontal.minX, screenFrame.minX + 69.0, accuracy: 0.0001)
        XCTAssertEqual(vertical.minX, screenFrame.minX + 30.0, accuracy: 0.0001)
        XCTAssertEqual(horizontal.minY, screenFrame.maxY - 90.0, accuracy: 0.0001)
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

    func testHorizontalResizeHandleFrameMathClampsLeftEdgeResizesAroundRightEdge() {
        let initialFrame = NSRect(x: 10, y: 20, width: 300, height: Ruler.thickness)

        let minFrame = resizedRulerFrame(
            orientation: .horizontal,
            zeroCorner: .topRight,
            initialFrame: initialFrame,
            delta: NSSize(width: 250, height: 0),
            minSize: NSSize(width: 200, height: Ruler.thickness),
            maxSize: NSSize(width: 400, height: Ruler.thickness)
        )
        let maxFrame = resizedRulerFrame(
            orientation: .horizontal,
            zeroCorner: .topRight,
            initialFrame: initialFrame,
            delta: NSSize(width: -250, height: 0),
            minSize: NSSize(width: 200, height: Ruler.thickness),
            maxSize: NSSize(width: 400, height: Ruler.thickness)
        )

        XCTAssertEqual(minFrame, NSRect(x: 110, y: 20, width: 200, height: Ruler.thickness))
        XCTAssertEqual(maxFrame, NSRect(x: -90, y: 20, width: 400, height: Ruler.thickness))
        XCTAssertEqual(minFrame.maxX, initialFrame.maxX)
        XCTAssertEqual(maxFrame.maxX, initialFrame.maxX)
    }

    func testVerticalResizeHandleFrameMathClampsTopEdgeResizesAroundBottomEdge() {
        let initialFrame = NSRect(x: 10, y: 20, width: Ruler.thickness, height: 300)

        let minFrame = resizedRulerFrame(
            orientation: .vertical,
            zeroCorner: .bottomLeft,
            initialFrame: initialFrame,
            delta: NSSize(width: 0, height: -250),
            minSize: NSSize(width: Ruler.thickness, height: 200),
            maxSize: NSSize(width: Ruler.thickness, height: 400)
        )
        let maxFrame = resizedRulerFrame(
            orientation: .vertical,
            zeroCorner: .bottomLeft,
            initialFrame: initialFrame,
            delta: NSSize(width: 0, height: 250),
            minSize: NSSize(width: Ruler.thickness, height: 200),
            maxSize: NSSize(width: Ruler.thickness, height: 400)
        )

        XCTAssertEqual(minFrame, NSRect(x: 10, y: 20, width: Ruler.thickness, height: 200))
        XCTAssertEqual(maxFrame, NSRect(x: 10, y: 20, width: Ruler.thickness, height: 400))
        XCTAssertEqual(minFrame.minY, initialFrame.minY)
        XCTAssertEqual(maxFrame.minY, initialFrame.minY)
    }

    func testResizeHandlePositionsFollowFarOppositeCornerFromZeroCorner() {
        withRestoredZeroCornerPreference {
            let cases: [
                (
                    zeroCorner: ZeroCorner,
                    expectedHorizontalXSide: RulerHorizontalSide,
                    expectedHorizontalYSide: RulerVerticalSide,
                    expectedVerticalXSide: RulerHorizontalSide,
                    expectedVerticalYSide: RulerVerticalSide
                )
            ] = [
                (.topLeft, .right, .top, .left, .bottom),
                (.topRight, .left, .top, .right, .bottom),
                (.bottomLeft, .right, .bottom, .left, .top),
                (.bottomRight, .left, .bottom, .right, .top),
            ]

            for testCase in cases {
                prefs.zeroCorner = testCase.zeroCorner
                let horizontalRule = HorizontalRule(
                    frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness)
                )
                let verticalRule = VerticalRule(
                    frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300)
                )

                guard let horizontalFrame = horizontalRule.resizeHandleExclusionFrame,
                      let verticalFrame = verticalRule.resizeHandleExclusionFrame else {
                    XCTFail("Expected both rulers to install resize handles for \(testCase.zeroCorner)")
                    continue
                }

                switch testCase.expectedHorizontalXSide {
                case .left:
                    XCTAssertLessThan(horizontalFrame.midX, horizontalRule.bounds.midX, "\(testCase.zeroCorner)")
                case .right:
                    XCTAssertGreaterThan(horizontalFrame.midX, horizontalRule.bounds.midX, "\(testCase.zeroCorner)")
                }

                switch testCase.expectedHorizontalYSide {
                case .top:
                    XCTAssertGreaterThan(horizontalFrame.midY, horizontalRule.bounds.midY, "\(testCase.zeroCorner)")
                case .bottom:
                    XCTAssertLessThan(horizontalFrame.midY, horizontalRule.bounds.midY, "\(testCase.zeroCorner)")
                }

                switch testCase.expectedVerticalXSide {
                case .left:
                    XCTAssertLessThan(verticalFrame.midX, verticalRule.bounds.midX, "\(testCase.zeroCorner)")
                case .right:
                    XCTAssertGreaterThan(verticalFrame.midX, verticalRule.bounds.midX, "\(testCase.zeroCorner)")
                }

                switch testCase.expectedVerticalYSide {
                case .top:
                    XCTAssertGreaterThan(verticalFrame.midY, verticalRule.bounds.midY, "\(testCase.zeroCorner)")
                case .bottom:
                    XCTAssertLessThan(verticalFrame.midY, verticalRule.bounds.midY, "\(testCase.zeroCorner)")
                }
            }
        }
    }

    func testPreferenceRedrawUpdatesResizeHandleFrameForZeroCornerChanges() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topLeft
            let rule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))
            guard let initialFrame = rule.resizeHandleExclusionFrame else {
                return XCTFail("Expected horizontal ruler to install a resize handle")
            }

            prefs.zeroCorner = .topRight
            rule.redrawForPreferenceChange()
            guard let flippedFrame = rule.resizeHandleExclusionFrame else {
                return XCTFail("Expected horizontal ruler to keep its resize handle")
            }

            XCTAssertGreaterThan(initialFrame.midX, rule.bounds.midX)
            XCTAssertLessThan(flippedFrame.midX, rule.bounds.midX)
        }
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

    func testHorizontalResizeHandleFramePinsToLeftEdgeSlot() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topRight

            let resizeHandle = ResizeHandleView(orientation: .horizontal, color: RulerColors())
            let frame = resizeHandle.frame(in: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))

            XCTAssertEqual(frame.minX, 0)
        }
    }

    func testHorizontalMouseTickLabelFlipsBeforeResizeHandleWithoutPinning() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topLeft

            let rule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))
            let labelSize = CGSize(width: 30, height: 10)
            let rulerSize = rule.bounds.size
            guard let resizeHandleFrame = rule.resizeHandleExclusionFrame else {
                return XCTFail("Expected horizontal ruler to install a resize handle")
            }
            let tickLabelSpacing: CGFloat = 5
            let mouseTickJustPastRightHandleFit = resizeHandleFrame.minX - labelSize.width - tickLabelSpacing + 1
            let mouseTickNearRightEdge: CGFloat = 290

            let labelJustPastRightHandleFit = rule.mouseNumberLabelRect(
                tickX: mouseTickJustPastRightHandleFit,
                labelSize: labelSize,
                rulerSize: rulerSize
            )
            let labelRect = rule.mouseNumberLabelRect(
                tickX: mouseTickNearRightEdge,
                labelSize: labelSize,
                rulerSize: rulerSize
            )

            XCTAssertLessThan(labelJustPastRightHandleFit.maxX, mouseTickJustPastRightHandleFit)
            XCTAssertLessThanOrEqual(labelJustPastRightHandleFit.maxX, resizeHandleFrame.minX)
            XCTAssertEqual(
                mouseTickJustPastRightHandleFit - labelJustPastRightHandleFit.maxX,
                tickLabelSpacing,
                accuracy: 0.0001
            )
            XCTAssertLessThan(labelRect.maxX, mouseTickNearRightEdge)
            XCTAssertEqual(
                mouseTickNearRightEdge - labelRect.maxX,
                tickLabelSpacing,
                accuracy: 0.0001
            )
        }
    }

    func testHorizontalMouseTickLabelFlipsBeforeRightUnitLabel() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topRight

            let rule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))
            let labelSize = CGSize(width: 30, height: 10)
            let tickLabelSpacing: CGFloat = 5
            let unitLabelFlipPadding: CGFloat = 3
            guard let unitLabelFrame = rule.unitLabelFrame else {
                return XCTFail("Expected horizontal ruler to install a unit label")
            }
            let mouseTickAtRightUnitFit = unitLabelFrame.minX - unitLabelFlipPadding - labelSize.width - tickLabelSpacing
            let mouseTickJustPastRightUnitFit = mouseTickAtRightUnitFit + 1

            let fittingLabelRect = rule.mouseNumberLabelRect(
                tickX: mouseTickAtRightUnitFit,
                labelSize: labelSize,
                rulerSize: rule.bounds.size
            )
            let flippedLabelRect = rule.mouseNumberLabelRect(
                tickX: mouseTickJustPastRightUnitFit,
                labelSize: labelSize,
                rulerSize: rule.bounds.size
            )

            XCTAssertGreaterThan(fittingLabelRect.minX, mouseTickAtRightUnitFit)
            XCTAssertEqual(
                fittingLabelRect.maxX,
                unitLabelFrame.minX - unitLabelFlipPadding,
                accuracy: 0.0001
            )
            XCTAssertLessThan(flippedLabelRect.maxX, mouseTickJustPastRightUnitFit)
            XCTAssertEqual(
                mouseTickJustPastRightUnitFit - flippedLabelRect.maxX,
                tickLabelSpacing,
                accuracy: 0.0001
            )
        }
    }

    func testHorizontalMouseTickLabelStaysOnPreferredSideNearLeftResizeEnd() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .bottomRight

            let rule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 600, height: Ruler.thickness))
            let labelSize = CGSize(width: 30, height: 10)
            let tickLabelSpacing: CGFloat = 5
            guard let resizeHandleFrame = rule.resizeHandleExclusionFrame else {
                return XCTFail("Expected horizontal ruler to install a resize handle")
            }
            let mouseTickInsideLeftResizeEnd = resizeHandleFrame.maxX - tickLabelSpacing - 1

            let labelRect = rule.mouseNumberLabelRect(
                tickX: mouseTickInsideLeftResizeEnd,
                labelSize: labelSize,
                rulerSize: rule.bounds.size
            )

            XCTAssertGreaterThan(labelRect.minX, mouseTickInsideLeftResizeEnd)
            XCTAssertEqual(
                labelRect.minX - mouseTickInsideLeftResizeEnd,
                tickLabelSpacing,
                accuracy: 0.0001
            )
        }
    }

    func testHorizontalMouseTickLabelClampsToRulerStart() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topLeft

            let rule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))
            let labelSize = CGSize(width: 30, height: 10)
            let rulerSize = rule.bounds.size
            let mouseTickNearLeftEdge: CGFloat = -10

            let labelRect = rule.mouseNumberLabelRect(
                tickX: mouseTickNearLeftEdge,
                labelSize: labelSize,
                rulerSize: rulerSize
            )

            XCTAssertEqual(
                labelRect.minX,
                0,
                accuracy: 0.0001
            )
        }
    }

    func testVerticalMouseTickLabelStaysOnPreferredSideNearTopResizeEnd() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .bottomLeft

            let rule = VerticalRule(frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))
            let labelSize = CGSize(width: 20, height: 10)
            let tickLabelSpacing: CGFloat = 4
            guard let resizeHandleFrame = rule.resizeHandleExclusionFrame else {
                return XCTFail("Expected vertical ruler to install a resize handle")
            }
            let mouseTickInsideTopResizeEnd = resizeHandleFrame.minY + tickLabelSpacing + 1

            let labelRect = rule.mouseNumberLabelRect(
                tickY: mouseTickInsideTopResizeEnd,
                labelSize: labelSize,
                rulerSize: rule.bounds.size
            )

            XCTAssertLessThan(labelRect.maxY, mouseTickInsideTopResizeEnd)
            XCTAssertEqual(
                mouseTickInsideTopResizeEnd - labelRect.maxY,
                tickLabelSpacing,
                accuracy: 0.0001
            )
        }
    }

    func testVerticalMouseTickLabelFlipsBeforeBottomUnitLabel() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .bottomLeft

            let rule = VerticalRule(frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))
            let labelSize = CGSize(width: 20, height: 10)
            let tickLabelSpacing: CGFloat = 4
            let unitLabelFlipPadding: CGFloat = 3
            guard let unitLabelFrame = rule.unitLabelFrame else {
                return XCTFail("Expected vertical ruler to install a unit label")
            }
            let mouseTickAtBottomUnitFit = unitLabelFrame.maxY
                + unitLabelFlipPadding
                + tickLabelSpacing
                + labelSize.height
            let mouseTickJustPastBottomUnitFit = mouseTickAtBottomUnitFit - 1

            let fittingLabelRect = rule.mouseNumberLabelRect(
                tickY: mouseTickAtBottomUnitFit,
                labelSize: labelSize,
                rulerSize: rule.bounds.size
            )
            let flippedLabelRect = rule.mouseNumberLabelRect(
                tickY: mouseTickJustPastBottomUnitFit,
                labelSize: labelSize,
                rulerSize: rule.bounds.size
            )

            XCTAssertLessThan(fittingLabelRect.maxY, mouseTickAtBottomUnitFit)
            XCTAssertEqual(
                fittingLabelRect.minY,
                unitLabelFrame.maxY + unitLabelFlipPadding,
                accuracy: 0.0001
            )
            XCTAssertGreaterThan(flippedLabelRect.minY, mouseTickJustPastBottomUnitFit)
            XCTAssertEqual(
                flippedLabelRect.minY - mouseTickJustPastBottomUnitFit,
                tickLabelSpacing,
                accuracy: 0.0001
            )
        }
    }

    func testVerticalMouseTickLabelStaysWithinRulerEnds() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topLeft

            let rule = VerticalRule(frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))
            let labelSize = CGSize(width: 20, height: 10)
            let rulerSize = rule.bounds.size

            let labelNearBottom = rule.mouseNumberLabelRect(
                tickY: 1,
                labelSize: labelSize,
                rulerSize: rulerSize
            )
            XCTAssertEqual(
                labelNearBottom.minY,
                5,
                accuracy: 0.0001
            )

            let labelNearTop = rule.mouseNumberLabelRect(
                tickY: 299,
                labelSize: labelSize,
                rulerSize: rulerSize
            )
            XCTAssertEqual(
                labelNearTop.minY,
                285,
                accuracy: 0.0001
            )
        }
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
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topLeft

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

    func testUngroupedHorizontalFlipDoesNotMoveRulerWindows() {
        withRestoredZeroCornerPreference {
            let previousGroupRulers = prefs.groupRulers
            defer { prefs.groupRulers = previousGroupRulers }

            prefs.zeroCorner = .topLeft
            prefs.groupRulers = false
            let appDelegate = AppDelegate()
            let horizontalController = RulerController(
                ruler: Ruler(.horizontal, frame: NSRect(x: 100, y: 299, width: 120, height: Ruler.thickness))
            )
            let verticalController = RulerController(
                ruler: Ruler(.vertical, frame: NSRect(x: 51, y: 150, width: Ruler.thickness, height: 160))
            )
            appDelegate.rulers = [verticalController, horizontalController]

            appDelegate.flipRulers(along: .horizontal)

            XCTAssertEqual(prefs.zeroCorner, .topRight)
            XCTAssertEqual(horizontalController.rulerWindow.frame, NSRect(x: 100, y: 299, width: 120, height: Ruler.thickness))
            XCTAssertEqual(verticalController.rulerWindow.frame, NSRect(x: 51, y: 150, width: Ruler.thickness, height: 160))
        }
    }

    func testGroupedHorizontalFlipMovesVerticalRulerToPreserveZeroPointOffset() {
        withRestoredZeroCornerPreference {
            let previousGroupRulers = prefs.groupRulers
            defer { prefs.groupRulers = previousGroupRulers }

            prefs.zeroCorner = .topLeft
            prefs.groupRulers = true
            let appDelegate = TestableFlipAppDelegate()
            let horizontalController = RulerController(
                ruler: Ruler(.horizontal, frame: NSRect(x: 100, y: 299, width: 120, height: Ruler.thickness))
            )
            let verticalController = RulerController(
                ruler: Ruler(.vertical, frame: NSRect(x: 51, y: 150, width: Ruler.thickness, height: 160))
            )
            appDelegate.rulers = [verticalController, horizontalController]

            appDelegate.flipRulers(along: .horizontal)

            XCTAssertEqual(prefs.zeroCorner, .topRight)
            XCTAssertEqual(horizontalController.rulerWindow.frame, NSRect(x: 100, y: 299, width: 120, height: Ruler.thickness))
            XCTAssertEqual(verticalController.rulerWindow.frame, NSRect(x: 210, y: 150, width: Ruler.thickness, height: 160))
        }
    }

    func testGroupedVerticalFlipMovesHorizontalRulerToPreserveZeroPointOffset() {
        withRestoredZeroCornerPreference {
            let previousGroupRulers = prefs.groupRulers
            defer { prefs.groupRulers = previousGroupRulers }

            prefs.zeroCorner = .topLeft
            prefs.groupRulers = true
            let appDelegate = TestableFlipAppDelegate()
            let horizontalController = RulerController(
                ruler: Ruler(.horizontal, frame: NSRect(x: 100, y: 299, width: 120, height: Ruler.thickness))
            )
            let verticalController = RulerController(
                ruler: Ruler(.vertical, frame: NSRect(x: 61, y: 140, width: Ruler.thickness, height: 160))
            )
            appDelegate.rulers = [verticalController, horizontalController]

            appDelegate.flipRulers(along: .vertical)

            XCTAssertEqual(prefs.zeroCorner, .bottomLeft)
            XCTAssertEqual(verticalController.rulerWindow.frame, NSRect(x: 61, y: 140, width: Ruler.thickness, height: 160))
            XCTAssertEqual(horizontalController.rulerWindow.frame, NSRect(x: 100, y: 101, width: 120, height: Ruler.thickness))
        }
    }

    func testGroupedFlipDoesNotShowHiddenRulerWindows() {
        withRestoredZeroCornerPreference {
            let previousGroupRulers = prefs.groupRulers
            defer { prefs.groupRulers = previousGroupRulers }

            prefs.zeroCorner = .topLeft
            prefs.groupRulers = true
            let appDelegate = AppDelegate()
            let horizontalController = RulerController(
                ruler: Ruler(.horizontal, frame: NSRect(x: 100, y: 299, width: 120, height: Ruler.thickness))
            )
            let verticalController = RulerController(
                ruler: Ruler(.vertical, frame: NSRect(x: 61, y: 140, width: Ruler.thickness, height: 160))
            )
            appDelegate.rulers = [verticalController, horizontalController]
            let horizontalFrame = horizontalController.rulerWindow.frame
            let verticalFrame = verticalController.rulerWindow.frame

            XCTAssertFalse(horizontalController.rulerWindow.isVisible)
            XCTAssertFalse(verticalController.rulerWindow.isVisible)

            appDelegate.flipRulers(along: .horizontal)

            XCTAssertFalse(horizontalController.rulerWindow.isVisible)
            XCTAssertFalse(verticalController.rulerWindow.isVisible)
            XCTAssertEqual(horizontalController.rulerWindow.frame, horizontalFrame)
            XCTAssertEqual(verticalController.rulerWindow.frame, verticalFrame)
        }
    }

    func testShiftHotkeysFlipRulerOrigins() {
        withRestoredZeroCornerPreference {
            let previousGroupRulers = prefs.groupRulers
            defer { prefs.groupRulers = previousGroupRulers }

            prefs.zeroCorner = .topLeft
            prefs.groupRulers = false
            let appDelegate = AppDelegate()
            let horizontalController = RulerController(
                ruler: Ruler(.horizontal, frame: NSRect(x: 100, y: 299, width: 120, height: Ruler.thickness))
            )
            let verticalController = RulerController(
                ruler: Ruler(.vertical, frame: NSRect(x: 61, y: 140, width: Ruler.thickness, height: 160))
            )
            appDelegate.rulers = [verticalController, horizontalController]

            XCTAssertTrue(
                appDelegate.performRulerHotkey(
                    keyCode: kVK_ANSI_H,
                    modifierFlags: .shift,
                    sender: horizontalController
                )
            )
            XCTAssertEqual(prefs.zeroCorner, .topRight)

            XCTAssertTrue(
                appDelegate.performRulerHotkey(
                    keyCode: kVK_ANSI_V,
                    modifierFlags: .shift,
                    sender: verticalController
                )
            )
            XCTAssertEqual(prefs.zeroCorner, .bottomRight)
        }
    }

    func testShiftHotkeysIgnoreCapsLock() {
        withRestoredZeroCornerPreference {
            let previousGroupRulers = prefs.groupRulers
            defer { prefs.groupRulers = previousGroupRulers }

            prefs.zeroCorner = .topLeft
            prefs.groupRulers = false
            let appDelegate = AppDelegate()
            let horizontalController = RulerController(
                ruler: Ruler(.horizontal, frame: NSRect(x: 100, y: 299, width: 120, height: Ruler.thickness))
            )
            appDelegate.rulers = [horizontalController]

            XCTAssertTrue(
                appDelegate.performRulerHotkey(
                    keyCode: kVK_ANSI_H,
                    modifierFlags: [.shift, .capsLock],
                    sender: horizontalController
                )
            )
            XCTAssertEqual(prefs.zeroCorner, .topRight)
        }
    }

    func testNonShiftModifiedRulerHotkeysAreIgnored() {
        let appDelegate = AppDelegate()

        XCTAssertFalse(
            appDelegate.performRulerHotkey(
                keyCode: kVK_ANSI_H,
                modifierFlags: .option,
                sender: self
            )
        )
    }

    func testResetPositionUsesCurrentZeroCorner() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .bottomRight
            let horizontalController = RulerController(
                ruler: Ruler(.horizontal, frame: NSRect(x: 10, y: 20, width: 300, height: Ruler.thickness))
            )
            let verticalController = RulerController(
                ruler: Ruler(.vertical, frame: NSRect(x: 10, y: 20, width: Ruler.thickness, height: 300))
            )

            horizontalController.resetPosition()
            verticalController.resetPosition()

            XCTAssertEqual(
                horizontalController.rulerWindow.frame,
                getDefaultContentRect(orientation: .horizontal, zeroCorner: .bottomRight)
            )
            XCTAssertEqual(
                verticalController.rulerWindow.frame,
                getDefaultContentRect(orientation: .vertical, zeroCorner: .bottomRight)
            )
            XCTAssertEqual(prefs.zeroCorner, .bottomRight)
        }
    }

    func testResetPositionKeepsFlippedDefaultRulersOnSharedZeroPoint() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topRight
            let horizontalController = RulerController(
                ruler: Ruler(.horizontal, frame: NSRect(x: 10, y: 20, width: 300, height: Ruler.thickness))
            )
            let verticalController = RulerController(
                ruler: Ruler(.vertical, frame: NSRect(x: 10, y: 20, width: Ruler.thickness, height: 300))
            )

            horizontalController.resetPosition()
            verticalController.resetPosition()

            let geometry = ZeroCornerGeometry(zeroCorner: .topRight)
            XCTAssertEqual(
                geometry.zeroPoint(in: horizontalController.rulerWindow.frame, for: .horizontal),
                geometry.zeroPoint(in: verticalController.rulerWindow.frame, for: .vertical)
            )
        }
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

private final class TestableFlipAppDelegate: AppDelegate {
    override func isRulerWindowShown(_ window: RulerWindow) -> Bool {
        return true
    }
}

private final class TestableZeroCornerHorizontalRule: HorizontalRule {
    var testZeroCorner: ZeroCorner = .topLeft

    override var zeroCorner: ZeroCorner {
        return testZeroCorner
    }
}

private func unitLabelSize(for rule: RuleView) -> NSSize {
    let label = NSAttributedString(
        string: rule.getUnitLabel(),
        attributes: rule.labelAttributes(alignment: .left, foregroundColor: rule.color.ticks)
    )

    return UnitLabelView.labelSize(for: label)
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
