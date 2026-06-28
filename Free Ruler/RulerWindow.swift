import Cocoa
import Carbon.HIToolbox

struct RulerWindowLayout: Equatable {
    let groupFrame: NSRect
    let horizontalFrame: NSRect
    let verticalFrame: NSRect

    static func joined(
        horizontalFrame: NSRect,
        verticalFrame: NSRect,
        zeroCorner: ZeroCorner
    ) -> RulerWindowLayout {
        let zeroPoint = ZeroCornerGeometry(zeroCorner: zeroCorner)
            .zeroPoint(in: horizontalFrame, for: .horizontal)

        return layout(
            horizontalLength: horizontalFrame.width,
            verticalLength: verticalFrame.height,
            zeroPoint: zeroPoint,
            zeroCorner: zeroCorner
        )
    }

    static func layout(
        groupFrame: NSRect,
        zeroCorner: ZeroCorner
    ) -> RulerWindowLayout {
        let zeroPoint = zeroPoint(in: groupFrame, zeroCorner: zeroCorner)
        let horizontalLength = length(
            in: groupFrame,
            from: zeroPoint,
            along: .horizontal,
            zeroCorner: zeroCorner
        )
        let verticalLength = length(
            in: groupFrame,
            from: zeroPoint,
            along: .vertical,
            zeroCorner: zeroCorner
        )

        return layout(
            horizontalLength: horizontalLength,
            verticalLength: verticalLength,
            zeroPoint: zeroPoint,
            zeroCorner: zeroCorner
        )
    }

    static func layout(
        horizontalLength: CGFloat,
        verticalLength: CGFloat,
        zeroPoint: NSPoint,
        zeroCorner: ZeroCorner
    ) -> RulerWindowLayout {
        let geometry = ZeroCornerGeometry(zeroCorner: zeroCorner)
        let horizontalFrame = geometry.frame(
            for: .horizontal,
            zeroPoint: zeroPoint,
            size: NSSize(width: horizontalLength, height: Ruler.thickness)
        )
        let verticalFrame = geometry.frame(
            for: .vertical,
            zeroPoint: zeroPoint,
            size: NSSize(width: Ruler.thickness, height: verticalLength)
        )

        return RulerWindowLayout(
            groupFrame: horizontalFrame.union(verticalFrame),
            horizontalFrame: horizontalFrame,
            verticalFrame: verticalFrame
        )
    }

    static func minSize(zeroCorner: ZeroCorner) -> NSSize {
        return size(
            horizontalLength: getMinSize(ruler: Ruler(.horizontal)).width,
            verticalLength: getMinSize(ruler: Ruler(.vertical)).height,
            zeroCorner: zeroCorner,
            showsHorizontalRule: true,
            showsVerticalRule: true
        )
    }

    static func minSize(
        zeroCorner: ZeroCorner,
        showsHorizontalRule: Bool,
        showsVerticalRule: Bool
    ) -> NSSize {
        return size(
            horizontalLength: getMinSize(ruler: Ruler(.horizontal)).width,
            verticalLength: getMinSize(ruler: Ruler(.vertical)).height,
            zeroCorner: zeroCorner,
            showsHorizontalRule: showsHorizontalRule,
            showsVerticalRule: showsVerticalRule
        )
    }

    static func maxSize(zeroCorner: ZeroCorner) -> NSSize {
        return size(
            horizontalLength: getMaxSize(ruler: Ruler(.horizontal)).width,
            verticalLength: getMaxSize(ruler: Ruler(.vertical)).height,
            zeroCorner: zeroCorner,
            showsHorizontalRule: true,
            showsVerticalRule: true
        )
    }

    static func maxSize(
        zeroCorner: ZeroCorner,
        showsHorizontalRule: Bool,
        showsVerticalRule: Bool
    ) -> NSSize {
        return size(
            horizontalLength: getMaxSize(ruler: Ruler(.horizontal)).width,
            verticalLength: getMaxSize(ruler: Ruler(.vertical)).height,
            zeroCorner: zeroCorner,
            showsHorizontalRule: showsHorizontalRule,
            showsVerticalRule: showsVerticalRule
        )
    }

    func localFrame(for orientation: Orientation) -> NSRect {
        let frame: NSRect
        switch orientation {
        case .horizontal:
            frame = horizontalFrame
        case .vertical:
            frame = verticalFrame
        }

        return NSRect(
            x: frame.minX - groupFrame.minX,
            y: frame.minY - groupFrame.minY,
            width: frame.width,
            height: frame.height
        )
    }

    func visibleFrame(
        showsHorizontalRule: Bool,
        showsVerticalRule: Bool
    ) -> NSRect {
        switch (showsHorizontalRule, showsVerticalRule) {
        case (true, true):
            return groupFrame
        case (true, false):
            return horizontalFrame
        case (false, true):
            return verticalFrame
        case (false, false):
            return .zero
        }
    }

    private static func zeroPoint(
        in groupFrame: NSRect,
        zeroCorner: ZeroCorner
    ) -> NSPoint {
        let geometry = ZeroCornerGeometry(zeroCorner: zeroCorner)
        let x: CGFloat
        let y: CGFloat

        switch geometry.horizontalZeroSide {
        case .left:
            x = groupFrame.minX + Ruler.thickness - ZeroCornerGeometry.borderCompensation
        case .right:
            x = groupFrame.maxX - Ruler.thickness
        }

        switch geometry.verticalZeroSide {
        case .top:
            y = groupFrame.maxY - Ruler.thickness + ZeroCornerGeometry.borderCompensation
        case .bottom:
            y = groupFrame.minY + Ruler.thickness - ZeroCornerGeometry.borderCompensation
        }

        return NSPoint(x: x, y: y)
    }

    private static func length(
        in groupFrame: NSRect,
        from zeroPoint: NSPoint,
        along orientation: Orientation,
        zeroCorner: ZeroCorner
    ) -> CGFloat {
        let geometry = ZeroCornerGeometry(zeroCorner: zeroCorner)

        switch orientation {
        case .horizontal:
            switch geometry.horizontalZeroSide {
            case .left:
                return max(0, groupFrame.maxX - zeroPoint.x)
            case .right:
                return max(0, zeroPoint.x - groupFrame.minX)
            }
        case .vertical:
            switch geometry.verticalZeroSide {
            case .top:
                return max(0, zeroPoint.y - groupFrame.minY)
            case .bottom:
                return max(0, groupFrame.maxY - zeroPoint.y)
            }
        }
    }

    private static func size(
        horizontalLength: CGFloat,
        verticalLength: CGFloat,
        zeroCorner: ZeroCorner,
        showsHorizontalRule: Bool,
        showsVerticalRule: Bool
    ) -> NSSize {
        let layout = layout(
            horizontalLength: horizontalLength,
            verticalLength: verticalLength,
            zeroPoint: .zero,
            zeroCorner: zeroCorner
        )

        return layout.visibleFrame(
            showsHorizontalRule: showsHorizontalRule,
            showsVerticalRule: showsVerticalRule
        ).size
    }
}

private extension RulerWindowLayout {
    func emptyCornerFrame(zeroCorner: ZeroCorner) -> NSRect {
        let geometry = ZeroCornerGeometry(zeroCorner: zeroCorner)
        let x: CGFloat
        let width: CGFloat
        let y: CGFloat
        let height: CGFloat

        switch geometry.horizontalZeroSide {
        case .left:
            x = groupFrame.minX
            width = horizontalFrame.minX - groupFrame.minX
        case .right:
            x = horizontalFrame.maxX
            width = groupFrame.maxX - horizontalFrame.maxX
        }

        switch geometry.verticalZeroSide {
        case .top:
            y = verticalFrame.maxY
            height = groupFrame.maxY - verticalFrame.maxY
        case .bottom:
            y = groupFrame.minY
            height = verticalFrame.minY - groupFrame.minY
        }

        return NSRect(
            x: x,
            y: y,
            width: width,
            height: height
        )
    }
}

