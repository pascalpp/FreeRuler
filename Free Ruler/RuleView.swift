import Cocoa

#if DEBUG
import SwiftUI
#endif

let rulerSettingsContextMenuItemIdentifier = NSUserInterfaceItemIdentifier("ruler-settings-context-menu-item")

protocol RulerContextMenuActivating: AnyObject {
    func activateForRulerContextMenu()
}

func rulerSettingsContextMenuTitle() -> String {
    return NSLocalizedString(
        "ContextMenu.RulerSettings",
        value: "Ruler Settings…",
        comment: "Context menu item title to open the active ruler settings panel"
    )
}

func rulerContextMenu(for view: NSView) -> NSMenu {
    (view.window as? RulerContextMenuActivating)?.activateForRulerContextMenu()

    let menu = NSMenu()
    let item = NSMenuItem(
        title: rulerSettingsContextMenuTitle(),
        action: #selector(AppDelegate.openRulerSettings(_:)),
        keyEquivalent: ""
    )
    item.identifier = rulerSettingsContextMenuItemIdentifier
    item.target = NSApp.delegate
    menu.addItem(item)
    return menu
}

struct RulerColors {
    var customFill: NSColor? = nil

    var fill: NSColor {
        return customFill ?? prefs.rulerColor
    }

    var numbers: NSColor {
        return contrastingColor(mixedBy: 0.55)
    }

    var ticks: NSColor {
        return contrastingColor(mixedBy: 0.5)
    }

    var mouseTick: NSColor {
        return contrastingColor(mixedBy: 0.8).withAlphaComponent(0.75)
    }

    var mouseNumber: NSColor {
        return contrastingColor(mixedBy: 0.8)
    }

    var resizeHandleLight: NSColor {
        return fill.isLightColor ? NSColor.white.withAlphaComponent(0.25) : NSColor.white.withAlphaComponent(0.45)
    }

    var resizeHandleShadow: NSColor {
        return fill.isLightColor ? NSColor.black.withAlphaComponent(0.15) : NSColor.black.withAlphaComponent(0.35)
    }

    private func contrastingColor(mixedBy fraction: CGFloat) -> NSColor {
        let color = fill.mixed(
            with: fill.isLightColor ? .black : .white,
            fraction: fraction
        )

        return fill.isLightColor ? color.withBoostedSaturation(multiplier: 3) : color
    }
}

struct MouseTickLabelLayout {
    private static let longestTickLength: CGFloat = 10
    private static let unitLabelFlipPadding: CGFloat = 3

    private struct Offsets {
        let topInset: CGFloat
        let bottomInset: CGFloat
        let leftInset: CGFloat
        let rightInset: CGFloat
        let tickLabelSpacing: CGFloat
    }

    static func labelFrame(
        labelSize: NSSize,
        rulerSize: NSSize,
        orientation: Orientation,
        zeroCorner: ZeroCorner,
        tickPosition: CGFloat,
        resizeHandleFrame: NSRect? = nil,
        unitLabelFrame: NSRect? = nil
    ) -> NSRect {
        let geometry = ZeroCornerGeometry(zeroCorner: zeroCorner)
        let placement = geometry.unitLabelPlacement(for: orientation)
        let offsets = offsets(for: orientation, placement: placement)
        let x: CGFloat
        let y: CGFloat

        switch orientation {
        case .horizontal:
            x = horizontalX(
                forTickX: tickPosition,
                labelSize: labelSize,
                rulerSize: rulerSize,
                zeroCorner: zeroCorner,
                resizeHandleFrame: resizeHandleFrame,
                unitLabelFrame: unitLabelFrame,
                offsets: offsets
            )

            switch placement.ySide {
            case .top:
                y = rulerSize.height - labelSize.height - offsets.topInset
            case .bottom:
                y = offsets.bottomInset
            }
        case .vertical:
            x = verticalX(
                labelSize: labelSize,
                rulerSize: rulerSize,
                tickSide: geometry.verticalTickSide,
                placement: placement,
                offsets: offsets
            )
            y = verticalY(
                forTickY: tickPosition,
                labelSize: labelSize,
                rulerSize: rulerSize,
                zeroCorner: zeroCorner,
                resizeHandleFrame: resizeHandleFrame,
                unitLabelFrame: unitLabelFrame,
                offsets: offsets
            )
        }

        return NSRect(x: x, y: y, width: labelSize.width, height: labelSize.height)
    }

