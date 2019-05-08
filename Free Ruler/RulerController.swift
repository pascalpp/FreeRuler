import Cocoa
import Carbon.HIToolbox // For key constants


class RulerController: NSWindowController, NSWindowDelegate, PreferenceSubscriber {

    var ruler: Ruler
    var rulerWindow: RulerWindow
    var otherWindow: RulerWindow?
    var keyListener: Any?

    var opacity = Prefs.foregroundOpacity.value {
        didSet {
            rulerWindow.alphaValue = windowAlphaValue(opacity)
        }
    }
    
    init(_ ruler: Ruler) {
        self.ruler = ruler
        self.rulerWindow = RulerWindow(ruler)

        super.init(window: self.rulerWindow)
        
        print("self.rulerWindow.canBecomeKey", self.rulerWindow.canBecomeKey)

        subscribeToPrefs()
    }
    
    required init?(coder: NSCoder) {
        // for some reason this init is required but it never gets called
        print("init?(coder: NSCoder)")
        self.ruler = Ruler(.horizontal)
        self.rulerWindow = RulerWindow(self.ruler)
        super.init(coder: coder)
    }
    
    override func showWindow(_ sender: Any?) {
        updateChildWindow()
        super.showWindow(sender)
        rulerWindow.orderFront(sender)
        rulerWindow.makeKey()
    }

    func windowWillStartLiveResize(_ notification: Notification) {
        // print(self.type, "windowWillStartLiveResize")
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        // print(self.type, "windowDidEndLiveResize")
    }

    func windowWillMove(_ notification: Notification) {
        // print(self.type, "windowWillMove")
    }

    func windowDidMove(_ notification: Notification) {
        // print(self.type, "windowDidMove")
        window?.invalidateShadow()
    }

    func windowDidBecomeKey(_ notification: Notification) {
        print("windowDidBecomeKey")
        updateChildWindow()
        //startKeyListener()
    }

    func windowDidResignKey(_ notification: Notification) {
        print("windowDidResignKey")
        updateChildWindow()
        stopKeyListener()
    }

    func onChangeGrouped() {
        updateChildWindow()
    }

    func updateChildWindow() {
        guard
            let otherWindow = otherWindow
            else { return }

        print(ruler.orientation, "rulerWindow.isKeyWindow", rulerWindow.isKeyWindow)
        if Prefs.groupRulers.value && rulerWindow.isKeyWindow {
            print("- addChildWindow")
            rulerWindow.addChildWindow(otherWindow, ordered: .below)
        } else {
            print("- removeChildWindow")
            rulerWindow.removeChildWindow(otherWindow)
        }
    }

    func foreground() {
        print("foreground")
        opacity = Prefs.foregroundOpacity.value
    }
    func background() {
        opacity = Prefs.backgroundOpacity.value
    }

    func subscribeToPrefs() {
        Prefs.groupRulers.subscribe(self)
        Prefs.foregroundOpacity.subscribe(self)
        Prefs.backgroundOpacity.subscribe(self)
        Prefs.floatRulers.subscribe(self)
    }

    func onChangePreference(_ name: String) {
        print("onChangePreference", name)
        switch(name) {
        case Prefs.groupRulers.name:
            updateChildWindow()
        case Prefs.foregroundOpacity.name:
            opacity = Prefs.foregroundOpacity.value
        case Prefs.backgroundOpacity.name:
            opacity = Prefs.backgroundOpacity.value
        case Prefs.floatRulers.name:
            rulerWindow.isFloatingPanel = Prefs.floatRulers.value
        default:
            print("Unknown preference changed: \(name)")
        }
    }
    
}

// MARK: KeyListener

extension RulerController {

    func startKeyListener() {
        self.keyListener = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] in
            guard let self = self else { return $0 }
            return self.onKeyDown(with: $0)
        }
    }

    func stopKeyListener() {
        if let keyListener = self.keyListener {
            NSEvent.removeMonitor(keyListener)
            self.keyListener = nil
        }
    }

    // Return nil if the event was handled here.
    func onKeyDown(with event: NSEvent) -> NSEvent? {
        // print(ruler.orientation, "onKeyDown")

        let shift = event.modifierFlags.contains(.shift)

        switch Int(event.keyCode) {
        case kVK_LeftArrow:
            rulerWindow.nudgeLeft(withShift: shift)
            return nil
        case kVK_RightArrow:
            rulerWindow.nudgeRight(withShift: shift)
            return nil
        case kVK_UpArrow:
            rulerWindow.nudgeUp(withShift: shift)
            return nil
        case kVK_DownArrow:
            rulerWindow.nudgeDown(withShift: shift)
            return nil
        default:
            return event
        }
    }

}