#if !SNAPSHOT_GENERATOR
final class RulerWindow: NSPanel {
    let horizontalRule: HorizontalRule
    let verticalRule: VerticalRule

    private let rulerContentView: RulerContentView
    private(set) var settings: RulerSettings

    init(frame: NSRect, settings: RulerSettings = RulerSettings(defaults: prefs)) {
        self.settings = settings
        horizontalRule = RulerWindowHorizontalRule(
            frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness)
        )
        verticalRule = RulerWindowVerticalRule(
            frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300)
        )
        rulerContentView = RulerContentView(
            frame: NSRect(origin: .zero, size: frame.size),
            horizontalRule: horizontalRule,
            verticalRule: verticalRule
        )

        let styleMask: NSWindow.StyleMask = [
            .borderless,
            .resizable,
            .fullSizeContentView,
        ]

        super.init(
            contentRect: frame,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )

        alphaValue = windowAlphaValue(settings.foregroundOpacity)
        title = NSLocalizedString(
            "Ruler",
            comment: "Window title for a ruler window"
        )
        identifier = NSUserInterfaceItemIdentifier("ruler-window")
        setAccessibilityIdentifier("ruler-window")
        minSize = RulerWindowLayout.minSize(zeroCorner: settings.zeroCorner)
        maxSize = RulerWindowLayout.maxSize(zeroCorner: settings.zeroCorner)

        isOpaque = false
        backgroundColor = .clear
        isFloatingPanel = settings.floatRulers
        hidesOnDeactivate = false
        isMovableByWindowBackground = true
        hasShadow = settings.rulerShadow

        horizontalRule.setAccessibilityElement(true)
        verticalRule.setAccessibilityElement(true)
        horizontalRule.setAccessibilityIdentifier("horizontal-ruler-view")
        verticalRule.setAccessibilityIdentifier("vertical-ruler-view")
        horizontalRule.nextResponder = self
        verticalRule.nextResponder = self
        rulerContentView.nextResponder = self

        contentView = rulerContentView
        apply(settings: settings)
        updateLayoutForCurrentZeroCorner()
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var acceptsMouseMovedEvents: Bool {
        get { return true }
        set {}
    }

    override func setFrame(_ frameRect: NSRect, display flag: Bool) {
        super.setFrame(frameRect, display: flag)
        updateRulerContentFrame()
    }

    override func setContentSize(_ size: NSSize) {
        super.setContentSize(size)
        updateRulerContentFrame()
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

    override func mouseEntered(with event: NSEvent) {
        nextResponder?.mouseEntered(with: event)
    }

    override func mouseExited(with event: NSEvent) {
        nextResponder?.mouseExited(with: event)
    }

    override func mouseMoved(with event: NSEvent) {
        nextResponder?.mouseMoved(with: event)
    }

    func updateLayoutForCurrentZeroCorner() {
        updateSizeConstraintsForVisibleRules()
        updateRulerContentFrame()
        rulerContentView.zeroCorner = settings.zeroCorner
        rulerContentView.needsLayout = true
        rulerContentView.layoutSubtreeIfNeeded()
        rulerContentView.needsDisplay = true
    }

    func apply(settings: RulerSettings) {
        self.settings = settings
        alphaValue = windowAlphaValue(settings.foregroundOpacity)
        isFloatingPanel = settings.floatRulers
        hasShadow = settings.rulerShadow
        horizontalRule.settingsOverride = settings
        verticalRule.settingsOverride = settings
        rulerContentView.color = RulerColors(customFill: settings.rulerColor)
        updateLayoutForCurrentZeroCorner()
    }

    func redrawForPreferenceChange() {
        updateLayoutForCurrentZeroCorner()
        horizontalRule.redrawForPreferenceChange()
        verticalRule.redrawForPreferenceChange()
    }

    func screenFrame(for orientation: Orientation) -> NSRect {
        return convertToScreen(rulerContentView.localFrame(for: orientation))
    }

    func visibleFrame(in layout: RulerWindowLayout) -> NSRect {
        return layout.visibleFrame(
            showsHorizontalRule: rulerContentView.showsHorizontalRule,
            showsVerticalRule: rulerContentView.showsVerticalRule
        )
    }

    func setVisibleRules(horizontal: Bool, vertical: Bool) {
        rulerContentView.showsHorizontalRule = horizontal
        rulerContentView.showsVerticalRule = vertical
        updateSizeConstraintsForVisibleRules()
        rulerContentView.needsLayout = true
        rulerContentView.layoutSubtreeIfNeeded()
    }

    func isRuleVisible(_ orientation: Orientation) -> Bool {
        switch orientation {
        case .horizontal:
            return rulerContentView.showsHorizontalRule
        case .vertical:
            return rulerContentView.showsVerticalRule
        }
    }

    func isEmptyCorner(atWindowPoint windowPoint: NSPoint) -> Bool {
        let contentPoint = rulerContentView.convert(windowPoint, from: nil)
        return rulerContentView.containsEmptyCorner(contentPoint)
    }

    func zeroPoint() -> NSPoint {
        let geometry = ZeroCornerGeometry(zeroCorner: settings.zeroCorner)

        if isRuleVisible(.horizontal) {
            return geometry.zeroPoint(
                in: screenFrame(for: .horizontal),
                for: .horizontal
            )
        }

        if isRuleVisible(.vertical) {
            return geometry.zeroPoint(
                in: screenFrame(for: .vertical),
                for: .vertical
            )
        }

        return frame.origin
    }

    var drawsActiveBorder: Bool {
        get { return rulerContentView.drawsActiveBorder }
        set { rulerContentView.drawsActiveBorder = newValue }
    }

    private var leftMouseButtonIsPressed: Bool {
        return NSEvent.pressedMouseButtons & 1 == 1
    }

    private func updateRulerContentFrame() {
        guard contentView === rulerContentView else { return }

        rulerContentView.frame = NSRect(origin: .zero, size: frame.size)
        rulerContentView.needsLayout = true
        rulerContentView.layoutSubtreeIfNeeded()
    }

    private func updateSizeConstraintsForVisibleRules() {
        minSize = RulerWindowLayout.minSize(
            zeroCorner: settings.zeroCorner,
            showsHorizontalRule: rulerContentView.showsHorizontalRule,
            showsVerticalRule: rulerContentView.showsVerticalRule
        )
        maxSize = RulerWindowLayout.maxSize(
            zeroCorner: settings.zeroCorner,
            showsHorizontalRule: rulerContentView.showsHorizontalRule,
            showsVerticalRule: rulerContentView.showsVerticalRule
        )
    }
}

extension RulerWindow: RulerContextMenuActivating {
    func activateForRulerContextMenu() {
        makeKey()
        (nextResponder as? RulerController)?.activateForRulerContextMenu()
    }
}

private final class RulerWindowHorizontalRule: HorizontalRule {
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(NSSize(width: newSize.width, height: Ruler.thickness))
    }
}

private final class RulerWindowVerticalRule: VerticalRule {
    override var rulerWidth: CGFloat {
        return Ruler.thickness
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(NSSize(width: Ruler.thickness, height: newSize.height))
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
#endif

private final class RulerClipView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.masksToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init(frame:)")
    }

