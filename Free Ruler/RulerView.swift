//
//  RulerView.swift
//  Free Ruler
//
//  Created by Pascal on 6/10/15.
//  Copyright (c) 2015 Pascal. All rights reserved.
//

import Cocoa

class RulerView: NSView {
	
	override var mouseDownCanMoveWindow: Bool {
		get {
			return true
		}
	}

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
		
    }
	
	override func mouseDown(theEvent: NSEvent) {
		// println(theEvent.deltaX)
	}

}
