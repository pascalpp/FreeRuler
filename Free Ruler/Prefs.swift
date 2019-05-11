import Foundation

// Prefs
// a KVO bridge for UserDefaults
// - registers default values
// - exposes defaults on the prefs instance for key-value observation
// - listens for changes and persists new values to UserDefaults
// - provides save method to synchronize UserDefaults on applicationWillTerminate

// TODO: there's a lot of boilerplate in here, not sure if we can reduce it
// TODO: figure out how avoid saving values that haven't changed from the default

class Prefs: NSObject {

    let defaults = UserDefaults.standard

    var defaultValues: [String: Any] = [
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
        defaults.register(defaults: defaultValues)

        floatRulers       = defaults.bool(forKey: "floatRulers")
        groupRulers       = defaults.bool(forKey: "groupRulers")
        foregroundOpacity = defaults.integer(forKey: "foregroundOpacity")
        backgroundOpacity = defaults.integer(forKey: "backgroundOpacity")

        super.init()

        addObservers()
    }

    func addObservers() {
        observers = [
            observe(\Prefs.floatRulers, options: .new) { prefs, changed in
                self.defaults.set(changed.newValue, forKey: "floatRulers")
            },
            observe(\Prefs.groupRulers, options: .new) { prefs, changed in
                self.defaults.set(changed.newValue, forKey: "groupRulers")
            },
            observe(\Prefs.foregroundOpacity, options: .new) { prefs, changed in
                self.defaults.set(changed.newValue, forKey: "foregroundOpacity")
            },
            observe(\Prefs.backgroundOpacity, options: .new) { prefs, changed in
                self.defaults.set(changed.newValue, forKey: "backgroundOpacity")
            },
        ]
    }

    func save() {
        defaults.synchronize()
    }
}

let prefs = Prefs()
