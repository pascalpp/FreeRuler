import Foundation

final class MouseTickTimerPolicy {
    let foregroundInterval: TimeInterval
    let backgroundInterval: TimeInterval

    private var hasApplicationState = false
    private var appIsActive = false
    private var hasVisibleRulers = false
    private let suspendedOwners = NSHashTable<AnyObject>.weakObjects()

    init(foregroundInterval: TimeInterval, backgroundInterval: TimeInterval) {
        self.foregroundInterval = foregroundInterval
        self.backgroundInterval = backgroundInterval
    }

    var desiredInterval: TimeInterval? {
        guard hasApplicationState, hasVisibleRulers, suspendedOwners.allObjects.isEmpty else { return nil }
        return appIsActive ? foregroundInterval : backgroundInterval
    }

    func applicationDidBecomeActive() {
        hasApplicationState = true
        appIsActive = true
    }

    func applicationDidResignActive() {
        hasApplicationState = true
        appIsActive = false
    }

    func updateVisibleRulers(_ hasVisibleRulers: Bool) {
        self.hasVisibleRulers = hasVisibleRulers
    }

    func suspend(owner: AnyObject) {
        suspendedOwners.add(owner)
    }

    func resume(owner: AnyObject) {
        suspendedOwners.remove(owner)
    }
}
