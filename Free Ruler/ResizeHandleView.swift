import Cocoa

final class ResizeHandleView: NSView {

    private let color: RulerColors
    private let orientation: Orientation

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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init(orientation:color:)")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        drawBackground()
        drawGripLines()
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

}
