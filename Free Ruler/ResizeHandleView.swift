import Cocoa

#if DEBUG
import SwiftUI
#endif

final class ResizeHandleView: NSView {

    var color: RulerColors
    var zeroCorner = prefs.zeroCorner {
        didSet {
            needsDisplay = true
        }
    }

    private let orientation: Orientation
    private var trackingArea: NSTrackingArea?
    private var dragInitialMouseLocation: NSPoint?
    private var dragInitialWindowFrame: NSRect?
    private var wasMovableByWindowBackgroundBeforeDrag: Bool?
    private var childWindowFramesBeforeDrag: [(window: NSWindow, frame: NSRect)] = []
    private var mouseTicksSuspendedDuringResize = false

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

        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(rect: gripClipRect(in: bounds)).addClip()
        drawBackground()
        drawGripLines()
        NSGraphicsContext.restoreGraphicsState()
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

    override func mouseExited(with event: NSEvent) {
        guard dragInitialMouseLocation == nil else { return }

        restoreRulerCursor(with: event)
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        return rulerContextMenu(for: self)
    }

    override var mouseDownCanMoveWindow: Bool {
        return false
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    override func mouseDown(with event: NSEvent) {
        guard let window = window else { return }

        suspendMouseTicksDuringResize()
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
            zeroCorner: zeroCorner,
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
        defer {
            resumeMouseTicksAfterResize(with: event)
        }

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
        restoreRulerCursor(with: event)
        if contains(event) {
            windowResizeCursor(for: orientation).set()
        }
    }

    func frame(in bounds: NSRect) -> NSRect {
        return frame(in: bounds, zeroCorner: zeroCorner)
    }

    func frame(in bounds: NSRect, zeroCorner: ZeroCorner) -> NSRect {
        let placement = ZeroCornerGeometry(zeroCorner: zeroCorner)
            .resizeHandlePlacement(for: orientation)
        let gripFrame = gripFrame(in: bounds, placement: placement)

        return slotFrame(for: gripFrame, in: bounds, placement: placement)
    }

    private func gripFrame(in bounds: NSRect, placement: RulerCornerPlacement) -> NSRect {
        switch orientation {
        case .horizontal:
            let bottomY: CGFloat
            let firstX: CGFloat

            switch placement.xSide {
            case .left:
                firstX = bounds.minX + horizontalXOffset + 1
            case .right:
                firstX = bounds.maxX
                    - horizontalXOffset
                    - CGFloat(lineCount - 1) * lineSpacing
                    - 1
            }

            switch placement.ySide {
            case .top:
                bottomY = bounds.maxY - horizontalYOffset - length
            case .bottom:
                bottomY = bounds.minY + horizontalYOffset
            }

            return NSRect(
                x: firstX - backgroundPadding,
                y: bottomY - backgroundPadding,
                width: CGFloat(lineCount - 1) * lineSpacing + 2 + (backgroundPadding * 2),
                height: length + (backgroundPadding * 2)
            )
        case .vertical:
            let leftX: CGFloat
            let firstY: CGFloat

            switch placement.xSide {
            case .left:
                leftX = bounds.minX + verticalXOffset
            case .right:
                leftX = bounds.maxX - verticalXOffset - length
            }

            switch placement.ySide {
            case .top:
                firstY = bounds.maxY
                    - verticalYOffset
                    - CGFloat(lineCount - 1) * lineSpacing
                    - 1
            case .bottom:
                firstY = bounds.minY + verticalYOffset + 1
            }

            return NSRect(
                x: leftX - backgroundPadding,
                y: firstY - 1 - backgroundPadding,
                width: length + (backgroundPadding * 2),
                height: CGFloat(lineCount - 1) * lineSpacing + 2 + (backgroundPadding * 2)
            )
        }
    }

    private func slotFrame(
        for gripFrame: NSRect,
        in bounds: NSRect,
        placement: RulerCornerPlacement
    ) -> NSRect {
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let height: CGFloat

        switch orientation {
        case .horizontal:
            switch placement.xSide {
            case .left:
                x = bounds.minX
                width = gripFrame.maxX - bounds.minX
            case .right:
                x = gripFrame.minX
                width = bounds.maxX - gripFrame.minX
            }
        case .vertical:
            x = bounds.minX
            width = bounds.width
        }

        switch orientation {
        case .horizontal:
            y = bounds.minY
            height = bounds.height
        case .vertical:
            switch placement.ySide {
            case .top:
                y = gripFrame.minY
                height = bounds.maxY - gripFrame.minY
            case .bottom:
                y = bounds.minY
                height = gripFrame.maxY - bounds.minY
            }
        }

        return NSRect(x: x, y: y, width: width, height: height)
    }

    private func drawBackground() {
        let gripRect = gripRect(in: bounds)
        let path = NSBezierPath(
            roundedRect: gripRect,
            xRadius: backgroundBorderRadius,
            yRadius: backgroundBorderRadius
        )

        color.fill.setFill()
        path.fill()
    }

    private func drawGripLines() {
        let gripRect = gripRect(in: bounds)

        switch orientation {
        case .horizontal:
            for index in 0..<lineCount {
                let x = gripRect.minX + backgroundPadding + CGFloat(index) * lineSpacing
                strokeLine(
                    from: CGPoint(x: x + 0.5, y: gripRect.minY + backgroundPadding),
                    to: CGPoint(x: x + 0.5, y: gripRect.maxY - backgroundPadding),
                    color: color.resizeHandleLight
                )
                strokeLine(
                    from: CGPoint(x: x + 1.5, y: gripRect.minY + backgroundPadding),
                    to: CGPoint(x: x + 1.5, y: gripRect.maxY - backgroundPadding),
                    color: color.resizeHandleShadow
                )
            }
        case .vertical:
            for index in 0..<lineCount {
                let y = gripRect.minY + backgroundPadding + 1 + CGFloat(index) * lineSpacing
                strokeLine(
                    from: CGPoint(x: gripRect.minX + backgroundPadding, y: y + 0.5),
                    to: CGPoint(x: gripRect.maxX - backgroundPadding, y: y + 0.5),
                    color: color.resizeHandleLight
                )
                strokeLine(
                    from: CGPoint(x: gripRect.minX + backgroundPadding, y: y - 0.5),
                    to: CGPoint(x: gripRect.maxX - backgroundPadding, y: y - 0.5),
                    color: color.resizeHandleShadow
                )
            }
        }
    }

    private func gripRect(in bounds: NSRect) -> NSRect {
        let placement = ZeroCornerGeometry(zeroCorner: zeroCorner)
            .resizeHandlePlacement(for: orientation)
        let gripSize = self.gripSize()
        let x: CGFloat
        let y: CGFloat

        switch orientation {
        case .horizontal:
            switch placement.xSide {
            case .left:
                x = bounds.maxX - gripSize.width
            case .right:
                x = bounds.minX
            }

            switch placement.ySide {
            case .top:
                y = bounds.maxY
                    - horizontalYOffset
                    - length
                    - backgroundPadding
            case .bottom:
                y = bounds.minY + horizontalYOffset - backgroundPadding
            }
        case .vertical:
            switch placement.xSide {
            case .left:
                x = bounds.minX + verticalXOffset - backgroundPadding
            case .right:
                x = bounds.maxX
                    - verticalXOffset
                    - length
                    - backgroundPadding
            }

            switch placement.ySide {
            case .top:
                y = bounds.minY
            case .bottom:
                y = bounds.maxY - gripSize.height
            }
        }

        return NSRect(origin: NSPoint(x: x, y: y), size: gripSize)
    }

    private func gripClipRect(in bounds: NSRect) -> NSRect {
        let placement = ZeroCornerGeometry(zeroCorner: zeroCorner)
            .resizeHandlePlacement(for: orientation)
        let gripRect = self.gripRect(in: bounds)

        switch orientation {
        case .horizontal:
            switch placement.ySide {
            case .top:
                return NSRect(
                    x: bounds.minX,
                    y: gripRect.minY,
                    width: bounds.width,
                    height: bounds.maxY - gripRect.minY
                )
            case .bottom:
                return NSRect(
                    x: bounds.minX,
                    y: bounds.minY,
                    width: bounds.width,
                    height: gripRect.maxY - bounds.minY
                )
            }
        case .vertical:
            switch placement.xSide {
            case .left:
                return NSRect(
                    x: bounds.minX,
                    y: bounds.minY,
                    width: gripRect.maxX - bounds.minX,
                    height: bounds.height
                )
            case .right:
                return NSRect(
                    x: gripRect.minX,
                    y: bounds.minY,
                    width: bounds.maxX - gripRect.minX,
                    height: bounds.height
                )
            }
        }
    }

    private func gripSize() -> NSSize {
        switch orientation {
        case .horizontal:
            return NSSize(
                width: CGFloat(lineCount - 1) * lineSpacing + 2 + (backgroundPadding * 2),
                height: length + (backgroundPadding * 2)
            )
        case .vertical:
            return NSSize(
                width: length + (backgroundPadding * 2),
                height: CGFloat(lineCount - 1) * lineSpacing + 2 + (backgroundPadding * 2)
            )
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

    private func suspendMouseTicksDuringResize() {
        #if !SNAPSHOT_GENERATOR
        guard !mouseTicksSuspendedDuringResize else { return }

        appDelegate?.suppressMouseTickDrawing(owner: self)
        appDelegate?.suspendMouseTickUpdates(owner: self)
        mouseTicksSuspendedDuringResize = true
        #endif
    }

    private func resumeMouseTicksAfterResize(with event: NSEvent) {
        #if !SNAPSHOT_GENERATOR
        guard mouseTicksSuspendedDuringResize else { return }

        mouseTicksSuspendedDuringResize = false
        appDelegate?.resumeMouseTickUpdates(owner: self)
        appDelegate?.unsuppressMouseTickDrawing(owner: self)
        #endif
    }

    private func restoreRulerCursor(with event: NSEvent) {
        guard let superview = superview else { return }

        let locationInSuperview = superview.convert(event.locationInWindow, from: nil)
        if superview.bounds.contains(locationInSuperview) {
            nextResponder?.mouseEntered(with: event)
        } else {
            nextResponder?.mouseExited(with: event)
        }
    }

    private func contains(_ event: NSEvent) -> Bool {
        let locationInView = convert(event.locationInWindow, from: nil)
        return bounds.contains(locationInView)
    }

#if !SNAPSHOT_GENERATOR
    private var appDelegate: AppDelegate? {
        return NSApp.delegate as? AppDelegate
    }
#endif

}

private func screenLocation(for event: NSEvent, in window: NSWindow) -> NSPoint {
    return window.convertPoint(toScreen: event.locationInWindow)
}

func resizedRulerFrame(
    orientation: Orientation,
    zeroCorner: ZeroCorner = .topLeft,
    initialFrame: NSRect,
    delta: NSSize,
    minSize: NSSize,
    maxSize: NSSize
) -> NSRect {
    let geometry = ZeroCornerGeometry(zeroCorner: zeroCorner)

    switch orientation {
    case .horizontal:
        switch geometry.horizontalResizeSide {
        case .left:
            let width = clamp(initialFrame.width - delta.width, minSize.width, maxSize.width)
            return NSRect(
                x: initialFrame.maxX - width,
                y: initialFrame.minY,
                width: width,
                height: initialFrame.height
            )
        case .right:
            let width = clamp(initialFrame.width + delta.width, minSize.width, maxSize.width)
            return NSRect(
                x: initialFrame.minX,
                y: initialFrame.minY,
                width: width,
                height: initialFrame.height
            )
        }
    case .vertical:
        switch geometry.verticalResizeSide {
        case .top:
            let height = clamp(initialFrame.height + delta.height, minSize.height, maxSize.height)
            return NSRect(
                x: initialFrame.minX,
                y: initialFrame.minY,
                width: initialFrame.width,
                height: height
            )
        case .bottom:
            let height = clamp(initialFrame.height - delta.height, minSize.height, maxSize.height)
            return NSRect(
                x: initialFrame.minX,
                y: initialFrame.maxY - height,
                width: initialFrame.width,
                height: height
            )
        }
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
        var arrowHeight: CGFloat = 7
        var arrowWidth: CGFloat = 3.5
        var arrowStroke: CGFloat = 1
        var shaftHeight: CGFloat = 2
        var shaftWidth: CGFloat = 7
        var arrowOffset: CGFloat = -0.5
        var miterLimit: CGFloat = 10
        var shadowAlpha: CGFloat = 0.45
        var shadowBlur: CGFloat = 2
        var shadowOffsetX: CGFloat = 0
        var shadowOffsetY: CGFloat = -1.5
        var shadowPadding: CGFloat = 3
    }

    static let horizontal = NSCursor(
        image: image(for: .horizontal, parameters: parameters),
        hotSpot: hotSpot(for: .horizontal, parameters: parameters)
    )
    static let vertical = NSCursor(
        image: image(for: .vertical, parameters: parameters),
        hotSpot: hotSpot(for: .vertical, parameters: parameters)
    )

    private static let parameters = Parameters()

    static func image(for orientation: Orientation, parameters: Parameters) -> NSImage {
        let image = NSImage(size: imageSize(for: orientation, parameters: parameters))

        image.lockFocus()
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: image.size).fill()

        let outlinePath = cursorBodyPath(for: orientation, parameters: parameters)
        outlinePath.lineWidth = parameters.arrowStroke * 2
        outlinePath.lineJoinStyle = .miter
        outlinePath.miterLimit = parameters.miterLimit
        outlinePath.lineCapStyle = .square

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(parameters.shadowAlpha)
        shadow.shadowBlurRadius = parameters.shadowBlur
        shadow.shadowOffset = NSSize(width: parameters.shadowOffsetX, height: parameters.shadowOffsetY)
        shadow.set()
        NSColor.white.setFill()
        NSColor.white.setStroke()
        outlinePath.stroke()
        outlinePath.fill()
        NSGraphicsContext.restoreGraphicsState()

        NSColor.white.setFill()
        NSColor.white.setStroke()
        outlinePath.stroke()
        outlinePath.fill()

        let bodyPath = cursorBodyPath(for: orientation, parameters: parameters)
        NSColor.black.setFill()
        bodyPath.fill()

        image.unlockFocus()
        image.isTemplate = false

        return image
    }

    static func imageSize(for orientation: Orientation, parameters: Parameters) -> NSSize {
        let arrowExtent = parameters.arrowWidth + parameters.arrowOffset
        let shadowInset = parameters.shadowPadding * 2
        let length = (arrowExtent * 2) + parameters.shaftWidth + (parameters.arrowStroke * 2) + shadowInset
        let thickness = max(parameters.arrowHeight, parameters.shaftHeight) + (parameters.arrowStroke * 2) + shadowInset

        switch orientation {
        case .horizontal:
            return NSSize(width: ceil(length), height: ceil(thickness))
        case .vertical:
            return NSSize(width: ceil(thickness), height: ceil(length))
        }
    }

    static func hotSpot(for orientation: Orientation, parameters: Parameters) -> NSPoint {
        let size = imageSize(for: orientation, parameters: parameters)

        return NSPoint(x: floor(size.width / 2), y: floor(size.height / 2))
    }

    private static func cursorBodyPath(for orientation: Orientation, parameters: Parameters) -> NSBezierPath {
        let size = imageSize(for: orientation, parameters: parameters)
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
    @State private var arrowHeight = 7.5
    @State private var arrowWidth = 3.5
    @State private var arrowStroke = 1.0
    @State private var shaftHeight = 2.0
    @State private var shaftWidth = 7.0
    @State private var arrowOffset = -0.5
    @State private var miterLimit = 10.0
    @State private var shadowAlpha = 0.45
    @State private var shadowBlur = 2.0
    @State private var shadowOffsetX = 0.0
    @State private var shadowOffsetY = -1.5
    @State private var shadowPadding = 3.0

    private var parameters: ResizeHandleCursor.Parameters {
        ResizeHandleCursor.Parameters(
            arrowHeight: CGFloat(arrowHeight),
            arrowWidth: CGFloat(arrowWidth),
            arrowStroke: CGFloat(arrowStroke),
            shaftHeight: CGFloat(shaftHeight),
            shaftWidth: CGFloat(shaftWidth),
            arrowOffset: CGFloat(arrowOffset),
            miterLimit: CGFloat(miterLimit),
            shadowAlpha: CGFloat(shadowAlpha),
            shadowBlur: CGFloat(shadowBlur),
            shadowOffsetX: CGFloat(shadowOffsetX),
            shadowOffsetY: CGFloat(shadowOffsetY),
            shadowPadding: CGFloat(shadowPadding)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 18) {
                previewImage(
                    image: ResizeHandleCursor.image(for: .horizontal, parameters: parameters),
                    title: "Custom Horizontal"
                )
                previewImage(
                    image: ResizeHandleCursor.image(for: .vertical, parameters: parameters),
                    title: "Custom Vertical"
                )
            }

            HStack(alignment: .top, spacing: 18) {
                privateCursorPreview(for: .horizontal)
                privateCursorPreview(for: .vertical)
            }

            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 8) {
                    slider("arrowHeight", value: $arrowHeight, range: 6...18)
                    slider("arrowWidth", value: $arrowWidth, range: 2...10)
                    slider("arrowStroke", value: $arrowStroke, range: 0.5...4)
                    slider("shaftHeight", value: $shaftHeight, range: 1...8)
                    slider("shaftWidth", value: $shaftWidth, range: 2...14)
                    slider("arrowOffset", value: $arrowOffset, range: -2...4)
                }

                VStack(spacing: 8) {
                    slider("miterLimit", value: $miterLimit, range: 1...20)
                    slider("shadowAlpha", value: $shadowAlpha, range: 0...1)
                    slider("shadowBlur", value: $shadowBlur, range: 0...6)
                    slider("shadowOffsetX", value: $shadowOffsetX, range: -4...4)
                    slider("shadowOffsetY", value: $shadowOffsetY, range: -4...4)
                    slider("shadowPadding", value: $shadowPadding, range: 0...8)
                }
            }
        }
        .padding(12)
        .frame(width: 560)
    }

    private func previewImage(image: NSImage, title: String) -> some View {
        VStack(spacing: 8) {
            Image(nsImage: image)
                .interpolation(.none)
                .resizable()
                .frame(width: image.size.width * 6, height: image.size.height * 6)
                .padding(12)
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
            VStack(spacing: 0) {
                Text(verbatim: "Unavailable")
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
        HStack(spacing: 6) {
            Text(title)
                .font(.caption.monospaced())
                .frame(width: 104, alignment: .leading)
            Slider(value: value, in: range, step: 0.1)
                .frame(width: 110)
            Text(String(format: "%.1f", value.wrappedValue))
                .font(.caption.monospacedDigit())
                .frame(width: 38, alignment: .trailing)
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
            .previewLayout(.fixed(width: 560, height: 600))
    }
}
#endif
