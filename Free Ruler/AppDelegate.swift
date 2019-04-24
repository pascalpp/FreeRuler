//
//  AppDelegate.swift
//  Free Ruler
//
//  Created by Jeff Hanbury on 12/04/19.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var rulerHorizontalWindow: RulerHorizontalWindow?
    var rulerVerticalWindow: RulerVerticalWindow?

    var timer: Timer?
    var currentTimerInterval: TimeInterval?
    var foregroundTimerInterval: TimeInterval = 40 / 1000 // 25 fps
    var backgroundTimerInterval: TimeInterval = 66 / 1000 // 15 fps
    var grouped: Bool = true
    

    // MARK: - Lifecycle
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        rulerHorizontalWindow = RulerHorizontalWindow(windowNibName: "RulerHorizontalWindow")
        rulerHorizontalWindow?.showWindow(self)

        rulerVerticalWindow = RulerVerticalWindow(windowNibName: "RulerVerticalWindow")
        rulerVerticalWindow?.showWindow(self)
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        rulerHorizontalWindow?.window?.alphaValue = 0.9
        rulerVerticalWindow?.window?.alphaValue = 0.9

        currentTimerInterval = foregroundTimerInterval
        startTimer()
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        rulerHorizontalWindow?.window?.alphaValue = 0.5
        rulerVerticalWindow?.window?.alphaValue = 0.5

        currentTimerInterval = backgroundTimerInterval
        startTimer()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func windowWillMove(_ notification: Notification, sender: NSWindowController) {
        let which = (sender === rulerHorizontalWindow) ? "horizonal" : "vertical"
        print("windowWillMove: sender is \(which)")
        let window = notification.object as? NSWindow
        print(window?.frame.origin as? Any)
        
    }
    
    func windowDidMove(_ notification: Notification, sender: NSWindowController) {
        let which = (sender === rulerHorizontalWindow) ? "horizonal" : "vertical"
        print("windowDidMove: sender is \(which)")
        let window = notification.object as? NSWindow
        print(window?.frame.origin as? Any)
    }

}


// MARK: - Timer
extension AppDelegate {
    private func startTimer() {
        timer?.invalidate()

        timer = Timer.scheduledTimer(
            timeInterval: currentTimerInterval!,
            target: self,
            selector: #selector(self.onInterval),
            userInfo: nil,
            repeats: true
        )
    }
    
    @objc func onInterval() {
        self.updateMouseLocation()
    }
    
    private func updateMouseLocation() {
        var mouseLoc = NSEvent.mouseLocation
        mouseLoc.x = mouseLoc.x.rounded()
        mouseLoc.y = mouseLoc.y.rounded()
        rulerHorizontalWindow?.horizontalRule.drawMouseTick(at: mouseLoc)
        rulerVerticalWindow?.verticalRule.drawMouseTick(at: mouseLoc)
    }

}

