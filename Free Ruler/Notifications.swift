import Foundation

// short name for NotificationCenter.default
let Notes = NotificationCenter.default

// add enums for custom event names
extension Notification.Name {

    static let preferencesWindowOpened = Notification.Name("preferencesWindowOpened")
    static let preferencesWindowClosed = Notification.Name("preferencesWindowClosed")

}

extension NotificationCenter {
    
    // convenience method for posting an event with no object or userInfo
    // Notes.post(.eventName)
    func post(_ name: Notification.Name) {
        self.post(name: name, object: nil)
    }

}
