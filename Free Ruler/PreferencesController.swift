import Cocoa

class PreferencesController: NSWindowController, NSWindowDelegate, PreferenceSubscriber {
    
    @IBOutlet weak var foregroundOpacitySlider: NSSlider!
    @IBOutlet weak var backgroundOpacitySlider: NSSlider!

    @IBOutlet weak var foregroundOpacityLabel: NSTextField!
    @IBOutlet weak var backgroundOpacityLabel: NSTextField!
    
    @IBOutlet weak var floatRulersCheckbox: NSButton!
    
    override var windowNibName: String {
        return "PreferencesController"
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        
        window?.isMovableByWindowBackground = true
        
        subscribeToPrefs()
        updateView()
    }
    
    override func showWindow(_ sender: Any?) {
        // send opened notification
        Notes.post(.preferencesWindowOpened)

        window?.makeKeyAndOrderFront(sender)
        window?.center()
    }
    
    func windowWillClose(_ notification: Notification) {
        // send closed notification
        Notes.post(.preferencesWindowClosed)
    }

    func subscribeToPrefs() {
        Prefs.foregroundOpacity.subscribe(self)
        Prefs.backgroundOpacity.subscribe(self)
        Prefs.floatRulers.subscribe(self)
    }
    
    func onChangePreference(_ name: String) {
        switch name {
        case Prefs.foregroundOpacity.name:
            updateForegroundSlider()
        case Prefs.backgroundOpacity.name:
            updateBackgroundSlider()
        case Prefs.floatRulers.name:
            updateFloatRulersCheckbox()
        default:
            break
        }
    }

    @IBAction func setForegroundOpacity(_ sender: Any) {
        Prefs.foregroundOpacity.value = foregroundOpacitySlider.integerValue
    }
    @IBAction func setBackgroundOpacity(_ sender: Any) {
        Prefs.backgroundOpacity.value = backgroundOpacitySlider.integerValue
    }
    @IBAction func setFloatRulers(_ sender: Any) {
        Prefs.floatRulers.value = floatRulersCheckbox.state == .on
    }
    
    func updateView() {
        updateForegroundSlider()
        updateBackgroundSlider()
        updateFloatRulersCheckbox()
    }
    
    func updateForegroundSlider() {
        let foregroundOpacity = Prefs.foregroundOpacity.value
        foregroundOpacitySlider.integerValue = foregroundOpacity
        foregroundOpacityLabel.stringValue = "\(foregroundOpacity)%"
    }
    
    func updateBackgroundSlider() {
        let backgroundOpacity = Prefs.backgroundOpacity.value
        backgroundOpacitySlider.integerValue = backgroundOpacity
        backgroundOpacityLabel.stringValue = "\(backgroundOpacity)%"
    }
    
    func updateFloatRulersCheckbox() {
        floatRulersCheckbox.state = Prefs.floatRulers.value ? .on : .off
    }

}
