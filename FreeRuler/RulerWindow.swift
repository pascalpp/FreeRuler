//
//  RulerWindow.swift
//  Free Ruler
//
//  Created by Pascal on 6/10/15.
//  Copyright (c) 2015 Pascal. All rights reserved.
//

import Cocoa

class RulerWindow: NSPanel {
	
	var orientation: Orientation?
	var ruler: Ruler?

    override init(contentRect: NSRect, styleMask aStyle: Int, backing bufferingType: NSBackingStoreType, `defer` flag: Bool) {
        super.init(contentRect: contentRect, styleMask: aStyle, backing: bufferingType, `defer`: flag)
        
        self.movableByWindowBackground = true
        self.backgroundColor = NSColor(calibratedRed: 255/255, green: 255/255, blue: 179/255, alpha: 1.0)
    }

	required init?(coder: NSCoder) {
	    super.init(coder: coder)
	}
	
	func drawMouseTick(mouseLoc: NSPoint) {
		switch orientation! {
		case .Horizontal:
			Swift.print("mouse x: \(mouseLoc.x)")
		case .Vertical:
			Swift.print("mouse y: \(mouseLoc.y)")
		}
	}
	
}
