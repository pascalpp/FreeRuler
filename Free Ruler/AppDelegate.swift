import Cocoa

let env = ProcessInfo.processInfo.environment
let APP_ICON_HELPER = env["APP_ICON_HELPER"] != nil

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var rulers: [RulerController] = []

    var timer: Timer?
    let foregroundTimerInterval: TimeInterval = 1 / 60 // 60 fps
    let backgroundTimerInterval: TimeInterval = 1 / 15 // 15 fps
    
    var grouped: Bool? {
        didSet {
            onChangeGrouped()
        }
    }

    @IBOutlet weak var groupedMenuItem: NSMenuItem!

    // MARK: - Lifecycle
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {

        // initialize preferences
        Prefs.readKeys()
        Prefs.bool(.groupRulers, defaultValue: true)
        Prefs.float(.foregroundOpacity, defaultValue: 0.9)
        Prefs.float(.backgroundOpacity, defaultValue: 0.5)
        
        grouped = Prefs.bool(.groupRulers)!
        
        if APP_ICON_HELPER {
            let helper = AppIconHelper()
            helper.show()
        } else {
            showRulers()
        }
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
            ruler.showWindow()
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

    func onChangeGrouped() {
        if let grouped = grouped {
            for ruler in rulers {
                ruler.onChangeGrouped()
            }

            groupedMenuItem?.state = (grouped ? .on : .off)
        }
    }

    @IBAction func toggleGroupedRulers(_ sender: Any) {
        grouped = !grouped!
        Prefs.set(.groupRulers, grouped!)
        print("grouped", grouped!)
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

