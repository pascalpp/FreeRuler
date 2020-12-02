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
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "HelveticaNeue", size: 10)!,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: color.numbers
        ]

        let path = NSBezierPath()
        let tickScale: CGFloat
        let textScale: Int
        let largeTicks: Int
        let mediumTicks: Int
        let smallTicks: Int
        let tinyTicks: Int?
        
        switch unit {
        case .millimetres:
            tickScale = NSScreen.main!.dpmm.width       // TODO: handle .main == nil
            textScale = 1
            largeTicks = 10
            mediumTicks = 5
            smallTicks = 1
            tinyTicks = nil
        case .inches:
            tickScale = NSScreen.main!.dpi.width / 16   // TODO: handle .main == nil
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

        // substract two so ticks don't overlap with border
        // subtract from this range so width var is accurate
        for i in 1...Int((dirtyRect.width - 2) / tickScale) {
            let pos = CGFloat(i) * tickScale
            if i.isMultiple(of: largeTicks) {
                path.move(to: CGPoint(x: pos, y: 1))
                path.line(to: CGPoint(x: pos, y: 10))

                let label = String(i / textScale)
                label.draw(
                    with: CGRect(x: pos - 20, y: 3, width: 40, height: 20),
                    options: .usesLineFragmentOrigin,
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
        switch unit {
        case .millimetres:
            label = String(format: "%.1f", number / NSScreen.main!.dpmm.width)  // TODO: handle .main == nil
        case .inches:
            label = String(format: "%.3f", number / NSScreen.main!.dpi.width)   // TODO: handle .main == nil
        default:
            label = String(Int(number))
        }
        
        label.draw(with: CGRect(x: labelX, y: 20, width: labelWidth, height: 20), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)

    }

}
