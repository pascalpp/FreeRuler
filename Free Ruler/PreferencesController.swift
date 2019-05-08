import Cocoa

class PreferencesController: NSWindowController, PreferenceSubscriber {

    @IBOutlet weak var rulerColorWell: NSColorWell!
    
    @IBOutlet weak var foregroundOpacitySlider: NSSlider!
    @IBOutlet weak var backgroundOpacitySlider: NSSlider!

    @IBOutlet weak var foregroundOpacityLabel: NSTextField!
    @IBOutlet weak var backgroundOpacityLabel: NSTextField!
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        
        Prefs.foregroundOpacity.subscribe(self)
        Prefs.backgroundOpacity.subscribe(self)
        
        updateView()
    }

    @IBAction func setForegroundOpacity(_ sender: Any) {
        Prefs.foregroundOpacity.value = foregroundOpacitySlider.integerValue
    }
    @IBAction func setBackgroundOpacity(_ sender: Any) {
        Prefs.backgroundOpacity.value = backgroundOpacitySlider.integerValue
    }
    
    func updateView() {
        updateForegroundSlider()
        updateBackgroundSlider()
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

    func onChangePreference(_ name: String) {
        print("onChangePreference", name)
        switch name {
        case Prefs.foregroundOpacity.name:
            updateForegroundSlider()
        case Prefs.backgroundOpacity.name:
            updateBackgroundSlider()
        default:
            break
        }
    }

}
