import AppKit

#if SNAPSHOT_GENERATOR
private typealias RulerUnit = Unit
#else
import XCTest
@testable import Free_Ruler

private typealias RulerUnit = Free_Ruler.Unit

final class RulerSnapshotTests: XCTestCase {

    func testRulerZeroCornerRenderingsMatchSnapshots() throws {
        try assertSnapshot(
            named: "ruler-zero-corners",
            view: RulerSnapshotFactory.zeroCornerSnapshotView()
        )
    }

    func testMouseTickLabelRenderingsMatchSnapshots() throws {
        try assertSnapshot(
            named: "ruler-mouse-tick-labels",
            view: RulerSnapshotFactory.mouseTickLabelSnapshotView()
        )
    }

    private func assertSnapshot(
        named name: String,
        view: NSView,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let actualData = try RulerSnapshotFactory.pngData(rendering: view)

        let testBundle = Bundle(for: Self.self)
        let snapshotURL = testBundle.url(forResource: name, withExtension: "png")
            ?? testBundle.url(
                forResource: name,
                withExtension: "png",
                subdirectory: "__Snapshots__/RulerSnapshotTests"
            )

        guard let snapshotURL else {
            XCTFail(
                "Missing snapshot resource \(name).png. Run scripts/generate-ruler-snapshots.sh to record baselines.",
                file: file,
                line: line
            )
            return
        }

        let expectedData = try Data(contentsOf: snapshotURL)
        guard actualData == expectedData else {
            let failureURL = try writeFailureSnapshot(named: name, data: actualData)

            let expectedAttachment = XCTAttachment(data: expectedData, uniformTypeIdentifier: "public.png")
            expectedAttachment.name = "\(name)-expected"
            expectedAttachment.lifetime = .keepAlways
            add(expectedAttachment)

            let actualAttachment = XCTAttachment(data: actualData, uniformTypeIdentifier: "public.png")
            actualAttachment.name = "\(name)-actual"
            actualAttachment.lifetime = .keepAlways
            add(actualAttachment)

            XCTFail(
                "Snapshot \(name) did not match baseline. Actual image written to \(failureURL.path). Run scripts/generate-ruler-snapshots.sh if the visual change is intended.",
                file: file,
                line: line
            )
            return
        }
    }

    private func writeFailureSnapshot(named name: String, data: Data) throws -> URL {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("FreeRulerSnapshotFailures", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let url = directory.appendingPathComponent("\(name)-actual.png")
        try data.write(to: url, options: .atomic)
        return url
    }
}
#endif

enum RulerSnapshotFactory {

    static func zeroCornerSnapshotView() -> NSView {
        let cellSize = NSSize(width: 272, height: 232)
        let spacing: CGFloat = 16
        let canvas = SnapshotCanvasView(
            frame: NSRect(
                x: 0,
                y: 0,
                width: (cellSize.width * 2) + spacing,
                height: (cellSize.height * 2) + spacing
            )
        )

        let cells: [(corner: ZeroCorner, origin: NSPoint, zeroPoint: NSPoint)] = [
            (.bottomLeft, NSPoint(x: 0, y: 0), NSPoint(x: 50, y: 50)),
            (.bottomRight, NSPoint(x: cellSize.width + spacing, y: 0), NSPoint(x: 222, y: 50)),
            (.topLeft, NSPoint(x: 0, y: cellSize.height + spacing), NSPoint(x: 50, y: 182)),
            (.topRight, NSPoint(x: cellSize.width + spacing, y: cellSize.height + spacing), NSPoint(x: 222, y: 182)),
        ]

        for cell in cells {
            let container = SnapshotCanvasView(frame: NSRect(origin: cell.origin, size: cellSize))
            container.backgroundColor = NSColor(deviceWhite: 0.96, alpha: 1)
            canvas.addSubview(container)

            let geometry = ZeroCornerGeometry(zeroCorner: cell.corner)
            let horizontalSize = NSSize(width: 200, height: Ruler.thickness)
            let verticalSize = NSSize(width: Ruler.thickness, height: 160)

            let horizontalRule = SnapshotHorizontalRule(
                unit: .pixels,
                zeroCorner: cell.corner,
                frame: geometry.frame(
                    for: .horizontal,
                    zeroPoint: cell.zeroPoint,
                    size: horizontalSize
                )
            )
            let verticalRule = SnapshotVerticalRule(
                unit: .pixels,
                zeroCorner: cell.corner,
                frame: geometry.frame(
                    for: .vertical,
                    zeroPoint: cell.zeroPoint,
                    size: verticalSize
                )
            )
            configure(horizontalRule, fill: SnapshotColors.lightRuler, showsMouseTick: false)
            configure(verticalRule, fill: SnapshotColors.lightRuler, showsMouseTick: false)

            container.addSubview(verticalRule)
            container.addSubview(horizontalRule)
        }

        return canvas
    }

