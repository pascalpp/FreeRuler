import Cocoa

class VerticalRule: RuleView {

    let transformer = AffineTransform(translationByX: 0, byY: -0.5)

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

        let width = dirtyRect.width
        let height = dirtyRect.height
        let path = NSBezierPath()
        let tickLayout = RulerTickLayout(unit: unit, screen: screen)
        let geometry = ZeroCornerGeometry(zeroCorner: prefs.zeroCorner)
        let tickSide = geometry.tickSide(for: .vertical)
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

        updateUnitLabelVisibility()

        // Draw the MouseTick & number
        if showMouseTick && mouseTickY >= 1 && mouseTickY < windowHeight {
            drawMouseTick(mouseTickY)
            drawMouseNumber(mouseTickY)
        }
    }

    override func drawMouseTick(at mouseLoc: NSPoint) {
        let windowY = self.window?.frame.origin.y ?? 0
        let mouseY = mouseLoc.y
        self.mouseTickY = mouseY - windowY
    }

    func drawMouseTick(_ mouseTickY: CGFloat) {
        let mouseTick = NSBezierPath()
        let width: CGFloat = 40
        let startX: CGFloat = 0

        mouseTick.move(to: CGPoint(x: startX, y: mouseTickY))
        mouseTick.line(to: CGPoint(x: width, y: mouseTickY))

        mouseTick.transform(using: transformer)

        color.mouseTick.setStroke()
        mouseTick.stroke()
    }

    func drawMouseNumber(_ mouseTickY: CGFloat) {
        let height = self.frame.height
        let number = mouseNumber(forTickY: mouseTickY, rulerHeight: height)

        let attributes = labelAttributes(alignment: .left, foregroundColor: color.mouseNumber)

        let mouseNumber = self.getMouseNumberLabel(number)
        let label = NSAttributedString(string: mouseNumber, attributes: attributes)
        let labelSize = label.size()

        let labelRect = mouseNumberLabelRect(
            number: height - mouseTickY,
            labelSize: labelSize,
            rulerHeight: height
        )
        color.fill.setFill()
        labelRect.fill()

        label.draw(
            with: labelRect,
            options: .usesLineFragmentOrigin,
            context: nil
        )
    }

    func mouseNumberLabelRect(number: CGFloat, labelSize: CGSize, rulerHeight: CGFloat) -> CGRect {
        let labelOffset: CGFloat = 2
        let tickSide = ZeroCornerGeometry(zeroCorner: prefs.zeroCorner).tickSide(for: .vertical)

        // Offset the bottom position until text can be centered vertically in the label rect.
        let bottomPosition = number + 7
        let topPosition = number - labelOffset - labelSize.height
        let enoughRoomToTheBottom = bottomPosition + labelSize.height < rulerHeight - labelOffset
        let labelY = enoughRoomToTheBottom ? bottomPosition : topPosition
        let labelX: CGFloat = tickSide == .right ? 7 : 11
        var labelRect = CGRect(x: labelX, y: rulerHeight - (labelY + labelSize.height), width: 22, height: 15)

        if let resizeHandleExclusionFrame = resizeHandleExclusionFrame {
            let minLabelBottom = resizeHandleExclusionFrame.maxY + mouseTickLabelResizeHandleSpacing
            labelRect.origin.y = max(labelRect.origin.y, minLabelBottom)
        }

        return labelRect
    }

    override func updateUnitLabelVisibility() {
        guard showMouseTick,
              mouseTickY >= 1,
              mouseTickY < windowHeight,
              let frame = unitLabelFrame else {
            setUnitLabelHidden(false)
            return
        }

        setUnitLabelHidden(frame.minY <= mouseTickY && mouseTickY <= frame.maxY)
    }

    func tickY(
        forOffset offset: CGFloat,
        rulerHeight: CGFloat,
        growthDirection: RulerGrowthDirection
    ) -> CGFloat {
        switch growthDirection {
        case .positive:
            return offset
        case .negative:
            return rulerHeight - offset
        }
    }

    func tickLine(
        forY y: CGFloat,
        length: CGFloat,
        rulerWidth: CGFloat,
        tickSide: RulerSide
    ) -> (start: CGPoint, end: CGPoint) {
        switch tickSide {
        case .right:
            return (CGPoint(x: rulerWidth - 1, y: y), CGPoint(x: rulerWidth - length, y: y))
        case .left:
            return (CGPoint(x: 1, y: y), CGPoint(x: length, y: y))
        case .top, .bottom:
            assertionFailure("Vertical ruler ticks must be placed on a vertical side")
            return (CGPoint(x: rulerWidth - 1, y: y), CGPoint(x: rulerWidth - length, y: y))
        }
    }

    func tickLabelRect(
        forY y: CGFloat,
        labelSize: NSSize,
        rulerWidth: CGFloat,
        tickSide: RulerSide
    ) -> CGRect {
        let labelOffset: CGFloat = 13
        let textHeight: CGFloat = 8
        let labelX: CGFloat

        switch tickSide {
        case .right:
            labelX = rulerWidth - labelSize.width - labelOffset
        case .left:
            labelX = labelOffset
        case .top, .bottom:
            assertionFailure("Vertical ruler labels must be placed on a vertical side")
            labelX = rulerWidth - labelSize.width - labelOffset
        }

        return CGRect(
            x: labelX,
            y: y - (textHeight / 2),
            width: labelSize.width,
            height: labelSize.height
        )
    }

    func mouseNumber(forTickY mouseTickY: CGFloat, rulerHeight: CGFloat) -> CGFloat {
        let growthDirection = ZeroCornerGeometry(zeroCorner: prefs.zeroCorner).growthDirection(for: .vertical)

        switch growthDirection {
        case .positive:
            return mouseTickY
        case .negative:
            return rulerHeight - mouseTickY
        }
    }

    func unitLabelRect(labelSize: NSSize, rulerSize: NSSize) -> CGRect {
        return UnitLabelView.labelFrame(
            labelSize: labelSize,
            rulerSize: rulerSize,
            orientation: .vertical,
            zeroCorner: prefs.zeroCorner
        )
    }


}
