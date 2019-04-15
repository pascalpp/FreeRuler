//
//  Window+Move.swift
//  Free Ruler
//
//  Created by Jeff Hanbury on 14/04/19.
//  Copyright © 2019 Marmaladesoul. All rights reserved.
//

import Cocoa


extension NSWindow {
    private enum Distance: CGFloat {
        case aLot = 10
        case aLittle = 1
    }
    
    func moveHorizontally(by pixels: CGFloat) {
        var position = frame.origin
        position.x = position.x + pixels
        setFrameOrigin(position)
    }
    
    func moveVertically(by pixels: CGFloat) {
        var position = frame.origin
        position.y = position.y + pixels
        setFrameOrigin(position)
    }
    
    private func distance(withShift: Bool) -> CGFloat {
        return withShift ? Distance.aLot.rawValue : Distance.aLittle.rawValue
    }
    
    func nudgeLeft(withShift shiftPressed: Bool) {
        let distance = -1 * self.distance(withShift: shiftPressed)
        moveHorizontally(by: distance)
    }
    
    func nudgeRight(withShift shiftPressed: Bool) {
        let distance = self.distance(withShift: shiftPressed)
        moveHorizontally(by: distance)
    }
    
    func nudgeDown(withShift shiftPressed: Bool) {
        let distance = -1 * self.distance(withShift: shiftPressed)
        moveVertically(by: distance)
    }
    
    func nudgeUp(withShift shiftPressed: Bool) {
        let distance = self.distance(withShift: shiftPressed)
        moveVertically(by: distance)
    }
    
}
