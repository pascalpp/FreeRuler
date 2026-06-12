import Cocoa

// Prefs
// a KVO bridge for UserDefaults
// - registers default values
// - exposes defaults on the prefs instance for key-value observation
// - listens for changes and persists new values to UserDefaults
// - provides save method to synchronize UserDefaults on applicationWillTerminate

// TODO: there's a lot of boilerplate in here, not sure if we can reduce it
// TODO: figure out how avoid saving values that haven't changed from the default

// MARK: - global shortcut to shared prefs instance
let prefs = Prefs.shared

@objc enum Unit: Int {
    case pixels
    case millimeters
    case inches
}

class Prefs: NSObject {

    // MARK: - shared singleton instance
    static let shared = Prefs()

    // MARK: - public properties
    @objc dynamic var floatRulers       : Bool
    @objc dynamic var groupRulers       : Bool
    @objc dynamic var rulerShadow       : Bool
    @objc dynamic var foregroundOpacity : Int
    @objc dynamic var backgroundOpacity : Int
    @objc dynamic var rulerColor        : NSColor
    @objc dynamic var unit              : Unit

    // MARK: - public save method
    func save() {
        defaults.synchronize()
    }

    // MARK: - private implementation

    private let defaults = UserDefaults.standard
    private static let defaultRulerColor = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)
    private static let defaultRulerColorData: Data? = {
        guard let data = archivedColorData(defaultRulerColor) else {
            assertionFailure("Unable to archive default ruler color")
            return nil
        }

        return data
    }()

    private static var defaultValues: [String: Any] {
        var values: [String: Any] = [
            "groupRulers":       true,
            "floatRulers":       true,
            "rulerShadow":       false,
            "foregroundOpacity": 90,
            "backgroundOpacity": 50,
            "unit":              Unit.pixels.rawValue
        ]

        if let defaultRulerColorData = Prefs.defaultRulerColorData {
            values["rulerColor"] = defaultRulerColorData
        }

        return values
    }

    private override init() {
        defaults.register(defaults: Prefs.defaultValues)

        floatRulers       = defaults.bool(forKey: "floatRulers")
        groupRulers       = defaults.bool(forKey: "groupRulers")
        rulerShadow       = defaults.bool(forKey: "rulerShadow")
        foregroundOpacity = defaults.integer(forKey: "foregroundOpacity")
        backgroundOpacity = defaults.integer(forKey: "backgroundOpacity")
        rulerColor        = Prefs.unarchiveColor(defaults.data(forKey: "rulerColor")) ?? Prefs.defaultRulerColor
        unit              = Unit(rawValue: defaults.integer(forKey: "unit")) ?? .pixels

        super.init()

        addObservers()
    }

    private var observers: [NSKeyValueObservation] = []

    private func addObservers() {
        observers = [
            observe(\Prefs.floatRulers, options: .new) { prefs, changed in
                self.defaults.set(changed.newValue, forKey: "floatRulers")
            },
            observe(\Prefs.groupRulers, options: .new) { prefs, changed in
                self.defaults.set(changed.newValue, forKey: "groupRulers")
            },
            observe(\Prefs.rulerShadow, options: .new) { prefs, changed in
                self.defaults.set(changed.newValue, forKey: "rulerShadow")
            },
            observe(\Prefs.foregroundOpacity, options: .new) { prefs, changed in
                self.defaults.set(changed.newValue, forKey: "foregroundOpacity")
            },
            observe(\Prefs.backgroundOpacity, options: .new) { prefs, changed in
                self.defaults.set(changed.newValue, forKey: "backgroundOpacity")
            },
            observe(\Prefs.rulerColor, options: .new) { prefs, changed in
                guard let color = changed.newValue else { return }
                let colorToArchive = Prefs.normalizedRulerColor(color)
                guard let data = Prefs.archivedColorData(colorToArchive) else { return }
                self.defaults.set(data, forKey: "rulerColor")
            },
            observe(\Prefs.unit, options: .new) { prefs, changed in
                self.defaults.set(prefs.unit.rawValue, forKey: "unit")
            },
        ]
    }

}

extension Prefs {
    static var defaultRulerFillColor: NSColor {
        return defaultRulerColor
    }

    private static func archivedColorData(_ color: NSColor) -> Data? {
        return try? NSKeyedArchiver.archivedData(
            withRootObject: color,
            requiringSecureCoding: true
        )
    }

    private static func normalizedRulerColor(_ color: NSColor) -> NSColor {
        return color.usingColorSpace(.deviceRGB) ?? defaultRulerColor
    }

    private static func unarchiveColor(_ data: Data?) -> NSColor? {
        guard let data = data else { return nil }

        return try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: NSColor.self,
            from: data
        )
    }
}
