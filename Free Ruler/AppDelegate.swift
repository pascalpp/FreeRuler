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

- moving windows
- drawing rulers
- close button
- resize controls? - probably not needed
- reading/writing preferences
- responding to settings changes?

*/



@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet weak var hRulerPanel: NSPanel!
	@IBOutlet weak var vRulerPanel: NSPanel!

	var hRuler = Ruler()
	var vRuler = Ruler()

	func applicationDidFinishLaunching(aNotification: NSNotification) {
		// Insert code here to initialize your application
		hRulerPanel.alphaValue = 0.9
		hRulerPanel.floatingPanel = true
		hRulerPanel.minSize.height = 50
		hRulerPanel.maxSize.height = 50
		hRulerPanel.minSize.width = 200
		hRulerPanel.maxSize.width = 5000
		
		vRulerPanel.alphaValue = 0.9
		vRulerPanel.floatingPanel = true
		vRulerPanel.minSize.width = 50
		vRulerPanel.maxSize.width = 50
		vRulerPanel.minSize.height = 200
		vRulerPanel.maxSize.height = 5000
	}
	
	func applicationDidBecomeActive(notification: NSNotification) {
		println("active")
		hRulerPanel.alphaValue = 0.9
		vRulerPanel.alphaValue = 0.9
	}
	
	func applicationDidResignActive(notification: NSNotification) {
		println("inactive")
		hRulerPanel.alphaValue = 0.5
		vRulerPanel.alphaValue = 0.5
	}

	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}

}

