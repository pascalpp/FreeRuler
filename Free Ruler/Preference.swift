import Foundation

protocol PreferenceSubscriber {
    func onChangePreference(_ name: String)
}

class Preference<T>: NSObject {

    let name: String

    private let defaultValue: T
    private var privateValue: T?
    
    var value: T {
        get {
            return privateValue ?? defaultValue
        }
        set {
            // print("Pref.\(name) changed: \(newValue)")
            privateValue = newValue
            notifySubscribers()
            writeValue()
        }
    }
    
    init(name: String, defaultValue: T) {
        self.name = name
        self.defaultValue = defaultValue
        super.init()
        readValue()
    }
    
    convenience init(_ name: String, defaultValue: T) {
        self.init(name: name, defaultValue: defaultValue)
    }
    convenience init(_ name: String, _ defaultValue: T) {
        self.init(name: name, defaultValue: defaultValue)
    }
    
    override var description: String {
        return "Preference<\(T.self)> \(name): \(value)"
    }
    

    // - MARK: UserDefaults
    
    private let defaults = UserDefaults.standard

    private func readValue() {
        if let savedValue = defaults.value(forKey: name) {
            if let typedValue = savedValue as? T {
                value = typedValue
            }
        }
    }
    private func writeValue() {
        if let unsavedValue = privateValue {
            defaults.set(unsavedValue, forKey: name)
        }
    }


    // - MARK: subcriptions

    private var subscribers: [PreferenceSubscriber] = []
    
    func subscribe(_ subscriber: PreferenceSubscriber) {
        subscribers.append(subscriber)
    }
    
    func notifySubscribers() {
        for subscriber in subscribers {
            subscriber.onChangePreference(name)
        }
    }
}
