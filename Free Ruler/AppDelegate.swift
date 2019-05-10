import Cocoa

let env = ProcessInfo.processInfo.environment
let APP_ICON_HELPER = env["APP_ICON_HELPER"] != nil

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var observers: [NSKeyValueObservation] = []
    
    var rulers: [RulerController] = []

    var timer: Timer?
    let foregroundTimerInterval: TimeInterval = 1 / 60 // 60 fps
    let backgroundTimerInterval: TimeInterval = 1 / 30 // 30 fps

    @IBOutlet weak var groupedMenuItem: NSMenuItem!

    var preferencesController: PreferencesController? = nil

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        subscribeToPrefs()
        updateDisplay()

        if APP_ICON_HELPER {
            let helper = AppIconHelper()
            helper.show()
        } else {
            showRulers()
        }

    }
    
    func subscribeToPrefs() {
        observers = [
            prefs.observe(\Prefs.groupRulers, options: .new) { ruler, changed in
                self.updateGroupRulersMenuItem()
            },
        ]
    }

    func updateDisplay() {
        updateGroupRulersMenuItem()
    }

    func updateGroupRulersMenuItem() {
        groupedMenuItem?.state = prefs.groupRulers ? .on : .off
    }
    
    func showRulers() {
        rulers = [
            RulerController(ruler: Ruler(.horizontal, name: "horizontal-ruler")),
            RulerController(ruler: Ruler(.vertical, name: "vertical-ruler")),
        ]

        // let rulers know about each other
        // TODO: provide each ruler with otherRulers: [RulerWindow]
        rulers[0].otherWindow = rulers[1].rulerWindow
        rulers[1].otherWindow = rulers[0].rulerWindow

        for ruler in rulers {
            
            ruler.showWindow(self)
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        for ruler in rulers {
            ruler.foreground()
        }

        startTimer(timeInterval: foregroundTimerInterval)
    }

    func applicationDidResignActive(_ notification: Notification) {
        for ruler in rulers {
            ruler.background()
        }

        startTimer(timeInterval: backgroundTimerInterval)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func toggleGroupedRulers(_ sender: Any) {
        prefs.groupRulers = !prefs.groupRulers
    }

    @IBAction func openPreferences(_ sender: Any) {
        if preferencesController == nil {
            preferencesController = PreferencesController()
        }

        if preferencesController != nil {
            preferencesController?.showWindow(self)
        }
    }

    @IBAction func resetRulerPositions(_ sender: Any) {
        for ruler in rulers {
            ruler.resetPosition()
        }
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
        for ruler in rulers {
            ruler.rulerWindow.rule.drawMouseTick(at: mouseLoc)
        }
    }

}
