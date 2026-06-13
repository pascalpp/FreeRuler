import Cocoa

#if DEBUG
import SwiftUI
#endif

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
    private struct Offsets {
        let topInset: CGFloat
        let bottomInset: CGFloat
        let leftInset: CGFloat
        let rightInset: CGFloat
        let tickGap: CGFloat
    }

    static func labelFrame(
        labelSize: NSSize,
        rulerSize: NSSize,
        orientation: Orientation,
        zeroCorner: ZeroCorner,
        tickPosition: CGFloat
    ) -> NSRect {
        let placement = ZeroCornerGeometry(zeroCorner: zeroCorner)
            .unitLabelPlacement(for: orientation)
        let offsets = offsets(for: orientation, placement: placement)
        let x: CGFloat
        let y: CGFloat

        switch (orientation, placement.xSide, placement.ySide) {
        case (.horizontal, .left, .top), (.horizontal, .right, .top):
            x = horizontalX(
                forTickX: tickPosition,
                labelSize: labelSize,
                rulerSize: rulerSize,
                offsets: offsets
            )
            y = rulerSize.height - labelSize.height - offsets.topInset
        case (.horizontal, .left, .bottom), (.horizontal, .right, .bottom):
            x = horizontalX(
                forTickX: tickPosition,
                labelSize: labelSize,
                rulerSize: rulerSize,
                offsets: offsets
            )
            y = offsets.bottomInset
        case (.vertical, .left, .top), (.vertical, .left, .bottom):
            x = offsets.leftInset
            y = verticalY(
                forTickY: tickPosition,
                labelSize: labelSize,
                rulerSize: rulerSize,
                offsets: offsets
            )
        case (.vertical, .right, .top), (.vertical, .right, .bottom):
            x = rulerSize.width - labelSize.width - offsets.rightInset
            y = verticalY(
                forTickY: tickPosition,
                labelSize: labelSize,
                rulerSize: rulerSize,
                offsets: offsets
            )
        case (_, _, _):
            assertionFailure("Mouse tick label must be anchored to left/right and top/bottom sides")
            x = offsets.leftInset
            y = offsets.bottomInset
        }

        return NSRect(x: x, y: y, width: labelSize.width, height: labelSize.height)
    }

    private static func offsets(
        for orientation: Orientation,
        placement: RulerCornerPlacement
    ) -> Offsets {
        switch (orientation, placement.xSide, placement.ySide) {
        case (.horizontal, .left, .top):
            return Offsets(topInset: 2, bottomInset: 2, leftInset: 5, rightInset: 5, tickGap: 5)
        case (.horizontal, .right, .top):
            return Offsets(topInset: 2, bottomInset: 2, leftInset: 5, rightInset: 5, tickGap: 5)
        case (.horizontal, .left, .bottom):
            return Offsets(topInset: 2, bottomInset: 2, leftInset: 5, rightInset: 5, tickGap: 5)
        case (.horizontal, .right, .bottom):
            return Offsets(topInset: 2, bottomInset: 2, leftInset: 5, rightInset: 5, tickGap: 5)
        case (.vertical, .left, .top):
            return Offsets(topInset: 2, bottomInset: 2, leftInset: 7, rightInset: 7, tickGap: 7)
        case (.vertical, .right, .top):
            return Offsets(topInset: 2, bottomInset: 2, leftInset: 7, rightInset: 7, tickGap: 7)
        case (.vertical, .left, .bottom):
            return Offsets(topInset: 2, bottomInset: 2, leftInset: 7, rightInset: 7, tickGap: 7)
        case (.vertical, .right, .bottom):
            return Offsets(topInset: 2, bottomInset: 2, leftInset: 7, rightInset: 7, tickGap: 7)
        case (_, _, _):
            assertionFailure("Mouse tick label offsets require left/right and top/bottom placement")
            return Offsets(topInset: 2, bottomInset: 2, leftInset: 5, rightInset: 5, tickGap: 5)
        }
    }

    private static func horizontalX(
        forTickX tickX: CGFloat,
        labelSize: NSSize,
        rulerSize: NSSize,
        offsets: Offsets
    ) -> CGFloat {
        let minLabelX = offsets.leftInset
        let maxLabelX = rulerSize.width - labelSize.width - offsets.rightInset

        let rightX = tickX + offsets.tickGap
        let leftX = tickX - offsets.tickGap - labelSize.width
        let preferredX = rightX <= maxLabelX ? rightX : leftX

        return clamp(preferredX, lowerBound: minLabelX, upperBound: maxLabelX)
    }

    private static func verticalY(
        forTickY tickY: CGFloat,
        labelSize: NSSize,
        rulerSize: NSSize,
        offsets: Offsets
    ) -> CGFloat {
        let minLabelY = offsets.bottomInset
        let maxLabelY = rulerSize.height - labelSize.height - offsets.topInset

        let belowTickY = tickY - offsets.tickGap - labelSize.height
        let aboveTickY = tickY + offsets.tickGap
        let preferredY = belowTickY >= minLabelY ? belowTickY : aboveTickY

        return clamp(preferredY, lowerBound: minLabelY, upperBound: maxLabelY)
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

class RuleView: NSView {

    var color = RulerColors() {
        didSet {
            resizeHandleView?.color = color
            resizeHandleView?.needsDisplay = true
            updateUnitLabelFrame()
        }
    }
    private var resizeHandleView: ResizeHandleView?
    private var unitLabelView: UnitLabelView?

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

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    override func layout() {
        super.layout()
        updateResizeHandleFrame()
        updateUnitLabelFrame()
        updateResizeHandleVisibility()
        updateUnitLabelVisibility()
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
    }

    var windowWidth: CGFloat {
        return self.window?.frame.width ?? 0
    }

    var windowHeight: CGFloat {
        return self.window?.frame.height ?? 0
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
    
    var screen: NSScreen? {
        guard let window = window else {
            return nil
        }
        return NSScreen.screens.first { $0.frame.intersects(window.convertToScreen(frame)) }
    }

    var unit: Unit {
        prefs.unit
    }

    var resizeHandleExclusionFrame: NSRect? {
        return resizeHandleView?.frame
    }

    var unitLabelFrame: NSRect? {
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
        unitLabelView?.isHidden = isHidden
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

        resizeHandleView.frame = resizeHandleView.frame(in: bounds)
    }

    private func updateUnitLabelFrame() {
        guard let unitLabelView = unitLabelView else { return }

        unitLabelView.label = unitLabel()
        unitLabelView.frame = unitLabelView.frame(in: bounds)
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
private struct MouseTickLabelLayoutPreview: NSViewRepresentable {
    let orientation: Orientation
    let zeroCorner: ZeroCorner
    let mouseX: CGFloat
    let mouseY: CGFloat

    func makeNSView(context: Context) -> MouseTickLabelLayoutPreviewView {
        return MouseTickLabelLayoutPreviewView(
            orientation: orientation,
            zeroCorner: zeroCorner,
            mouseX: mouseX,
            mouseY: mouseY
        )
    }

    func updateNSView(_ view: MouseTickLabelLayoutPreviewView, context: Context) {
        view.orientation = orientation
        view.zeroCorner = zeroCorner
        view.mouseX = mouseX
        view.mouseY = mouseY
    }
}

private final class MouseTickLabelLayoutPreviewView: NSView {
    var orientation: Orientation {
        didSet { needsDisplay = true }
    }
    var zeroCorner: ZeroCorner {
        didSet { needsDisplay = true }
    }
    var mouseX: CGFloat {
        didSet { needsDisplay = true }
    }
    var mouseY: CGFloat {
        didSet { needsDisplay = true }
    }

    private let rulerFill = NSColor(calibratedRed: 0.94, green: 0.82, blue: 0.54, alpha: 1)
    private let tickColor = NSColor(calibratedRed: 0.41, green: 0.31, blue: 0.08, alpha: 1)
    private let mouseTickColor = NSColor(calibratedRed: 0.14, green: 0.12, blue: 0.06, alpha: 0.75)
    private let resizeHandleLength: CGFloat = 12
    private let resizeHandleLineCount = 4
    private let resizeHandleLineSpacing: CGFloat = 3
    private let resizeHandleBackgroundPadding: CGFloat = 1.5
    private let horizontalResizeHandleXOffset: CGFloat = 5
    private let horizontalResizeHandleYOffset: CGFloat = 4
    private let verticalResizeHandleXOffset: CGFloat = 4
    private let verticalResizeHandleYOffset: CGFloat = 5

    init(orientation: Orientation, zeroCorner: ZeroCorner, mouseX: CGFloat, mouseY: CGFloat) {
        self.orientation = orientation
        self.zeroCorner = zeroCorner
        self.mouseX = mouseX
        self.mouseY = mouseY
        super.init(frame: .zero)

        setAccessibilityElement(false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init(orientation:zeroCorner:mouseX:mouseY:)")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        rulerFill.setFill()
        bounds.fill()

        drawRulerTicks()
        drawBorder()
        drawTickSide()
        drawUnitLabel()
        drawResizeHandle()
        drawMouseTick()
    }

    private func drawBorder() {
        tickColor.withAlphaComponent(0.45).setStroke()
        let border = NSBezierPath(rect: bounds.insetBy(dx: 0.5, dy: 0.5))
        border.lineWidth = 1
        border.stroke()
    }

    private func drawTickSide() {
        let side = ZeroCornerGeometry(zeroCorner: zeroCorner)
            .tickSide(for: orientation)
        let path = NSBezierPath()

        switch side {
        case .top:
            path.move(to: CGPoint(x: bounds.minX, y: bounds.maxY - 0.5))
            path.line(to: CGPoint(x: bounds.maxX, y: bounds.maxY - 0.5))
        case .right:
            path.move(to: CGPoint(x: bounds.maxX - 0.5, y: bounds.minY))
            path.line(to: CGPoint(x: bounds.maxX - 0.5, y: bounds.maxY))
        case .bottom:
            path.move(to: CGPoint(x: bounds.minX, y: bounds.minY + 0.5))
            path.line(to: CGPoint(x: bounds.maxX, y: bounds.minY + 0.5))
        case .left:
            path.move(to: CGPoint(x: bounds.minX + 0.5, y: bounds.minY))
            path.line(to: CGPoint(x: bounds.minX + 0.5, y: bounds.maxY))
        }

        tickColor.setStroke()
        path.lineWidth = 2
        path.stroke()
    }

    private func drawRulerTicks() {
        let geometry = ZeroCornerGeometry(zeroCorner: zeroCorner)
        let tickSide = geometry.tickSide(for: orientation)
        let growthDirection = geometry.growthDirection(for: orientation)
        let rulerLength = orientation == .horizontal ? bounds.width : bounds.height
        let path = NSBezierPath()
        var offset: CGFloat = 2

        while offset <= rulerLength - 2 {
            let roundedOffset = Int(offset)
            let tickLength: CGFloat

            if roundedOffset.isMultiple(of: 50) {
                tickLength = 10
            } else if roundedOffset.isMultiple(of: 10) {
                tickLength = 8
            } else if roundedOffset.isMultiple(of: 2) {
                tickLength = 5
            } else {
                offset += 1
                continue
            }

            let position: CGFloat
            switch growthDirection {
            case .positive:
                position = offset
            case .negative:
                position = rulerLength - offset
            }

            appendTick(to: path, position: position, length: tickLength, tickSide: tickSide)
            offset += 1
        }

        tickColor.withAlphaComponent(0.82).setStroke()
        path.lineWidth = 1
        path.stroke()
    }

    private func appendTick(
        to path: NSBezierPath,
        position: CGFloat,
        length: CGFloat,
        tickSide: RulerSide
    ) {
        switch (orientation, tickSide) {
        case (.horizontal, .bottom):
            path.move(to: CGPoint(x: position + 0.5, y: bounds.minY + 1))
            path.line(to: CGPoint(x: position + 0.5, y: bounds.minY + length))
        case (.horizontal, .top):
            path.move(to: CGPoint(x: position + 0.5, y: bounds.maxY - 1))
            path.line(to: CGPoint(x: position + 0.5, y: bounds.maxY - length))
        case (.vertical, .right):
            path.move(to: CGPoint(x: bounds.maxX - 1, y: position - 0.5))
            path.line(to: CGPoint(x: bounds.maxX - length, y: position - 0.5))
        case (.vertical, .left):
            path.move(to: CGPoint(x: bounds.minX + 1, y: position - 0.5))
            path.line(to: CGPoint(x: bounds.minX + length, y: position - 0.5))
        case (_, _):
            return
        }
    }

    private func drawUnitLabel() {
        let label = NSAttributedString(
            string: "px",
            attributes: [
                .font: NSFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: tickColor,
            ]
        )
        let labelFrame = UnitLabelView.labelFrame(
            labelSize: UnitLabelView.labelSize(for: label),
            rulerSize: bounds.size,
            orientation: orientation,
            zeroCorner: zeroCorner
        )

        label.draw(with: labelFrame, context: nil)
    }

    private func drawResizeHandle() {
        let frame = resizeHandleFrame()
        let background = NSBezierPath(
            roundedRect: frame,
            xRadius: 2,
            yRadius: 2
        )

        rulerFill.setFill()
        background.fill()

        switch orientation {
        case .horizontal:
            drawHorizontalResizeHandleLines(in: frame)
        case .vertical:
            drawVerticalResizeHandleLines(in: frame)
        }
    }

    private func resizeHandleFrame() -> NSRect {
        let placement = ZeroCornerGeometry(zeroCorner: zeroCorner)
            .resizeHandlePlacement(for: orientation)

        switch orientation {
        case .horizontal:
            let firstX: CGFloat
            let bottomY: CGFloat

            switch placement.xSide {
            case .left:
                firstX = bounds.minX + horizontalResizeHandleXOffset + 1
            case .right:
                firstX = bounds.maxX
                    - horizontalResizeHandleXOffset
                    - CGFloat(resizeHandleLineCount - 1) * resizeHandleLineSpacing
                    - 1
            case .top, .bottom:
                assertionFailure("Horizontal preview resize handle must be placed on a horizontal side")
                firstX = bounds.maxX
                    - horizontalResizeHandleXOffset
                    - CGFloat(resizeHandleLineCount - 1) * resizeHandleLineSpacing
                    - 1
            }

            switch placement.ySide {
            case .top:
                bottomY = bounds.maxY - horizontalResizeHandleYOffset - resizeHandleLength
            case .bottom:
                bottomY = bounds.minY + horizontalResizeHandleYOffset
            case .left, .right:
                assertionFailure("Horizontal preview resize handle must be placed on a vertical side")
                bottomY = bounds.maxY - horizontalResizeHandleYOffset - resizeHandleLength
            }

            return NSRect(
                x: firstX - resizeHandleBackgroundPadding,
                y: bottomY - resizeHandleBackgroundPadding,
                width: CGFloat(resizeHandleLineCount - 1) * resizeHandleLineSpacing + 2 + (resizeHandleBackgroundPadding * 2),
                height: resizeHandleLength + (resizeHandleBackgroundPadding * 2)
            )
        case .vertical:
            let leftX: CGFloat
            let firstY: CGFloat

            switch placement.xSide {
            case .left:
                leftX = bounds.minX + verticalResizeHandleXOffset
            case .right:
                leftX = bounds.maxX - verticalResizeHandleXOffset - resizeHandleLength
            case .top, .bottom:
                assertionFailure("Vertical preview resize handle must be placed on a horizontal side")
                leftX = bounds.minX + verticalResizeHandleXOffset
            }

            switch placement.ySide {
            case .top:
                firstY = bounds.maxY
                    - verticalResizeHandleYOffset
                    - CGFloat(resizeHandleLineCount - 1) * resizeHandleLineSpacing
                    - 1
            case .bottom:
                firstY = bounds.minY + verticalResizeHandleYOffset + 1
            case .left, .right:
                assertionFailure("Vertical preview resize handle must be placed on a vertical side")
                firstY = bounds.minY + verticalResizeHandleYOffset + 1
            }

            return NSRect(
                x: leftX - resizeHandleBackgroundPadding,
                y: firstY - 1 - resizeHandleBackgroundPadding,
                width: resizeHandleLength + (resizeHandleBackgroundPadding * 2),
                height: CGFloat(resizeHandleLineCount - 1) * resizeHandleLineSpacing + 2 + (resizeHandleBackgroundPadding * 2)
            )
        }
    }

    private func drawHorizontalResizeHandleLines(in frame: NSRect) {
        for index in 0..<resizeHandleLineCount {
            let x = frame.minX
                + resizeHandleBackgroundPadding
                + CGFloat(index) * resizeHandleLineSpacing
            strokeResizeHandleLine(
                from: CGPoint(x: x + 0.5, y: frame.minY + resizeHandleBackgroundPadding),
                to: CGPoint(x: x + 0.5, y: frame.maxY - resizeHandleBackgroundPadding),
                color: NSColor.white.withAlphaComponent(0.35)
            )
            strokeResizeHandleLine(
                from: CGPoint(x: x + 1.5, y: frame.minY + resizeHandleBackgroundPadding),
                to: CGPoint(x: x + 1.5, y: frame.maxY - resizeHandleBackgroundPadding),
                color: tickColor.withAlphaComponent(0.28)
            )
        }
    }

    private func drawVerticalResizeHandleLines(in frame: NSRect) {
        for index in 0..<resizeHandleLineCount {
            let y = frame.minY
                + resizeHandleBackgroundPadding
                + 1
                + CGFloat(index) * resizeHandleLineSpacing
            strokeResizeHandleLine(
                from: CGPoint(x: frame.minX + resizeHandleBackgroundPadding, y: y + 0.5),
                to: CGPoint(x: frame.maxX - resizeHandleBackgroundPadding, y: y + 0.5),
                color: NSColor.white.withAlphaComponent(0.35)
            )
            strokeResizeHandleLine(
                from: CGPoint(x: frame.minX + resizeHandleBackgroundPadding, y: y - 0.5),
                to: CGPoint(x: frame.maxX - resizeHandleBackgroundPadding, y: y - 0.5),
                color: tickColor.withAlphaComponent(0.28)
            )
        }
    }

    private func strokeResizeHandleLine(
        from start: CGPoint,
        to end: CGPoint,
        color: NSColor
    ) {
        let path = NSBezierPath()

        path.lineWidth = 1
        path.move(to: start)
        path.line(to: end)

        color.setStroke()
        path.stroke()
    }

    private func drawMouseTick() {
        let measurement = orientation == .horizontal ? mouseX : mouseY
        let position = localMouseTickPosition(for: measurement)

        drawMouseTickLine(at: position)
        drawMouseTickLabel(at: position, measurement: measurement)
    }

    private func localMouseTickPosition(for measurement: CGFloat) -> CGFloat {
        let rulerLength = orientation == .horizontal ? bounds.width : bounds.height
        let clampedMeasurement = min(max(measurement, 0), rulerLength)
        let growthDirection = ZeroCornerGeometry(zeroCorner: zeroCorner)
            .growthDirection(for: orientation)

        switch growthDirection {
        case .positive:
            return clampedMeasurement
        case .negative:
            return rulerLength - clampedMeasurement
        }
    }

    private func drawMouseTickLine(at position: CGFloat) {
        let path = NSBezierPath()

        switch orientation {
        case .horizontal:
            path.move(to: CGPoint(x: position + 0.5, y: bounds.minY))
            path.line(to: CGPoint(x: position + 0.5, y: bounds.maxY))
        case .vertical:
            path.move(to: CGPoint(x: bounds.minX, y: position - 0.5))
            path.line(to: CGPoint(x: bounds.maxX, y: position - 0.5))
        }

        mouseTickColor.setStroke()
        path.lineWidth = 1
        path.stroke()
    }

    private func drawMouseTickLabel(at position: CGFloat, measurement: CGFloat) {
        let label = mouseTickLabel(for: measurement)
        let labelSize = label.size()
        let labelFrame = MouseTickLabelLayout.labelFrame(
            labelSize: labelSize,
            rulerSize: bounds.size,
            orientation: orientation,
            zeroCorner: zeroCorner,
            tickPosition: position
        )
        let background = NSBezierPath(
            roundedRect: labelFrame.insetBy(dx: -1, dy: -1),
            xRadius: 2,
            yRadius: 2
        )

        rulerFill.setFill()
        background.fill()
        label.draw(with: labelFrame, context: nil)
    }

    private func mouseTickLabel(for measurement: CGFloat) -> NSAttributedString {
        return NSAttributedString(
            string: "\(Int(measurement.rounded()))",
            attributes: [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular),
                .foregroundColor: mouseTickColor,
            ]
        )
    }
}

private struct MouseTickLabelOffsetPreview: View {
    let mouseX: CGFloat
    let mouseY: CGFloat

    private let cellSize = CGSize(
        width: 260 + Ruler.thickness,
        height: 260 + Ruler.thickness
    )
    private let cases: [(name: String, zeroCorner: ZeroCorner)] = [
        ("Top Left", .topLeft),
        ("Top Right", .topRight),
        ("Bottom Left", .bottomLeft),
        ("Bottom Right", .bottomRight),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Mouse Tick Label Offsets (mouseX: \(Int(mouseX)), mouseY: \(Int(mouseY)))")
                .font(.headline)

            LazyVGrid(
                columns: [
                    GridItem(.fixed(cellSize.width), spacing: 24),
                    GridItem(.fixed(cellSize.width), spacing: 24),
                ],
                alignment: .leading,
                spacing: 22
            ) {
                ForEach(cases, id: \.name) { testCase in
                    MouseTickLabelCornerPreview(
                        name: testCase.name,
                        zeroCorner: testCase.zeroCorner,
                        rulerLength: 260,
                        mouseX: mouseX,
                        mouseY: mouseY
                    )
                }
            }
        }
        .padding()
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
                MouseTickLabelLayoutPreview(
                    orientation: .horizontal,
                    zeroCorner: zeroCorner,
                    mouseX: mouseX,
                    mouseY: mouseY
                )
                .frame(width: rulerLength, height: thickness)
                .position(x: horizontalCenter.x, y: horizontalCenter.y)

                MouseTickLabelLayoutPreview(
                    orientation: .vertical,
                    zeroCorner: zeroCorner,
                    mouseX: mouseX,
                    mouseY: mouseY
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

private struct RuleViewPreview: NSViewRepresentable {
    let orientation: Orientation

    func makeNSView(context: Context) -> RuleView {
        let view: RuleView
        switch orientation {
        case .horizontal:
            view = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 320, height: Ruler.thickness))
        case .vertical:
            view = VerticalRule(frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 320))
        }

        view.showMouseTick = false
        view.wantsLayer = true
        view.layer?.borderColor = CGColor(gray: 0, alpha: 0.5)
        view.layer?.borderWidth = 1
        return view
    }

    func updateNSView(_ view: RuleView, context: Context) {
        view.showMouseTick = false
        view.needsDisplay = true
    }
}

struct RuleView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HStack(alignment: .top, spacing: 24) {
                RuleViewPreview(orientation: .horizontal)
                    .frame(width: 320, height: Ruler.thickness)

                RuleViewPreview(orientation: .vertical)
                    .frame(width: Ruler.thickness, height: 320)
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Rulers")

            MouseTickLabelOffsetPreview(mouseX: 8, mouseY: 8)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Mouse Tick Labels")
        }
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
