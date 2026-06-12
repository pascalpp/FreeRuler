import Cocoa

class PreferencesController: NSWindowController, NSWindowDelegate, NotificationPoster {

    var observers: [NSKeyValueObservation] = []

    @IBOutlet weak var foregroundOpacitySlider: NSSlider!
    @IBOutlet weak var backgroundOpacitySlider: NSSlider!

    @IBOutlet weak var foregroundOpacityLabel: NSTextField!
    @IBOutlet weak var backgroundOpacityLabel: NSTextField!

    @IBOutlet weak var rulerColorWell: NSColorWell!

    @IBOutlet weak var floatRulersCheckbox: NSButton!
    @IBOutlet weak var groupRulersCheckbox: NSButton!
    @IBOutlet weak var rulerShadowCheckbox: NSButton!

    override var windowNibName: String {
        return "PreferencesController"
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        window?.delegate = self
        window?.identifier = NSUserInterfaceItemIdentifier("preferences-window")
        window?.isMovableByWindowBackground = true
        floatRulersCheckbox.identifier = NSUserInterfaceItemIdentifier("float-rulers-checkbox")
        floatRulersCheckbox.setAccessibilityIdentifier("float-rulers-checkbox")
        groupRulersCheckbox.identifier = NSUserInterfaceItemIdentifier("group-rulers-checkbox")
        groupRulersCheckbox.setAccessibilityIdentifier("group-rulers-checkbox")
        rulerShadowCheckbox.identifier = NSUserInterfaceItemIdentifier("ruler-shadow-checkbox")
        rulerShadowCheckbox.setAccessibilityIdentifier("ruler-shadow-checkbox")
        rulerColorWell.isContinuous = true
        rulerColorWell.identifier = NSUserInterfaceItemIdentifier("ruler-color-well")
        rulerColorWell.setAccessibilityIdentifier("ruler-color-well")

        subscribeToPrefs()
        updateView()
    }

    override func showWindow(_ sender: Any?) {

        // send opened notification
        post(.preferencesWindowOpened)

        window?.makeKeyAndOrderFront(sender)
        window?.center()
    }

    func windowWillClose(_ notification: Notification) {
        // send closed notification
        post(.preferencesWindowClosed)
    }

    func subscribeToPrefs() {
        observers = [
            prefs.observe(\Prefs.foregroundOpacity, options: .new) { prefs, changed in
                self.updateForegroundSlider()
            },
            prefs.observe(\Prefs.backgroundOpacity, options: .new) { prefs, changed in
                self.updateBackgroundSlider()
            },
            prefs.observe(\Prefs.floatRulers, options: .new) { prefs, changed in
                self.updateFloatRulersCheckbox()
            },
            prefs.observe(\Prefs.groupRulers, options: .new) { prefs, changed in
                self.updateGroupRulersCheckbox()
            },
            prefs.observe(\Prefs.rulerShadow, options: .new) { prefs, changed in
                self.updateRulerShadowCheckbox()
            },
            prefs.observe(\Prefs.rulerColor, options: .new) { prefs, changed in
                self.updateRulerColorWell()
            },
        ]
    }

    @IBAction func setForegroundOpacity(_ sender: Any) {
        prefs.foregroundOpacity = foregroundOpacitySlider.integerValue
    }
    @IBAction func setBackgroundOpacity(_ sender: Any) {
        prefs.backgroundOpacity = backgroundOpacitySlider.integerValue
    }
    @IBAction func setFloatRulers(_ sender: Any) {
        prefs.floatRulers = floatRulersCheckbox.state == .on
    }
    @IBAction func setGroupRulers(_ sender: Any) {
        prefs.groupRulers = groupRulersCheckbox.state == .on
    }
    @IBAction func setRulerShadow(_ sender: Any) {
        prefs.rulerShadow = rulerShadowCheckbox.state == .on
    }
    @IBAction func setRulerColor(_ sender: Any) {
        prefs.rulerColor = rulerColorWell.color
    }

    func updateView() {
        updateForegroundSlider()
        updateBackgroundSlider()
        updateRulerColorWell()
        updateFloatRulersCheckbox()
        updateGroupRulersCheckbox()
        updateRulerShadowCheckbox()
    }

    func updateForegroundSlider() {
        foregroundOpacitySlider.integerValue = prefs.foregroundOpacity
        foregroundOpacityLabel.stringValue = "\(prefs.foregroundOpacity)%"
    }

    func updateBackgroundSlider() {
        backgroundOpacitySlider.integerValue = prefs.backgroundOpacity
        backgroundOpacityLabel.stringValue = "\(prefs.backgroundOpacity)%"
    }

    func updateRulerColorWell() {
        rulerColorWell.color = prefs.rulerColor
    }

    func updateFloatRulersCheckbox() {
        floatRulersCheckbox.state = prefs.floatRulers ? .on : .off
    }

    func updateGroupRulersCheckbox() {
        groupRulersCheckbox.state = prefs.groupRulers ? .on : .off
    }

    func updateRulerShadowCheckbox() {
        rulerShadowCheckbox.state = prefs.rulerShadow ? .on : .off
    }

}
