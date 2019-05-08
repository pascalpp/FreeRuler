import Foundation

// define default preferences

struct Prefs {

    static var groupRulers          = Preference("groupRulers",         defaultValue: true)
    static var foregroundOpacity    = Preference("foregroundOpacity",   defaultValue: CGFloat(0.9))
    static var backgroundOpacity    = Preference("backgroundOpacity",   defaultValue: CGFloat(0.5))
    static var floatRulers          = Preference("floatRulers",         defaultValue: true)

}