    static func labelBackgroundFrame(
        labelSize: NSSize,
        rulerSize: NSSize,
        orientation: Orientation,
        zeroCorner: ZeroCorner,
        tickPosition: CGFloat,
        resizeHandleFrame: NSRect? = nil,
        unitLabelFrame: NSRect? = nil
    ) -> NSRect {
        guard orientation == .vertical else {
            return labelFrame(
                labelSize: labelSize,
                rulerSize: rulerSize,
                orientation: orientation,
                zeroCorner: zeroCorner,
                tickPosition: tickPosition,
                resizeHandleFrame: resizeHandleFrame,
                unitLabelFrame: unitLabelFrame
            )
        }

        let labelFrame = labelFrame(
            labelSize: labelSize,
            rulerSize: rulerSize,
            orientation: orientation,
            zeroCorner: zeroCorner,
            tickPosition: tickPosition,
            resizeHandleFrame: resizeHandleFrame,
            unitLabelFrame: unitLabelFrame
        )
        let geometry = ZeroCornerGeometry(zeroCorner: zeroCorner)

        return verticalLabelLaneFrame(
            rulerSize: rulerSize,
            tickSide: geometry.verticalTickSide,
            y: labelFrame.minY,
            height: labelFrame.height
        ).union(labelFrame)
    }

    private static func offsets(
        for orientation: Orientation,
        placement: RulerCornerPlacement
    ) -> Offsets {
        switch orientation {
        case .horizontal:
            switch placement.ySide {
            case .top:
                return Offsets(topInset: 2, bottomInset: 2, leftInset: 0, rightInset: 0, tickLabelSpacing: 5)
            case .bottom:
                return Offsets(topInset: 2, bottomInset: 7, leftInset: 5, rightInset: 0, tickLabelSpacing: 5)
            }
        case .vertical:
            return Offsets(topInset: 2, bottomInset: 2, leftInset: 7, rightInset: 7, tickLabelSpacing: 4)
        }
    }

    private static func horizontalX(
        forTickX tickX: CGFloat,
        labelSize: NSSize,
        rulerSize: NSSize,
        zeroCorner: ZeroCorner,
        resizeHandleFrame: NSRect?,
        unitLabelFrame: NSRect?,
        offsets: Offsets
    ) -> CGFloat {
        let minLabelX = offsets.leftInset
        let maxLabelX = rulerSize.width - labelSize.width - offsets.rightInset

        let rightX = tickX + offsets.tickLabelSpacing
        let leftX = tickX - offsets.tickLabelSpacing - labelSize.width
        let preferredX = horizontalLabelFitsPreferredSide(
            labelX: rightX,
            labelSize: labelSize,
            maxLabelX: maxLabelX,
            zeroCorner: zeroCorner,
            resizeHandleFrame: resizeHandleFrame,
            unitLabelFrame: unitLabelFrame
        ) ? rightX : leftX

        return clamp(preferredX, lowerBound: minLabelX, upperBound: maxLabelX)
    }

    private static func horizontalLabelFitsPreferredSide(
        labelX: CGFloat,
        labelSize: NSSize,
        maxLabelX: CGFloat,
        zeroCorner: ZeroCorner,
        resizeHandleFrame: NSRect?,
        unitLabelFrame: NSRect?
    ) -> Bool {
        guard labelX <= maxLabelX else { return false }

        let geometry = ZeroCornerGeometry(zeroCorner: zeroCorner)
        if let unitLabelFrame = unitLabelFrame,
           geometry.unitLabelPlacement(for: .horizontal).xSide == .right,
           labelX + labelSize.width > unitLabelFrame.minX - unitLabelFlipPadding {
            return false
        }

        guard let resizeHandleFrame = resizeHandleFrame else { return true }

        switch geometry.horizontalResizeSide {
        case .left:
            return true
        case .right:
            return labelX + labelSize.width <= resizeHandleFrame.minX
        }
    }

