//
//  AppDelegate.swift
//  Free Ruler
//
//  Created by Jeff Hanbury on 12/04/19.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let defaults = UserDefaults.standard

    let horizontal = HorizontalController()
    let vertical = VerticalController()

    var timer: Timer?
    var currentTimerInterval: TimeInterval?
    let foregroundTimerInterval: TimeInterval = 40 / 1000 // 25 fps
    let backgroundTimerInterval: TimeInterval = 66 / 1000 // 15 fps

    @IBOutlet weak var groupedMenuItem: NSMenuItem!
    var groupedRulers: Bool = false

    // MARK: - Lifecycle
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        updateGroupedRulers()

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
    
    func synchroniseWindows() {
        guard groupedRulers,
            let hWindow = horizontal.window,
            let vWindow = vertical.window
            else { return }

        if hWindow.isKeyWindow {
            vertical.moveWith(hWindow)
        } else if vWindow.isKeyWindow {
            horizontal.moveWith(vWindow)
        }
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
    
    @IBAction func toggleGroupedRulers(_ sender: Any) {
        defaults.set(!groupedRulers, forKey: "groupedRulers")
        updateGroupedRulers()
    }

    func updateGroupedRulers() {
        groupedRulers = defaults.bool(forKey: "groupedRulers")
        groupedMenuItem?.state = (groupedRulers ? .on : .off)
    }
    

}

