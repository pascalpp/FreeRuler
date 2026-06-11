import Cocoa
import SwiftUI

final class ResizeHandleView: NSView {

    private let color: RulerColors
    private let orientation: Orientation
    private var trackingArea: NSTrackingArea?
    private var dragInitialMouseLocation: NSPoint?
    private var dragInitialWindowFrame: NSRect?
    private var wasMovableByWindowBackgroundBeforeDrag: Bool?
    private var childWindowFramesBeforeDrag: [(window: NSWindow, frame: NSRect)] = []

    private let length: CGFloat = 12
    private let lineCount = 4
    private let lineSpacing: CGFloat = 3
    private let backgroundPadding: CGFloat = 1.5
    private let backgroundBorderRadius: CGFloat = 2
    private let horizontalXOffset: CGFloat = 5
    private let horizontalYOffset: CGFloat = 4
    private let verticalXOffset: CGFloat = 4
    private let verticalYOffset: CGFloat = 5

    init(orientation: Orientation, color: RulerColors) {
        self.orientation = orientation
        self.color = color
        super.init(frame: .zero)

        setAccessibilityElement(true)
        setAccessibilityIdentifier(resizeHandleAccessibilityIdentifier(for: orientation))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init(orientation:color:)")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        drawBackground()
        drawGripLines()
    }

