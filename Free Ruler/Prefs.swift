import Foundation

// TODO: there's a lot of boilerplate in here, not sure if we can reduce it

class Prefs: NSObject {

    let defaults = UserDefaults.standard

    var values: [String: Any] = [
        "groupRulers":       true,
        "floatRulers":       true,
        "foregroundOpacity": 90,
        "backgroundOpacity": 50,
    ]

    @objc dynamic var floatRulers       : Bool
    @objc dynamic var groupRulers       : Bool
    @objc dynamic var foregroundOpacity : Int
    @objc dynamic var backgroundOpacity : Int

    var observers: [NSKeyValueObservation] = []

    override init() {
        defaults.register(defaults: values)

        floatRulers       = defaults.bool(forKey: "floatRulers")
        groupRulers       = defaults.bool(forKey: "groupRulers")
        foregroundOpacity = defaults.integer(forKey: "foregroundOpacity")
        backgroundOpacity = defaults.integer(forKey: "backgroundOpacity")

        super.init()

        self.updateValues()

        addObservers()
    }

    func addObservers() {
        observers = [
            observe(\Prefs.floatRulers, options: .new) { prefs, changed in
                self.updateValues()
            },
            observe(\Prefs.groupRulers, options: .new) { prefs, changed in
                self.updateValues()
            },
            observe(\Prefs.foregroundOpacity, options: .new) { prefs, changed in
                self.updateValues()
            },
            observe(\Prefs.backgroundOpacity, options: .new) { prefs, changed in
                self.updateValues()
            },
        ]
    }

    func updateValues() {
        values["floatRulers"] = floatRulers
        values["groupRulers"] = groupRulers
        values["foregroundOpacity"] = foregroundOpacity
        values["backgroundOpacity"] = backgroundOpacity
    }

    func save() {
        defaults.setValuesForKeys(values)
    }
}

let prefs = Prefs()

// TODO: figure registering defaults
// TODO: figure out saving preferences on quit

// above is sorta working but not quite
// TODO: figure out how avoid saving values that haven't changed from the default
