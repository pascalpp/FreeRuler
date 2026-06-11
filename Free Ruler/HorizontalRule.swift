import Cocoa

class HorizontalRule: RuleView {

    let transformer = AffineTransform(translationByX: 0.5, byY: 0)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        installResizeHandle(for: .horizontal)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        installResizeHandle(for: .horizontal)
    }

    var mouseTickX: CGFloat = 0 {
        didSet {
            if mouseTickX != oldValue {
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
        let path = NSBezierPath()
        let tickLayout = RulerTickLayout(unit: unit, screen: screen)

        let labelWidth: CGFloat = 50
        let labelHeight: CGFloat = 20
        let labelOffset: CGFloat = 13 // offset of label from bottom edge of ruler
        // TODO: refactor this to use label.size() logic (see func drawUnitLabel)

        // substract two so ticks don't overlap with border
        // subtract from this range so width var is accurate
        for i in 1...Int((width - 2) / tickLayout.tickScale) {
            let pos = CGFloat(i) * tickLayout.tickScale
            if i.isMultiple(of: tickLayout.largeTicks) {
                path.move(to: CGPoint(x: pos, y: 1))
                path.line(to: CGPoint(x: pos, y: 10))

                let label = String(i / tickLayout.textScale)
                let labelX: CGFloat = pos - (labelWidth / 2) + 0.5 // half-pixel nudge /shrug
                let labelY: CGFloat = labelOffset
                let labelRect = CGRect(x: labelX, y: labelY, width: labelWidth, height: labelHeight)
                
                label.draw(
                    with: labelRect,
                    attributes: attrs,
                    context: nil
                )

            }
            else if i.isMultiple(of: tickLayout.mediumTicks) {
                path.move(to: CGPoint(x: pos, y: 1))
                path.line(to: CGPoint(x: pos, y: 8))
            }
            else if i.isMultiple(of: tickLayout.smallTicks) {
                path.move(to: CGPoint(x: pos, y: 1))
                path.line(to: CGPoint(x: pos, y: 5))
            }
            else if let tinyTicks = tickLayout.tinyTicks, i.isMultiple(of: tinyTicks) {
                path.move(to: CGPoint(x: pos, y: 1))
                path.line(to: CGPoint(x: pos, y: 3))
            }
        }

        path.transform(using: transformer)

        color.ticks.setStroke()
        path.stroke()

        if !showMouseTick || mouseTickX < 0 || mouseTickX > 26 {
            drawUnitLabel()
        }

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
        let number = mouseTickX
        let width = self.frame.width
        let height = self.frame.height

        let attributes = labelAttributes(alignment: .center, foregroundColor: color.mouseNumber)

        let mouseNumber = self.getMouseNumberLabel(number)
        let label = NSAttributedString(string: mouseNumber, attributes: attributes)
        let labelSize = label.size()

        let labelRect = mouseNumberLabelRect(
            number: number,
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

        let rightPosition = number + labelOffset
        let leftPosition = number - labelOffset - labelSize.width
        var maxLabelRight = rulerSize.width - labelOffset

        if let resizeHandleExclusionFrame = resizeHandleExclusionFrame {
            maxLabelRight = min(
                maxLabelRight,
                resizeHandleExclusionFrame.minX - mouseTickLabelResizeHandleSpacing
            )
        }

        let pinnedRightPosition = maxLabelRight - labelSize.width
        let rightLabelX = min(rightPosition, pinnedRightPosition)
        let leftLabelX = min(leftPosition, pinnedRightPosition)
        let labelX = number < rightLabelX ? rightLabelX : leftLabelX

        return CGRect(
            x: labelX,
            y: rulerSize.height - labelSize.height,
            width: labelSize.width,
            height: labelSize.height
        )
    }

    func drawUnitLabel() {
        let attributes = labelAttributes(alignment: .left, foregroundColor: color.ticks)

        let unitlabel = self.getUnitLabel()
        let label = NSAttributedString(string: unitlabel, attributes: attributes)
        let height = self.frame.height
        let labelSize = label.size()
        let labelRect = CGRect(x: 10, y: height - labelSize.height, width: labelSize.width, height: labelSize.height)

        label.draw(
            with: labelRect,
            context: nil
        )
    }

}
