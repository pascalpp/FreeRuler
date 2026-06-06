import Cocoa

class PreferencesController: NSWindowController, NSWindowDelegate, NotificationPoster {

    var observers: [NSKeyValueObservation] = []

    @IBOutlet weak var foregroundOpacitySlider: NSSlider!
    @IBOutlet weak var backgroundOpacitySlider: NSSlider!

    @IBOutlet weak var foregroundOpacityLabel: NSTextField!
    @IBOutlet weak var backgroundOpacityLabel: NSTextField!

    @IBOutlet weak var floatRulersCheckbox: NSButton!
    @IBOutlet weak var groupRulersCheckbox: NSButton!
    @IBOutlet weak var rulerShadowCheckbox: NSButton!

    @IBOutlet weak var UserUnitScreenValueTbx: NSTextField!
    @IBOutlet weak var UserUnitScreenUnitPopup: NSPopUpButton!
    @IBOutlet weak var UserUnitValueTbx: NSTextField!
    @IBOutlet weak var UserUnitUnitTbx: NSTextField!
    

    override var windowNibName: String {
        return "PreferencesController"
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        window?.isMovableByWindowBackground = true

        if let app=NSApplication.shared.delegate as? AppDelegate{
            UserUnitScreenUnitPopup.addItems(withTitles: [
                app.pixelsMenuItem.title,
                app.millimetersMenuItem.title,
                app.inchesMenuItem.title
            ])
        }

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
            prefs.observe(\Prefs.userUnitScreenValue, options:.new){ prefs, changed in
                self.updateUserUnitScreenValue()
            },
            prefs.observe(\Prefs.userUnitScreenUnit, options:.new){ prefs, changed in
                self.updateUserUnitScreenUnit()
            },
            prefs.observe(\Prefs.userUnitValue, options:.new){ prefs, changed in
                self.updateUserUnitValue()
            },
            prefs.observe(\Prefs.userUnitUnit, options:.new){ prefs, changed in
                self.updateUserUnitUnit()
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
    @IBAction func setUserScreenValue(_ Sender: Any) {
        prefs.userUnitScreenValue = UserUnitScreenValueTbx.floatValue
    }
    var screen: NSScreen? {
        guard let window = window else {
            return nil
        }
        return NSScreen.screens.first { $0.frame.intersects(window.convertToScreen(self.UserUnitScreenUnitPopup.frame)) }
    }
    @IBAction func setUserScreenUnit(_ Sender: Any) {
        let oldScale:Float
        switch(prefs.userUnitScreenUnit) {
        case .pixels:      oldScale = 1.0
        case .millimeters: oldScale = Float(screen?.dpmm.width ?? NSScreen.defaultDpmm)
        case .inches:      oldScale = Float(screen?.dpi.width ?? NSScreen.defaultDpi)
        default:           oldScale = 1.0
        }

        switch(UserUnitScreenUnitPopup.indexOfSelectedItem){
        case 0:  prefs.userUnitScreenUnit = .pixels
        case 1:  prefs.userUnitScreenUnit = .millimeters
        case 2:  prefs.userUnitScreenUnit = .inches
        default: prefs.userUnitScreenUnit = .pixels
        }

        let newScale:Float
        switch(prefs.userUnitScreenUnit) {
        case .pixels:      newScale = 1.0
        case .millimeters: newScale = Float(screen?.dpmm.width ?? NSScreen.defaultDpmm)
        case .inches:      newScale = Float(screen?.dpi.width ?? NSScreen.defaultDpi)
        default:           newScale = 1.0
        }
        prefs.userUnitScreenValue = prefs.userUnitScreenValue * oldScale / newScale;
    }
    @IBAction func setUserUnitValue(_ Sender: Any) {
        prefs.userUnitValue = UserUnitValueTbx.floatValue
    }
    @IBAction func setUserUnit(_ Sender: Any) {
        prefs.userUnitUnit = UserUnitUnitTbx.stringValue
    }

    func updateView() {
        updateForegroundSlider()
        updateBackgroundSlider()
        updateFloatRulersCheckbox()
        updateGroupRulersCheckbox()
        updateRulerShadowCheckbox()
        updateUserUnitScreenValue()
        updateUserUnitScreenUnit()
        updateUserUnitValue()
        updateUserUnitUnit()
    }

    func updateForegroundSlider() {
        foregroundOpacitySlider.integerValue = prefs.foregroundOpacity
        foregroundOpacityLabel.stringValue = "\(prefs.foregroundOpacity)%"
    }

    func updateBackgroundSlider() {
        backgroundOpacitySlider.integerValue = prefs.backgroundOpacity
        backgroundOpacityLabel.stringValue = "\(prefs.backgroundOpacity)%"
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

    func updateUserUnitScreenValue() {
        UserUnitScreenValueTbx.floatValue = prefs.userUnitScreenValue
    }
    
    func updateUserUnitScreenUnit() {
        switch(prefs.userUnitScreenUnit) {
        case .pixels:      UserUnitScreenUnitPopup.selectItem(at: 0)
        case .millimeters: UserUnitScreenUnitPopup.selectItem(at: 1)
        case .inches:      UserUnitScreenUnitPopup.selectItem(at: 2)
        default:           UserUnitScreenUnitPopup.selectItem(at: 0)
        }
    }
    func updateUserUnitValue(){
        UserUnitValueTbx.floatValue = prefs.userUnitValue
    }
    
    func updateUserUnitUnit(){
        UserUnitUnitTbx.stringValue = prefs.userUnitUnit
    }

}