    override var isOpaque: Bool {
        return false
    }

    override var mouseDownCanMoveWindow: Bool {
        return true
    }
}

private final class RulerWindowBorderView: RulerBorderView {
    private static let activeBorderCenterInset = borderCenterInset + borderWidth
    private static let activeBorderColor = NSColor(calibratedWhite: 0, alpha: 0.25)

    var zeroCorner = prefs.zeroCorner {
        didSet {
            needsDisplay = true
        }
    }

    var showsHorizontalRule = true {
        didSet {
            needsDisplay = true
        }
    }

    var showsVerticalRule = true {
        didSet {
            needsDisplay = true
        }
    }

    var drawsActiveBorder = false {
        didSet {
            needsDisplay = true
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard drawsActiveBorder else { return }

        let path = activeBorderPath(in: bounds)
        path.lineWidth = Self.borderWidth
        path.lineJoinStyle = .miter
        path.lineCapStyle = .butt
        Self.activeBorderColor.setStroke()
        path.stroke()
    }

    override func borderPath(in bounds: NSRect) -> NSBezierPath {
        return panelBorderPath(in: bounds, inset: Self.borderCenterInset)
    }

    private func activeBorderPath(in bounds: NSRect) -> NSBezierPath {
        return panelBorderPath(in: bounds, inset: Self.activeBorderCenterInset)
    }

    private func panelBorderPath(in bounds: NSRect, inset: CGFloat) -> NSBezierPath {
        switch (showsHorizontalRule, showsVerticalRule) {
        case (true, true):
            return lShapedBorderPath(inset: inset)
        case (true, false):
            return visibleBoundsBorderPath(inset: inset)
        case (false, true):
            return visibleBoundsBorderPath(inset: inset)
        case (false, false):
            return NSBezierPath()
        }
    }

    private func lShapedBorderPath(inset: CGFloat) -> NSBezierPath {
        return rulerWindowLShapedPath(
            in: bounds,
            zeroCorner: zeroCorner,
            inset: inset
        )
    }

    private func visibleBoundsBorderPath(inset: CGFloat) -> NSBezierPath {
        return NSBezierPath(rect: bounds.insetBy(
            dx: inset,
            dy: inset
        ))
    }
}

private final class RulerWindowZeroLabelsView: NSView {
    private let horizontalRule: HorizontalRule
    private let verticalRule: VerticalRule
    private let zeroLabel = "0"
    private let zeroLabelSize = NSSize(width: 50, height: 20)

    var color = RulerColors() {
        didSet {
            needsDisplay = true
        }
    }

    var zeroCorner = prefs.zeroCorner {
        didSet {
            needsDisplay = true
        }
    }

    var horizontalRuleFrame: NSRect = .zero {
        didSet {
            needsDisplay = true
        }
    }

    var verticalRuleFrame: NSRect = .zero {
        didSet {
            needsDisplay = true
        }
    }

    var showsHorizontalRule = true {
        didSet {
            needsDisplay = true
        }
    }

    var showsVerticalRule = true {
        didSet {
            needsDisplay = true
        }
    }

    init(horizontalRule: HorizontalRule, verticalRule: VerticalRule) {
        self.horizontalRule = horizontalRule
        self.verticalRule = verticalRule
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init(horizontalRule:verticalRule:)")
    }

    override var isOpaque: Bool {
        return false
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard showsHorizontalRule && showsVerticalRule else { return }

        if showsHorizontalRule {
            drawHorizontalZeroLabel()
        }
        if showsVerticalRule {
            drawVerticalZeroLabel()
        }
    }

    private func drawHorizontalZeroLabel() {
        let geometry = ZeroCornerGeometry(zeroCorner: zeroCorner)
        let growthDirection = geometry.growthDirection(for: .horizontal)
        let zeroTickX: CGFloat

        switch growthDirection {
        case .positive:
            zeroTickX = horizontalRule.bounds.minX
        case .negative:
            zeroTickX = horizontalRule.bounds.maxX
        }

        let lineX = horizontalRule.mouseTickLineX(
            forTickX: zeroTickX,
            growthDirection: growthDirection
        )
        let labelRect = horizontalRule.tickLabelRect(
            forX: lineX,
            labelSize: zeroLabelSize,
            rulerHeight: horizontalRule.bounds.height,
            tickSide: geometry.horizontalTickSide
        ).offsetBy(dx: horizontalRuleFrame.minX, dy: horizontalRuleFrame.minY)
        let attributes = labelAttributes(alignment: .center)

        zeroLabel.draw(
            with: labelRect,
            attributes: attributes,
            context: nil
        )
    }

    private func drawVerticalZeroLabel() {
        let geometry = ZeroCornerGeometry(zeroCorner: zeroCorner)
        let growthDirection = geometry.growthDirection(for: .vertical)
        let zeroTickY: CGFloat

        switch growthDirection {
        case .positive:
            zeroTickY = verticalRule.bounds.minY
        case .negative:
            zeroTickY = verticalRule.bounds.maxY
        }

        let lineY = verticalRule.mouseTickLineY(
            forTickY: zeroTickY,
            growthDirection: growthDirection
        )
        let labelRect = verticalRule.tickLabelRect(
            forY: lineY,
            labelSize: zeroLabelSize,
            rulerWidth: verticalRule.rulerWidth,
            tickSide: geometry.verticalTickSide
        ).offsetBy(dx: verticalRuleFrame.minX, dy: verticalRuleFrame.minY)
        let attributes = labelAttributes(
            alignment: geometry.verticalTickSide == .right ? .right : .left
        )

        zeroLabel.draw(
            with: labelRect,
            attributes: attributes,
            context: nil
        )
    }

    private func labelAttributes(alignment: NSTextAlignment) -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        let font = NSFont(name: "HelveticaNeue", size: 10) ?? .systemFont(ofSize: 10)

        return [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: color.numbers,
        ]
    }
}

final class RulerContentView: NSView {
    let horizontalRule: HorizontalRule
    let verticalRule: VerticalRule
    private let horizontalHost = RulerClipView(frame: .zero)
    private let verticalHost = RulerClipView(frame: .zero)
    private let unitLabelView = UnitLabelView(
        orientation: .horizontal,
        label: NSAttributedString(string: "")
    )
    private let zeroLabelsView: RulerWindowZeroLabelsView
    private let borderView = RulerWindowBorderView(frame: .zero)
    private var cornerTrackingArea: NSTrackingArea?

    var showsHorizontalRule = true {
        didSet {
            guard showsHorizontalRule != oldValue else { return }
            updateRuleVisibility()
        }
    }

    var showsVerticalRule = true {
        didSet {
            guard showsVerticalRule != oldValue else { return }
            updateRuleVisibility()
        }
    }

    var color = RulerColors() {
        didSet {
            zeroLabelsView.color = color
            updateUnitLabel()
            needsDisplay = true
        }
    }

    var zeroCorner = prefs.zeroCorner {
        didSet {
            zeroLabelsView.zeroCorner = zeroCorner
            horizontalRule.needsDisplay = true
            verticalRule.needsDisplay = true
            needsLayout = true
            needsDisplay = true
        }
    }

    var drawsActiveBorder = false {
        didSet {
            borderView.drawsActiveBorder = drawsActiveBorder
        }
    }

