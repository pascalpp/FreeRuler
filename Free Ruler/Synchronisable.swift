//
//  Synchronisable.swift
//  Free Ruler
//
//  Created by Jeff Hanbury on 26/04/19.
//  Copyright © 2019 Free Ruler. All rights reserved.
//

import Cocoa

protocol Synchronisable: NSWindowController {
    func moveWith(_ otherWindow: NSWindow?)
}

extension Synchronisable {
    func moveWith(_ otherWindow: NSWindow?) {
        guard let otherWindow = otherWindow,
            let window = window
            else {return}

        let point = CGPoint(x: otherWindow.frame.minX, y: otherWindow.frame.maxY)
        window.setFrameTopLeftPoint(point)
    }
    
}
