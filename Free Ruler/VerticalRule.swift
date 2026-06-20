import Cocoa

class VerticalRule: RuleView {

    let transformer = AffineTransform(translationByX: 0, byY: -0.5)
    let mouseTickTransformer = AffineTransform(translationByX: 0, byY: 0.5)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        installUnitLabel(for: .vertical)
        installResizeHandle(for: .vertical)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        installUnitLabel(for: .vertical)
        installResizeHandle(for: .vertical)
    }

    var mouseTickY: CGFloat = 0 {
        didSet {
            if mouseTickY != oldValue {
                updateResizeHandleVisibility()
                updateUnitLabelVisibility()
                needsDisplay = true
            }
        }
    }

    var rulerWidth: CGFloat {
        return bounds.width
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        if drawsBackground {
            color.fill.setFill()
            dirtyRect.fill()
        }

        let width = rulerWidth
        let height = bounds.height
        let path = NSBezierPath()
        let tickLayout = RulerTickLayout(unit: unit, screen: screen)
        let geometry = ZeroCornerGeometry(zeroCorner: zeroCorner)
        let tickSide = geometry.verticalTickSide
        let growthDirection = geometry.growthDirection(for: .vertical)
        let attrs = labelAttributes(
            alignment: tickSide == .right ? .right : .left,
            foregroundColor: color.numbers
        )

        let labelWidth: CGFloat = 50
        let labelHeight: CGFloat = 20
        // TODO: refactor this to use measured label sizes.

        // substract two so ticks don't overlap with border
        // substract from this range so we can use the height var for position calculations
        for i in 1...Int((height - 2) / tickLayout.tickScale) {
            let offset = CGFloat(i) * tickLayout.tickScale
            let pos = tickY(
                forOffset: offset,
                rulerHeight: height,
                growthDirection: growthDirection
            )
            if i.isMultiple(of: tickLayout.largeTicks) {
                let tickLine = tickLine(forY: pos, length: 10, rulerWidth: width, tickSide: tickSide)
                path.move(to: tickLine.start)
                path.line(to: tickLine.end)

                let label = String(i / tickLayout.textScale)
                let labelRect = tickLabelRect(
                    forY: pos,
                    labelSize: NSSize(width: labelWidth, height: labelHeight),
                    rulerWidth: width,
                    tickSide: tickSide
                )

                label.draw(
                    with: labelRect,
                    attributes: attrs,
                    context: nil
                )

            }
            else if i.isMultiple(of: tickLayout.mediumTicks) {
                let tickLine = tickLine(forY: pos, length: 8, rulerWidth: width, tickSide: tickSide)
                path.move(to: tickLine.start)
                path.line(to: tickLine.end)
            }
            else if i.isMultiple(of: tickLayout.smallTicks) {
                let tickLine = tickLine(forY: pos, length: 5, rulerWidth: width, tickSide: tickSide)
                path.move(to: tickLine.start)
                path.line(to: tickLine.end)
            }
            else if let tinyTicks = tickLayout.tinyTicks, i.isMultiple(of: tinyTicks) {
                let tickLine = tickLine(forY: pos, length: 3, rulerWidth: width, tickSide: tickSide)
                path.move(to: tickLine.start)
                path.line(to: tickLine.end)
            }
        }

        path.transform(using: transformer)

        color.ticks.setStroke()
        path.stroke()

        if showsZeroTick {
            drawZeroTick()
        }

        updateUnitLabelVisibility()

        // Draw the MouseTick & number
        if showMouseTick && mouseTickY >= bounds.minY && mouseTickY <= bounds.maxY {
            drawMouseTick(mouseTickY)
            drawMouseNumber(mouseTickY)
        }
    }

    override func drawMouseTick(at mouseLoc: NSPoint) {
        guard let window = window else { return }

        let windowPoint = window.convertPoint(fromScreen: mouseLoc)
        let viewPoint = convert(windowPoint, from: nil)
        mouseTickY = mouseTickY(forLocalMouseY: viewPoint.y)
    }

    func mouseTickY(forLocalMouseY localMouseY: CGFloat) -> CGFloat {
        return localMouseY.rounded()
    }

    func drawMouseTick(_ mouseTickY: CGFloat) {
        let mouseTick = NSBezierPath()
        let startX: CGFloat = 0
        let growthDirection = ZeroCornerGeometry(zeroCorner: zeroCorner).growthDirection(for: .vertical)
        let lineY = mouseTickLineY(forTickY: mouseTickY, growthDirection: growthDirection)

        mouseTick.move(to: CGPoint(x: startX, y: lineY))
        mouseTick.line(to: CGPoint(x: rulerWidth, y: lineY))

        mouseTick.transform(using: mouseTickTransformer)

        color.mouseTick.setStroke()
        mouseTick.stroke()
    }

    func drawZeroTick() {
        let geometry = ZeroCornerGeometry(zeroCorner: zeroCorner)
        let growthDirection = geometry.growthDirection(for: .vertical)
        let zeroTickY: CGFloat

        switch growthDirection {
        case .positive:
            zeroTickY = bounds.minY + 1
        case .negative:
            zeroTickY = bounds.maxY
        }

        let lineY = mouseTickLineY(forTickY: zeroTickY, growthDirection: growthDirection)
        let tickLine = tickLine(
            forY: lineY,
            length: 10,
            rulerWidth: rulerWidth,
            tickSide: geometry.verticalTickSide
        )
        let path = NSBezierPath()

        path.move(to: tickLine.start)
        path.line(to: tickLine.end)
        path.transform(using: transformer)

        color.ticks.setStroke()
        path.stroke()
    }

    func drawMouseNumber(_ mouseTickY: CGFloat) {
        let height = self.frame.height
        let width = rulerWidth
        let number = mouseNumber(forTickY: mouseTickY, rulerHeight: height)

        let attributes = labelAttributes(alignment: .left, foregroundColor: color.mouseNumber)

        let mouseNumber = self.getMouseNumberLabel(number)
        let label = NSAttributedString(string: mouseNumber, attributes: attributes)
        let labelSize = label.size()

        let labelRect = mouseNumberLabelRect(
            tickY: mouseTickY,
            labelSize: labelSize,
            rulerSize: CGSize(width: width, height: height)
        )
        let backgroundRect = mouseNumberLabelBackgroundRect(
            tickY: mouseTickY,
            labelSize: labelSize,
            rulerSize: CGSize(width: width, height: height)
        )

        guard NSGraphicsContext.current != nil else { return }
        color.fill.setFill()
        backgroundRect.fill()

        label.draw(
            with: labelRect,
            options: .usesLineFragmentOrigin,
            context: nil
        )
    }

    func mouseNumberLabelRect(tickY: CGFloat, labelSize: CGSize, rulerSize: CGSize) -> CGRect {
        return MouseTickLabelLayout.labelFrame(
            labelSize: labelSize,
            rulerSize: rulerSize,
            orientation: .vertical,
            zeroCorner: zeroCorner,
            tickPosition: tickY,
            resizeHandleFrame: resizeHandleExclusionFrame,
            unitLabelFrame: unitLabelFrame
        )
    }

    func mouseNumberLabelBackgroundRect(tickY: CGFloat, labelSize: CGSize, rulerSize: CGSize) -> CGRect {
        return MouseTickLabelLayout.labelBackgroundFrame(
            labelSize: labelSize,
            rulerSize: rulerSize,
            orientation: .vertical,
            zeroCorner: zeroCorner,
            tickPosition: tickY,
            resizeHandleFrame: resizeHandleExclusionFrame,
            unitLabelFrame: unitLabelFrame
        )
    }

    override func updateUnitLabelVisibility() {
        guard showMouseTick,
              mouseTickY >= bounds.minY,
              mouseTickY <= bounds.maxY,
              let frame = unitLabelFrame else {
            setUnitLabelHidden(false)
            return
        }

        let number = mouseNumber(forTickY: mouseTickY, rulerHeight: bounds.height)
        let mouseNumber = getMouseNumberLabel(number)
        let attributes = labelAttributes(alignment: .left, foregroundColor: color.mouseNumber)
        let labelSize = NSAttributedString(string: mouseNumber, attributes: attributes).size()
        let backgroundRect = mouseNumberLabelBackgroundRect(
            tickY: mouseTickY,
            labelSize: labelSize,
            rulerSize: CGSize(width: rulerWidth, height: bounds.height)
        )

        setUnitLabelHidden(
            (frame.minY <= mouseTickY && mouseTickY <= frame.maxY)
                || frame.intersects(backgroundRect)
        )
    }

    override func updateResizeHandleVisibility() {
        guard showMouseTick,
              mouseTickY >= bounds.minY,
              mouseTickY <= bounds.maxY,
              let frame = resizeHandleExclusionFrame else {
            setResizeHandleObscured(false)
            return
        }

        setResizeHandleObscured(frame.minY <= mouseTickY && mouseTickY <= frame.maxY)
    }

    func tickY(
        forOffset offset: CGFloat,
        rulerHeight: CGFloat,
        growthDirection: RulerGrowthDirection
    ) -> CGFloat {
        switch growthDirection {
        case .positive:
            return offset + 1
        case .negative:
            return rulerHeight - offset
        }
    }

    func tickLine(
        forY y: CGFloat,
        length: CGFloat,
        rulerWidth: CGFloat,
        tickSide: RulerHorizontalSide
    ) -> (start: CGPoint, end: CGPoint) {
        switch tickSide {
        case .right:
            return (CGPoint(x: rulerWidth - 1, y: y), CGPoint(x: rulerWidth - length, y: y))
        case .left:
            return (CGPoint(x: 1, y: y), CGPoint(x: length, y: y))
        }
    }

    func tickLabelRect(
        forY y: CGFloat,
        labelSize: NSSize,
        rulerWidth: CGFloat,
        tickSide: RulerHorizontalSide
    ) -> CGRect {
        let labelOffset: CGFloat = 13
        let textHeight: CGFloat = 8
        let labelX: CGFloat

        switch tickSide {
        case .right:
            labelX = rulerWidth - labelSize.width - labelOffset
        case .left:
            labelX = labelOffset
        }

        return CGRect(
            x: labelX,
            y: y - (textHeight / 2),
            width: labelSize.width,
            height: labelSize.height
        )
    }

    func mouseNumber(forTickY mouseTickY: CGFloat, rulerHeight: CGFloat) -> CGFloat {
        let growthDirection = ZeroCornerGeometry(zeroCorner: zeroCorner).growthDirection(for: .vertical)

        switch growthDirection {
        case .positive:
            return mouseTickY
        case .negative:
            return max(0, rulerHeight - mouseTickY - 1)
        }
    }

    func mouseTickLineY(
        forTickY mouseTickY: CGFloat,
        growthDirection: RulerGrowthDirection
    ) -> CGFloat {
        switch growthDirection {
        case .positive:
            return mouseTickY
        case .negative:
            return mouseTickY
        }
    }

    func unitLabelRect(labelSize: NSSize, rulerSize: NSSize) -> CGRect {
        return UnitLabelView.labelFrame(
            labelSize: labelSize,
            rulerSize: rulerSize,
            orientation: .vertical,
            zeroCorner: zeroCorner
        )
    }


}
