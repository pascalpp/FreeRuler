import Cocoa

class HorizontalRule: RuleView {

    let transformer = AffineTransform(translationByX: 0.5, byY: 0)

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

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "HelveticaNeue", size: 10)!,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: color.numbers
        ]

        let width = dirtyRect.width
        let path = NSBezierPath()
        let tickScale: CGFloat
        let textScale: Int
        let largeTicks: Int
        let mediumTicks: Int
        let smallTicks: Int
        let tinyTicks: Int?
        
        switch prefs.unit {
        case .millimeters:
            tickScale = screen?.dpmm.width ?? NSScreen.defaultDpmm
            textScale = 1
            largeTicks = 10
            mediumTicks = 5
            smallTicks = 1
            tinyTicks = nil
        case .inches:
            tickScale = (screen?.dpi.width ?? NSScreen.defaultDpi) / 16
            textScale = 16
            largeTicks = 16
            mediumTicks = 8
            smallTicks = 4
            tinyTicks = 1
        case .scaled:
            tickScale =  1 / prefs.xscale
            textScale = 1 
            largeTicks = 10
            mediumTicks = 5
            smallTicks = 1
            tinyTicks = nil
        default:
            tickScale = 1
            textScale = 1
            largeTicks = 50
            mediumTicks = 10
            smallTicks = 2
            tinyTicks = nil
        }

        let labelWidth: CGFloat = 50
        let labelHeight: CGFloat = 20
        let labelOffset: CGFloat = 13 // offset of label from bottom edge of ruler
        // TODO: refactor this to use label.size() logic (see func drawUnitLabel)

        // substract two so ticks don't overlap with border
        // subtract from this range so width var is accurate
        for i in 1...Int((width - 2) / tickScale) {
            let pos = CGFloat(i) * tickScale
            if i.isMultiple(of: largeTicks) {
                path.move(to: CGPoint(x: pos, y: 1))
                path.line(to: CGPoint(x: pos, y: 10))

                let label = String(i / textScale)
                let labelX: CGFloat = pos - (labelWidth / 2) + 0.5 // half-pixel nudge /shrug
                let labelY: CGFloat = labelOffset
                let labelRect = CGRect(x: labelX, y: labelY, width: labelWidth, height: labelHeight)
                
                label.draw(
                    with: labelRect,
                    attributes: attrs,
                    context: nil
                )

            }
            else if i.isMultiple(of: mediumTicks) {
                path.move(to: CGPoint(x: pos, y: 1))
                path.line(to: CGPoint(x: pos, y: 8))
            }
            else if i.isMultiple(of: smallTicks) {
                path.move(to: CGPoint(x: pos, y: 1))
                path.line(to: CGPoint(x: pos, y: 5))
            }
            else if let tinyTicks = tinyTicks, i.isMultiple(of: tinyTicks) {
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
        let labelOffset: CGFloat = 5

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes = [
            NSAttributedString.Key.font: NSFont(name: "HelveticaNeue", size: 10)!,
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.foregroundColor: color.mouseNumber,
        ]

        let mouseNumber = self.getXMouseNumberLabel(number)
        let label = NSAttributedString(string: mouseNumber, attributes: attributes)
        let labelSize = label.size()

        let rightPosition = number + labelOffset;
        let leftPosition = number - labelOffset - labelSize.width
        let enoughRoomToTheRight = rightPosition + labelSize.width < width - labelOffset
        let labelX = enoughRoomToTheRight ? rightPosition : leftPosition

        let labelRect = CGRect(x: labelX, y: height - labelSize.height, width: labelSize.width, height: labelSize.height)

        label.draw(
            with: labelRect,
            context: nil
        )
    }

    func drawUnitLabel() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left

        let attributes = [
            NSAttributedString.Key.font: NSFont(name: "HelveticaNeue", size: 10)!,
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.foregroundColor: color.ticks,
        ]

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
