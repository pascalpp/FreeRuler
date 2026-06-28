import Cocoa

class HorizontalRule: RuleView {

    let transformer = AffineTransform(translationByX: 0.5, byY: 0)
    let mouseTickTransformer = AffineTransform(translationByX: -0.5, byY: 0)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        installUnitLabel(for: .horizontal)
        installResizeHandle(for: .horizontal)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        installUnitLabel(for: .horizontal)
        installResizeHandle(for: .horizontal)
    }

    var mouseTickX: CGFloat = 0 {
        didSet {
            if mouseTickX != oldValue {
                updateResizeHandleVisibility()
                updateUnitLabelVisibility()
                needsDisplay = true
            }
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        if drawsBackground {
            color.fill.setFill()
            dirtyRect.fill()
        }

        let attrs = labelAttributes(alignment: .center, foregroundColor: color.numbers)

        let width = bounds.width
        let height = bounds.height
        let path = NSBezierPath()
        let tickLayout = RulerTickLayout(unit: unit, screen: screen)
        let geometry = ZeroCornerGeometry(zeroCorner: zeroCorner)
        let tickSide = geometry.horizontalTickSide
        let growthDirection = geometry.growthDirection(for: .horizontal)

        let labelWidth: CGFloat = 50
        let labelHeight: CGFloat = 20
        // TODO: refactor this to use measured label sizes.

        // substract two so ticks don't overlap with border
        // subtract from this range so width var is accurate
        for i in 1...Int((width - 2) / tickLayout.tickScale) {
            let offset = CGFloat(i) * tickLayout.tickScale
            let pos = tickX(
                forOffset: offset,
                rulerWidth: width,
                growthDirection: growthDirection
            )
            if i.isMultiple(of: tickLayout.largeTicks) {
                let tickLine = tickLine(forX: pos, length: 10, rulerHeight: height, tickSide: tickSide)
                path.move(to: tickLine.start)
                path.line(to: tickLine.end)

                let label = String(i / tickLayout.textScale)
                let labelRect = tickLabelRect(
                    forX: pos,
                    labelSize: NSSize(width: labelWidth, height: labelHeight),
                    rulerHeight: height,
                    tickSide: tickSide
                )

                label.draw(
                    with: labelRect,
                    attributes: attrs,
                    context: nil
                )

            }
            else if i.isMultiple(of: tickLayout.mediumTicks) {
                let tickLine = tickLine(forX: pos, length: 8, rulerHeight: height, tickSide: tickSide)
                path.move(to: tickLine.start)
                path.line(to: tickLine.end)
            }
            else if i.isMultiple(of: tickLayout.smallTicks) {
                let tickLine = tickLine(forX: pos, length: 5, rulerHeight: height, tickSide: tickSide)
                path.move(to: tickLine.start)
                path.line(to: tickLine.end)
            }
            else if let tinyTicks = tickLayout.tinyTicks, i.isMultiple(of: tinyTicks) {
                let tickLine = tickLine(forX: pos, length: 3, rulerHeight: height, tickSide: tickSide)
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
        if showMouseTick && mouseTickX >= bounds.minX && mouseTickX <= bounds.maxX {
            drawMouseTick(mouseTickX)
            drawMouseNumber(mouseTickX)
        }

    }

    override func drawMouseTick(at mouseLoc: NSPoint) {
        guard let window = window else { return }

        let windowPoint = window.convertPoint(fromScreen: mouseLoc)
        let viewPoint = convert(windowPoint, from: nil)
        mouseTickX = mouseTickX(forLocalMouseX: viewPoint.x)
    }

    func mouseTickX(forLocalMouseX localMouseX: CGFloat) -> CGFloat {
        return localMouseX.rounded()
    }

    func drawMouseTick(_ mouseTickX: CGFloat) {
        let mouseTick = NSBezierPath()
        let height: CGFloat = 40
        let growthDirection = ZeroCornerGeometry(zeroCorner: zeroCorner).growthDirection(for: .horizontal)
        let lineX = mouseTickLineX(forTickX: mouseTickX, growthDirection: growthDirection)

        mouseTick.move(to: CGPoint(x: lineX, y: 0))
        mouseTick.line(to: CGPoint(x: lineX, y: height))

        mouseTick.transform(using: mouseTickTransformer)

        color.mouseTick.setStroke()
        mouseTick.stroke()
    }

    func drawZeroTick() {
        let geometry = ZeroCornerGeometry(zeroCorner: zeroCorner)
        let growthDirection = geometry.growthDirection(for: .horizontal)
        let zeroTickX: CGFloat

        switch growthDirection {
        case .positive:
            zeroTickX = bounds.minX
        case .negative:
            zeroTickX = bounds.maxX - 1
        }

        let lineX = mouseTickLineX(forTickX: zeroTickX, growthDirection: growthDirection)
        let tickLine = tickLine(
            forX: lineX,
            length: 10,
            rulerHeight: bounds.height,
            tickSide: geometry.horizontalTickSide
        )
        let path = NSBezierPath()

        path.move(to: tickLine.start)
        path.line(to: tickLine.end)
        path.transform(using: transformer)

        color.ticks.setStroke()
        path.stroke()
    }

    func drawMouseNumber(_ mouseTickX: CGFloat) {
        let number = mouseNumber(forTickX: mouseTickX, rulerWidth: self.frame.width)
        let width = self.frame.width
        let height = self.frame.height

        let attributes = labelAttributes(alignment: .center, foregroundColor: color.mouseNumber)

        let mouseNumber = self.getMouseNumberLabel(number)
        let label = NSAttributedString(string: mouseNumber, attributes: attributes)
        let labelSize = label.size()

        let labelRect = mouseNumberLabelRect(
            tickX: mouseTickX,
            labelSize: labelSize,
            rulerSize: CGSize(width: width, height: height)
        )

        guard NSGraphicsContext.current != nil else { return }
        label.draw(
            with: labelRect,
            context: nil
        )
    }

    func mouseNumberLabelRect(tickX: CGFloat, labelSize: CGSize, rulerSize: CGSize) -> CGRect {
        return MouseTickLabelLayout.labelFrame(
            labelSize: labelSize,
            rulerSize: rulerSize,
            orientation: .horizontal,
            zeroCorner: zeroCorner,
            tickPosition: tickX,
            resizeHandleFrame: resizeHandleExclusionFrame,
            unitLabelFrame: unitLabelFrame
        )
    }

    override func updateUnitLabelVisibility() {
        guard showMouseTick,
              mouseTickX >= bounds.minX,
              mouseTickX <= bounds.maxX,
              let frame = unitLabelFrame else {
            setUnitLabelHidden(false)
            return
        }

        setUnitLabelHidden(frame.minX <= mouseTickX && mouseTickX <= frame.maxX)
    }

    override func updateResizeHandleVisibility() {
        guard showMouseTick,
              mouseTickX >= bounds.minX,
              mouseTickX <= bounds.maxX,
              let frame = resizeHandleExclusionFrame else {
            setResizeHandleObscured(false)
            return
        }

        setResizeHandleObscured(frame.minX <= mouseTickX && mouseTickX <= frame.maxX)
    }

    func tickX(
        forOffset offset: CGFloat,
        rulerWidth: CGFloat,
        growthDirection: RulerGrowthDirection
    ) -> CGFloat {
        switch growthDirection {
        case .positive:
            return offset
        case .negative:
            // subtract 1 so first tick doesn't abut the border
            return rulerWidth - offset - 1
        }
    }

    func tickLine(
        forX x: CGFloat,
        length: CGFloat,
        rulerHeight: CGFloat,
        tickSide: RulerVerticalSide
    ) -> (start: CGPoint, end: CGPoint) {
        switch tickSide {
        case .bottom:
            return (CGPoint(x: x, y: 1), CGPoint(x: x, y: length))
        case .top:
            return (CGPoint(x: x, y: rulerHeight - 1), CGPoint(x: x, y: rulerHeight - length))
        }
    }

    func tickLabelRect(
        forX x: CGFloat,
        labelSize: NSSize,
        rulerHeight: CGFloat,
        tickSide: RulerVerticalSide
    ) -> CGRect {
        let labelOffset: CGFloat = 13
        let textHeight: CGFloat = 8
        let labelX: CGFloat = x - (labelSize.width / 2) + 0.5
        let labelY: CGFloat

        switch tickSide {
        case .bottom:
            labelY = labelOffset
        case .top:
            labelY = rulerHeight - labelOffset - textHeight
        }

        return CGRect(x: labelX, y: labelY, width: labelSize.width, height: labelSize.height)
    }

    func mouseNumber(forTickX mouseTickX: CGFloat, rulerWidth: CGFloat) -> CGFloat {
        let growthDirection = ZeroCornerGeometry(zeroCorner: zeroCorner).growthDirection(for: .horizontal)

        switch growthDirection {
        case .positive:
            return max(0, mouseTickX - 1)
        case .negative:
            return max(0, rulerWidth - mouseTickX)
        }
    }

    func mouseTickLineX(
        forTickX mouseTickX: CGFloat,
        growthDirection: RulerGrowthDirection
    ) -> CGFloat {
        switch growthDirection {
        case .positive:
            return mouseTickX
        case .negative:
            return mouseTickX
        }
    }

    func unitLabelRect(labelSize: NSSize, rulerSize: NSSize) -> CGRect {
        return UnitLabelView.labelFrame(
            labelSize: labelSize,
            rulerSize: rulerSize,
            orientation: .horizontal,
            zeroCorner: zeroCorner
        )
    }

}