    init(
        frame frameRect: NSRect,
        horizontalRule: HorizontalRule,
        verticalRule: VerticalRule
    ) {
        self.horizontalRule = horizontalRule
        self.verticalRule = verticalRule
        self.zeroLabelsView = RulerWindowZeroLabelsView(
            horizontalRule: horizontalRule,
            verticalRule: verticalRule
        )
        super.init(frame: frameRect)

        autoresizesSubviews = false
        horizontalHost.autoresizingMask = []
        verticalHost.autoresizingMask = []
        horizontalRule.autoresizingMask = []
        verticalRule.autoresizingMask = []
        unitLabelView.autoresizingMask = []
        zeroLabelsView.autoresizingMask = []
        borderView.autoresizingMask = []
        horizontalRule.drawsBackground = false
        verticalRule.drawsBackground = false
        horizontalRule.showsUnitLabel = false
        verticalRule.showsUnitLabel = false
        horizontalRule.showsZeroTick = true
        verticalRule.showsZeroTick = true
        horizontalHost.addSubview(horizontalRule)
        verticalHost.addSubview(verticalRule)
        addSubview(horizontalHost)
        addSubview(verticalHost)
        addSubview(unitLabelView)
        addSubview(zeroLabelsView)
        addSubview(borderView)
        zeroLabelsView.color = color
        zeroLabelsView.zeroCorner = zeroCorner
        updateRuleVisibility()
        updateUnitLabel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init(frame:horizontalRule:verticalRule:)")
    }

    override var isOpaque: Bool {
        return false
    }

    override var mouseDownCanMoveWindow: Bool {
        return true
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        rebuildCornerTrackingArea()
    }

    override func resetCursorRects() {
        super.resetCursorRects()

        if showsHorizontalRule && showsVerticalRule {
            addCursorRect(cornerFrame(), cursor: .openHand)
        }
    }

    override func layout() {
        super.layout()

        let layout = RulerWindowLayout.layout(groupFrame: bounds, zeroCorner: zeroCorner)
        let cornerFrame = layout.emptyCornerFrame(zeroCorner: zeroCorner)
        setFrame(ruleFrame(for: .horizontal, in: bounds, layout: layout), for: horizontalHost)
        setFrame(horizontalHost.bounds, for: horizontalRule)
        setFrame(ruleFrame(for: .vertical, in: bounds, layout: layout), for: verticalHost)
        setFrame(verticalHost.bounds, for: verticalRule)
        updateUnitLabel()
        setFrame(unitLabelFrame(in: cornerFrame), for: unitLabelView)
        setFrame(bounds, for: zeroLabelsView)
        zeroLabelsView.horizontalRuleFrame = horizontalHost.frame
        zeroLabelsView.verticalRuleFrame = verticalHost.frame
        zeroLabelsView.showsHorizontalRule = showsHorizontalRule
        zeroLabelsView.showsVerticalRule = showsVerticalRule
        setFrame(bounds, for: borderView)
        borderView.zeroCorner = zeroCorner
        borderView.showsHorizontalRule = showsHorizontalRule
        borderView.showsVerticalRule = showsVerticalRule
        horizontalRule.needsDisplay = true
        verticalRule.needsDisplay = true
        window?.invalidateCursorRects(for: self)
        rebuildCornerTrackingArea()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        color.fill.setFill()
        rulerFillPath().fill()
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard bounds.contains(point) else { return nil }

        if let hitView = super.hitTest(point),
           hitView !== self,
           hitView !== unitLabelView {
            return hitView
        }

        return containsEmptyCorner(point) ? self : nil
    }

    override func mouseEntered(with event: NSEvent) {
        nextResponder?.mouseEntered(with: event)
    }

