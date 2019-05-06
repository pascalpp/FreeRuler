import Cocoa
import SwiftyUserDefaults

let env = ProcessInfo.processInfo.environment
let APP_ICON_HELPER = env["APP_ICON_HELPER"] != nil

extension DefaultsKeys {
    static let groupedRulers = DefaultsKey<Bool>("groupedRulers", defaultValue: false)
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let horizontal = RulerController(ruler: Ruler(.horizontal, name: "horizontal-ruler"))
    let vertical = RulerController(ruler: Ruler(.vertical, name: "vertical-ruler"))

    var timer: Timer?
    let foregroundTimerInterval: TimeInterval = 1 / 60 // 60 fps
    let backgroundTimerInterval: TimeInterval = 1 / 15 // 15 fps

    @IBOutlet weak var groupedMenuItem: NSMenuItem!
    
    var preferencesController: PreferencesController? = nil

    // MARK: - Lifecycle
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        updateGroupedRulers()
        
        if APP_ICON_HELPER {
            let helper = AppIconHelper()
            helper.show()
        } else {
            showRulers()
        }
        
    }
    
    func showRulers() {
        horizontal.otherWindow = vertical.rulerWindow
        vertical.otherWindow = horizontal.rulerWindow
        
        vertical.showWindow()
        horizontal.showWindow()
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

    }

    @IBAction func openPreferences(_ sender: Any) {
        if preferencesController == nil {
            preferencesController = PreferencesController(windowNibName: "PreferencesController")
        }
        
        if preferencesController != nil {
            preferencesController?.showWindow(nil)
        }
    }

    @IBAction func toggleGroupedRulers(_ sender: Any) {
        Defaults[.groupedRulers] = !Defaults[.groupedRulers]
        print("grouped", Defaults[.groupedRulers])
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