    private static func verticalY(
        forTickY tickY: CGFloat,
        labelSize: NSSize,
        rulerSize: NSSize,
        zeroCorner: ZeroCorner,
        resizeHandleFrame: NSRect?,
        unitLabelFrame: NSRect?,
        offsets: Offsets
    ) -> CGFloat {
        let minLabelY = offsets.bottomInset
        let maxLabelY = rulerSize.height - labelSize.height - offsets.topInset

        let belowTickY = tickY - offsets.tickLabelSpacing - labelSize.height
        let aboveTickY = tickY + offsets.tickLabelSpacing
        let preferredY = verticalLabelFitsPreferredSide(
            labelY: belowTickY,
            labelSize: labelSize,
            minLabelY: minLabelY,
            zeroCorner: zeroCorner,
            resizeHandleFrame: resizeHandleFrame,
            unitLabelFrame: unitLabelFrame
        ) ? belowTickY : aboveTickY

        return clamp(preferredY, lowerBound: minLabelY, upperBound: maxLabelY)
    }

    private static func verticalX(
        labelSize: NSSize,
        rulerSize: NSSize,
        tickSide: RulerHorizontalSide,
        placement: RulerCornerPlacement,
        offsets: Offsets
    ) -> CGFloat {
        let laneFrame = verticalLabelLaneFrame(
            rulerSize: rulerSize,
            tickSide: tickSide,
            y: 0,
            height: labelSize.height
        )

        switch placement.xSide {
        case .left:
            return laneFrame.minX + offsets.leftInset
        case .right:
            return laneFrame.maxX - labelSize.width - offsets.rightInset
        }
    }

    private static func verticalLabelLaneFrame(
        rulerSize: NSSize,
        tickSide: RulerHorizontalSide,
        y: CGFloat,
        height: CGFloat
    ) -> NSRect {
        let laneWidth = max(0, rulerSize.width - longestTickLength)

        switch tickSide {
        case .right:
            return NSRect(x: 0, y: y, width: laneWidth, height: height)
        case .left:
            return NSRect(x: rulerSize.width - laneWidth, y: y, width: laneWidth, height: height)
        }
    }

    private static func verticalLabelFitsPreferredSide(
        labelY: CGFloat,
        labelSize: NSSize,
        minLabelY: CGFloat,
        zeroCorner: ZeroCorner,
        resizeHandleFrame: NSRect?,
        unitLabelFrame: NSRect?
    ) -> Bool {
        guard labelY >= minLabelY else { return false }

        let geometry = ZeroCornerGeometry(zeroCorner: zeroCorner)
        if let unitLabelFrame = unitLabelFrame,
           geometry.unitLabelPlacement(for: .vertical).ySide == .bottom,
           labelY < unitLabelFrame.maxY + unitLabelFlipPadding {
            return false
        }

        guard let resizeHandleFrame = resizeHandleFrame else { return true }

        switch geometry.verticalResizeSide {
        case .bottom:
            return labelY >= resizeHandleFrame.maxY
        case .top:
            return true
        }
    }

    private static func clamp(
        _ value: CGFloat,
        lowerBound: CGFloat,
        upperBound: CGFloat
    ) -> CGFloat {
        guard lowerBound <= upperBound else {
            return lowerBound
        }

        return min(max(value, lowerBound), upperBound)
    }
}

class RulerBorderView: NSView {
    static let borderColor = NSColor(calibratedWhite: 0, alpha: 0.5)
    static let borderWidth: CGFloat = 1
    static let borderCenterInset: CGFloat = borderWidth / 2

    override var isOpaque: Bool {
        return false
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let path = borderPath(in: bounds)
        path.lineWidth = Self.borderWidth
        path.lineJoinStyle = .miter
        path.lineCapStyle = .butt
        Self.borderColor.setStroke()
        path.stroke()
    }

    func borderPath(in bounds: NSRect) -> NSBezierPath {
        return NSBezierPath(rect: bounds.insetBy(
            dx: Self.borderCenterInset,
            dy: Self.borderCenterInset
        ))
    }
}

class RuleView: NSView {

    var color = RulerColors() {
        didSet {
            resizeHandleView?.color = color
            resizeHandleView?.needsDisplay = true
            updateUnitLabelFrame()
        }
    }
    var drawsBackground = true {
        didSet {
            needsDisplay = true
        }
    }
    private var resizeHandleView: ResizeHandleView?
    private var unitLabelView: UnitLabelView?
    private var borderView: RulerBorderView?

    var trackingArea: NSTrackingArea?
    let trackingAreaOptions: NSTrackingArea.Options = [
        .mouseMoved,
        .mouseEnteredAndExited,
        .activeAlways,
        .inVisibleRect,
    ]