    override func updateTrackingAreas() {
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }

        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [
                .activeAlways,
                .cursorUpdate,
                .inVisibleRect,
                .mouseEnteredAndExited,
            ],
            owner: self,
            userInfo: nil
        )

        addTrackingArea(trackingArea!)
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: windowResizeCursor(for: orientation))
    }

    override func cursorUpdate(with event: NSEvent) {
        windowResizeCursor(for: orientation).set()
    }

    override func mouseEntered(with event: NSEvent) {
        windowResizeCursor(for: orientation).set()
    }

    override var mouseDownCanMoveWindow: Bool {
        return false
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    override func mouseDown(with event: NSEvent) {
        guard let window = window else { return }

        dragInitialMouseLocation = screenLocation(for: event, in: window)
        dragInitialWindowFrame = window.frame
        wasMovableByWindowBackgroundBeforeDrag = window.isMovableByWindowBackground

        window.isMovableByWindowBackground = false
        window.makeKey()

        childWindowFramesBeforeDrag = window.childWindows?.map { ($0, $0.frame) } ?? []
        for childWindow in childWindowFramesBeforeDrag.map(\.window) {
            window.removeChildWindow(childWindow)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window = window,
              let dragInitialMouseLocation = dragInitialMouseLocation,
              let dragInitialWindowFrame = dragInitialWindowFrame else { return }

        let mouseLocation = screenLocation(for: event, in: window)
        let delta = NSSize(
            width: mouseLocation.x - dragInitialMouseLocation.x,
            height: mouseLocation.y - dragInitialMouseLocation.y
        )
        let nextFrame = resizedRulerFrame(
            orientation: orientation,
            initialFrame: dragInitialWindowFrame,
            delta: delta,
            minSize: window.minSize,
            maxSize: window.maxSize
        )

        window.setFrame(nextFrame, display: true)
        for (childWindow, childFrame) in childWindowFramesBeforeDrag {
            childWindow.setFrame(childFrame, display: false)
        }
    }

    override func mouseUp(with event: NSEvent) {
        guard let window = window else {
            resetDragState()
            return
        }

        if let wasMovableByWindowBackgroundBeforeDrag = wasMovableByWindowBackgroundBeforeDrag {
            window.isMovableByWindowBackground = wasMovableByWindowBackgroundBeforeDrag
        }
        for (childWindow, childFrame) in childWindowFramesBeforeDrag {
            childWindow.setFrame(childFrame, display: false)
            window.addChildWindow(childWindow, ordered: .below)
        }

        resetDragState()
    }

    func frame(in bounds: NSRect) -> NSRect {
        switch orientation {
        case .horizontal:
            let topY = bounds.maxY - horizontalYOffset
            let bottomY = topY - length
            let firstX = bounds.maxX
                - horizontalXOffset
                - CGFloat(lineCount - 1) * lineSpacing
                - 1

            return NSRect(
                x: firstX - backgroundPadding,
                y: bottomY - backgroundPadding,
                width: CGFloat(lineCount - 1) * lineSpacing + 2 + (backgroundPadding * 2),
                height: length + (backgroundPadding * 2)
            )
        case .vertical:
            let rightX = bounds.minX + verticalXOffset + length
            let leftX = rightX - length
            let firstY = bounds.minY + verticalYOffset + 1

            return NSRect(
                x: leftX - backgroundPadding,
                y: firstY - 1 - backgroundPadding,
                width: length + (backgroundPadding * 2),
                height: CGFloat(lineCount - 1) * lineSpacing + 2 + (backgroundPadding * 2)
            )
        }
    }

    private func drawBackground() {
        let path = NSBezierPath(
            roundedRect: bounds,
            xRadius: backgroundBorderRadius,
            yRadius: backgroundBorderRadius
        )

        color.fill.setFill()
        path.fill()
    }

    private func drawGripLines() {
        switch orientation {
        case .horizontal:
            for index in 0..<lineCount {
                let x = backgroundPadding + CGFloat(index) * lineSpacing
                strokeLine(
                    from: CGPoint(x: x + 0.5, y: backgroundPadding),
                    to: CGPoint(x: x + 0.5, y: bounds.maxY - backgroundPadding),
                    color: color.resizeHandleLight
                )
                strokeLine(
                    from: CGPoint(x: x + 1.5, y: backgroundPadding),
                    to: CGPoint(x: x + 1.5, y: bounds.maxY - backgroundPadding),
                    color: color.resizeHandleShadow
                )
            }
        case .vertical:
            for index in 0..<lineCount {
                let y = backgroundPadding + 1 + CGFloat(index) * lineSpacing
                strokeLine(
                    from: CGPoint(x: backgroundPadding, y: y + 0.5),
                    to: CGPoint(x: bounds.maxX - backgroundPadding, y: y + 0.5),
                    color: color.resizeHandleLight
                )
                strokeLine(
                    from: CGPoint(x: backgroundPadding, y: y - 0.5),
                    to: CGPoint(x: bounds.maxX - backgroundPadding, y: y - 0.5),
                    color: color.resizeHandleShadow
                )
            }
        }
    }

    private func strokeLine(from start: CGPoint, to end: CGPoint, color: NSColor) {
        let path = NSBezierPath()
        path.lineWidth = 1
        path.move(to: start)
        path.line(to: end)

        color.setStroke()
        path.stroke()
    }

    private func resetDragState() {
        dragInitialMouseLocation = nil
        dragInitialWindowFrame = nil
        wasMovableByWindowBackgroundBeforeDrag = nil
        childWindowFramesBeforeDrag = []
    }

}

private func screenLocation(for event: NSEvent, in window: NSWindow) -> NSPoint {
    return window.convertPoint(toScreen: event.locationInWindow)
}

func resizedRulerFrame(
    orientation: Orientation,
    initialFrame: NSRect,
    delta: NSSize,
    minSize: NSSize,
    maxSize: NSSize
) -> NSRect {
    switch orientation {
    case .horizontal:
        let width = clamp(initialFrame.width + delta.width, minSize.width, maxSize.width)
        return NSRect(
            x: initialFrame.minX,
            y: initialFrame.minY,
            width: width,
            height: initialFrame.height
        )
    case .vertical:
        let height = clamp(initialFrame.height - delta.height, minSize.height, maxSize.height)
        return NSRect(
            x: initialFrame.minX,
            y: initialFrame.maxY - height,
            width: initialFrame.width,
            height: height
        )
    }
}

private func clamp(_ value: CGFloat, _ minValue: CGFloat, _ maxValue: CGFloat) -> CGFloat {
    return min(max(value, minValue), maxValue)
}

func windowResizeCursor(for orientation: Orientation) -> NSCursor {
    switch orientation {
    case .horizontal:
        return ResizeHandleCursor.horizontal
    case .vertical:
        return ResizeHandleCursor.vertical
    }
}

private enum ResizeHandleCursor {
    struct Parameters {
        var arrowHeight: CGFloat = 13
        var arrowWidth: CGFloat = 5
        var arrowStroke: CGFloat = 2
        var shaftHeight: CGFloat = 4
        var shaftWidth: CGFloat = 7
        var arrowOffset: CGFloat = 0
    }

    static let horizontal = NSCursor(
        image: image(for: .horizontal, parameters: parameters),
        hotSpot: hotSpot(for: parameters)
    )
    static let vertical = NSCursor(
        image: image(for: .vertical, parameters: parameters),
        hotSpot: hotSpot(for: parameters)
    )

    private static let parameters = Parameters()

    static func image(for orientation: Orientation, parameters: Parameters) -> NSImage {
        let image = NSImage(size: imageSize(for: parameters))

        image.lockFocus()
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: image.size).fill()

        let outlinePath = cursorBodyPath(for: orientation, parameters: parameters)
        NSColor.white.setFill()
        NSColor.white.setStroke()
        outlinePath.lineWidth = parameters.arrowStroke * 2
        outlinePath.lineJoinStyle = .miter
        outlinePath.lineCapStyle = .square
        outlinePath.stroke()
        outlinePath.fill()

        let bodyPath = cursorBodyPath(for: orientation, parameters: parameters)
        NSColor.black.setFill()
        bodyPath.fill()

        image.unlockFocus()
        image.isTemplate = false

        return image
    }

    static func imageSize(for parameters: Parameters) -> NSSize {
        let arrowExtent = parameters.arrowWidth + parameters.arrowOffset
        let width = (arrowExtent * 2) + parameters.shaftWidth + (parameters.arrowStroke * 2)
        let height = max(parameters.arrowHeight, parameters.shaftHeight) + (parameters.arrowStroke * 2)

        return NSSize(width: ceil(width), height: ceil(height))
    }

    static func hotSpot(for parameters: Parameters) -> NSPoint {
        let size = imageSize(for: parameters)

        return NSPoint(x: floor(size.width / 2), y: floor(size.height / 2))
    }

    private static func cursorBodyPath(for orientation: Orientation, parameters: Parameters) -> NSBezierPath {
        let size = imageSize(for: parameters)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let arrowExtent = parameters.arrowWidth + parameters.arrowOffset
        let shaftHalfWidth = parameters.shaftWidth / 2
        let arrowHalfHeight = parameters.arrowHeight / 2
        let shaftHalfHeight = parameters.shaftHeight / 2

        switch orientation {
        case .horizontal:
            return closedPath([
                CGPoint(x: center.x - shaftHalfWidth - arrowExtent, y: center.y),
                CGPoint(x: center.x - shaftHalfWidth - parameters.arrowOffset, y: center.y - arrowHalfHeight),
                CGPoint(x: center.x - shaftHalfWidth - parameters.arrowOffset, y: center.y - shaftHalfHeight),
                CGPoint(x: center.x + shaftHalfWidth + parameters.arrowOffset, y: center.y - shaftHalfHeight),
                CGPoint(x: center.x + shaftHalfWidth + parameters.arrowOffset, y: center.y - arrowHalfHeight),
                CGPoint(x: center.x + shaftHalfWidth + arrowExtent, y: center.y),
                CGPoint(x: center.x + shaftHalfWidth + parameters.arrowOffset, y: center.y + arrowHalfHeight),
                CGPoint(x: center.x + shaftHalfWidth + parameters.arrowOffset, y: center.y + shaftHalfHeight),
                CGPoint(x: center.x - shaftHalfWidth - parameters.arrowOffset, y: center.y + shaftHalfHeight),
                CGPoint(x: center.x - shaftHalfWidth - parameters.arrowOffset, y: center.y + arrowHalfHeight),
            ])
        case .vertical:
            return closedPath([
                CGPoint(x: center.x, y: center.y - shaftHalfWidth - arrowExtent),
                CGPoint(x: center.x + arrowHalfHeight, y: center.y - shaftHalfWidth - parameters.arrowOffset),
                CGPoint(x: center.x + shaftHalfHeight, y: center.y - shaftHalfWidth - parameters.arrowOffset),
                CGPoint(x: center.x + shaftHalfHeight, y: center.y + shaftHalfWidth + parameters.arrowOffset),
                CGPoint(x: center.x + arrowHalfHeight, y: center.y + shaftHalfWidth + parameters.arrowOffset),
                CGPoint(x: center.x, y: center.y + shaftHalfWidth + arrowExtent),
                CGPoint(x: center.x - arrowHalfHeight, y: center.y + shaftHalfWidth + parameters.arrowOffset),
                CGPoint(x: center.x - shaftHalfHeight, y: center.y + shaftHalfWidth + parameters.arrowOffset),
                CGPoint(x: center.x - shaftHalfHeight, y: center.y - shaftHalfWidth - parameters.arrowOffset),
                CGPoint(x: center.x - arrowHalfHeight, y: center.y - shaftHalfWidth - parameters.arrowOffset),
            ])
        }
    }

    private static func closedPath(_ points: [CGPoint]) -> NSBezierPath {
        let path = NSBezierPath()
        guard let firstPoint = points.first else { return path }

        path.move(to: firstPoint)
        for point in points.dropFirst() {
            path.line(to: point)
        }
        path.close()
        return path
    }
}