    override func mouseExited(with event: NSEvent) {
        nextResponder?.mouseExited(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        nextResponder?.mouseDown(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        nextResponder?.mouseUp(with: event)
    }

    override func mouseMoved(with event: NSEvent) {
        nextResponder?.mouseMoved(with: event)
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        return rulerContextMenu(for: self)
    }

    func containsEmptyCorner(_ point: NSPoint) -> Bool {
        return showsHorizontalRule && showsVerticalRule && cornerFrame().contains(point)
    }

    func localFrame(for orientation: Orientation) -> NSRect {
        let layout = RulerWindowLayout.layout(groupFrame: bounds, zeroCorner: zeroCorner)
        return ruleFrame(for: orientation, in: bounds, layout: layout)
    }

    private func cornerFrame() -> NSRect {
        return RulerWindowLayout
            .layout(groupFrame: bounds, zeroCorner: zeroCorner)
            .emptyCornerFrame(zeroCorner: zeroCorner)
    }

    private func ruleFrame(
        for orientation: Orientation,
        in bounds: NSRect,
        layout: RulerWindowLayout
    ) -> NSRect {
        switch (showsHorizontalRule, showsVerticalRule) {
        case (true, true):
            return layout.localFrame(for: orientation)
        case (true, false):
            return orientation == .horizontal ? bounds : .zero
        case (false, true):
            return orientation == .vertical ? bounds : .zero
        case (false, false):
            return .zero
        }
    }

    private func rebuildCornerTrackingArea() {
        if let cornerTrackingArea = cornerTrackingArea {
            removeTrackingArea(cornerTrackingArea)
            self.cornerTrackingArea = nil
        }

        let frame = cornerFrame()
        guard showsHorizontalRule && showsVerticalRule,
              frame.width > 0,
              frame.height > 0 else { return }

        let trackingArea = NSTrackingArea(
            rect: frame,
            options: [
                .activeAlways,
                .mouseEnteredAndExited,
                .mouseMoved,
            ],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        cornerTrackingArea = trackingArea
    }

    private func setFrame(_ frame: NSRect, for view: NSView) {
        view.setFrameOrigin(frame.origin)
        view.setFrameSize(frame.size)
    }

    private func updateRuleVisibility() {
        rebuildSubviews()
        updateRuleViewLabels()
        needsLayout = true
        needsDisplay = true
    }

    private func rebuildSubviews() {
        for view in [horizontalHost, verticalHost, unitLabelView, zeroLabelsView, borderView] {
            view.removeFromSuperview()
        }

        if showsHorizontalRule {
            addSubview(horizontalHost)
        }
        if showsVerticalRule {
            addSubview(verticalHost)
        }

        addSubview(unitLabelView)
        addSubview(zeroLabelsView)
        addSubview(borderView)
    }

    private func updateRuleViewLabels() {
        let showsBothRules = showsHorizontalRule && showsVerticalRule
        unitLabelView.isHidden = !showsBothRules
        zeroLabelsView.isHidden = !showsBothRules
        horizontalRule.showsUnitLabel = showsHorizontalRule && !showsVerticalRule
        verticalRule.showsUnitLabel = showsVerticalRule && !showsHorizontalRule
        horizontalRule.showsZeroTick = showsHorizontalRule
        verticalRule.showsZeroTick = showsVerticalRule
    }

    private func rulerFillPath() -> NSBezierPath {
        let layout = RulerWindowLayout.layout(groupFrame: bounds, zeroCorner: zeroCorner)

        switch (showsHorizontalRule, showsVerticalRule) {
        case (true, true):
            return rulerWindowLShapedPath(in: bounds, zeroCorner: zeroCorner, inset: 0)
        case (true, false):
            return NSBezierPath(rect: ruleFrame(for: .horizontal, in: bounds, layout: layout))
        case (false, true):
            return NSBezierPath(rect: ruleFrame(for: .vertical, in: bounds, layout: layout))
        case (false, false):
            return NSBezierPath()
        }
    }

    private func unitLabelFrame(in cornerFrame: NSRect) -> NSRect {
        let labelFrame = unitLabelView.frame(in: NSRect(origin: .zero, size: cornerFrame.size))
        return NSRect(
            x: cornerFrame.minX + labelFrame.minX,
            y: cornerFrame.minY + labelFrame.minY,
            width: labelFrame.width,
            height: labelFrame.height
        )
    }

    private func updateUnitLabel() {
        unitLabelView.zeroCorner = zeroCorner
        unitLabelView.label = NSAttributedString(
            string: unitLabelString(),
            attributes: unitLabelAttributes()
        )
    }

    private func unitLabelString() -> String {
        return horizontalRule.getUnitLabel()
    }

    private func unitLabelAttributes() -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        let font = NSFont(name: "HelveticaNeue", size: 10) ?? .systemFont(ofSize: 10)

        return [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: color.ticks,
        ]
    }
}

#if !SNAPSHOT_GENERATOR
final class RulerController: NSWindowController, NSWindowDelegate, NotificationObserver {
    var observers: [NSKeyValueObservation] = []
    var notificationObservers: [NSObjectProtocol] = []

    let rulerWindow: RulerWindow
    var state: RulerInstanceState
    var onBecameActive: ((RulerController) -> Void)?
    var onDragStarted: ((RulerController) -> Void)?
    var onDragged: ((RulerController) -> Void)?
    var onDragFinished: ((RulerController) -> Void)?
    var onStateChanged: ((RulerController) -> Void)?

    private var keyListener: Any?
    private var mouseInteraction: RulerMouseInteractionState!
    private var isMouseTickDrawingEnabled = true
    private let rulerInteractionSuspensionOwners = NSHashTable<AnyObject>.weakObjects()
    private let followsDefaultPreferences: Bool

    var isLeftMouseButtonPressed = {
        return NSEvent.pressedMouseButtons & 1 == 1
    }

    var isRulerInteractionSuspended: Bool {
        guard rulerInteractionSuspensionOwners.count > 0 else { return false }
        return rulerInteractionSuspensionOwners.anyObject != nil
    }

    var opacity = 0 {
        didSet {
            rulerWindow.alphaValue = windowAlphaValue(opacity)
        }
    }

    convenience init(frame: NSRect) {
        let layout = RulerWindowLayout.layout(groupFrame: frame, zeroCorner: prefs.zeroCorner)
        let state = RulerInstanceState(
            settings: RulerSettings(defaults: prefs),
            layout: RulerLayoutState(
                horizontalFrame: layout.horizontalFrame,
                verticalFrame: layout.verticalFrame,
                zeroCorner: prefs.zeroCorner
            )
        )

        self.init(state: state, followsDefaultPreferences: true)
    }

    convenience init(state: RulerInstanceState) {
        self.init(state: state, followsDefaultPreferences: false)
    }

    private init(state: RulerInstanceState, followsDefaultPreferences: Bool) {
        self.state = state
        self.followsDefaultPreferences = followsDefaultPreferences
        let layout = state.layout.layout(zeroCorner: state.settings.zeroCorner)
        rulerWindow = RulerWindow(
            frame: layout.visibleFrame(
                showsHorizontalRule: state.visibility.showsHorizontal,
                showsVerticalRule: state.visibility.showsVertical
            ),
            settings: state.settings
        )
        super.init(window: rulerWindow)

        opacity = state.settings.foregroundOpacity
        createObservers()
        subscribeToPrefs()

        rulerWindow.delegate = self
        rulerWindow.nextResponder = self
        mouseInteraction = RulerMouseInteractionState(owner: self) { [weak self] event in
            return self?.mouseIsInsideRuler(with: event) ?? false
        }
        applyStateToWindow(display: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init(frame:)")
    }

    deinit {
        mouseInteraction?.invalidate()
        removeObservers(&notificationObservers)
        stopKeyListener()
    }

    var isVisible: Bool {
        return rulerWindow.isVisible
    }

    func show() {
        applyStateToWindow(display: false)
        showWindow(self)
        rulerWindow.orderFrontRegardless()
    }

    func show(
        horizontalFrame: NSRect,
        verticalFrame: NSRect,
        showsHorizontalRule: Bool,
        showsVerticalRule: Bool
    ) {
        state.layout = RulerLayoutState(
            horizontalFrame: horizontalFrame,
            verticalFrame: verticalFrame,
            zeroCorner: prefs.zeroCorner
        )
        state.settings.zeroCorner = prefs.zeroCorner
        state.visibility = RulerWingVisibility(
            horizontal: showsHorizontalRule,
            vertical: showsVerticalRule
        )
        show()
    }

    func hide() {
        rulerWindow.orderOut(self)
    }

    @discardableResult
    func toggleWing(_ orientation: Orientation) -> Bool {
        guard state.toggleWing(orientation) else { return false }

        applyStateToWindow(display: true)
        notifyStateChanged()
        return true
    }

    @discardableResult
    func setWing(_ orientation: Orientation, isVisible: Bool) -> Bool {
        guard state.setWing(orientation, isVisible: isVisible) else { return false }

        applyStateToWindow(display: true)
        notifyStateChanged()
        return true
    }

    func align(at point: NSPoint) {
        let horizontalLength = rulerWindow.screenFrame(for: .horizontal).width
        let verticalLength = rulerWindow.screenFrame(for: .vertical).height
        let layout = RulerWindowLayout.layout(
            horizontalLength: horizontalLength,
            verticalLength: verticalLength,
            zeroPoint: point,
            zeroCorner: state.settings.zeroCorner
        )

        rulerWindow.setFrame(rulerWindow.visibleFrame(in: layout), display: true)
        rulerWindow.updateLayoutForCurrentZeroCorner()
        captureStateFromWindow()
    }

    func prepareForZeroCornerChange(to zeroCorner: ZeroCorner) {
        let zeroPoint = rulerWindow.zeroPoint()
        let horizontalLength = rulerWindow.screenFrame(for: .horizontal).width
        let verticalLength = rulerWindow.screenFrame(for: .vertical).height
        let layout = RulerWindowLayout.layout(
            horizontalLength: horizontalLength,
            verticalLength: verticalLength,
            zeroPoint: zeroPoint,
            zeroCorner: zeroCorner
        )

        state.settings.zeroCorner = zeroCorner
        rulerWindow.apply(settings: state.settings)
        rulerWindow.alphaValue = windowAlphaValue(opacity)
        updateIsFloatingPanel()
        updateHasShadow()
        rulerWindow.setFrame(rulerWindow.visibleFrame(in: layout), display: true)
        captureStateFromWindow()
        notifyStateChanged()
    }

    func foreground() {
        opacity = state.settings.foregroundOpacity
    }

    func background() {
        opacity = state.settings.backgroundOpacity
    }

    func suspendRulerInteraction(owner: AnyObject) {
        guard !rulerInteractionSuspensionOwners.contains(owner) else { return }

        rulerInteractionSuspensionOwners.add(owner)
        updateIsFloatingPanel()
    }

    func resumeRulerInteraction(owner: AnyObject) {
        guard rulerInteractionSuspensionOwners.contains(owner) else { return }

        rulerInteractionSuspensionOwners.remove(owner)
        updateIsFloatingPanel()

        if !isRulerInteractionSuspended {
            opacity = state.settings.foregroundOpacity
        }
    }

    func updateIsFloatingPanel() {
        rulerWindow.isFloatingPanel = isRulerInteractionSuspended ? false : state.settings.floatRulers
    }

    func updateHasShadow() {
        rulerWindow.hasShadow = state.settings.rulerShadow
    }

    func redrawForPreferenceChange() {
        rulerWindow.redrawForPreferenceChange()
    }

    func updateSettings(_ update: (inout RulerSettings) -> Void) {
        update(&state.settings)
        applyStateToWindow(display: true)
        notifyStateChanged()
    }

    func updateDimensions(horizontalLength: CGFloat, verticalLength: CGFloat) {
        let minHorizontalLength = getMinSize(ruler: Ruler(.horizontal)).width
        let maxHorizontalLength = getMaxSize(ruler: Ruler(.horizontal)).width
        let minVerticalLength = getMinSize(ruler: Ruler(.vertical)).height
        let maxVerticalLength = getMaxSize(ruler: Ruler(.vertical)).height

        state.layout = RulerLayoutState(
            zeroPoint: rulerWindow.zeroPoint(),
            horizontalLength: min(max(horizontalLength, minHorizontalLength), maxHorizontalLength),
            verticalLength: min(max(verticalLength, minVerticalLength), maxVerticalLength)
        )
        applyStateToWindow(display: true)
        notifyStateChanged()
    }

    func move(to frame: NSRect) {
        rulerWindow.setFrame(frame, display: false)
        captureStateFromWindow()
    }

    func captureCurrentState() {
        captureStateFromWindow()
    }

    func resetPosition() {
        state.settings.zeroCorner = Prefs.defaultZeroCorner
        state.layout = RulerLayoutState.defaults(
            zeroCorner: Prefs.defaultZeroCorner
        )
        state.visibility = RulerWingVisibility()
        show()
        notifyStateChanged()
    }

    func drawMouseTick(at mouseLoc: NSPoint) {
        if rulerWindow.isRuleVisible(.horizontal) {
            rulerWindow.horizontalRule.drawMouseTick(at: mouseLoc)
        }
        if rulerWindow.isRuleVisible(.vertical) {
            rulerWindow.verticalRule.drawMouseTick(at: mouseLoc)
        }
    }

    func setMouseTickDrawingEnabled(_ isEnabled: Bool) {
        isMouseTickDrawingEnabled = isEnabled
        updateMouseTickDrawingVisibility()
    }

    private func updateMouseTickDrawingVisibility() {
        rulerWindow.horizontalRule.showMouseTick = isMouseTickDrawingEnabled
            && rulerWindow.isRuleVisible(.horizontal)
        rulerWindow.verticalRule.showMouseTick = isMouseTickDrawingEnabled
            && rulerWindow.isRuleVisible(.vertical)
    }

    private func applyStateToWindow(display: Bool) {
        let zeroCorner = state.settings.zeroCorner
        let layout = state.layout.layout(zeroCorner: zeroCorner)
        rulerWindow.apply(settings: state.settings)
        rulerWindow.alphaValue = windowAlphaValue(opacity)
        updateIsFloatingPanel()
        updateHasShadow()
        rulerWindow.setVisibleRules(
            horizontal: state.visibility.showsHorizontal,
            vertical: state.visibility.showsVertical
        )
        updateMouseTickDrawingVisibility()
        rulerWindow.setFrame(
            layout.visibleFrame(
                showsHorizontalRule: state.visibility.showsHorizontal,
                showsVerticalRule: state.visibility.showsVertical
            ),
            display: display
        )
        rulerWindow.updateLayoutForCurrentZeroCorner()
    }

    private func captureStateFromWindow() {
        var horizontalLength = state.layout.horizontalLength
        var verticalLength = state.layout.verticalLength

        if rulerWindow.isRuleVisible(.horizontal) {
            horizontalLength = rulerWindow.screenFrame(for: .horizontal).width
        }
        if rulerWindow.isRuleVisible(.vertical) {
            verticalLength = rulerWindow.screenFrame(for: .vertical).height
        }

        state.layout = RulerLayoutState(
            zeroPoint: rulerWindow.zeroPoint(),
            horizontalLength: horizontalLength,
            verticalLength: verticalLength
        )
        state.visibility = RulerWingVisibility(
            horizontal: rulerWindow.isRuleVisible(.horizontal),
            vertical: rulerWindow.isRuleVisible(.vertical)
        )
        notifyStateChanged()
    }

    private func notifyStateChanged() {
        onStateChanged?(self)
    }

    func windowWillStartLiveResize(_ notification: Notification) {
        mouseInteraction.windowWillStartLiveResize()
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        captureStateFromWindow()
        mouseInteraction.windowDidEndLiveResize()
    }

    func windowWillMove(_ notification: Notification) {
        mouseInteraction.windowWillMove()
    }

    func windowDidMove(_ notification: Notification) {
        rulerWindow.invalidateShadow()
        captureStateFromWindow()
        onDragged?(self)
        mouseInteraction.windowDidMove(isLeftMouseButtonPressed: isLeftMouseButtonPressed())
    }

    func windowDidBecomeKey(_ notification: Notification) {
        onBecameActive?(self)
        startKeyListener()
    }

    func windowDidResignKey(_ notification: Notification) {
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
        onDragStarted?(self)
    }

    override func mouseUp(with event: NSEvent) {
        finishMouseDrag(with: event)
    }

    func finishMouseDrag(with event: NSEvent) {
        if mouseInteraction.finishMouseDrag(with: event) {
            captureStateFromWindow()
            onDragFinished?(self)
        }
    }

    func activateForRulerContextMenu() {
        onBecameActive?(self)
    }

    override func mouseMoved(with event: NSEvent) {
        mouseInteraction.mouseMoved(with: event)
    }

    private func mouseIsInsideRuler(with event: NSEvent) -> Bool {
        return orientation(at: event) != nil
            || rulerWindow.isEmptyCorner(atWindowPoint: event.locationInWindow)
    }

    private func orientation(at event: NSEvent) -> Orientation? {
        let horizontalLocation = rulerWindow.horizontalRule.convert(event.locationInWindow, from: nil)
        let verticalLocation = rulerWindow.verticalRule.convert(event.locationInWindow, from: nil)

        if rulerWindow.isRuleVisible(.horizontal),
           rulerWindow.horizontalRule.bounds.contains(horizontalLocation) {
            return .horizontal
        }

        if rulerWindow.isRuleVisible(.vertical),
           rulerWindow.verticalRule.bounds.contains(verticalLocation) {
            return .vertical
        }

        return nil
    }

    private func createObservers() {
        notificationObservers = [
            addObserver(.preferencesWindowOpened) { [weak self] notification in
                guard let owner = notification.object else { return }
                self?.suspendRulerInteraction(owner: owner as AnyObject)
            },
            addObserver(.preferencesWindowClosed) { [weak self] notification in
                guard let owner = notification.object else { return }
                self?.resumeRulerInteraction(owner: owner as AnyObject)
            },
        ]
    }

    private func subscribeToPrefs() {
        guard followsDefaultPreferences else {
            observers = []
            return
        }

        observers = [
            prefs.observe(\Prefs.foregroundOpacity, options: .new) { [weak self] prefs, changed in
                self?.opacity = prefs.foregroundOpacity
            },
            prefs.observe(\Prefs.backgroundOpacity, options: .new) { [weak self] prefs, changed in
                self?.opacity = prefs.backgroundOpacity
            },
            prefs.observe(\Prefs.floatRulers, options: .new) { [weak self] prefs, changed in
                self?.updateIsFloatingPanel()
            },
            prefs.observe(\Prefs.rulerShadow, options: .new) { [weak self] prefs, changed in
                self?.updateHasShadow()
            },
        ]
    }
}

// MARK: KeyListener

extension RulerController {
    func startKeyListener() {
        keyListener = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] in
            guard let self = self else { return $0 }
            return self.onKeyDown(with: $0)
        }
    }

    func stopKeyListener() {
        if let keyListener = keyListener {
            NSEvent.removeMonitor(keyListener)
            self.keyListener = nil
        }
    }

    func onKeyDown(with event: NSEvent) -> NSEvent? {
        let shift = event.modifierFlags.contains(.shift)
        let keyboardModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        guard !isRulerInteractionSuspended,
              rulerWindow.isKeyWindow else { return event }

        if let appDelegate = NSApp.delegate as? AppDelegate,
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

final class RulerManager {
    typealias ControllerFactory = (RulerInstanceState) -> RulerController

    private struct GroupedDragState {
        let draggedRulerID: UUID
        let framesByRulerID: [UUID: NSRect]
        let attachedRulerIDs: Set<UUID>
    }

    private let controllerFactory: ControllerFactory
    private(set) var controllers: [RulerController] = []
    private(set) var activeRulerID: UUID?
    var onActiveControllerChanged: ((RulerController?) -> Void)?
    var onStateChanged: ((RulerManager) -> Void)?
    private var isApplicationActive = true
    private var groupedDragState: GroupedDragState?
    private var isApplyingGroupedDrag = false

    init(
        initialStates: [RulerInstanceState] = [],
        controllerFactory: @escaping ControllerFactory = { RulerController(state: $0) }
    ) {
        self.controllerFactory = controllerFactory
        restore(initialStates)
    }

    var hasRulers: Bool {
        return !controllers.isEmpty
    }

    var hasVisibleRulers: Bool {
        return controllers.contains { $0.isVisible }
    }

    var activeController: RulerController? {
        if let activeRulerID = activeRulerID,
           let controller = controllers.first(where: { $0.state.id == activeRulerID }) {
            return controller
        }

        if let keyController = controllers.first(where: { $0.rulerWindow.isKeyWindow }) {
            return keyController
        }

        return controllers.last
    }

    var states: [RulerInstanceState] {
        return controllers.map { $0.state }
    }

    @discardableResult
    func createRuler(
        defaults: RulerSettings = RulerSettings(defaults: prefs),
        screenFrame: NSRect = defaultRulerScreenFrame()
    ) -> RulerController {
        let defaultState = RulerInstanceState.createFromDefaults(
            defaults: defaults,
            screenFrame: screenFrame
        )
        let state = staggeredState(from: defaultState)

        return addRuler(state: state)
    }

    @discardableResult
    func addRuler(state: RulerInstanceState) -> RulerController {
        let controller = controllerFactory(state)
        configure(controller)
        controllers.append(controller)
        markActive(controller)
        return controller
    }

    func restore(_ states: [RulerInstanceState], activeRulerID restoredActiveRulerID: UUID? = nil) {
        for controller in controllers {
            controller.rulerWindow.drawsActiveBorder = false
            controller.hide()
        }

        controllers = []
        activeRulerID = nil
        onActiveControllerChanged?(nil)

        for state in states where state.hasVisibleWing {
            addRuler(state: state)
        }

        if let restoredActiveRulerID = restoredActiveRulerID,
           let restoredActiveController = controller(id: restoredActiveRulerID) {
            markActive(restoredActiveController)
        }

        notifyStateChanged()
    }

    func showAll() {
        for controller in controllers {
            controller.show()
        }

        if let activeController = activeController {
            activeController.rulerWindow.makeKey()
        }
    }

    @discardableResult
    func cycleActiveRuler() -> RulerController? {
        let visibleControllers = controllers.filter(\.isVisible)
        guard !visibleControllers.isEmpty else { return nil }

        let activeID = activeController?.state.id
        let activeIndex = activeID.flatMap { activeID in
            visibleControllers.firstIndex { $0.state.id == activeID }
        }
        let nextIndex = activeIndex.map { ($0 + 1) % visibleControllers.count } ?? 0
        let nextController = visibleControllers[nextIndex]

        markActive(nextController)
        nextController.rulerWindow.orderFrontRegardless()
        nextController.rulerWindow.makeKey()
        return nextController
    }

    func setApplicationActive(_ isApplicationActive: Bool) {
        guard self.isApplicationActive != isApplicationActive else { return }

        self.isApplicationActive = isApplicationActive
        updateActiveRulerBorders()
    }

    @discardableResult
    func closeActiveRuler() -> Bool {
        guard let activeController = activeController else { return false }

        close(activeController)
        return true
    }

    func close(_ controller: RulerController) {
        let wasActiveController = activeRulerID == controller.state.id

        controller.hide()
        controllers.removeAll { $0 === controller }

        if wasActiveController {
            activeRulerID = controllers.last?.state.id
        }

        updateActiveRulerBorders()

        if wasActiveController {
            onActiveControllerChanged?(activeController)
        }

        notifyStateChanged()
    }

    func markActive(_ controller: RulerController) {
        guard controllers.contains(where: { $0 === controller }) else { return }

        activeRulerID = controller.state.id
        if prefs.groupRulers {
            moveControllerToTopOfStack(controller)
        }
        updateActiveRulerBorders()
        onActiveControllerChanged?(controller)
        notifyStateChanged()
    }

    func beginGroupedDrag(from controller: RulerController) {
        if let groupedDragState = groupedDragState {
            detachGroupedDragFollowers(groupedDragState)
        }

        guard prefs.groupRulers,
              controllers.contains(where: { $0 === controller }) else {
            groupedDragState = nil
            return
        }

        let visibleControllers = controllers.filter(\.isVisible)
        groupedDragState = GroupedDragState(
            draggedRulerID: controller.state.id,
            framesByRulerID: Dictionary(
                uniqueKeysWithValues: visibleControllers
                    .map { ($0.state.id, $0.rulerWindow.frame) }
            ),
            attachedRulerIDs: attachGroupedDragFollowers(
                to: controller,
                visibleControllers: visibleControllers
            )
        )
    }

    func syncGroupedDrag(from controller: RulerController) {
        guard prefs.groupRulers,
              !isApplyingGroupedDrag,
              let groupedDragState = groupedDragState,
              groupedDragState.draggedRulerID == controller.state.id,
              let originalDraggedFrame = groupedDragState.framesByRulerID[controller.state.id] else {
            return
        }

        let offset = NSSize(
            width: controller.rulerWindow.frame.minX - originalDraggedFrame.minX,
            height: controller.rulerWindow.frame.minY - originalDraggedFrame.minY
        )
        guard offset.width != 0 || offset.height != 0 else { return }

        isApplyingGroupedDrag = true
        defer {
            isApplyingGroupedDrag = false
        }

        var movedFollower = false
        for otherController in controllers where otherController !== controller && otherController.isVisible {
            guard var frame = groupedDragState.framesByRulerID[otherController.state.id] else { continue }
            guard !rulerMovesWithGroupedDragParent(
                otherController,
                draggedController: controller,
                groupedDragState: groupedDragState
            ) else {
                continue
            }

            frame.origin.x += offset.width
            frame.origin.y += offset.height
            otherController.move(to: frame)
            movedFollower = true
        }

        if movedFollower {
            notifyStateChanged()
        }
    }

    func finishGroupedDrag(from controller: RulerController) {
        guard let groupedDragState = groupedDragState else { return }
        guard groupedDragState.draggedRulerID == controller.state.id else {
            detachGroupedDragFollowers(groupedDragState)
            self.groupedDragState = nil
            return
        }

        syncGroupedDrag(from: controller)
        detachGroupedDragFollowers(from: controller, groupedDragState: groupedDragState)
        captureGroupedDragFollowerStates(excluding: controller, groupedDragState: groupedDragState)
        moveControllerToTopOfStack(controller)
        DispatchQueue.main.async { [weak self, weak controller] in
            guard let self = self,
                  let controller = controller,
                  prefs.groupRulers,
                  self.activeRulerID == controller.state.id else {
                return
            }

            self.moveControllerToTopOfStack(controller)
        }
        self.groupedDragState = nil
        notifyStateChanged()
    }

    func controller(containing window: NSWindow?) -> RulerController? {
        guard let window = window else { return nil }

        return controllers.first { $0.rulerWindow === window }
    }

    func controller(id: UUID) -> RulerController? {
        return controllers.first { $0.state.id == id }
    }

    private func configure(_ controller: RulerController) {
        controller.onBecameActive = { [weak self, weak controller] _ in
            guard let controller = controller else { return }
            self?.markActive(controller)
        }
        controller.onDragStarted = { [weak self, weak controller] _ in
            guard let controller = controller else { return }
            self?.beginGroupedDrag(from: controller)
        }
        controller.onDragged = { [weak self, weak controller] _ in
            guard let controller = controller else { return }
            self?.syncGroupedDrag(from: controller)
        }
        controller.onDragFinished = { [weak self, weak controller] _ in
            guard let controller = controller else { return }
            self?.finishGroupedDrag(from: controller)
        }
        controller.onStateChanged = { [weak self, weak controller] _ in
            guard let controller = controller,
                  self?.activeRulerID == controller.state.id else { return }

            self?.activeRulerID = controller.state.id
            self?.notifyStateChanged()
        }
    }

    private func moveControllerToTopOfStack(_ controller: RulerController) {
        if let index = controllers.firstIndex(where: { $0 === controller }),
           index != controllers.index(before: controllers.endIndex) {
            controllers.remove(at: index)
            controllers.append(controller)
        }

        if controller.isVisible {
            controller.rulerWindow.orderFrontRegardless()
            for otherController in controllers where otherController !== controller && otherController.isVisible {
                controller.rulerWindow.order(.above, relativeTo: otherController.rulerWindow.windowNumber)
                otherController.rulerWindow.order(.below, relativeTo: controller.rulerWindow.windowNumber)
            }
        }
    }

    private func attachGroupedDragFollowers(
        to draggedController: RulerController,
        visibleControllers: [RulerController]
    ) -> Set<UUID> {
        let draggedWindow = draggedController.rulerWindow
        var attachedRulerIDs = Set<UUID>()

        for followerController in visibleControllers where followerController !== draggedController {
            let followerWindow = followerController.rulerWindow
            guard followerWindow.parent == nil else { continue }

            draggedWindow.addChildWindow(followerWindow, ordered: .below)
            attachedRulerIDs.insert(followerController.state.id)
        }

        return attachedRulerIDs
    }

    private func detachGroupedDragFollowers(_ groupedDragState: GroupedDragState) {
        guard let draggedController = controller(id: groupedDragState.draggedRulerID) else { return }

        detachGroupedDragFollowers(from: draggedController, groupedDragState: groupedDragState)
    }

    private func detachGroupedDragFollowers(
        from draggedController: RulerController,
        groupedDragState: GroupedDragState
    ) {
        let draggedWindow = draggedController.rulerWindow

        for rulerID in groupedDragState.attachedRulerIDs {
            guard let followerController = controller(id: rulerID),
                  followerController.rulerWindow.parent === draggedWindow else { continue }

            draggedWindow.removeChildWindow(followerController.rulerWindow)
            if draggedController.isVisible, followerController.isVisible {
                followerController.rulerWindow.order(.below, relativeTo: draggedWindow.windowNumber)
            }
        }
    }

    private func rulerMovesWithGroupedDragParent(
        _ followerController: RulerController,
        draggedController: RulerController,
        groupedDragState: GroupedDragState
    ) -> Bool {
        return groupedDragState.attachedRulerIDs.contains(followerController.state.id)
            || followerController.rulerWindow.parent === draggedController.rulerWindow
    }

    private func captureGroupedDragFollowerStates(
        excluding draggedController: RulerController,
        groupedDragState: GroupedDragState
    ) {
        for followerController in controllers where followerController !== draggedController {
            guard groupedDragState.framesByRulerID[followerController.state.id] != nil else { continue }

            followerController.captureCurrentState()
        }
    }

    private func staggeredState(from defaultState: RulerInstanceState) -> RulerInstanceState {
        var state = defaultState
        let offset = Ruler.thickness / 2

        while controllers.contains(where: { $0.state.layout.zeroPoint == state.layout.zeroPoint }) {
            state.layout.zeroPoint.x += offset
            state.layout.zeroPoint.y -= offset
        }

        return state
    }

    private func notifyStateChanged() {
        onStateChanged?(self)
    }

    private func updateActiveRulerBorders() {
        for controller in controllers {
            controller.rulerWindow.drawsActiveBorder = isApplicationActive
                && controller.state.id == activeRulerID
        }
    }
}
#endif

private func rulerWindowLShapedPath(
    in bounds: NSRect,
    zeroCorner: ZeroCorner,
    inset: CGFloat
) -> NSBezierPath {
    let layout = RulerWindowLayout.layout(groupFrame: bounds, zeroCorner: zeroCorner)
    let horizontalFrame = layout.localFrame(for: .horizontal)
    let verticalFrame = layout.localFrame(for: .vertical)
    let minX = bounds.minX + inset
    let maxX = bounds.maxX - inset
    let minY = bounds.minY + inset
    let maxY = bounds.maxY - inset
    let path = NSBezierPath()
    let points: [NSPoint]

    switch zeroCorner {
    case .topLeft:
        let innerX = verticalFrame.maxX - inset
        let innerY = horizontalFrame.minY + inset
        points = [
            NSPoint(x: minX, y: minY),
            NSPoint(x: innerX, y: minY),
            NSPoint(x: innerX, y: innerY),
            NSPoint(x: maxX, y: innerY),
            NSPoint(x: maxX, y: maxY),
            NSPoint(x: minX, y: maxY),
        ]
    case .topRight:
        let innerX = verticalFrame.minX + inset
        let innerY = horizontalFrame.minY + inset
        points = [
            NSPoint(x: minX, y: innerY),
            NSPoint(x: innerX, y: innerY),
            NSPoint(x: innerX, y: minY),
            NSPoint(x: maxX, y: minY),
            NSPoint(x: maxX, y: maxY),
            NSPoint(x: minX, y: maxY),
        ]
    case .bottomLeft:
        let innerX = verticalFrame.maxX - inset
        let innerY = horizontalFrame.maxY - inset
        points = [
            NSPoint(x: minX, y: minY),
            NSPoint(x: maxX, y: minY),
            NSPoint(x: maxX, y: innerY),
            NSPoint(x: innerX, y: innerY),
            NSPoint(x: innerX, y: maxY),
            NSPoint(x: minX, y: maxY),
        ]
    case .bottomRight:
        let innerX = verticalFrame.minX + inset
        let innerY = horizontalFrame.maxY - inset
        points = [
            NSPoint(x: minX, y: minY),
            NSPoint(x: maxX, y: minY),
            NSPoint(x: maxX, y: maxY),
            NSPoint(x: innerX, y: maxY),
            NSPoint(x: innerX, y: innerY),
            NSPoint(x: minX, y: innerY),
        ]
    }

    guard let firstPoint = points.first else { return path }

    path.move(to: firstPoint)
    for point in points.dropFirst() {
        path.line(to: point)
    }
    path.close()
    return path
}