    override func updateTrackingAreas() {
        if trackingArea != nil {
            removeTrackingArea(trackingArea!)
        }

        trackingArea = NSTrackingArea(
            rect: self.bounds,
            options: trackingAreaOptions,
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
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

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    override func layout() {
        super.layout()
        updateResizeHandleFrame()
        updateUnitLabelFrame()
        updateResizeHandleVisibility()
        updateUnitLabelVisibility()
        updateBorderFrame()
    }

    func installResizeHandle(for orientation: Orientation) {
        let view = ResizeHandleView(orientation: orientation, color: color)
        addSubview(view)
        resizeHandleView = view
        updateResizeHandleFrame()
    }

    func installUnitLabel(for orientation: Orientation) {
        let view = UnitLabelView(orientation: orientation, label: unitLabel())
        addSubview(view)
        unitLabelView = view
        updateUnitLabelFrame()
        updateUnitLabelVisibility()
    }

    func drawMouseTick(at mouseLoc: NSPoint) {
        // required override
        // TODO: is there a better way to do this, maybe via a protocol?
        // AppDelegate needs to be able to infer that any RulerView has this method
        fatalError("RuleView subclass must override drawMouseTick method.")
    }

    func redrawForPreferenceChange() {
        updateResizeHandleFrame()
        updateUnitLabelFrame()
        updateResizeHandleVisibility()
        updateUnitLabelVisibility()
        setNeedsDisplay(visibleRect)
        resizeHandleView?.needsDisplay = true
        unitLabelView?.needsDisplay = true
        borderView?.needsDisplay = true
    }

    func installWindowBorder() {
        if borderView == nil {
            let view = RulerBorderView(frame: bounds)
            view.autoresizingMask = [.width, .height]
            addSubview(view, positioned: .above, relativeTo: nil)
            borderView = view
        }

        updateBorderFrame()
        borderView?.needsDisplay = true
    }

    var windowWidth: CGFloat {
        return self.window?.frame.width ?? bounds.width
    }

    var windowHeight: CGFloat {
        return self.window?.frame.height ?? bounds.height
    }

    var showMouseTick: Bool = true {
        didSet {
            if showMouseTick != oldValue {
                updateResizeHandleVisibility()
                updateUnitLabelVisibility()
                needsDisplay = true
            }
        }
    }

    var showsUnitLabel: Bool = true {
        didSet {
            updateUnitLabelVisibility()
        }
    }

    var showsZeroTick: Bool = false {
        didSet {
            needsDisplay = true
        }
    }

    var settingsOverride: RulerSettings? {
        didSet {
            color = RulerColors(customFill: settingsOverride?.rulerColor)
            redrawForPreferenceChange()
        }
    }

    var screen: NSScreen? {
        guard let window = window else {
            return nil
        }
        return NSScreen.screens.first { $0.frame.intersects(window.convertToScreen(frame)) }
    }

    var unit: Unit {
        return settingsOverride?.unit ?? prefs.unit
    }

    var zeroCorner: ZeroCorner {
        return settingsOverride?.zeroCorner ?? prefs.zeroCorner
    }

    var resizeHandleExclusionFrame: NSRect? {
        return resizeHandleView?.frame
    }

    var unitLabelFrame: NSRect? {
        guard showsUnitLabel else { return nil }
        return unitLabelView?.frame
    }

    func getUnitLabel() -> String {
        switch unit {
        case .pixels:
            return "px"
        case .millimeters:
            return "mm"
        case .inches:
            return "in"
        }
    }

    func labelAttributes(
        alignment: NSTextAlignment,
        foregroundColor: NSColor
    ) -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        let font = NSFont(name: "HelveticaNeue", size: 10) ?? .systemFont(ofSize: 10)

        return [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: foregroundColor,
        ]
    }

    override func accessibilityValue() -> Any? {
        return getUnitLabel()
    }

    func getMouseNumberLabel(_ number: CGFloat) -> String {
        switch unit {
        case .pixels:
            return String(format: "%d", Int(number))
        case .millimeters:
            return String(format: "%.1f", number / (screen?.dpmm.width ?? NSScreen.defaultDpmm))
        case .inches:
            return String(format: "%.3f", number / (screen?.dpi.width ?? NSScreen.defaultDpi))
        }
    }

    func setUnitLabelHidden(_ isHidden: Bool) {
        unitLabelView?.isHidden = !showsUnitLabel || isHidden
    }

    func setResizeHandleObscured(_ isObscured: Bool) {
        resizeHandleView?.alphaValue = isObscured ? 0 : 1
    }

    func updateResizeHandleVisibility() {
        setResizeHandleObscured(false)
    }

    func updateUnitLabelVisibility() {
        setUnitLabelHidden(false)
    }

    private func updateResizeHandleFrame() {
        guard let resizeHandleView = resizeHandleView else { return }

        resizeHandleView.zeroCorner = zeroCorner
        resizeHandleView.frame = resizeHandleView.frame(in: bounds, zeroCorner: zeroCorner)
    }

    private func updateUnitLabelFrame() {
        guard let unitLabelView = unitLabelView else { return }

        unitLabelView.zeroCorner = zeroCorner
        unitLabelView.label = unitLabel()
        unitLabelView.frame = unitLabelView.frame(in: bounds, zeroCorner: zeroCorner)
    }

    private func updateBorderFrame() {
        borderView?.frame = bounds
    }

    private func unitLabel() -> NSAttributedString {
        return NSAttributedString(
            string: getUnitLabel(),
            attributes: labelAttributes(alignment: .left, foregroundColor: color.ticks)
        )
    }

}

extension NSColor {
    private var deviceRGBComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        guard let color = usingColorSpace(.deviceRGB) else { return nil }