    static func mouseTickLabelSnapshotView() -> NSView {
        let horizontalSize = NSSize(width: 320, height: Ruler.thickness)
        let verticalSize = NSSize(width: Ruler.thickness, height: 220)
        let margin: CGFloat = 16
        let spacing: CGFloat = 18
        let canvas = SnapshotCanvasView(
            frame: NSRect(
                x: 0,
                y: 0,
                width: (margin * 2) + horizontalSize.width + spacing + (verticalSize.width * 2) + spacing,
                height: (margin * 2) + (Ruler.thickness * 2) + (spacing * 2) + verticalSize.height
            )
        )

        let topLeftHorizontal = SnapshotHorizontalRule(
            unit: .pixels,
            zeroCorner: .topLeft,
            frame: NSRect(
                x: margin,
                y: margin + verticalSize.height + spacing + Ruler.thickness + spacing,
                width: horizontalSize.width,
                height: Ruler.thickness
            )
        )
        topLeftHorizontal.mouseTickX = 292
        configure(topLeftHorizontal, fill: SnapshotColors.lightRuler, showsMouseTick: true)
        canvas.addSubview(topLeftHorizontal)

        let topRightHorizontal = SnapshotHorizontalRule(
            unit: .inches,
            zeroCorner: .topRight,
            frame: NSRect(
                x: margin,
                y: margin + verticalSize.height + spacing,
                width: horizontalSize.width,
                height: Ruler.thickness
            )
        )
        topRightHorizontal.mouseTickX = 268
        configure(topRightHorizontal, fill: SnapshotColors.darkRuler, showsMouseTick: true)
        canvas.addSubview(topRightHorizontal)

        let bottomLeftVertical = SnapshotVerticalRule(
            unit: .pixels,
            zeroCorner: .bottomLeft,
            frame: NSRect(
                x: margin + horizontalSize.width + spacing,
                y: margin,
                width: Ruler.thickness,
                height: verticalSize.height
            )
        )
        bottomLeftVertical.mouseTickY = 26
        configure(bottomLeftVertical, fill: SnapshotColors.lightRuler, showsMouseTick: true)
        canvas.addSubview(bottomLeftVertical)

        let bottomRightVertical = SnapshotVerticalRule(
            unit: .inches,
            zeroCorner: .bottomRight,
            frame: NSRect(
                x: margin + horizontalSize.width + spacing + Ruler.thickness + spacing,
                y: margin,
                width: Ruler.thickness,
                height: verticalSize.height
            )
        )
        bottomRightVertical.mouseTickY = 194
        configure(bottomRightVertical, fill: SnapshotColors.darkRuler, showsMouseTick: true)
        canvas.addSubview(bottomRightVertical)

        return canvas
    }

    static func writeSnapshots(to directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let snapshots: [(name: String, view: NSView)] = [
            ("ruler-zero-corners", zeroCornerSnapshotView()),
            ("ruler-mouse-tick-labels", mouseTickLabelSnapshotView()),
        ]

        for snapshot in snapshots {
            let url = directory.appendingPathComponent("\(snapshot.name).png")
            try pngData(rendering: snapshot.view).write(to: url, options: .atomic)
        }
    }

