import Cocoa

class VerticalRule: RuleView {

    let transformer = AffineTransform(translationByX: 0, byY: -0.5)

    var mouseTickY: CGFloat = 0 {
        didSet {
            if mouseTickY != oldValue {
                needsDisplay = true
            }
        }
    }

    var windowHeight: CGFloat {
        return self.window?.frame.height ?? 0
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        color.fill.setFill()
        dirtyRect.fill()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "HelveticaNeue", size: 10)!,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: color.numbers
       ]

        let width = dirtyRect.width
        let height = dirtyRect.height
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

        // substract two so ticks don't overlap with border
        // substract from this range so we can use the height var for position calculations
        for i in 1...Int((height - 2) / tickScale) {
            let pos = CGFloat(i) * tickScale
            if i.isMultiple(of: largeTicks) {
                path.move(to: CGPoint(x: width - 1, y: height - pos))
                path.line(to: CGPoint(x: width - 10, y: height - pos))

                let label = String(i / textScale)
                label.draw(
                    with: CGRect(x: 3, y: height - pos - 13.5, width: 24, height: 20),
                    options: .usesLineFragmentOrigin,
                    attributes: attrs,
                    context: nil
                )

            }
            else if i.isMultiple(of: mediumTicks) {
                path.move(to: CGPoint(x: width - 1, y: height - pos))
                path.line(to: CGPoint(x: width - 8, y: height - pos))
            }
            else if i.isMultiple(of: smallTicks) {
                path.move(to: CGPoint(x: width - 1, y: height - pos))
                path.line(to: CGPoint(x: width - 5, y: height - pos))
            }
            else if let tinyTicks = tinyTicks, i.isMultiple(of: tinyTicks) {
                path.move(to: CGPoint(x: width - 1, y: height - pos))
                path.line(to: CGPoint(x: width - 3, y: height - pos))
            }
        }

        path.transform(using: transformer)

        color.ticks.setStroke()
        path.stroke()

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
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left

        let number = windowHeight - mouseTickY

        // draw below the tick
        var labelY = number + 23

        if labelY > windowHeight - 15 {
            // switch to above the tick
            labelY = number
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

        label.draw(with: CGRect(x: 5, y: windowHeight - labelY, width: 40, height: 20), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)

    }

}