        return (color.redComponent, color.greenComponent, color.blueComponent, color.alphaComponent)
    }

    fileprivate var isLightColor: Bool {
        guard let components = deviceRGBComponents else { return false }
        return (0.299 * components.red)
            + (0.587 * components.green)
            + (0.114 * components.blue) > 0.5
    }

    fileprivate func mixed(with color: NSColor, fraction: CGFloat) -> NSColor {
        guard let baseColor = usingColorSpace(.deviceRGB),
              let mixColor = color.usingColorSpace(.deviceRGB) else {
            return self
        }

        let clampedFraction = min(max(fraction, 0), 1)
        let baseFraction = 1 - clampedFraction

        return NSColor(
            deviceRed: (baseColor.redComponent * baseFraction) + (mixColor.redComponent * clampedFraction),
            green: (baseColor.greenComponent * baseFraction) + (mixColor.greenComponent * clampedFraction),
            blue: (baseColor.blueComponent * baseFraction) + (mixColor.blueComponent * clampedFraction),
            alpha: baseColor.alphaComponent
        )
    }

    fileprivate func withBoostedSaturation(multiplier: CGFloat) -> NSColor {
        guard let components = deviceRGBComponents else { return self }

        let maxValue = max(components.red, components.green, components.blue)
        let minValue = min(components.red, components.green, components.blue)
        let delta = maxValue - minValue
        let brightness = maxValue
        let saturation = maxValue == 0 ? 0 : delta / maxValue
        let hue: CGFloat

        if delta == 0 {
            hue = 0
        } else if maxValue == components.red {
            hue = ((components.green - components.blue) / delta / 6).truncatingRemainder(dividingBy: 1)
        } else if maxValue == components.green {
            hue = ((components.blue - components.red) / delta + 2) / 6
        } else {
            hue = ((components.red - components.green) / delta + 4) / 6
        }

        return NSColor(
            calibratedHue: hue < 0 ? hue + 1 : hue,
            saturation: min(saturation * multiplier, 1),
            brightness: brightness,
            alpha: components.alpha
        )
    }
}

#if DEBUG
private let mouseTickLabelPreviewRulerLength: CGFloat = 260
private let mouseTickLabelPreviewMouseRange = -10...(mouseTickLabelPreviewRulerLength + 10)

private struct MouseTickRulePreview: NSViewRepresentable {
    let orientation: Orientation
    let zeroCorner: ZeroCorner
    let mouseX: CGFloat
    let mouseY: CGFloat
    let rulerLength: CGFloat

    func makeNSView(context: Context) -> RuleView {
        let view: RuleView
        switch orientation {
        case .horizontal:
            view = MouseTickPreviewHorizontalRule(
                frame: NSRect(x: 0, y: 0, width: rulerLength, height: Ruler.thickness)
            )
        case .vertical:
            view = MouseTickPreviewVerticalRule(
                frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: rulerLength)
            )
        }

