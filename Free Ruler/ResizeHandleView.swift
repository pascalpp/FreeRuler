import Cocoa

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
        childWindowFramesBeforeDrag = window.childWindows?.map { ($0, $0.frame) } ?? []

        window.isMovableByWindowBackground = false
        for childWindow in childWindowFramesBeforeDrag.map(\.window) {
            window.removeChildWindow(childWindow)
        }
        window.makeKey()
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

private func windowResizeCursor(for orientation: Orientation) -> NSCursor {
    // Public AppKit cursors keep App Store review safe. The private two-arrow
    // variants to revisit for non-App-Store builds are `_windowResizeEastWestCursor`
    // and `_windowResizeNorthSouthCursor`.
    switch orientation {
    case .horizontal:
        return .resizeLeftRight
    case .vertical:
        return .resizeUpDown
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
