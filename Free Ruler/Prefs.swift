import Foundation

// define default preferences

struct Prefs {

    static var groupRulers          = Preference("groupRulers",         defaultValue: true)
    static var foregroundOpacity    = Preference("foregroundOpacity",   defaultValue: 90)
    static var backgroundOpacity    = Preference("backgroundOpacity",   defaultValue: 50)
    static var floatRulers          = Preference("floatRulers",         defaultValue: true)

}

// helper to convert opacity Int to window.alphaValue
func windowAlphaValue(_ value: Int) -> CGFloat {
    return CGFloat(value) / 100.0
}