        view.color = RulerColors(
            customFill: NSColor(calibratedRed: 0.94, green: 0.82, blue: 0.54, alpha: 1)
        )
        view.showMouseTick = true
        view.installWindowBorder()
        view.setAccessibilityElement(false)
        configure(view)
        return view
    }

    func updateNSView(_ view: RuleView, context: Context) {
        configure(view)
    }

    private func configure(_ view: RuleView) {
        switch view {
        case let horizontalRule as MouseTickPreviewHorizontalRule:
            horizontalRule.previewZeroCorner = zeroCorner
            horizontalRule.mouseTickX = localMousePosition(for: mouseX)
        case let verticalRule as MouseTickPreviewVerticalRule:
            verticalRule.previewZeroCorner = zeroCorner
            verticalRule.mouseTickY = localMousePosition(for: mouseY)
        default:
            assertionFailure("Mouse tick preview must host a concrete preview ruler")
        }

        view.redrawForPreferenceChange()
        view.layoutSubtreeIfNeeded()
        view.needsDisplay = true
    }

    private func localMousePosition(for measurement: CGFloat) -> CGFloat {
        let growthDirection = ZeroCornerGeometry(zeroCorner: zeroCorner)
            .growthDirection(for: orientation)

        switch growthDirection {
        case .positive:
            return measurement
        case .negative:
            return rulerLength - measurement
        }
    }
}

private final class MouseTickPreviewHorizontalRule: HorizontalRule {
    var previewZeroCorner: ZeroCorner = .topLeft

    override var unit: Unit {
        .pixels
    }

    override var zeroCorner: ZeroCorner {
        previewZeroCorner
    }

    override var windowWidth: CGFloat {
        bounds.width
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(bounds)
    }
}

private final class MouseTickPreviewVerticalRule: VerticalRule {
    var previewZeroCorner: ZeroCorner = .topLeft

    override var unit: Unit {
        .pixels
    }

    override var zeroCorner: ZeroCorner {
        previewZeroCorner
    }

    override var windowHeight: CGFloat {
        bounds.height
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(bounds)
    }
}

private struct MouseTickLabelOffsetPreview: View {
    let mouseX: CGFloat
    let mouseY: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MouseTickLabelOffsetPreviewHeading(mouseX: mouseX, mouseY: mouseY)

            MouseTickLabelOffsetPreviewGrid(
                mouseX: mouseX,
                mouseY: mouseY
            )
        }
        .padding()
    }
}

private struct MouseTickLabelOffsetPreviewHeading: View {
    let mouseX: CGFloat
    let mouseY: CGFloat

    var body: some View {
        Text("Mouse Tick Label Offsets (mouseX: \(Int(mouseX)), mouseY: \(Int(mouseY)))")
            .font(.headline)
    }
}

private struct MouseTickLabelOffsetPreviewGrid: View {
    let mouseX: CGFloat
    let mouseY: CGFloat

    private let cellSize = CGSize(
        width: mouseTickLabelPreviewRulerLength + Ruler.thickness,
        height: mouseTickLabelPreviewRulerLength + Ruler.thickness
    )
    private let cases: [(name: String, zeroCorner: ZeroCorner)] = [
        ("Top Left", .topLeft),
        ("Top Right", .topRight),
        ("Bottom Left", .bottomLeft),
        ("Bottom Right", .bottomRight),
    ]

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.fixed(cellSize.width), spacing: 24),
                GridItem(.fixed(cellSize.width), spacing: 24),
            ],
            alignment: .leading,
            spacing: 22
        ) {
            ForEach(cases, id: \.name) { testCase in
                cornerPreview(name: testCase.name, zeroCorner: testCase.zeroCorner)
            }
        }
    }

    private func cornerPreview(name: String, zeroCorner: ZeroCorner) -> some View {
        MouseTickLabelCornerPreview(
            name: name,
            zeroCorner: zeroCorner,
            rulerLength: mouseTickLabelPreviewRulerLength,
            mouseX: mouseX,
            mouseY: mouseY
        )
    }
}

private struct MouseTickLabelCornerPreview: View {
    let name: String
    let zeroCorner: ZeroCorner
    let rulerLength: CGFloat
    let mouseX: CGFloat
    let mouseY: CGFloat

