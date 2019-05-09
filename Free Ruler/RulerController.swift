import Cocoa
import Carbon.HIToolbox // For key constants


class RulerController: NSWindowController, NSWindowDelegate, PreferenceSubscriber {

    let ruler: Ruler
    let rulerWindow: RulerWindow
    var otherWindow: RulerWindow?
    var keyListener: Any?

    var opacity = Prefs.foregroundOpacity.value {
        didSet {
            rulerWindow.alphaValue = windowAlphaValue(opacity)
        }
    }

    init(ruler: Ruler) {
        self.ruler = ruler
        self.rulerWindow = RulerWindow(ruler)

        super.init(window: self.rulerWindow)
        
        subscribeToPrefs()

        rulerWindow.delegate = self

        if let windowFrameAutosaveName = ruler.name {
            self.windowFrameAutosaveName = windowFrameAutosaveName
        }
    }

    convenience init(_ ruler: Ruler) {
        self.init(ruler: ruler)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init(ruler: Ruler)")
    }

    func windowWillStartLiveResize(_ notification: Notification) {
        // print("windowWillStartLiveResize")
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        // print("windowDidEndLiveResize")
    }

    func windowWillMove(_ notification: Notification) {
        // print("windowWillMove")
    }

    func windowDidMove(_ notification: Notification) {
        // print("windowDidMove")
        rulerWindow.invalidateShadow()
    }

    func windowDidBecomeKey(_ notification: Notification) {
        // print("windowDidBecomeKey")
        updateChildWindow()
        startKeyListener()
    }

    func windowDidResignKey(_ notification: Notification) {
        // print("windowDidResignKey")
        updateChildWindow()
        stopKeyListener()
    }

    func onChangeGrouped() {
        updateChildWindow()
    }

    func updateChildWindow() {
        guard let otherWindow = otherWindow else { return }

        if Prefs.groupRulers.value && rulerWindow.isKeyWindow {
            rulerWindow.addChildWindow(otherWindow, ordered: .below)
        } else {
            rulerWindow.removeChildWindow(otherWindow)
        }
    }

    func foreground() {
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
        // print("onChangePreference", name)
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
    
    func resetPosition() {
        let frame = getDefaultContentRect(orientation: ruler.orientation)
        rulerWindow.setFrame(frame, display: true)
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
