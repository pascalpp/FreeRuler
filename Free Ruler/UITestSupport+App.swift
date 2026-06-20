import Foundation

extension UITestSupport {
    func resetApplicationState() {
        let defaults = UserDefaults.standard
        [
            "groupRulers",
            "floatRulers",
            "rulerShadow",
            "foregroundOpacity",
            "backgroundOpacity",
            "rulerColor",
            "unit",
            "zeroCorner",
            Prefs.rulerSetStateKey,
            "NSWindow Frame horizontal-ruler",
            "NSWindow Frame vertical-ruler",
            "NSWindow Frame preferencesWindow",
        ].forEach(defaults.removeObject(forKey:))

        prefs.groupRulers = Prefs.defaultGroupRulers
        prefs.floatRulers = true
        prefs.rulerShadow = false
        prefs.foregroundOpacity = 90
        prefs.backgroundOpacity = 50
        prefs.rulerColor = Prefs.defaultRulerFillColor
        prefs.unit = .pixels
        prefs.zeroCorner = Prefs.defaultZeroCorner
    }

    func writePreferencesState(activeSettings: RulerSettings? = nil) {
        let activeSettings = activeSettings ?? RulerSettings(defaults: prefs)
        let state = [
            "activeFloatRulers": boolStateValue(activeSettings.floatRulers),
            "activeRulerShadow": boolStateValue(activeSettings.rulerShadow),
            "activeUnit": unitStateValue(activeSettings.unit),
            "floatRulers": boolStateValue(prefs.floatRulers),
            "groupRulers": boolStateValue(prefs.groupRulers),
            "rulerShadow": boolStateValue(prefs.rulerShadow),
            "unit": unitStateValue(prefs.unit),
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: state, options: [.sortedKeys]),
              let value = String(data: data, encoding: .utf8) else { return }

        writeState(value, to: preferencesStateURL)
    }

    private func boolStateValue(_ value: Bool) -> String {
        return value ? "true" : "false"
    }

    private func unitStateValue(_ unit: Unit) -> String {
        switch unit {
        case .pixels:
            return "px"
        case .millimeters:
            return "mm"
        case .inches:
            return "in"
        }
    }
}
