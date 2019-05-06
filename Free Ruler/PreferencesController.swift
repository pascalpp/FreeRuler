import Cocoa
import SwiftyUserDefaults

let defaults = UserDefaults.standard

class PreferencesController: NSWindowController {

    @IBOutlet weak var rulerColorWell: NSColorWell!
    
    @IBOutlet weak var foregroundOpacitySlider: NSSlider!
    @IBOutlet weak var backgroundOpacitySlider: NSSlider!

    @IBOutlet weak var foregroundOpacityLabel: NSTextField!
    @IBOutlet weak var backgroundOpacityLabel: NSTextField!
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        
        print(defaults.dictionaryRepresentation().keys)
        print(defaults.dictionaryRepresentation().values)
        
        updateDisplay()
    }
    
    func updateDisplay() {
        let foregroundOpacity = Int(defaults.float(forKey: "foregroundOpacity") * 100)
        let backgroundOpacity = Int(defaults.float(forKey: "backgroundOpacity") * 100)
        
        foregroundOpacitySlider.integerValue = foregroundOpacity
        backgroundOpacitySlider.integerValue = backgroundOpacity
        
        foregroundOpacityLabel.stringValue = "\(foregroundOpacity)%"
        backgroundOpacityLabel.stringValue = "\(backgroundOpacity)%"

    }

    @IBAction func setForegroundOpacity(_ sender: Any) {
        print("---------------------")
        print("integerValue", foregroundOpacitySlider.integerValue)
        
        let value = foregroundOpacitySlider.floatValue / 100

        print("floatValue", value)

        Defaults[.foregroundOpacity] = Float(value)

        print("Defaults", Defaults[.foregroundOpacity])
        
        // TODO why isn't the default updating?

        defaults.set(value, forKey: "foregroundOpacity")
        
        print(defaults.float(forKey: "unknown"))
        
        updateDisplay()
    }
    
}
