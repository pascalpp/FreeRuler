//
//  VerticalRule.swift
//  Free Ruler
//
//  Created by Pascal on 2019-04-19.
//
//

import Cocoa

class VerticalRule: RuleView {

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
        #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1).setFill()
        dirtyRect.fill()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        let attrs = [
            NSAttributedString.Key.font: NSFont(name: "HelveticaNeue", size: 10)!,
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.7254902124, green: 0.4784313738, blue: 0.09803921729, alpha: 1)
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
        #colorLiteral(red: 0.3098039329, green: 0.2039215714, blue: 0.03921568766, alpha: 0.75).setStroke()
        mouseTick.stroke()
    }

    func drawMouseNumber(_ mouseTickY: CGFloat) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        
        let number = windowHeight - mouseTickY

        // draw below the tick
        var labelY = number + 13

        if labelY > windowHeight - 15 {
            // switch to above the tick
            labelY = number - 5
        }

        let attrs = [
            NSAttributedString.Key.font: NSFont(name: "HelveticaNeue", size: 10)!,
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.3098039329, green: 0.2039215714, blue: 0.03921568766, alpha: 1),
            NSAttributedString.Key.backgroundColor: #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1),
        ]

        let label = String(Int(number))
        label.draw(with: CGRect(x: 5, y: windowHeight - labelY, width: 40, height: 10), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)

    }

}
