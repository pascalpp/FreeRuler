import Cocoa
import SwiftyUserDefaults

extension DefaultsKeys {
    static let groupedRulers = DefaultsKey<Bool>("groupedRulers", defaultValue: false)
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let horizontal = RulerController(type: .Horizontal)
    let vertical = RulerController(type: .Vertical)

    var timer: Timer?
    let foregroundTimerInterval: TimeInterval = 1 / 60 // 60 fps
    let backgroundTimerInterval: TimeInterval = 1 / 15 // 15 fps

    @IBOutlet weak var groupedMenuItem: NSMenuItem!

    // MARK: - Lifecycle
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        horizontal.otherWindow = vertical.rulerWindow
        vertical.otherWindow = horizontal.rulerWindow
        
        updateGroupedRulers()
        
        horizontal.showWindow()
        vertical.showWindow()
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        horizontal.rulerWindow.alphaValue = 0.9
        vertical.rulerWindow.alphaValue = 0.9

        startTimer(timeInterval: foregroundTimerInterval)
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        horizontal.rulerWindow.alphaValue = 0.5
        vertical.rulerWindow.alphaValue = 0.5

        startTimer(timeInterval: backgroundTimerInterval)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func updateGroupedRulers() {
        let grouped = Defaults[.groupedRulers]

        horizontal.updateChildWindow()
        vertical.updateChildWindow()

        groupedMenuItem?.state = (grouped ? .on : .off)

        print("grouped", grouped)
    }

    @IBAction func toggleGroupedRulers(_ sender: Any) {
        Defaults[.groupedRulers] = !Defaults[.groupedRulers]
        updateGroupedRulers()
    }

}



// MARK: - Timer
extension AppDelegate {

    private func startTimer(timeInterval: TimeInterval) {
        timer?.invalidate()

        timer = Timer.scheduledTimer(
            timeInterval: timeInterval,
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
        horizontal.rulerWindow.rule.drawMouseTick(at: mouseLoc)
        vertical.rulerWindow.rule.drawMouseTick(at: mouseLoc)
    }

}

