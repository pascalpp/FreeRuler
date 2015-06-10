//
//  RulerWindow.swift
//  Free Ruler
//
//  Created by Pascal on 6/10/15.
//  Copyright (c) 2015 Pascal. All rights reserved.
//

import Cocoa

class RulerWindow: NSPanel {

	override init(contentRect: NSRect, styleMask aStyle: Int, backing bufferingType: NSBackingStoreType, defer flag: Bool) {
		super.init(contentRect: contentRect, styleMask: aStyle, backing: bufferingType, defer: flag)
		
		self.movableByWindowBackground = true
	}

	required init?(coder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
}
