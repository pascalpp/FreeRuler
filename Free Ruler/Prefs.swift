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

    private struct UserDefaultsConfiguration {
        let defaults: UserDefaults
        let persistentDomainName: String?
    }

    // MARK: - shared singleton instance
    static let shared = Prefs(defaults: userDefaultsConfiguration.defaults)
    static var userDefaults: UserDefaults {
        return shared.defaults
    }
    static var userDefaultsPersistentDomainName: String? {
        return userDefaultsConfiguration.persistentDomainName
    }

    // MARK: - public properties
    @objc dynamic var floatRulers       : Bool
    @objc dynamic var groupRulers       : Bool
    @objc dynamic var rulerShadow       : Bool
    @objc dynamic var foregroundOpacity : Int
    @objc dynamic var backgroundOpacity : Int
    @objc dynamic var rulerColor        : NSColor
    @objc dynamic var unit              : Unit
    @objc dynamic var defaultHorizontalLength: Double
    @objc dynamic var defaultVerticalLength: Double
    @objc dynamic var zeroCorner        : ZeroCorner

    // MARK: - public save method
    func save() {
        defaults.synchronize()
    }

    // MARK: - private implementation

    private let defaults: UserDefaults
    private static let userDefaultsConfiguration: UserDefaultsConfiguration = {
        guard isRunningHostedUnitTests else {
            return UserDefaultsConfiguration(
                defaults: .standard,
                persistentDomainName: Bundle.main.bundleIdentifier
            )
        }

        let suiteName = "com.pascal.freeruler.unit-tests"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return UserDefaultsConfiguration(
                defaults: .standard,
                persistentDomainName: Bundle.main.bundleIdentifier
            )
        }

        defaults.removePersistentDomain(forName: suiteName)
        return UserDefaultsConfiguration(defaults: defaults, persistentDomainName: suiteName)
    }()
    private static var isRunningHostedUnitTests: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["XCTestConfigurationFilePath"] != nil
            && environment["FREE_RULER_UI_TESTS"] == nil
    }
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
            "groupRulers":       defaultGroupRulers,
            "floatRulers":       defaultFloatRulers,
            "rulerShadow":       defaultRulerShadow,
            "foregroundOpacity": defaultForegroundOpacity,
            "backgroundOpacity": defaultBackgroundOpacity,
            "unit":              defaultUnit.rawValue,
            "defaultHorizontalLength": unsetDefaultRulerLength,
            "defaultVerticalLength": unsetDefaultRulerLength,
            "zeroCorner":        defaultZeroCorner.rawValue
        ]

        if let defaultRulerColorData = Prefs.defaultRulerColorData {
            values["rulerColor"] = defaultRulerColorData
        }

        return values
    }

    private init(defaults: UserDefaults) {
        self.defaults = defaults
        defaults.register(defaults: Prefs.defaultValues)

        floatRulers       = defaults.bool(forKey: "floatRulers")
        groupRulers       = defaults.bool(forKey: "groupRulers")
        rulerShadow       = defaults.bool(forKey: "rulerShadow")
        foregroundOpacity = defaults.integer(forKey: "foregroundOpacity")
        backgroundOpacity = defaults.integer(forKey: "backgroundOpacity")
        rulerColor        = Prefs.rulerFillColor(fromArchivedData: defaults.data(forKey: "rulerColor"))
        unit              = Unit(rawValue: defaults.integer(forKey: "unit")) ?? .pixels
        defaultHorizontalLength = defaults.double(forKey: "defaultHorizontalLength")
        defaultVerticalLength = defaults.double(forKey: "defaultVerticalLength")
        zeroCorner        = Prefs.zeroCorner(fromRawValue: defaults.integer(forKey: "zeroCorner"))

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
                let normalizedColor = Prefs.normalizedRulerColor(color)
                guard Prefs.colorsMatch(color, normalizedColor) else {
                    prefs.rulerColor = normalizedColor
                    return
                }

                guard let data = Prefs.archivedColorData(normalizedColor) else { return }
                self.defaults.set(data, forKey: "rulerColor")
            },
            observe(\Prefs.unit, options: .new) { prefs, changed in
                self.defaults.set(prefs.unit.rawValue, forKey: "unit")
            },
            observe(\Prefs.defaultHorizontalLength, options: .new) { prefs, changed in
                self.defaults.set(prefs.defaultHorizontalLength, forKey: "defaultHorizontalLength")
            },
            observe(\Prefs.defaultVerticalLength, options: .new) { prefs, changed in
                self.defaults.set(prefs.defaultVerticalLength, forKey: "defaultVerticalLength")
            },
            observe(\Prefs.zeroCorner, options: .new) { prefs, changed in
                self.defaults.set(prefs.zeroCorner.rawValue, forKey: "zeroCorner")
            },
        ]
    }

}

extension Prefs {
    static let rulerSetStateKey = "rulerSetState"

    static var defaultUnit: Unit {
        return .pixels
    }

    static var unsetDefaultRulerLength: Double {
        return 0
    }

    static var defaultZeroCorner: ZeroCorner {
        return .topLeft
    }

    static var defaultRulerFillColor: NSColor {
        return defaultRulerColor
    }

    static var defaultForegroundOpacity: Int {
        return 90
    }

    static var defaultBackgroundOpacity: Int {
        return 50
    }

