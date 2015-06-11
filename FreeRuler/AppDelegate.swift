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
√ detecting mouse position
- drawing mousetick
- close button
- resize controls? - probably not needed
- reading/writing preferences
- responding to settings changes?

*/

enum Orientation {
	case Horizontal
	case Vertical
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet weak var hRulerWindow: RulerWindow!
	@IBOutlet weak var vRulerWindow: RulerWindow!

	var hRuler: Ruler?
	var vRuler: Ruler?
	
	var foregroundTimerInterval: NSTimeInterval = 10 / 1000
	var backgroundTimerInterval: NSTimeInterval = 100 / 1000
	var currentTimerInterval: NSTimeInterval?
	var timer: NSTimer?

	func applicationDidFinishLaunching(aNotification: NSNotification) {
		// Insert code here to initialize your application

		hRuler = Ruler(length: 200, opacity: 0.9, orientation: .Horizontal)
		hRulerWindow.orientation = .Horizontal
		hRulerWindow.alphaValue = 0.9
		hRulerWindow.floatingPanel = true
		hRulerWindow.minSize.height = 50
		hRulerWindow.maxSize.height = 50
		hRulerWindow.minSize.width = 200
		hRulerWindow.maxSize.width = 5000
		
		vRuler = Ruler(length: 200, opacity: 0.9, orientation: .Vertical)
		vRulerWindow.orientation = .Vertical
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
		
		currentTimerInterval = foregroundTimerInterval
		startTimer()

	}
	
	func applicationDidResignActive(notification: NSNotification) {
		println("inactive")
		hRulerWindow.alphaValue = 0.5
		vRulerWindow.alphaValue = 0.5

		currentTimerInterval = backgroundTimerInterval
		startTimer()
		
}

	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}
	
	func startTimer() {
		timer?.invalidate()
		
		timer = NSTimer.scheduledTimerWithTimeInterval(currentTimerInterval!,
			target: self,
			selector: "onInterval:",
			userInfo: nil,
			repeats: true)
	}
	
	func onInterval(timer: NSTimer) {
		println("onInterval")
		self.queryMouseLocation()
	}
	
	func queryMouseLocation() {
		var mouseLoc = NSEvent.mouseLocation()
		hRulerWindow.drawMouseTick(mouseLoc)
		vRulerWindow.drawMouseTick(mouseLoc)
	}

	@IBAction func closeHorizontalRuler(sender: AnyObject) {
		hRulerWindow.close()
	}

	@IBAction func closeVerticalRuler(sender: AnyObject) {
		vRulerWindow.close()
	}
	
}

