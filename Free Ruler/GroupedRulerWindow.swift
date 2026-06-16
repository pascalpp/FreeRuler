import Cocoa
import Carbon.HIToolbox

struct GroupedRulerLayout: Equatable {
    let groupFrame: NSRect
    let horizontalFrame: NSRect
    let verticalFrame: NSRect

    private static let borderCompensation: CGFloat = 1.0

    static func joined(
        horizontalFrame: NSRect,
        verticalFrame: NSRect,
        zeroCorner: ZeroCorner
    ) -> GroupedRulerLayout {
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
    ) -> GroupedRulerLayout {
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
    ) -> GroupedRulerLayout {
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

        return GroupedRulerLayout(
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
        let x: CGFloat
        let y: CGFloat

        switch zeroCorner.horizontalZeroSide {
        case .left:
            x = groupFrame.minX + Ruler.thickness - borderCompensation
        case .right:
            x = groupFrame.maxX - Ruler.thickness
        }

        switch zeroCorner.verticalZeroSide {
        case .top:
            y = groupFrame.maxY - Ruler.thickness + borderCompensation
        case .bottom:
            y = groupFrame.minY + Ruler.thickness - borderCompensation
        }

        return NSPoint(x: x, y: y)
    }

    private static func length(
        in groupFrame: NSRect,
        from zeroPoint: NSPoint,
        along orientation: Orientation,
        zeroCorner: ZeroCorner
    ) -> CGFloat {
        switch orientation {
        case .horizontal:
            switch zeroCorner.horizontalZeroSide {
            case .left:
                return max(0, groupFrame.maxX - zeroPoint.x)
            case .right:
                return max(0, zeroPoint.x - groupFrame.minX)
            }
        case .vertical:
            switch zeroCorner.verticalZeroSide {
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

private extension ZeroCorner {
    var horizontalZeroSide: RulerHorizontalSide {
        switch self {
        case .topLeft, .bottomLeft:
            return .left
        case .topRight, .bottomRight:
            return .right
        }
    }

    var verticalZeroSide: RulerVerticalSide {
        switch self {
        case .topLeft, .topRight:
            return .top
        case .bottomLeft, .bottomRight:
            return .bottom
        }
    }
}

private extension GroupedRulerLayout {
    func emptyCornerFrame(zeroCorner: ZeroCorner) -> NSRect {
        let x: CGFloat
        let width: CGFloat
        let y: CGFloat
        let height: CGFloat

        switch zeroCorner.horizontalZeroSide {
        case .left:
            x = groupFrame.minX
            width = horizontalFrame.minX - groupFrame.minX
        case .right:
            x = horizontalFrame.maxX
            width = groupFrame.maxX - horizontalFrame.maxX
        }

        switch zeroCorner.verticalZeroSide {
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
final class GroupedRulerWindow: NSPanel {
    let horizontalRule: HorizontalRule
    let verticalRule: VerticalRule

    private let groupedContentView: GroupedRulerContentView

    init(frame: NSRect) {
        horizontalRule = GroupedHorizontalRule(
            frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness)
        )
        verticalRule = GroupedVerticalRule(
            frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300)
        )
        groupedContentView = GroupedRulerContentView(
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

        alphaValue = windowAlphaValue(prefs.foregroundOpacity)
        title = NSLocalizedString(
            "Grouped Rulers",
            comment: "Window title for the grouped ruler window"
        )
        identifier = NSUserInterfaceItemIdentifier("grouped-ruler-window")
        setAccessibilityIdentifier("grouped-ruler-window")
        minSize = GroupedRulerLayout.minSize(zeroCorner: prefs.zeroCorner)
        maxSize = GroupedRulerLayout.maxSize(zeroCorner: prefs.zeroCorner)

        isOpaque = false
        backgroundColor = .clear
        isFloatingPanel = prefs.floatRulers
        hidesOnDeactivate = false
        isMovableByWindowBackground = true
        hasShadow = prefs.rulerShadow

        horizontalRule.setAccessibilityElement(true)
        verticalRule.setAccessibilityElement(true)
        horizontalRule.setAccessibilityIdentifier("horizontal-ruler-view")
        verticalRule.setAccessibilityIdentifier("vertical-ruler-view")
        horizontalRule.nextResponder = self
        verticalRule.nextResponder = self
        groupedContentView.nextResponder = self

        contentView = groupedContentView
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
        updateGroupedContentFrame()
    }

    override func setContentSize(_ size: NSSize) {
        super.setContentSize(size)
        updateGroupedContentFrame()
    }

    override func mouseDown(with event: NSEvent) {
        nextResponder?.mouseDown(with: event)
        super.mouseDown(with: event)

        if !leftMouseButtonIsPressed {
            (nextResponder as? GroupedRulerController)?.finishMouseDrag(with: event)
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
        updateGroupedContentFrame()
        groupedContentView.zeroCorner = prefs.zeroCorner
        groupedContentView.needsLayout = true
        groupedContentView.layoutSubtreeIfNeeded()
        groupedContentView.needsDisplay = true
    }

    func redrawForPreferenceChange() {
        updateLayoutForCurrentZeroCorner()
        horizontalRule.redrawForPreferenceChange()
        verticalRule.redrawForPreferenceChange()
    }

    func screenFrame(for orientation: Orientation) -> NSRect {
        return convertToScreen(groupedContentView.localFrame(for: orientation))
    }

    func visibleFrame(in layout: GroupedRulerLayout) -> NSRect {
        return layout.visibleFrame(
            showsHorizontalRule: groupedContentView.showsHorizontalRule,
            showsVerticalRule: groupedContentView.showsVerticalRule
        )
    }

    func setVisibleRules(horizontal: Bool, vertical: Bool) {
        groupedContentView.showsHorizontalRule = horizontal
        groupedContentView.showsVerticalRule = vertical
        updateSizeConstraintsForVisibleRules()
        groupedContentView.needsLayout = true
        groupedContentView.layoutSubtreeIfNeeded()
    }

    func isRuleVisible(_ orientation: Orientation) -> Bool {
        switch orientation {
        case .horizontal:
            return groupedContentView.showsHorizontalRule
        case .vertical:
            return groupedContentView.showsVerticalRule
        }
    }

    func isEmptyCorner(atWindowPoint windowPoint: NSPoint) -> Bool {
        let contentPoint = groupedContentView.convert(windowPoint, from: nil)
        return groupedContentView.containsEmptyCorner(contentPoint)
    }

    func zeroPoint() -> NSPoint {
        let geometry = ZeroCornerGeometry(zeroCorner: prefs.zeroCorner)

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

    private var leftMouseButtonIsPressed: Bool {
        return NSEvent.pressedMouseButtons & 1 == 1
    }

    private func updateGroupedContentFrame() {
        guard contentView === groupedContentView else { return }

        groupedContentView.frame = NSRect(origin: .zero, size: frame.size)
        groupedContentView.needsLayout = true
        groupedContentView.layoutSubtreeIfNeeded()
    }

    private func updateSizeConstraintsForVisibleRules() {
        minSize = GroupedRulerLayout.minSize(
            zeroCorner: prefs.zeroCorner,
            showsHorizontalRule: groupedContentView.showsHorizontalRule,
            showsVerticalRule: groupedContentView.showsVerticalRule
        )
        maxSize = GroupedRulerLayout.maxSize(
            zeroCorner: prefs.zeroCorner,
            showsHorizontalRule: groupedContentView.showsHorizontalRule,
            showsVerticalRule: groupedContentView.showsVerticalRule
        )
    }
}

private final class GroupedHorizontalRule: HorizontalRule {
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(NSSize(width: newSize.width, height: Ruler.thickness))
    }
}

private final class GroupedVerticalRule: VerticalRule {
    override var rulerWidth: CGFloat {
        return Ruler.thickness
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(NSSize(width: Ruler.thickness, height: newSize.height))
    }
}

extension GroupedRulerWindow {
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

private final class GroupedRulerBorderView: RulerBorderView {
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

    override func borderPath(in bounds: NSRect) -> NSBezierPath {
        switch (showsHorizontalRule, showsVerticalRule) {
        case (true, true):
            return lShapedBorderPath()
        case (true, false):
            return visibleBoundsBorderPath()
        case (false, true):
            return visibleBoundsBorderPath()
        case (false, false):
            return NSBezierPath()
        }
    }

    private func lShapedBorderPath() -> NSBezierPath {
        let layout = GroupedRulerLayout.layout(groupFrame: bounds, zeroCorner: zeroCorner)
        let horizontalFrame = layout.localFrame(for: .horizontal)
        let verticalFrame = layout.localFrame(for: .vertical)
        let inset = Self.borderCenterInset
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

    private func visibleBoundsBorderPath() -> NSBezierPath {
        return NSBezierPath(rect: bounds.insetBy(
            dx: Self.borderCenterInset,
            dy: Self.borderCenterInset
        ))
    }
}

private final class GroupedRulerZeroLabelsView: NSView {
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

final class GroupedRulerContentView: NSView {
    let horizontalRule: HorizontalRule
    let verticalRule: VerticalRule
    private let horizontalHost = RulerClipView(frame: .zero)
    private let verticalHost = RulerClipView(frame: .zero)
    private let unitLabelView = UnitLabelView(
        orientation: .horizontal,
        label: NSAttributedString(string: "")
    )
    private let zeroLabelsView: GroupedRulerZeroLabelsView
    private let borderView = GroupedRulerBorderView(frame: .zero)
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

    init(
        frame frameRect: NSRect,
        horizontalRule: HorizontalRule,
        verticalRule: VerticalRule
    ) {
        self.horizontalRule = horizontalRule
        self.verticalRule = verticalRule
        self.zeroLabelsView = GroupedRulerZeroLabelsView(
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

        let layout = GroupedRulerLayout.layout(groupFrame: bounds, zeroCorner: zeroCorner)
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

        guard showsHorizontalRule && showsVerticalRule else { return }

        color.fill.setFill()
        cornerFrame().fill()
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

    func containsEmptyCorner(_ point: NSPoint) -> Bool {
        return showsHorizontalRule && showsVerticalRule && cornerFrame().contains(point)
    }

    func localFrame(for orientation: Orientation) -> NSRect {
        let layout = GroupedRulerLayout.layout(groupFrame: bounds, zeroCorner: zeroCorner)
        return ruleFrame(for: orientation, in: bounds, layout: layout)
    }

    private func cornerFrame() -> NSRect {
        return GroupedRulerLayout
            .layout(groupFrame: bounds, zeroCorner: zeroCorner)
            .emptyCornerFrame(zeroCorner: zeroCorner)
    }

    private func ruleFrame(
        for orientation: Orientation,
        in bounds: NSRect,
        layout: GroupedRulerLayout
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
        switch prefs.unit {
        case .pixels:
            return "px"
        case .millimeters:
            return "mm"
        case .inches:
            return "in"
        }
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
final class GroupedRulerController: NSWindowController, NSWindowDelegate, NotificationObserver {
    var observers: [NSKeyValueObservation] = []
    var notificationObservers: [NSObjectProtocol] = []

    let groupedWindow: GroupedRulerWindow

    private var keyListener: Any?
    private var mouseTickResumeTimer: Timer?
    private let mouseTickResumeDelay: TimeInterval = 0.15
    private var mouseIsDraggingRuler = false
    private var mouseIsHoveringRuler = false

    var isLeftMouseButtonPressed = {
        return NSEvent.pressedMouseButtons & 1 == 1
    }

    var preferencesWindowOpen = false {
        didSet {
            updateIsFloatingPanel()
            if !preferencesWindowOpen {
                opacity = prefs.foregroundOpacity
            }
        }
    }

    var opacity = prefs.foregroundOpacity {
        didSet {
            groupedWindow.alphaValue = windowAlphaValue(opacity)
        }
    }

    init(frame: NSRect) {
        groupedWindow = GroupedRulerWindow(frame: frame)
        super.init(window: groupedWindow)

        createObservers()
        subscribeToPrefs()

        groupedWindow.delegate = self
        groupedWindow.nextResponder = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init(frame:)")
    }

    deinit {
        mouseTickResumeTimer?.invalidate()
        removeObservers(&notificationObservers)
        stopKeyListener()
    }

    var isVisible: Bool {
        return groupedWindow.isVisible
    }

    func show(
        horizontalFrame: NSRect,
        verticalFrame: NSRect,
        showsHorizontalRule: Bool,
        showsVerticalRule: Bool
    ) {
        let layout = GroupedRulerLayout.joined(
            horizontalFrame: horizontalFrame,
            verticalFrame: verticalFrame,
            zeroCorner: prefs.zeroCorner
        )
        groupedWindow.setVisibleRules(
            horizontal: showsHorizontalRule,
            vertical: showsVerticalRule
        )
        groupedWindow.setFrame(
            layout.visibleFrame(
                showsHorizontalRule: showsHorizontalRule,
                showsVerticalRule: showsVerticalRule
            ),
            display: false
        )
        groupedWindow.updateLayoutForCurrentZeroCorner()
        showWindow(self)
        groupedWindow.orderFrontRegardless()
    }

    func hide() {
        groupedWindow.orderOut(self)
    }

    func syncFrames(
        to horizontalWindow: RulerWindow,
        and verticalWindow: RulerWindow
    ) {
        guard isVisible else { return }

        let frames = syncedRulerFrames(
            horizontalWindow: horizontalWindow,
            verticalWindow: verticalWindow
        )

        syncFrame(frames.horizontal, to: horizontalWindow)
        syncFrame(frames.vertical, to: verticalWindow)
    }

    func align(at point: NSPoint) {
        let horizontalLength = groupedWindow.screenFrame(for: .horizontal).width
        let verticalLength = groupedWindow.screenFrame(for: .vertical).height
        let layout = GroupedRulerLayout.layout(
            horizontalLength: horizontalLength,
            verticalLength: verticalLength,
            zeroPoint: point,
            zeroCorner: prefs.zeroCorner
        )

        groupedWindow.setFrame(groupedWindow.visibleFrame(in: layout), display: true)
        groupedWindow.updateLayoutForCurrentZeroCorner()
    }

    func prepareForZeroCornerChange(to zeroCorner: ZeroCorner) {
        let zeroPoint = groupedWindow.zeroPoint()
        let horizontalLength = groupedWindow.screenFrame(for: .horizontal).width
        let verticalLength = groupedWindow.screenFrame(for: .vertical).height
        let layout = GroupedRulerLayout.layout(
            horizontalLength: horizontalLength,
            verticalLength: verticalLength,
            zeroPoint: zeroPoint,
            zeroCorner: zeroCorner
        )

        groupedWindow.setFrame(groupedWindow.visibleFrame(in: layout), display: true)
    }

    func foreground() {
        opacity = prefs.foregroundOpacity
    }

    func background() {
        opacity = prefs.backgroundOpacity
    }

    func updateIsFloatingPanel() {
        groupedWindow.isFloatingPanel = preferencesWindowOpen ? false : prefs.floatRulers
    }

    func updateHasShadow() {
        groupedWindow.hasShadow = prefs.rulerShadow
    }

    func redrawForPreferenceChange() {
        groupedWindow.redrawForPreferenceChange()
    }

    func drawMouseTick(at mouseLoc: NSPoint) {
        if groupedWindow.isRuleVisible(.horizontal) {
            groupedWindow.horizontalRule.drawMouseTick(at: mouseLoc)
        }
        if groupedWindow.isRuleVisible(.vertical) {
            groupedWindow.verticalRule.drawMouseTick(at: mouseLoc)
        }
    }

    func setMouseTickDrawingEnabled(_ isEnabled: Bool) {
        groupedWindow.horizontalRule.showMouseTick = isEnabled && groupedWindow.isRuleVisible(.horizontal)
        groupedWindow.verticalRule.showMouseTick = isEnabled && groupedWindow.isRuleVisible(.vertical)
    }

    private func syncedRulerFrames(
        horizontalWindow: RulerWindow,
        verticalWindow: RulerWindow
    ) -> (horizontal: NSRect, vertical: NSRect) {
        let showsHorizontalRule = groupedWindow.isRuleVisible(.horizontal)
        let showsVerticalRule = groupedWindow.isRuleVisible(.vertical)

        switch (showsHorizontalRule, showsVerticalRule) {
        case (true, true):
            return (
                groupedWindow.screenFrame(for: .horizontal),
                groupedWindow.screenFrame(for: .vertical)
            )
        case (true, false):
            let horizontalFrame = groupedWindow.screenFrame(for: .horizontal)
            let zeroPoint = ZeroCornerGeometry(zeroCorner: prefs.zeroCorner)
                .zeroPoint(in: horizontalFrame, for: .horizontal)
            return (
                horizontalFrame,
                hiddenRuleFrame(
                    orientation: .vertical,
                    zeroPoint: zeroPoint,
                    size: verticalWindow.frame.size
                )
            )
        case (false, true):
            let verticalFrame = groupedWindow.screenFrame(for: .vertical)
            let zeroPoint = ZeroCornerGeometry(zeroCorner: prefs.zeroCorner)
                .zeroPoint(in: verticalFrame, for: .vertical)
            return (
                hiddenRuleFrame(
                    orientation: .horizontal,
                    zeroPoint: zeroPoint,
                    size: horizontalWindow.frame.size
                ),
                verticalFrame
            )
        case (false, false):
            return (horizontalWindow.frame, verticalWindow.frame)
        }
    }

    private func hiddenRuleFrame(
        orientation: Orientation,
        zeroPoint: NSPoint,
        size: NSSize
    ) -> NSRect {
        return ZeroCornerGeometry(zeroCorner: prefs.zeroCorner).frame(
            for: orientation,
            zeroPoint: zeroPoint,
            size: size
        )
    }

    private func syncFrame(_ frame: NSRect, to window: RulerWindow) {
        window.setFrame(frame, display: false)

        if let frameAutosaveName = window.ruler.name {
            window.saveFrame(usingName: NSWindow.FrameAutosaveName(frameAutosaveName))
        }
    }

    func windowWillStartLiveResize(_ notification: Notification) {
        disableMouseTicks()
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        syncRulerWindowFrames()
        resumeMouseTicksUnlessHovering()
    }

    func windowWillMove(_ notification: Notification) {
        disableMouseTicks()
    }

    func windowDidMove(_ notification: Notification) {
        groupedWindow.invalidateShadow()
        syncRulerWindowFrames()
        guard !mouseIsDraggingRuler && !isLeftMouseButtonPressed() else { return }
        resumeMouseTicksUnlessHovering()
    }

    func windowDidBecomeKey(_ notification: Notification) {
        startKeyListener()
    }

    func windowDidResignKey(_ notification: Notification) {
        stopKeyListener()
    }

    override func mouseEntered(with event: NSEvent) {
        mouseIsHoveringRuler = true
        hideMouseTicksForHover()
        rulerCursorController?.mouseEnteredRuler()
    }

    override func mouseExited(with event: NSEvent) {
        mouseIsHoveringRuler = false
        if !mouseIsDraggingRuler {
            enableMouseTicks()
        }
        rulerCursorController?.mouseExitedRuler()
    }

    override func mouseDown(with event: NSEvent) {
        mouseIsDraggingRuler = true
        disableMouseTicks()
        rulerCursorController?.mouseDownInRuler()
    }

    override func mouseUp(with event: NSEvent) {
        finishMouseDrag(with: event)
    }

    func finishMouseDrag(with event: NSEvent) {
        guard mouseIsDraggingRuler else { return }

        mouseIsDraggingRuler = false
        mouseIsHoveringRuler = mouseIsInsideRuler(with: event)
        resumeMouseTicksUnlessHovering()

        rulerCursorController?.mouseUpInRuler(mouseIsInsideRuler: mouseIsHoveringRuler)
    }

    override func mouseMoved(with event: NSEvent) {
        guard !mouseIsDraggingRuler else { return }
        mouseIsHoveringRuler = mouseIsInsideRuler(with: event)
        if mouseIsHoveringRuler {
            hideMouseTicksForHover()
        } else {
            enableMouseTicks()
        }
    }

    private func disableMouseTicks() {
        mouseTickResumeTimer?.invalidate()
        mouseTickResumeTimer = nil
        appDelegate?.suppressMouseTickDrawing(owner: self)
        appDelegate?.suspendMouseTickUpdates(owner: self)
    }

    private func enableMouseTicks() {
        appDelegate?.unsuppressMouseTickDrawing(owner: self)
        appDelegate?.resumeMouseTickUpdates(owner: self)
    }

    private func scheduleMouseTickResume() {
        mouseTickResumeTimer?.invalidate()
        mouseTickResumeTimer = Timer.scheduledTimer(
            withTimeInterval: mouseTickResumeDelay,
            repeats: false
        ) { [weak self] _ in
            self?.enableMouseTicks()
            self?.mouseTickResumeTimer = nil
        }
    }

    private func resumeMouseTicksUnlessHovering() {
        if mouseIsHoveringRuler {
            hideMouseTicksForHover()
            appDelegate?.resumeMouseTickUpdates(owner: self)
        } else {
            scheduleMouseTickResume()
        }
    }

    private func hideMouseTicksForHover() {
        mouseTickResumeTimer?.invalidate()
        mouseTickResumeTimer = nil
        appDelegate?.suppressMouseTickDrawing(owner: self)
    }

    private var rulerCursorController: RulerCursorController? {
        return appDelegate?.rulerCursorController
    }

    private var appDelegate: AppDelegate? {
        return NSApp.delegate as? AppDelegate
    }

    private func syncRulerWindowFrames() {
        appDelegate?.syncGroupedRulerFramesToRulerWindows()
    }

    private func mouseIsInsideRuler(with event: NSEvent) -> Bool {
        return orientation(at: event) != nil
            || groupedWindow.isEmptyCorner(atWindowPoint: event.locationInWindow)
    }

    private func orientation(at event: NSEvent) -> Orientation? {
        let horizontalLocation = groupedWindow.horizontalRule.convert(event.locationInWindow, from: nil)
        let verticalLocation = groupedWindow.verticalRule.convert(event.locationInWindow, from: nil)

        if groupedWindow.isRuleVisible(.horizontal),
           groupedWindow.horizontalRule.bounds.contains(horizontalLocation) {
            return .horizontal
        }

        if groupedWindow.isRuleVisible(.vertical),
           groupedWindow.verticalRule.bounds.contains(verticalLocation) {
            return .vertical
        }

        return nil
    }

    private func createObservers() {
        notificationObservers = [
            addObserver(.preferencesWindowOpened) { [weak self] _ in
                self?.preferencesWindowOpen = true
            },
            addObserver(.preferencesWindowClosed) { [weak self] _ in
                self?.preferencesWindowOpen = false
            },
        ]
    }

    private func subscribeToPrefs() {
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

extension GroupedRulerController {
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

        if groupedWindow.isKeyWindow,
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
            groupedWindow.nudgeLeft(withShift: shift)
            return nil
        case kVK_RightArrow:
            groupedWindow.nudgeRight(withShift: shift)
            return nil
        case kVK_UpArrow:
            groupedWindow.nudgeUp(withShift: shift)
            return nil
        case kVK_DownArrow:
            groupedWindow.nudgeDown(withShift: shift)
            return nil
        default:
            return event
        }
    }
}
#endif
