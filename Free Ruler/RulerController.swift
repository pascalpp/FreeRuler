import Cocoa
import Carbon.HIToolbox // For key constants


class RulerController: NSWindowController, NSWindowDelegate, NotificationObserver {

    var observers: [NSKeyValueObservation] = []

    let ruler: Ruler

    let rulerWindow: RulerWindow
    var otherWindow: RulerWindow?

    var keyListener: Any?

    let openHand = NSCursor.openHand
    let closedHand = NSCursor.closedHand
    let crosshair = NSCursor.crosshair

    var preferencesWindowOpen = false {
        didSet {
            updateIsFloatingPanel()
            // reset opacity to foreground in case they modified background opacity last
            if !preferencesWindowOpen {
                opacity = prefs.foregroundOpacity
            }
        }
    }

    var opacity = prefs.foregroundOpacity {
        didSet {
            rulerWindow.alphaValue = windowAlphaValue(opacity)
        }
    }

    convenience init(_ ruler: Ruler) {
        self.init(ruler: ruler)
    }

    init(ruler: Ruler) {
        self.ruler = ruler
        self.rulerWindow = RulerWindow(ruler)

        super.init(window: self.rulerWindow)

        createObservers()
        subscribeToPrefs()

        rulerWindow.delegate = self
        rulerWindow.nextResponder = self

        if let windowFrameAutosaveName = ruler.name {
            self.windowFrameAutosaveName = windowFrameAutosaveName
        }

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init(ruler: Ruler)")
    }

    deinit {
        removeObserver()
    }

    func createObservers() {
        addObserver(.preferencesWindowOpened) { _ in self.preferencesWindowOpen = true }
        addObserver(.preferencesWindowClosed) { _ in self.preferencesWindowOpen = false }
    }

    func windowWillStartLiveResize(_ notification: Notification) {
        disableMouseTicks()
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        enableMouseTicks()
    }

    func windowWillMove(_ notification: Notification) {
        disableMouseTicks()
    }

    func windowDidMove(_ notification: Notification) {
        rulerWindow.invalidateShadow()
    }

    func windowDidBecomeKey(_ notification: Notification) {
        updateChildWindow()
        startKeyListener()
    }

    func windowDidResignKey(_ notification: Notification) {
        updateChildWindow()
        stopKeyListener()
    }

    override func mouseEntered(with event: NSEvent) {
        openHand.push()
    }

    override func mouseExited(with event: NSEvent) {
        openHand.pop()
        crosshair.push()
    }

    override func mouseDown(with event: NSEvent) {
        closedHand.push()
}

    override func mouseUp(with event: NSEvent) {
        closedHand.pop()
    }

    override func mouseMoved(with event: NSEvent) {
        enableMouseTicks()
    }

    func disableMouseTicks() {
        rulerWindow.rule.showMouseTick = false
        otherWindow?.rule.showMouseTick = false
    }

    func enableMouseTicks() {
        rulerWindow.rule.showMouseTick = true
        otherWindow?.rule.showMouseTick = true
    }

    func onChangeGrouped() {
        updateChildWindow()
    }

    func updateChildWindow() {
        guard let otherWindow = otherWindow else { return }

        if prefs.groupRulers && rulerWindow.isKeyWindow {
            rulerWindow.addChildWindow(otherWindow, ordered: .below)
        } else {
            rulerWindow.removeChildWindow(otherWindow)
        }
    }

    func updateIsFloatingPanel() {
        // never float while preferences window is open
        if preferencesWindowOpen {
            rulerWindow.isFloatingPanel = false
        } else {
            rulerWindow.isFloatingPanel = prefs.floatRulers
        }
    }

    func foreground() {
        opacity = prefs.foregroundOpacity
    }
    func background() {
        opacity = prefs.backgroundOpacity
    }

    func subscribeToPrefs() {
        observers = [
            prefs.observe(\Prefs.foregroundOpacity, options: .new) { prefs, changed in
                self.opacity = prefs.foregroundOpacity
            },
            prefs.observe(\Prefs.backgroundOpacity, options: .new) { prefs, changed in
                self.opacity = prefs.backgroundOpacity
            },
            prefs.observe(\Prefs.floatRulers, options: .new) { prefs, changed in
                self.updateIsFloatingPanel()
            },
            prefs.observe(\Prefs.groupRulers, options: .new) { prefs, changed in
                self.updateChildWindow()
            },
            prefs.observe(\Prefs.rulerShadow, options: .new) { prefs, changed in
                self.rulerWindow.hasShadow = prefs.rulerShadow
            },
        ]
    }

    func alignRuler(at point: NSPoint) {
        // only key window controller should respond to this command
        guard rulerWindow.isKeyWindow else { return }

        if prefs.groupRulers {
            // if grouped, ungroup rulers, move both, regroup
            prefs.groupRulers = false
            alignRuler(window: rulerWindow, at: point)
            alignRuler(window: otherWindow, at: point)
            prefs.groupRulers = true
        } else {
            // if not groups, just move key window
            alignRuler(window: rulerWindow, at: point)
        }
    }

    private func alignRuler(window: RulerWindow?, at point: NSPoint) {
        guard let window = window else { return }

        let frame = window.frame
        var x: CGFloat
        var y: CGFloat

        switch window.ruler.orientation {
        case .horizontal:
            // offset horizontal by 1px downward to compensate for ruler border
            x = point.x
            y = point.y - 1.0
        case .vertical:
            // offset vertical by 1px rightward to compensate for ruler border
            x = point.x - frame.width + 1.0
            y = point.y - frame.height
        }

        let rect = NSRect(
            x: x,
            y: y,
            width: frame.width,
            height: frame.height
        )

        window.setFrame(rect, display: false)
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
        case 47: // "."
            rulerWindow.rule.flipReferencePoint(location: NSEvent.mouseLocation)
            otherWindow?.rule.flipReferencePoint(location: NSEvent.mouseLocation)
            return nil
        default:
            return event
        }
    }

}

// helper to convert opacity Int to window.alphaValue
func windowAlphaValue(_ value: Int) -> CGFloat {
    return CGFloat(value) / 100.0
}
