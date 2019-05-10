import Foundation

// define default preferences

//let prefs = UserDefaults.standard

//let defaults: [String: Any] = [
//    "groupRulers": true,
//    "floatRulers": true,
//    "foregroundOpacity": 90,
//    "backgroundOpacity": 50,
//]
//

class Prefs: NSObject {
    
    @objc dynamic var groupRulers          = true
    @objc dynamic var foregroundOpacity    = 90
    @objc dynamic var backgroundOpacity    = 50
    @objc dynamic var floatRulers          = true
    
}



// TODO: figure registering defaults
// TODO: figure out saving preferences on quit
