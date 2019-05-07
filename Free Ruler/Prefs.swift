import Cocoa

enum PrefKey: String {
    case keys
    case groupRulers
    case foregroundOpacity
    case backgroundOpacity
    case floatRulers
    case rulerColor
}

class Prefs {

    private static let defaults = UserDefaults.standard

    static var keyPrefix = "preferences"
    static var keys: Set<PrefKey> = []

    static func prefix(_ key: PrefKey) -> String {
        return "\(keyPrefix).\(key.rawValue)"
    }

    static func readKeys() {
        if let array = defaults.array(forKey: prefix(.keys)) {
            for key in array {
                if let stringKey = key as? String {
                    if let prefKey = PrefKey(rawValue: stringKey) {
                        keys.insert(prefKey)
                    }
                }
            }
        }
        print("keys", keys)
    }
    static func insertKey(_ key: PrefKey) {
        if !keys.contains(key) {
            keys.insert(key)
            saveKeys()
        }
    }
    static func saveKeys() {
        var stringKeys: [String] = []
        for key in keys {
            stringKeys.append(key.rawValue)
        }
        defaults.set(stringKeys, forKey: prefix(.keys))
    }


    // initializers
    static func string(_ key: PrefKey, defaultValue: String) {
        if !keys.contains(key) {
            set(key, defaultValue)
        }
    }
    static func bool(_ key: PrefKey, defaultValue: Bool) {
        if !keys.contains(key) {
            print("atempt to set default bool")
            set(key, defaultValue)
        }
    }
    static func int(_ key: PrefKey, defaultValue: Int) {
        if !keys.contains(key) {
            set(key, defaultValue)
        }
    }
    static func float(_ key: PrefKey, defaultValue: Float) {
        if !keys.contains(key) {
            set(key, defaultValue)
        }
    }

    // setters
    static func set(_ key: PrefKey, _ value: String) {
        defaults.set(value, forKey: prefix(key))
        insertKey(key)
    }
    static func set(_ key: PrefKey, _ value: Bool) {
        defaults.set(value, forKey: prefix(key))
        insertKey(key)
    }
    static func set(_ key: PrefKey, _ value: Int) {
        defaults.set(value, forKey: prefix(key))
        insertKey(key)
    }
    static func set(_ key: PrefKey, _ value: Float) {
        defaults.set(value, forKey: prefix(key))
        insertKey(key)
    }

    // getters
    static func string(_ key: PrefKey) -> String? {
        if keys.contains(key) {
            if let value = defaults.string(forKey: prefix(key)) {
                return value
            }
        }
        return nil
    }
    static func bool(_ key: PrefKey) -> Bool? {
        if keys.contains(key) {
            return defaults.bool(forKey: prefix(key))
        }
        return nil
    }
    static func int(_ key: PrefKey) -> Int? {
        if keys.contains(key) {
            return defaults.integer(forKey: prefix(key))
        }
        return nil
    }
    static func float(_ key: PrefKey) -> Float? {
        if keys.contains(key) {
            return defaults.float(forKey: prefix(key))
        }
        return nil
    }

}
