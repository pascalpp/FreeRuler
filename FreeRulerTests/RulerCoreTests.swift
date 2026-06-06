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
}
