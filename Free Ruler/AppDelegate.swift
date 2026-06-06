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

    let crosshair = NSCursor.crosshair

    @IBOutlet weak var pixelsMenuItem: NSMenuItem!
    @IBOutlet weak var millimetersMenuItem: NSMenuItem!
    @IBOutlet weak var inchesMenuItem: NSMenuItem!
    @IBOutlet weak var cycleUnitsMenuItem: NSMenuItem!

    @IBOutlet weak var floatRulersMenuItem: NSMenuItem!
    @IBOutlet weak var groupRulersMenuItem: NSMenuItem!
    @IBOutlet weak var rulerShadowMenuItem: NSMenuItem!
    @IBOutlet weak var alignRulersMenuItem: NSMenuItem!

    var preferencesController: PreferencesController? = nil

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        subscribeToPrefs()
        updateDisplay()

        if APP_ICON_HELPER {
            let helper = AppIconLayout()
            helper.show()
        } else {
            showRulers()
        }

    }

    func subscribeToPrefs() {
        observers = [
            prefs.observe(\Prefs.unit, options: .new) { prefs, changed in
                self.updateUnitMenu()
                self.redrawRulers()
            },
            prefs.observe(\Prefs.floatRulers, options: .new) { prefs, changed in
                self.updateFloatRulersMenuItem()
            },
            prefs.observe(\Prefs.groupRulers, options: .new) { prefs, changed in
                self.updateGroupRulersMenuItem()
            },
            prefs.observe(\Prefs.rulerShadow, options: .new) { prefs, changed in
                self.updateRulerShadowMenuItem()
            },
        ]
    }

    func updateDisplay() {
        updateUnitMenu()
        updateFloatRulersMenuItem()
        updateGroupRulersMenuItem()
        updateRulerShadowMenuItem()
    }
    
    func updateUnitMenu() {
        pixelsMenuItem?.state      = prefs.unit == .pixels ? .on : .off
        millimetersMenuItem?.state = prefs.unit == .millimeters ? .on : .off
        inchesMenuItem?.state      = prefs.unit == .inches ? .on : .off
    }

    func redrawRulers() {
        for ruler in rulers {
            ruler.rulerWindow.rule.setNeedsDisplay(ruler.rulerWindow.rule.visibleRect)
        }
    }

    func updateFloatRulersMenuItem() {
        floatRulersMenuItem?.state = prefs.floatRulers ? .on : .off
    }

    func updateGroupRulersMenuItem() {
        groupRulersMenuItem?.state = prefs.groupRulers ? .on : .off
    }

    func updateRulerShadowMenuItem() {
        rulerShadowMenuItem?.state = prefs.rulerShadow ? .on : .off
    }

    func createRulersIfNeeded() {
        guard rulers.isEmpty else { return }

        rulers = [
            RulerController(Ruler(.vertical, name: "vertical-ruler")),
            RulerController(Ruler(.horizontal, name: "horizontal-ruler")),
        ]

        // let rulers know about each other
        // TODO: provide each ruler with otherRulers: [RulerWindow]
        rulers[0].otherWindow = rulers[1].rulerWindow
        rulers[1].otherWindow = rulers[0].rulerWindow
    }

    func showRulers() {
        createRulersIfNeeded()

        for ruler in rulers {
            showRuler(ruler)
        }
    }

    func toggleRuler(orientation: Orientation) {
        guard canToggleRulerVisibility else { return }
        guard let ruler = rulerController(orientation: orientation) else { return }

        if prefs.groupRulers {
            prefs.groupRulers = false
            detachRulerWindows()
        }

        if ruler.rulerWindow.isVisible {
            detachRulerWindow(ruler.rulerWindow)
            ruler.rulerWindow.orderOut(self)
        } else {
            showRuler(ruler)
        }

        updateRulerGrouping()
    }

    private func detachRulerWindows() {
        for ruler in rulers {
            detachRulerWindow(ruler.rulerWindow)
        }
    }

    private func rulerController(orientation: Orientation) -> RulerController? {
        createRulersIfNeeded()
        return existingRulerController(orientation: orientation)
    }

    private func existingRulerController(orientation: Orientation) -> RulerController? {
        return rulers.first { $0.ruler.orientation == orientation }
    }

    private func showRuler(_ ruler: RulerController) {
        ruler.showWindow(self)
        ruler.rulerWindow.orderFrontRegardless()
        updateRulerGrouping()
    }

    private func detachRulerWindow(_ window: RulerWindow) {
        for ruler in rulers {
            guard ruler.rulerWindow != window else { continue }

            ruler.rulerWindow.removeChildWindow(window)
            window.removeChildWindow(ruler.rulerWindow)
        }
    }

    private func updateRulerGrouping() {
        for ruler in rulers {
            ruler.updateChildWindow()
        }
    }

    private var isRulerFrontmost: Bool {
        return rulers.contains { $0.rulerWindow.isKeyWindow }
    }

    private var hasVisibleRuler: Bool {
        return rulers.contains { $0.rulerWindow.isVisible }
    }

    private var canToggleRulerVisibility: Bool {
        return isRulerFrontmost || !hasVisibleRuler
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showRulers()
            return false
        }

        return true
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        for ruler in rulers {
            ruler.foreground()
        }

        startTimer(timeInterval: foregroundTimerInterval)

        crosshair.push()
    }

    func applicationDidResignActive(_ notification: Notification) {
        for ruler in rulers {
            ruler.background()
        }

        startTimer(timeInterval: backgroundTimerInterval)

        crosshair.pop()
    }
    
    @IBAction func setUnitPixels(_ sender: Any) {
        prefs.unit = .pixels
    }
    @IBAction func setUnitMillimetres(_ sender: Any) {
        prefs.unit = .millimeters
    }
    @IBAction func setUnitInches(_ sender: Any) {
        prefs.unit = .inches
    }
    @IBAction func cycleUnits(_ sender: Any) {
        switch prefs.unit {
        case .pixels:
            prefs.unit = .millimeters
        case .millimeters:
            prefs.unit = .inches
        case .inches:
            prefs.unit = .pixels
        }
    }

    @IBAction func toggleFloatRulers(_ sender: Any) {
        prefs.floatRulers = !prefs.floatRulers
    }

    @IBAction func toggleGroupRulers(_ sender: Any) {
        prefs.groupRulers = !prefs.groupRulers
    }
    @IBAction func toggleRulerShadow(_ sender: Any) {
        prefs.rulerShadow = !prefs.rulerShadow
    }

    @IBAction func openPreferences(_ sender: Any) {
        if preferencesController == nil {
            preferencesController = PreferencesController()
        }

        if preferencesController != nil {
            preferencesController?.showWindow(self)
        }
    }

    @IBAction func closePreferences(_ sender: Any) {
        guard preferencesController?.window?.isKeyWindow == true else { return }
        preferencesController?.close()
    }

    @IBAction func alignRulersAtMouseLocation(_ sender: Any) {
        var mouseLoc = NSEvent.mouseLocation
        mouseLoc.x = mouseLoc.x.rounded()
        mouseLoc.y = mouseLoc.y.rounded()
        for ruler in rulers {
            ruler.alignRuler(at: mouseLoc)
        }
    }

    @IBAction func resetRulerPositions(_ sender: Any) {
        createRulersIfNeeded()

        // ungroup rulers during reset operation
        let groupRulers = prefs.groupRulers
        prefs.groupRulers = false
        for ruler in rulers {
            ruler.resetPosition()
            showRuler(ruler)
        }
        // reset groupRulers to previous value
        prefs.groupRulers = groupRulers
        updateRulerGrouping()
    }

    @IBAction func showRulers(_ sender: Any) {
        showRulers()
    }

    @IBAction func toggleHorizontalRuler(_ sender: Any) {
        toggleRuler(orientation: .horizontal)
    }

    @IBAction func toggleVerticalRuler(_ sender: Any) {
        toggleRuler(orientation: .vertical)
    }

    // MARK: - Application Quit

    func applicationWillTerminate(_ aNotification: Notification) {
        prefs.save()
    }

}

extension AppDelegate: NSMenuItemValidation {

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(closePreferences(_:)):
            return preferencesController?.window?.isKeyWindow == true
        case #selector(toggleHorizontalRuler(_:)):
            let ruler = existingRulerController(orientation: .horizontal)
            menuItem.title = ruler?.rulerWindow.isVisible == true
                ? NSLocalizedString("Hide Horizontal Ruler", comment: "Menu item title to hide the horizontal ruler")
                : NSLocalizedString("Show Horizontal Ruler", comment: "Menu item title to show the horizontal ruler")
            return canToggleRulerVisibility
        case #selector(toggleVerticalRuler(_:)):
            let ruler = existingRulerController(orientation: .vertical)
            menuItem.title = ruler?.rulerWindow.isVisible == true
                ? NSLocalizedString("Hide Vertical Ruler", comment: "Menu item title to hide the vertical ruler")
                : NSLocalizedString("Show Vertical Ruler", comment: "Menu item title to show the vertical ruler")
            return canToggleRulerVisibility
        case #selector(showRulers(_:)):
            menuItem.title = NSLocalizedString("Show All Rulers", comment: "Menu item title to show all ruler windows")
            return true
        default:
            return true
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
