//
//  AppDelegate.swift
//  Free Ruler
//
//  Created by Pascal on 6/9/15.
//  Copyright (c) 2015 Pascal. All rights reserved.
//

import Cocoa

/**

# TODO

√ moving windows
- drawing rulers
- close button
- resize controls? - probably not needed
- reading/writing preferences
- responding to settings changes?

*/



@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet weak var hRulerWindow: RulerWindow!
	@IBOutlet weak var vRulerWindow: RulerWindow!

	var hRuler = Ruler()
	var vRuler = Ruler()

	func applicationDidFinishLaunching(aNotification: NSNotification) {
		// Insert code here to initialize your application
		hRulerWindow.alphaValue = 0.9
		hRulerWindow.floatingPanel = true
		hRulerWindow.minSize.height = 50
		hRulerWindow.maxSize.height = 50
		hRulerWindow.minSize.width = 200
		hRulerWindow.maxSize.width = 5000
		
		vRulerWindow.alphaValue = 0.9
		vRulerWindow.floatingPanel = true
		vRulerWindow.minSize.width = 50
		vRulerWindow.maxSize.width = 50
		vRulerWindow.minSize.height = 200
		vRulerWindow.maxSize.height = 5000
	}
	
	func applicationDidBecomeActive(notification: NSNotification) {
		println("active")
		hRulerWindow.alphaValue = 0.9
		vRulerWindow.alphaValue = 0.9
	}
	
	func applicationDidResignActive(notification: NSNotification) {
		println("inactive")
		hRulerWindow.alphaValue = 0.5
		vRulerWindow.alphaValue = 0.5
	}

	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}

}

