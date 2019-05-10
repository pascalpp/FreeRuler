import Foundation

// add enums for custom event names
extension Notification.Name {

    static let preferencesWindowOpened = Notification.Name("preferencesWindowOpened")
    static let preferencesWindowClosed = Notification.Name("preferencesWindowClosed")

}

protocol NotificationPoster {}
extension NotificationPoster {

    func post(_ name: Notification.Name) {
        NotificationCenter.default.post(name: name, object: self)
    }

}

protocol NotificationObserver {}
extension NotificationObserver {
    
    func addObserver(_ forName: Notification.Name, using: @escaping (Notification) -> Void) {
        NotificationCenter.default.addObserver(forName: forName, object: nil, queue: nil, using: using)
    }
    
    // call removeObserver in your class deinit
    // deinit {
    //    removeObserver()
    // }
    func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
}