    private var thickness: CGFloat {
        Ruler.thickness
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(name)
                .font(.caption)

            ZStack(alignment: .topLeading) {
                MouseTickRulePreview(
                    orientation: .horizontal,
                    zeroCorner: zeroCorner,
                    mouseX: mouseX,
                    mouseY: mouseY,
                    rulerLength: rulerLength
                )
                .frame(width: rulerLength, height: thickness)
                .position(x: horizontalCenter.x, y: horizontalCenter.y)

                MouseTickRulePreview(
                    orientation: .vertical,
                    zeroCorner: zeroCorner,
                    mouseX: mouseX,
                    mouseY: mouseY,
                    rulerLength: rulerLength
                )
                .frame(width: thickness, height: rulerLength)
                .position(x: verticalCenter.x, y: verticalCenter.y)
            }
            .frame(
                width: rulerLength + thickness,
                height: rulerLength + thickness
            )
        }
    }

    private var horizontalCenter: CGPoint {
        switch zeroCorner {
        case .topLeft:
            return CGPoint(x: thickness + (rulerLength / 2), y: thickness / 2)
        case .topRight:
            return CGPoint(x: rulerLength / 2, y: thickness / 2)
        case .bottomLeft:
            return CGPoint(x: thickness + (rulerLength / 2), y: rulerLength + (thickness / 2))
        case .bottomRight:
            return CGPoint(x: rulerLength / 2, y: rulerLength + (thickness / 2))
        }
    }

    private var verticalCenter: CGPoint {
        switch zeroCorner {
        case .topLeft:
            return CGPoint(x: thickness / 2, y: thickness + (rulerLength / 2))
        case .topRight:
            return CGPoint(x: rulerLength + (thickness / 2), y: thickness + (rulerLength / 2))
        case .bottomLeft:
            return CGPoint(x: thickness / 2, y: rulerLength / 2)
        case .bottomRight:
            return CGPoint(x: rulerLength + (thickness / 2), y: rulerLength / 2)
        }
    }
}

private struct MouseTickLabelOffsetPreviewControls: View {
    @State private var mouseX: CGFloat = 36
    @State private var mouseY: CGFloat = 200

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MouseTickLabelOffsetPreviewHeading(mouseX: mouseX, mouseY: mouseY)

            ZStack(alignment: .top) {
                MouseTickLabelOffsetPreviewGrid(
                    mouseX: mouseX,
                    mouseY: mouseY
                )

                MouseTickLabelOffsetSliderPanel(mouseX: $mouseX, mouseY: $mouseY)
                    .frame(width: 320)
                    .padding(.top, 126)
            }
        }
        .padding()
    }
}

private struct MouseTickLabelOffsetSliderPanel: View {
    @Binding var mouseX: CGFloat
    @Binding var mouseY: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MouseTickLabelOffsetSlider(title: "X", value: $mouseX)
            MouseTickLabelOffsetSlider(title: "Y", value: $mouseY)
        }
    }
}

private struct MouseTickLabelOffsetSlider: View {
    let title: String
    @Binding var value: CGFloat

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .frame(width: 12, alignment: .leading)

            Slider(
                value: $value,
                in: mouseTickLabelPreviewMouseRange,
                step: 1
            )

            TextField(title, value: editableValue, format: .number.precision(.fractionLength(0)))
                .font(.caption.monospacedDigit())
                .multilineTextAlignment(.trailing)
                .frame(width: 44)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var editableValue: Binding<Double> {
        Binding(
            get: { Double(value) },
            set: { newValue in
                guard newValue.isFinite else { return }

                value = min(
                    max(CGFloat(newValue).rounded(), mouseTickLabelPreviewMouseRange.lowerBound),
                    mouseTickLabelPreviewMouseRange.upperBound
                )
            }
        )
    }
}

struct RuleView_Previews: PreviewProvider {
    static var previews: some View {
        MouseTickLabelOffsetPreviewControls()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Mouse Tick Labels")
    }
}
#endif

fileprivate let mmPerIn: CGFloat = 25.4

public extension NSScreen {

    // This is the same as what CoreGraphics assumes if no EDID data is available from the display device
    // https://developer.apple.com/documentation/coregraphics/1456599-cgdisplayscreensize
    static let defaultDpi: CGFloat = 72.0
    static let defaultDpmm: CGFloat = defaultDpi / mmPerIn
    
    var dpmm: CGSize {
        if let resolution = (deviceDescription[.size] as? NSValue)?.sizeValue,
           let screenNumber = (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value {
            let physicalSize = CGDisplayScreenSize(screenNumber)
            return CGSize(width: resolution.width / physicalSize.width,
                          height: resolution.height / physicalSize.height)
        } else {
            return CGSize(width: NSScreen.defaultDpmm, height: NSScreen.defaultDpmm)
        }
    }
    
    var dpi: CGSize {
        return CGSize(width: mmPerIn * dpmm.width,
                      height: mmPerIn * dpmm.height)
    }
    
}
