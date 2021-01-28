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

    var windowWidth: CGFloat {
        return self.window?.frame.width ?? 0
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        color.fill.setFill()
        dirtyRect.fill()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineHeightMultiple = 1
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
                // labelRect.frame() // for debugging

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

        // Draw the MouseTick & number
        if showMouseTick && mouseTickX > 0 && mouseTickX < windowWidth {
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
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left

        let number = mouseTickX
        let labelWidth: CGFloat = 40

        var labelX = number + 5 // 3px padding from the line

        if labelX + labelWidth > windowWidth {
            // Switch to the left of the tick
            labelX = number - labelWidth - 5
            paragraphStyle.alignment = .right
        }

        let attrs = [
            NSAttributedString.Key.font: NSFont(name: "HelveticaNeue", size: 10)!,
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.foregroundColor: color.mouseNumber,
            NSAttributedString.Key.backgroundColor: color.fill,
        ]

        let label: String
        switch prefs.unit {
        case .millimeters:
            label = String(format: "%.1f", number / (screen?.dpmm.width ?? NSScreen.defaultDpmm))
        case .inches:
            label = String(format: "%.3f", number / (screen?.dpi.width ?? NSScreen.defaultDpi))
        default:
            label = String(Int(number))
        }
        
        label.draw(with: CGRect(x: labelX, y: 20, width: labelWidth, height: 20), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)

    }

}