    static func pngData(rendering view: NSView) throws -> Data {
        view.layoutSubtreeIfNeeded()
        view.displayIfNeeded()

        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(view.bounds.width),
            pixelsHigh: Int(view.bounds.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw SnapshotError.bitmapCreationFailed
        }

        bitmap.size = view.bounds.size

        guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
            throw SnapshotError.graphicsContextCreationFailed
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        drawViewHierarchy(view)
        NSGraphicsContext.restoreGraphicsState()

        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw SnapshotError.pngEncodingFailed
        }

        return pngData
    }

    private static func drawViewHierarchy(_ view: NSView) {
        guard !view.isHidden,
              view.alphaValue > 0,
              !view.bounds.isEmpty else { return }

        view.layoutSubtreeIfNeeded()

        guard let context = NSGraphicsContext.current else { return }

        context.cgContext.saveGState()
        context.cgContext.translateBy(x: view.frame.minX, y: view.frame.minY)
        context.cgContext.setAlpha(view.alphaValue)
        NSBezierPath(rect: view.bounds).addClip()

        view.draw(view.bounds)
        for subview in view.subviews {
            drawViewHierarchy(subview)
        }

        context.cgContext.restoreGState()
    }

    private static func configure(_ rule: RuleView, fill: NSColor, showsMouseTick: Bool) {
        rule.showMouseTick = showsMouseTick
        rule.color = RulerColors(customFill: fill)
        rule.layoutSubtreeIfNeeded()
        rule.needsDisplay = true
    }
}

private final class SnapshotCanvasView: NSView {
    var backgroundColor = NSColor(deviceWhite: 1, alpha: 1)

    override func draw(_ dirtyRect: NSRect) {
        backgroundColor.setFill()
        dirtyRect.fill()
    }
}

private final class SnapshotHorizontalRule: HorizontalRule {
    private let snapshotUnit: RulerUnit
    private let snapshotZeroCorner: ZeroCorner

    override var unit: RulerUnit {
        return snapshotUnit
    }

    override var zeroCorner: ZeroCorner {
        return snapshotZeroCorner
    }

    init(unit: RulerUnit, zeroCorner: ZeroCorner, frame: NSRect) {
        self.snapshotUnit = unit
        self.snapshotZeroCorner = zeroCorner
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(bounds)
    }
}

private final class SnapshotVerticalRule: VerticalRule {
    private let snapshotUnit: RulerUnit
    private let snapshotZeroCorner: ZeroCorner

    override var unit: RulerUnit {
        return snapshotUnit
    }

    override var zeroCorner: ZeroCorner {
        return snapshotZeroCorner
    }

    init(unit: RulerUnit, zeroCorner: ZeroCorner, frame: NSRect) {
        self.snapshotUnit = unit
        self.snapshotZeroCorner = zeroCorner
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(bounds)
    }
}

private enum SnapshotColors {
    static let lightRuler = NSColor(deviceRed: 0.9765, green: 0.8510, blue: 0.5490, alpha: 1)
    static let darkRuler = NSColor(deviceRed: 0.16, green: 0.21, blue: 0.25, alpha: 1)
}

private enum SnapshotError: Error {
    case bitmapCreationFailed
    case graphicsContextCreationFailed
    case pngEncodingFailed
}

#if SNAPSHOT_GENERATOR
@main
private enum RulerSnapshotGeneratorMain {
    static func main() throws {
        let outputDirectory: URL
        if CommandLine.arguments.count > 1 {
            outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        } else {
            outputDirectory = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .appendingPathComponent("__Snapshots__")
                .appendingPathComponent("RulerSnapshotTests")
        }

        try RulerSnapshotFactory.writeSnapshots(to: outputDirectory)
    }
}
#endif
