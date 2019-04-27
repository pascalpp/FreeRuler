//
//  HorizontalRule.swift
//  Free Ruler
//
//  Created by Jeff Hanbury on 12/04/19.
//  Copyright © 2019 Marmaladesoul. All rights reserved.
//

import Cocoa

@IBDesignable
class HorizontalRule: NSView {

    var mouseTickX: CGFloat = 0 {
        didSet {
            if mouseTickX != oldValue {
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

    var windowWidth: CGFloat {
        return self.window?.frame.width ?? 0
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1).setFill()
        dirtyRect.fill()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attrs = [
            NSAttributedString.Key.font: NSFont(name: "HelveticaNeue", size: 10)!,
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.7254902124, green: 0.4784313738, blue: 0.09803921729, alpha: 1)
        ]

        let width = Int(dirtyRect.width)
        let myPath = NSBezierPath()

        for i in 1...width {
            if i.isMultiple(of: 50) {
                myPath.move(to: CGPoint(x: i, y: 0))
                myPath.line(to: CGPoint(x: i, y: 10))

                let label = String(i)
                label.draw(with: CGRect(x: i-20, y: 3, width: 40, height: 20), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)

            }
            if i.isMultiple(of: 10) {
                myPath.move(to: CGPoint(x: i, y: 0))
                myPath.line(to: CGPoint(x: i, y: 8))
            }
            else if i.isMultiple(of: 2) {
                myPath.move(to: CGPoint(x: i, y: 0))
                myPath.line(to: CGPoint(x: i, y: 5))
            }
        }

        #colorLiteral(red: 0.7254902124, green: 0.4784313738, blue: 0.09803921729, alpha: 1).setStroke()
        myPath.stroke()

        // Draw the MouseTick & number
        if showMouseTick && mouseTickX > 0 && mouseTickX < windowWidth {
            drawMouseTick(mouseTickX)
            drawMouseNumber(mouseTickX)
        }
    }
    
    func drawMouseTick(_ mouseTickX: CGFloat) {
        let mouseTick = NSBezierPath()
        let height: CGFloat = 40
        
        mouseTick.move(to: CGPoint(x: mouseTickX, y: 0))
        mouseTick.line(to: CGPoint(x: mouseTickX, y: height))
        #colorLiteral(red: 0.3098039329, green: 0.2039215714, blue: 0.03921568766, alpha: 0.75).setStroke()
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
            NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.3098039329, green: 0.2039215714, blue: 0.03921568766, alpha: 1),
            NSAttributedString.Key.backgroundColor: #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1),
        ]

        let label = String(Int(number))
        label.draw(with: CGRect(x: labelX, y: 30, width: labelWidth, height: 10), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)

    }

}

extension HorizontalRule: TickableX {
    func drawMouseTick(at mouseLoc: NSPoint) {
        let windowX = self.window?.frame.origin.x ?? 0
        let mouseX = mouseLoc.x
        self.mouseTickX = mouseX - windowX
    }
}

protocol TickableX {
    func drawMouseTick(at mouseLoc: NSPoint)
}


// MARK: - Mouse events

extension HorizontalRule {
    // Hide the ruler tick when the mouse is clicked on the ruler, for example
    // during window drag.
    override func mouseDown(with event: NSEvent) {
        showMouseTick = false
    }

    override func mouseUp(with event: NSEvent) {
        showMouseTick = true
    }
}
