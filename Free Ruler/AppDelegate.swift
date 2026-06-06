import Cocoa
import Carbon.HIToolbox

let env = ProcessInfo.processInfo.environment
let APP_ICON_HELPER = env["APP_ICON_HELPER"] != nil
let UI_TESTS = env["FREE_RULER_UI_TESTS"] != nil

private enum HotkeyBezelLocalizationKey: String {
    case rulersFloated = "HotkeyBezel.RulersFloated"
    case rulersUnfloated = "HotkeyBezel.RulersUnfloated"
    case rulersGrouped = "HotkeyBezel.RulersGrouped"
    case rulersUngrouped = "HotkeyBezel.RulersUngrouped"
    case shadowEnabled = "HotkeyBezel.ShadowEnabled"
    case shadowDisabled = "HotkeyBezel.ShadowDisabled"
    case unitsFormat = "HotkeyBezel.UnitsFormat"
    case pixelsUnit = "Unit.Pixels.Abbreviation"
    case millimetersUnit = "Unit.Millimeters.Abbreviation"
    case inchesUnit = "Unit.Inches.Abbreviation"

    var localizedString: String {
        NSLocalizedString(rawValue, comment: comment)
    }

    private var comment: String {
        switch self {
        case .rulersFloated:
            return "Hotkey status bezel text indicating rulers now float above other windows"
        case .rulersUnfloated:
            return "Hotkey status bezel text indicating rulers no longer float above other windows"
        case .rulersGrouped:
            return "Hotkey status bezel text indicating rulers are grouped"
        case .rulersUngrouped:
            return "Hotkey status bezel text indicating rulers are ungrouped"
        case .shadowEnabled:
            return "Hotkey status bezel text indicating ruler shadow is enabled"
        case .shadowDisabled:
            return "Hotkey status bezel text indicating ruler shadow is disabled"
        case .unitsFormat:
            return "Hotkey status bezel format for the selected measurement unit"
        case .pixelsUnit:
            return "Pixels unit abbreviation"
        case .millimetersUnit:
            return "Millimeters unit abbreviation"
        case .inchesUnit:
            return "Inches unit abbreviation"
        }
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var observers: [NSKeyValueObservation] = []

    var rulers: [RulerController] = []

    var timer: Timer?
    private var timerInterval: TimeInterval?
    let foregroundTimerInterval: TimeInterval = 1 / 60 // 60 fps
    let backgroundTimerInterval: TimeInterval = 1 / 30 // 30 fps

    let rulerCursorController = RulerCursorController()
    lazy var mouseTickTimerPolicy = MouseTickTimerPolicy(
        foregroundInterval: foregroundTimerInterval,
        backgroundInterval: backgroundTimerInterval
    )

    @IBOutlet weak var pixelsMenuItem: NSMenuItem!
    @IBOutlet weak var millimetersMenuItem: NSMenuItem!
    @IBOutlet weak var inchesMenuItem: NSMenuItem!
    @IBOutlet weak var cycleUnitsMenuItem: NSMenuItem!

    @IBOutlet weak var floatRulersMenuItem: NSMenuItem!
    @IBOutlet weak var groupRulersMenuItem: NSMenuItem!
    @IBOutlet weak var rulerShadowMenuItem: NSMenuItem!
    @IBOutlet weak var alignRulersMenuItem: NSMenuItem!

    var preferencesController: PreferencesController? = nil
    private let hotkeyBezel = HotkeyBezel()

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        if UI_TESTS {
            resetStateForUITests()
        }

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

    private func resetStateForUITests() {
        let defaults = UserDefaults.standard
        [
            "groupRulers",
            "floatRulers",
            "rulerShadow",
            "foregroundOpacity",
            "backgroundOpacity",
            "unit",
            "NSWindow Frame horizontal-ruler",
            "NSWindow Frame vertical-ruler",
            "NSWindow Frame preferencesWindow",
        ].forEach(defaults.removeObject(forKey:))

        prefs.groupRulers = true
        prefs.floatRulers = true
        prefs.rulerShadow = false
        prefs.foregroundOpacity = 90
        prefs.backgroundOpacity = 50
        prefs.unit = .pixels
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
            updateRulerGrouping()
            updateMouseTickTimer()
        } else {
            showRuler(ruler)
        }
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
        updateMouseTickTimer()
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

        mouseTickTimerPolicy.applicationDidBecomeActive()
        updateMouseTickTimer()

        rulerCursorController.applicationDidBecomeActive()
    }

