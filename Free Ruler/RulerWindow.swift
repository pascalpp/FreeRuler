import Cocoa

class RulerWindow: NSPanel {

    var ruler: Ruler
    var rule: RuleView

    convenience init(_ ruler: Ruler) {
        self.init(ruler: ruler)
    }

    init(ruler: Ruler) {
        self.ruler = ruler
        self.rule = getRulerView(ruler: ruler)

        let styleMask: NSWindow.StyleMask = [
            .borderless,
            .resizable,
            .fullSizeContentView,
        ]

        super.init(
            contentRect: ruler.frame,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )

        self.alphaValue = windowAlphaValue(prefs.foregroundOpacity)
        self.title = getTitle(for: ruler.orientation)
        self.identifier = NSUserInterfaceItemIdentifier(getIdentifier(for: ruler.orientation))
        self.setAccessibilityIdentifier(getIdentifier(for: ruler.orientation))
        self.minSize = getMinSize(ruler: ruler)
        self.maxSize = getMaxSize(ruler: ruler)

        self.isFloatingPanel = prefs.floatRulers
        self.hidesOnDeactivate = false
        self.isMovableByWindowBackground = true
        self.hasShadow = prefs.rulerShadow

        rule.wantsLayer = true
        rule.layer?.borderColor = CGColor(gray: 0, alpha: 0.5)
        rule.layer?.borderWidth = 1.0
        rule.setAccessibilityElement(true)
        rule.setAccessibilityIdentifier(getRuleIdentifier(for: ruler.orientation))

        rule.nextResponder = self
        self.contentView = rule
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var acceptsMouseMovedEvents: Bool {
        get { return true }
        set {}
    }

    override func mouseDown(with event: NSEvent) {
        nextResponder?.mouseDown(with: event)
        super.mouseDown(with: event)

        if !leftMouseButtonIsPressed {
            (nextResponder as? RulerController)?.finishMouseDrag(with: event)
        }
    }

    override func mouseUp(with event: NSEvent) {
        nextResponder?.mouseUp(with: event)
        super.mouseUp(with: event)
    }

    private var leftMouseButtonIsPressed: Bool {
        return NSEvent.pressedMouseButtons & 1 == 1
    }

}

private func getTitle(for orientation: Orientation) -> String {
    switch orientation {
    case .horizontal:
        return NSLocalizedString(
            "Horizontal Ruler",
            comment: "Window title for the horizontal ruler"
        )
    case .vertical:
        return NSLocalizedString(
            "Vertical Ruler",
            comment: "Window title for the vertical ruler"
        )
    }
}

private func getIdentifier(for orientation: Orientation) -> String {
    switch orientation {
    case .horizontal:
        return "horizontal-ruler-window"
    case .vertical:
        return "vertical-ruler-window"
    }
}

private func getRuleIdentifier(for orientation: Orientation) -> String {
    switch orientation {
    case .horizontal:
        return "horizontal-ruler-view"
    case .vertical:
        return "vertical-ruler-view"
    }
}

extension RulerWindow {
    private enum Distance: CGFloat {
        case aLittle = 1
        case aLot = 10
    }

    func moveHorizontally(by pixels: CGFloat) {
        var position = frame.origin
        position.x = position.x + pixels
        setFrameOrigin(position)
    }

    func moveVertically(by pixels: CGFloat) {
        var position = frame.origin
        position.y = position.y + pixels
        setFrameOrigin(position)
    }

    private func distance(withShift: Bool) -> CGFloat {
        let dist = withShift ? Distance.aLot : Distance.aLittle
        return dist.rawValue
    }

    func nudgeLeft(withShift shiftPressed: Bool) {
        let dist = distance(withShift: shiftPressed)
        moveHorizontally(by: dist * -1)
    }

    func nudgeRight(withShift shiftPressed: Bool) {
        let dist = distance(withShift: shiftPressed)
        moveHorizontally(by: dist)
    }

    func nudgeDown(withShift shiftPressed: Bool) {
        let dist = distance(withShift: shiftPressed)
        moveVertically(by: dist * -1)
    }

    func nudgeUp(withShift shiftPressed: Bool) {
        let dist = distance(withShift: shiftPressed)
        moveVertically(by: dist)
    }

}
