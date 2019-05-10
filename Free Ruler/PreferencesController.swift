import Cocoa

class PreferencesController: NSWindowController, NSWindowDelegate, NotificationPoster {
    
    @objc var prefs: Prefs?
    var observers: [NSKeyValueObservation] = []

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

        window?.isMovableByWindowBackground = true
        
        subscribeToPrefs()
        updateView()
    }
    
    func showWindow(_ sender: Any?, prefs: Prefs) {
        self.prefs = prefs

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
        guard let prefs = prefs else { return }
        observers = [
            prefs.observe(\Prefs.foregroundOpacity, options: .new) { ruler, changed in
                self.updateForegroundSlider()
            },
            prefs.observe(\Prefs.backgroundOpacity, options: .new) { ruler, changed in
                self.updateBackgroundSlider()
            },
            prefs.observe(\Prefs.floatRulers, options: .new) { ruler, changed in
                self.updateFloatRulersCheckbox()
            },
        ]
    }
    
    @IBAction func setForegroundOpacity(_ sender: Any) {
        prefs?.foregroundOpacity = foregroundOpacitySlider.integerValue
    }
    @IBAction func setBackgroundOpacity(_ sender: Any) {
        prefs?.backgroundOpacity = backgroundOpacitySlider.integerValue
    }
    @IBAction func setFloatRulers(_ sender: Any) {
        prefs?.floatRulers = floatRulersCheckbox.state == .on
    }
    
    func updateView() {
        updateForegroundSlider()
        updateBackgroundSlider()
        updateFloatRulersCheckbox()
    }
    
    func updateForegroundSlider() {
        if let foregroundOpacity = prefs?.foregroundOpacity {
            foregroundOpacitySlider.integerValue = foregroundOpacity
            foregroundOpacityLabel.stringValue = "\(foregroundOpacity)%"
        }
    }
    
    func updateBackgroundSlider() {
        if let backgroundOpacity = prefs?.backgroundOpacity {
            backgroundOpacitySlider.integerValue = backgroundOpacity
            backgroundOpacityLabel.stringValue = "\(backgroundOpacity)%"
        }
    }
    
    func updateFloatRulersCheckbox() {
        if let floatRulers = prefs?.floatRulers {
            floatRulersCheckbox.state = floatRulers ? .on : .off
        }
    }

}
