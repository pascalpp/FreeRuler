import Cocoa

class PreferencesController: NSWindowController {

    @IBOutlet weak var rulerColorWell: NSColorWell!
    
    @IBOutlet weak var foregroundOpacitySlider: NSSlider!
    @IBOutlet weak var backgroundOpacitySlider: NSSlider!

    @IBOutlet weak var foregroundOpacityLabel: NSTextField!
    @IBOutlet weak var backgroundOpacityLabel: NSTextField!
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        
        updateDisplay()
    }
    
    func updateDisplay() {
        let foregroundOpacity = Prefs.foregroundOpacity.value
        let backgroundOpacity = Prefs.backgroundOpacity.value
        
        foregroundOpacitySlider.integerValue = foregroundOpacity
        backgroundOpacitySlider.integerValue = backgroundOpacity
        
        foregroundOpacityLabel.stringValue = "\(foregroundOpacity)%"
        backgroundOpacityLabel.stringValue = "\(backgroundOpacity)%"

    }

    @IBAction func setForegroundOpacity(_ sender: Any) {
        Prefs.foregroundOpacity.value = foregroundOpacitySlider.integerValue
        updateDisplay()
    }
    
}
