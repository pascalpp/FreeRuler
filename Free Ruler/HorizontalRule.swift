import Cocoa

class HorizontalRule: RuleView {

    let transformer = AffineTransform(translationByX: 0.5, byY: 0)

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
                updateUnitLabelVisibility()
                needsDisplay = true
            }
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        color.fill.setFill()
        dirtyRect.fill()

        let attrs = labelAttributes(alignment: .center, foregroundColor: color.numbers)

        let width = dirtyRect.width
        let height = dirtyRect.height
        let path = NSBezierPath()
        let tickLayout = RulerTickLayout(unit: unit, screen: screen)
        let geometry = ZeroCornerGeometry(zeroCorner: prefs.zeroCorner)
        let tickSide = geometry.tickSide(for: .horizontal)
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

        updateUnitLabelVisibility()

        // Draw the MouseTick & number
        if showMouseTick && mouseTickX > 0 && mouseTickX < self.windowWidth {
            drawMouseTick(mouseTickX)
            drawMouseNumber(mouseTickX)
        }

    }

    override func drawMouseTick(at mouseLoc: NSPoint) {
        let windowX = self.window?.frame.origin.x ?? 0
        let mouseX = mouseLoc.x
        self.mouseTickX = mouseX - windowX
    }

    func drawMouseTick(_ mouseTickX: CGFloat) {
        let mouseTick = NSBezierPath()
        let height: CGFloat = 40

        mouseTick.move(to: CGPoint(x: mouseTickX, y: 0))
        mouseTick.line(to: CGPoint(x: mouseTickX, y: height))

        mouseTick.transform(using: transformer)

        color.mouseTick.setStroke()
        mouseTick.stroke()
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
            number: mouseTickX,
            labelSize: labelSize,
            rulerSize: CGSize(width: width, height: height)
        )

        label.draw(
            with: labelRect,
            context: nil
        )
    }

    func mouseNumberLabelRect(number: CGFloat, labelSize: CGSize, rulerSize: CGSize) -> CGRect {
        let labelOffset: CGFloat = 5
        let tickSide = ZeroCornerGeometry(zeroCorner: prefs.zeroCorner).tickSide(for: .horizontal)

        let rightPosition = number + labelOffset
        let leftPosition = number - labelOffset - labelSize.width
        var minLabelLeft = labelOffset
        var maxLabelRight = rulerSize.width - labelOffset

        if let resizeHandleExclusionFrame = resizeHandleExclusionFrame {
            if resizeHandleExclusionFrame.midX < rulerSize.width / 2 {
                minLabelLeft = max(
                    minLabelLeft,
                    resizeHandleExclusionFrame.maxX + mouseTickLabelResizeHandleSpacing
                )
            } else {
                maxLabelRight = min(
                    maxLabelRight,
                    resizeHandleExclusionFrame.minX - mouseTickLabelResizeHandleSpacing
                )
            }
        }

        let pinnedRightPosition = maxLabelRight - labelSize.width
        let rightLabelX = max(min(rightPosition, pinnedRightPosition), minLabelLeft)
        let leftLabelX = max(min(leftPosition, pinnedRightPosition), minLabelLeft)
        let labelX = number < rightLabelX ? rightLabelX : leftLabelX

        return CGRect(
            x: labelX,
            y: tickSide == .bottom ? rulerSize.height - labelSize.height : 0,
            width: labelSize.width,
            height: labelSize.height
        )
    }

    override func updateUnitLabelVisibility() {
        guard showMouseTick,
              mouseTickX > 0,
              mouseTickX < windowWidth,
              let frame = unitLabelFrame else {
            setUnitLabelHidden(false)
            return
        }

        setUnitLabelHidden(frame.minX <= mouseTickX && mouseTickX <= frame.maxX)
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
            return rulerWidth - offset
        }
    }

    func tickLine(
        forX x: CGFloat,
        length: CGFloat,
        rulerHeight: CGFloat,
        tickSide: RulerSide
    ) -> (start: CGPoint, end: CGPoint) {
        switch tickSide {
        case .bottom:
            return (CGPoint(x: x, y: 1), CGPoint(x: x, y: length))
        case .top:
            return (CGPoint(x: x, y: rulerHeight - 1), CGPoint(x: x, y: rulerHeight - length))
        case .left, .right:
            assertionFailure("Horizontal ruler ticks must be placed on a horizontal side")
            return (CGPoint(x: x, y: 1), CGPoint(x: x, y: length))
        }
    }

    func tickLabelRect(
        forX x: CGFloat,
        labelSize: NSSize,
        rulerHeight: CGFloat,
        tickSide: RulerSide
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
        case .left, .right:
            assertionFailure("Horizontal ruler labels must be placed on a horizontal side")
            labelY = labelOffset
        }

        return CGRect(x: labelX, y: labelY, width: labelSize.width, height: labelSize.height)
    }

    func mouseNumber(forTickX mouseTickX: CGFloat, rulerWidth: CGFloat) -> CGFloat {
        let growthDirection = ZeroCornerGeometry(zeroCorner: prefs.zeroCorner).growthDirection(for: .horizontal)

        switch growthDirection {
        case .positive:
            return mouseTickX
        case .negative:
            return rulerWidth - mouseTickX
        }
    }

    func unitLabelRect(labelSize: NSSize, rulerSize: NSSize) -> CGRect {
        return UnitLabelView.labelFrame(
            labelSize: labelSize,
            rulerSize: rulerSize,
            orientation: .horizontal,
            zeroCorner: prefs.zeroCorner
        )
    }

}