    func applicationDidResignActive(_ notification: Notification) {
        for ruler in rulers {
            ruler.background()
        }

        mouseTickTimerPolicy.applicationDidResignActive()
        updateMouseTickTimer()

        rulerCursorController.applicationDidResignActive()
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

        showHotkeyBezel(format: .unitsFormat, unitLabel(prefs.unit), on: bezelScreen(for: sender))
    }

    @IBAction func toggleFloatRulers(_ sender: Any) {
        prefs.floatRulers = !prefs.floatRulers
        showHotkeyBezel(
            prefs.floatRulers ? .rulersFloated : .rulersUnfloated,
            on: bezelScreen(for: sender)
        )
    }

    @IBAction func toggleGroupRulers(_ sender: Any) {
        prefs.groupRulers = !prefs.groupRulers
        showGroupRulersHotkeyBezel(on: bezelScreen(for: sender))
    }
    @IBAction func toggleRulerShadow(_ sender: Any) {
        prefs.rulerShadow = !prefs.rulerShadow
        showHotkeyBezel(
            prefs.rulerShadow ? .shadowEnabled : .shadowDisabled,
            on: bezelScreen(for: sender)
        )
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

    func performRulerHotkey(keyCode: Int, sender: Any) -> Bool {
        switch keyCode {
        case kVK_ANSI_H:
            toggleHorizontalRuler(sender)
        case kVK_ANSI_V:
            toggleVerticalRuler(sender)
        case kVK_ANSI_U:
            cycleUnits(sender)
        case kVK_ANSI_F:
            toggleFloatRulers(sender)
        case kVK_ANSI_G:
            toggleGroupRulers(sender)
        case kVK_ANSI_S:
            toggleRulerShadow(sender)
        case kVK_ANSI_O:
            alignRulersAtMouseLocation(sender)
        default:
            return false
        }

        return true
    }

    private func showHotkeyBezel(_ key: HotkeyBezelLocalizationKey, on screen: NSScreen?) {
        hotkeyBezel.show(key.localizedString, on: screen)
    }

    private func showHotkeyBezel(format key: HotkeyBezelLocalizationKey, _ value: String, on screen: NSScreen?) {
        hotkeyBezel.show(String(format: key.localizedString, value), on: screen)
    }

    private func showGroupRulersHotkeyBezel(on screen: NSScreen?) {
        showHotkeyBezel(prefs.groupRulers ? .rulersGrouped : .rulersUngrouped, on: screen)
    }

    private func bezelScreen(for sender: Any) -> NSScreen? {
        if let rulerController = sender as? RulerController {
            return rulerController.rulerWindow.screen
        }

        return rulers.first { $0.rulerWindow.isKeyWindow }?.rulerWindow.screen
    }

    private func unitLabel(_ unit: Unit) -> String {
        switch unit {
        case .pixels:
            return HotkeyBezelLocalizationKey.pixelsUnit.localizedString
        case .millimeters:
            return HotkeyBezelLocalizationKey.millimetersUnit.localizedString
        case .inches:
            return HotkeyBezelLocalizationKey.inchesUnit.localizedString
        }
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

    func suspendMouseTickUpdates(owner: AnyObject) {
        mouseTickTimerPolicy.suspend(owner: owner)
        updateMouseTickTimer()
    }

    func resumeMouseTickUpdates(owner: AnyObject) {
        mouseTickTimerPolicy.resume(owner: owner)
        updateMouseTickTimer()
    }

    private func updateMouseTickTimer() {
        mouseTickTimerPolicy.updateVisibleRulers(hasVisibleRuler)

        guard let timeInterval = mouseTickTimerPolicy.desiredInterval else {
            stopTimer()
            return
        }

        startTimer(timeInterval: timeInterval)
    }

    private func startTimer(timeInterval: TimeInterval) {
        guard timer == nil || timerInterval != timeInterval else { return }

        timer?.invalidate()
        timerInterval = timeInterval

        timer = Timer.scheduledTimer(
            timeInterval: timeInterval,
            target: self,
            selector: #selector(self.onInterval),
            userInfo: nil,
            repeats: true
        )
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerInterval = nil
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
