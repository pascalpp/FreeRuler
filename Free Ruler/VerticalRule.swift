//
//  VerticalRule.swift
//  Free Ruler
//
//  Created by Pascal on 2019-04-19.
//
//

import Cocoa

@IBDesignable
class VerticalRule: NSView {

    var mouseTickY: CGFloat = 0 {
        didSet {
            if mouseTickY != oldValue {
                needsDisplay = true
            }
        }
    }

    var showMouseTick: Bool = true {
        didSet {
            if showMouseTick != oldValue {
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
        #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1).setFill()
        dirtyRect.fill()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        let attrs = [
            NSAttributedString.Key.font: NSFont(name: "HelveticaNeue", size: 10)!, NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.3098039329, green: 0.2039215714, blue: 0.03921568766, alpha: 1)
        ]

        let width = Int(dirtyRect.width)
        let height = Int(dirtyRect.height)
        let myPath = NSBezierPath()

        for i in 1...height {
            if i.isMultiple(of: 50) {
                myPath.move(to: CGPoint(x: width - 0, y: height - i))
                myPath.line(to: CGPoint(x: width - 10, y: height - i))

                let label = String(i)
                label.draw(with: CGRect(x: 3, y: height - i - 13, width: 24, height: 20), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)

            }
            if i.isMultiple(of: 10) {
                myPath.move(to: CGPoint(x: width - 0, y: height - i))
                myPath.line(to: CGPoint(x: width - 8, y: height - i))
            }
            else if i.isMultiple(of: 2) {
                myPath.move(to: CGPoint(x: width - 0, y: height - i))
                myPath.line(to: CGPoint(x: width - 5, y: height - i))
            }
        }

        #colorLiteral(red: 0.7254902124, green: 0.4784313738, blue: 0.09803921729, alpha: 1).setStroke()
        myPath.stroke()

        // Draw the MouseTick & number
        if showMouseTick && mouseTickY >= 1 && mouseTickY < windowHeight {
            let mouseTick = NSBezierPath()
            let width: CGFloat = (mouseTickY > 21) ? 40 : 20

            mouseTick.move(to: CGPoint(x: width, y: mouseTickY))
            mouseTick.line(to: CGPoint(x: 0, y: mouseTickY))
            #colorLiteral(red: 0.7254902124, green: 0.4784313738, blue: 0.09803921729, alpha: 1).setStroke()
            mouseTick.stroke()

            drawMouseNumber(mouseTickY)
        }
    }

    func drawMouseNumber(_ mouseTickY: CGFloat) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        
        let number = windowHeight - mouseTickY

        var labelY = number - 5

        if labelY < 30 {
            // Switch to below the tick
            labelY = number + 13
        }

        if labelY < 30 {
            // don't collide with close button
            labelY = 30
        }

        let attrs = [
            NSAttributedString.Key.font: NSFont(name: "HelveticaNeue", size: 10)!, NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.7254902124, green: 0.4784313738, blue: 0.09803921729, alpha: 1)
        ]

        let label = String(Int(number))
        label.draw(with: CGRect(x: 3, y: windowHeight - labelY, width: 20, height: 10), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)

    }

}

extension VerticalRule: TickableY {
    func drawMouseTick(at mouseLoc: NSPoint) {
        let windowY = self.window?.frame.origin.y ?? 0
        let mouseY = mouseLoc.y
        self.mouseTickY = mouseY - windowY
    }
}

protocol TickableY {
    func drawMouseTick(at mouseLoc: NSPoint)
}


// MARK: - Mouse events

extension VerticalRule {
    // Hide the ruler tick when the mouse is clicked on the ruler, for example
    // during window drag.
    override func mouseDown(with event: NSEvent) {
        showMouseTick = false
    }

    override func mouseUp(with event: NSEvent) {
        showMouseTick = true
    }
}