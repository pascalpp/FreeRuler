import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let defaults = UserDefaults.standard

    let horizontal = RulerController(type: .Horizontal)
    let vertical = RulerController(type: .Vertical)

//    var timer: Timer?
//    var currentTimerInterval: TimeInterval?
//    let foregroundTimerInterval: TimeInterval = 40 / 1000 // 25 fps
//    let backgroundTimerInterval: TimeInterval = 66 / 1000 // 15 fps

    @IBOutlet weak var groupedMenuItem: NSMenuItem!

    // MARK: - Lifecycle
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        horizontal.other = vertical.window
        vertical.other = horizontal.window
        
        updateGroupedRulers()
        
        horizontal.showWindow()
        vertical.showWindow()
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        horizontal.window.alphaValue = 0.9
        vertical.window.alphaValue = 0.9

//        currentTimerInterval = foregroundTimerInterval
//        startTimer()
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        horizontal.window.alphaValue = 0.5
        vertical.window.alphaValue = 0.5

//        currentTimerInterval = backgroundTimerInterval
//        startTimer()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func updateGroupedRulers() {
        let grouped = defaults.bool(forKey: "groupedRulers")

        horizontal.updateChildWindow()
        vertical.updateChildWindow()

        groupedMenuItem?.state = (grouped ? .on : .off)

        print("grouped", grouped)
    }

    @IBAction func toggleGroupedRulers(_ sender: Any) {
        let grouped = defaults.bool(forKey: "groupedRulers")
        defaults.set(!grouped, forKey: "groupedRulers")
        updateGroupedRulers()
    }

}



// MARK: - Timer
extension AppDelegate {

//    private func startTimer() {
//        timer?.invalidate()
//
//        timer = Timer.scheduledTimer(
//            timeInterval: currentTimerInterval!,
//            target: self,
//            selector: #selector(self.onInterval),
//            userInfo: nil,
//            repeats: true
//        )
//    }
//
//    @objc func onInterval() {
//        self.updateMouseLocation()
//    }
//
//    private func updateMouseLocation() {
//        var mouseLoc = NSEvent.mouseLocation
//        mouseLoc.x = mouseLoc.x.rounded()
//        mouseLoc.y = mouseLoc.y.rounded()
//        horizontal.rule?.drawMouseTick(at: mouseLoc)
//        vertical.rule?.drawMouseTick(at: mouseLoc)
//    }
//

}