private func resizeHandleAccessibilityIdentifier(for orientation: Orientation) -> String {
    switch orientation {
    case .horizontal:
        return "horizontal-resize-handle"
    case .vertical:
        return "vertical-resize-handle"
    }
}

#if DEBUG
private struct ResizeHandleCursorPreview: View {
    @State private var arrowHeight = 13.0
    @State private var arrowWidth = 5.0
    @State private var arrowStroke = 2.0
    @State private var shaftHeight = 4.0
    @State private var shaftWidth = 7.0
    @State private var arrowOffset = 0.0

    private var parameters: ResizeHandleCursor.Parameters {
        ResizeHandleCursor.Parameters(
            arrowHeight: CGFloat(arrowHeight),
            arrowWidth: CGFloat(arrowWidth),
            arrowStroke: CGFloat(arrowStroke),
            shaftHeight: CGFloat(shaftHeight),
            shaftWidth: CGFloat(shaftWidth),
            arrowOffset: CGFloat(arrowOffset)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 24) {
                previewImage(
                    image: ResizeHandleCursor.image(for: .horizontal, parameters: parameters),
                    title: "Custom Horizontal"
                )
                previewImage(
                    image: ResizeHandleCursor.image(for: .vertical, parameters: parameters),
                    title: "Custom Vertical"
                )
            }

            HStack(alignment: .top, spacing: 24) {
                privateCursorPreview(for: .horizontal)
                privateCursorPreview(for: .vertical)
            }

            VStack(spacing: 10) {
                slider("arrowHeight", value: $arrowHeight, range: 6...18)
                slider("arrowWidth", value: $arrowWidth, range: 2...10)
                slider("arrowStroke", value: $arrowStroke, range: 0.5...4)
                slider("shaftHeight", value: $shaftHeight, range: 1...8)
                slider("shaftWidth", value: $shaftWidth, range: 2...14)
                slider("arrowOffset", value: $arrowOffset, range: -2...4)
            }
        }
        .padding()
        .frame(width: 720)
    }

    private func previewImage(image: NSImage, title: String) -> some View {
        VStack(spacing: 8) {
            Image(nsImage: image)
                .interpolation(.none)
                .resizable()
                .frame(width: image.size.width * 8, height: image.size.height * 8)
                .padding(20)
                .background(Color(red: 0.25, green: 0.49, blue: 0.46))

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func privateCursorPreview(for orientation: Orientation) -> some View {
        if let cursor = privateWindowResizeCursor(for: orientation) {
            previewImage(
                image: cursor.image,
                title: previewTitle(for: orientation, prefix: "Private")
            )
        } else {
            VStack(spacing: 8) {
                Text("Unavailable")
                    .font(.caption.monospaced())
                    .frame(width: 130, height: 80)
                    .background(Color(red: 0.25, green: 0.49, blue: 0.46))

                Text(previewTitle(for: orientation, prefix: "Private"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text(title)
                .font(.caption.monospaced())
                .frame(width: 120, alignment: .leading)
            Slider(value: value, in: range, step: 0.5)
                .frame(minWidth: 420)
            Text(String(format: "%.1f", value.wrappedValue))
                .font(.caption.monospacedDigit())
                .frame(width: 48, alignment: .trailing)
        }
    }

    private func previewTitle(for orientation: Orientation, prefix: String) -> String {
        switch orientation {
        case .horizontal:
            return "\(prefix) Horizontal"
        case .vertical:
            return "\(prefix) Vertical"
        }
    }
}

private func privateWindowResizeCursor(for orientation: Orientation) -> NSCursor? {
    let selectorName: String
    switch orientation {
    case .horizontal:
        selectorName = "_windowResizeEastWestCursor"
    case .vertical:
        selectorName = "_windowResizeNorthSouthCursor"
    }

    let selector = NSSelectorFromString(selectorName)
    guard NSCursor.responds(to: selector),
          let unmanagedCursor = NSCursor.perform(selector) else {
        return nil
    }

    return unmanagedCursor.takeUnretainedValue() as? NSCursor
}

struct ResizeHandleCursor_Previews: PreviewProvider {
    static var previews: some View {
        ResizeHandleCursorPreview()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Resize Handle Cursor")
    }
}
#endif