    static var defaultFloatRulers: Bool {
        return true
    }

    static var defaultRulerShadow: Bool {
        return false
    }
  
    static var defaultGroupRulers: Bool {
        return false
    }

    func applyDefaults(from settings: RulerSettings, layout: RulerLayoutState? = nil) {
        unit = settings.unit
        rulerColor = settings.rulerColor
        foregroundOpacity = settings.foregroundOpacity
        backgroundOpacity = settings.backgroundOpacity
        floatRulers = settings.floatRulers
        rulerShadow = settings.rulerShadow
        zeroCorner = settings.zeroCorner

        if let layout = layout {
            defaultHorizontalLength = Double(layout.horizontalLength)
            defaultVerticalLength = Double(layout.verticalLength)
        }
    }

    func resetRulerDefaultsToFactoryDefaults() {
        unit = Self.defaultUnit
        rulerColor = Self.defaultRulerFillColor
        foregroundOpacity = Self.defaultForegroundOpacity
        backgroundOpacity = Self.defaultBackgroundOpacity
        floatRulers = Self.defaultFloatRulers
        rulerShadow = Self.defaultRulerShadow
        groupRulers = Self.defaultGroupRulers
        defaultHorizontalLength = Self.unsetDefaultRulerLength
        defaultVerticalLength = Self.unsetDefaultRulerLength
        zeroCorner = Self.defaultZeroCorner
    }

    func effectiveDefaultHorizontalLength(screenFrame: NSRect = defaultRulerScreenFrame()) -> CGFloat {
        guard defaultHorizontalLength > Self.unsetDefaultRulerLength else {
            return RulerLayoutState.defaultLengths(screenFrame: screenFrame).horizontal
        }

        return CGFloat(defaultHorizontalLength)
    }

    func effectiveDefaultVerticalLength(screenFrame: NSRect = defaultRulerScreenFrame()) -> CGFloat {
        guard defaultVerticalLength > Self.unsetDefaultRulerLength else {
            return RulerLayoutState.defaultLengths(screenFrame: screenFrame).vertical
        }

        return CGFloat(defaultVerticalLength)
    }

    var customDefaultHorizontalLength: CGFloat? {
        return defaultHorizontalLength > Self.unsetDefaultRulerLength ? CGFloat(defaultHorizontalLength) : nil
    }

    var customDefaultVerticalLength: CGFloat? {
        return defaultVerticalLength > Self.unsetDefaultRulerLength ? CGFloat(defaultVerticalLength) : nil
    }

    static func rulerFillColor(fromArchivedData data: Data?) -> NSColor {
        return normalizedRulerColor(unarchiveColor(data) ?? defaultRulerColor)
    }

    static func zeroCorner(fromRawValue rawValue: Int) -> ZeroCorner {
        return ZeroCorner(rawValue: rawValue) ?? defaultZeroCorner
    }

    private static func archivedColorData(_ color: NSColor) -> Data? {
        return try? NSKeyedArchiver.archivedData(
            withRootObject: color,
            requiringSecureCoding: true
        )
    }

    private static func normalizedRulerColor(_ color: NSColor) -> NSColor {
        guard let color = color.usingColorSpace(.deviceRGB) else {
            return defaultRulerColor
        }

        return NSColor(
            deviceRed: color.redComponent,
            green: color.greenComponent,
            blue: color.blueComponent,
            alpha: 1
        )
    }

    static func colorsMatch(_ firstColor: NSColor, _ secondColor: NSColor) -> Bool {
        guard let first = firstColor.usingColorSpace(.deviceRGB),
              let second = secondColor.usingColorSpace(.deviceRGB) else {
            return firstColor == secondColor
        }

        return abs(first.redComponent - second.redComponent) < 0.0001
            && abs(first.greenComponent - second.greenComponent) < 0.0001
            && abs(first.blueComponent - second.blueComponent) < 0.0001
            && abs(first.alphaComponent - second.alphaComponent) < 0.0001
    }

    private static func unarchiveColor(_ data: Data?) -> NSColor? {
        guard let data = data else { return nil }

        return try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: NSColor.self,
            from: data
        )
    }

    func saveRulerSetState(rulers: [RulerInstanceState], activeRulerID: UUID?) {
        let visibleRulers = rulers.filter(\.hasVisibleWing)
        guard !visibleRulers.isEmpty else {
            clearRulerSetState()
            return
        }

        let activeRulerIDToSave = activeRulerID.flatMap { activeRulerID in
            visibleRulers.contains { $0.id == activeRulerID } ? activeRulerID : nil
        }
        let state = StoredRulerSetState(
            rulers: visibleRulers,
            activeRulerID: activeRulerIDToSave
        )

        guard let data = try? JSONEncoder().encode(state) else { return }

        defaults.set(data, forKey: Self.rulerSetStateKey)
    }

    func loadRulerSetState() -> StoredRulerSetState? {
        guard let data = defaults.data(forKey: Self.rulerSetStateKey),
              let state = try? JSONDecoder().decode(StoredRulerSetState.self, from: data),
              state.schemaVersion == StoredRulerSetState.currentSchemaVersion else {
            return nil
        }

        return state.sanitizedForRestore()
    }

    func clearRulerSetState() {
        defaults.removeObject(forKey: Self.rulerSetStateKey)
    }
}
