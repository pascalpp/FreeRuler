import Foundation

// sugar syntax for NotificationCenter

// short name for NotificationCenter.default
let Notes = NotificationCenter.default

// add enums for custom event names
extension Notification.Name {

    static let preferencesWindowOpened = Notification.Name("preferencesWindowOpened")
    static let preferencesWindowClosed = Notification.Name("preferencesWindowClosed")

}

extension NotificationCenter {
    
    // convenience method for addObserver with closure
    // rather than call an @objc selector, pass a closure that changes some local state variable when the event occurs
    //
    // Notes.addObserver(.preferencesWindowOpened) { _ in self.preferencesWindowOpen = true }
    //
    // use in conjunction with didSet to react to changes
    func addObserver(_ forName: Notification.Name, using: @escaping (Notification) -> Void) {
        self.addObserver(forName: forName, object: nil, queue: nil, using: using)
    }
    
    // convenience method for posting an event with no object or userInfo
    // Notes.post(.eventName)
    func post(_ name: Notification.Name) {
        self.post(name: name, object: nil)
    }

}
