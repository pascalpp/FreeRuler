import Cocoa
import Carbon.HIToolbox // For key constants


class RulerController: NSWindowController, NSWindowDelegate, NotificationObserver {

    var observers: [NSKeyValueObservation] = []
    var notificationObservers: [NSObjectProtocol] = []

    let ruler: Ruler

    let rulerWindow: RulerWindow
    var otherWindow: RulerWindow?

    var keyListener: Any?
    private var mouseInteraction: RulerMouseInteractionState!
    var isLeftMouseButtonPressed = {
        return NSEvent.pressedMouseButtons & 1 == 1
    }

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
        mouseInteraction = RulerMouseInteractionState(owner: self) { [weak self] event in
            return self?.isMouseInsideRuler(with: event) ?? false
        }

        if let windowFrameAutosaveName = ruler.name {
            self.windowFrameAutosaveName = windowFrameAutosaveName
        }

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init(ruler: Ruler)")
    }

    deinit {
        mouseInteraction?.invalidate()
        removeObservers(&notificationObservers)
    }

    func createObservers() {
        notificationObservers = [
            addObserver(.preferencesWindowOpened) { [weak self] _ in
                self?.preferencesWindowOpen = true
            },
            addObserver(.preferencesWindowClosed) { [weak self] _ in
                self?.preferencesWindowOpen = false
            },
        ]
    }

    func windowWillStartLiveResize(_ notification: Notification) {
        mouseInteraction.windowWillStartLiveResize()
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        mouseInteraction.windowDidEndLiveResize()
    }

    func windowWillMove(_ notification: Notification) {
        mouseInteraction.windowWillMove()
    }

    func windowDidMove(_ notification: Notification) {
        rulerWindow.invalidateShadow()
        mouseInteraction.windowDidMove(isLeftMouseButtonPressed: isLeftMouseButtonPressed())
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
        mouseInteraction.mouseEntered(with: event)
    }

    override func mouseExited(with event: NSEvent) {
        mouseInteraction.mouseExited(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        mouseInteraction.mouseDown(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        finishMouseDrag(with: event)
    }

    func finishMouseDrag(with event: NSEvent) {
        mouseInteraction.finishMouseDrag(with: event)
    }

    override func mouseMoved(with event: NSEvent) {
        mouseInteraction.mouseMoved(with: event)
    }

    func disableMouseTicks() {
        mouseInteraction.disableMouseTicks()
    }

    func enableMouseTicks() {
        mouseInteraction.enableMouseTicks()
    }

    private func isMouseInsideRuler(with event: NSEvent) -> Bool {
        let location = rulerWindow.rule.convert(event.locationInWindow, from: nil)
        return rulerWindow.rule.bounds.contains(location)
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
        let rect = ZeroCornerGeometry(zeroCorner: prefs.zeroCorner).frame(
            for: window.ruler.orientation,
            zeroPoint: point,
            size: frame.size
        )

        window.setFrame(rect, display: false)
    }

    func resetPosition() {
        let frame = getDefaultContentRect(orientation: ruler.orientation, zeroCorner: prefs.zeroCorner)
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
        let keyboardModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if rulerWindow.isKeyWindow,
           let appDelegate = NSApp.delegate as? AppDelegate,
           appDelegate.performRulerHotkey(
               keyCode: Int(event.keyCode),
               modifierFlags: keyboardModifiers,
               sender: self
           ) {
            return nil
        }

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

// helper to convert opacity Int to window.alphaValue
func windowAlphaValue(_ value: Int) -> CGFloat {
    return CGFloat(value) / 100.0
}
