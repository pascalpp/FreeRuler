//
//  AppDelegate.swift
//  Free Ruler
//
//  Created by Jeff Hanbury on 12/04/19.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let horizontal = RulerHorizontalWindow()
    let vertical = RulerVerticalWindow()

    var timer: Timer?
    var currentTimerInterval: TimeInterval?
    var foregroundTimerInterval: TimeInterval = 40 / 1000 // 25 fps
    var backgroundTimerInterval: TimeInterval = 66 / 1000 // 15 fps
    var grouped: Bool = true
    

    // MARK: - Lifecycle
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        horizontal.showWindow(nil)
        vertical.showWindow(nil)
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        horizontal.window?.alphaValue = 0.9
        vertical.window?.alphaValue = 0.9

        currentTimerInterval = foregroundTimerInterval
        startTimer()
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        horizontal.window?.alphaValue = 0.5
        vertical.window?.alphaValue = 0.5

        currentTimerInterval = backgroundTimerInterval
        startTimer()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func windowWillMove(_ notification: Notification, sender: NSWindowController) {
        let which = (sender === horizontal) ? "horizonal" : "vertical"
        print("windowWillMove: sender is \(which)")
        let window = notification.object as? NSWindow
        print(window?.frame.origin as Any)
        
    }
    
    func windowDidMove(_ notification: Notification, sender: NSWindowController) {
        let which = (sender === horizontal) ? "horizonal" : "vertical"
        print("windowDidMove: sender is \(which)")
        let window = notification.object as? NSWindow
        print(window?.frame.origin as Any)
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
        horizontal.rule?.drawMouseTick(at: mouseLoc)
        vertical.rule?.drawMouseTick(at: mouseLoc)
    }

}

