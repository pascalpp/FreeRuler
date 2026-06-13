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

class RuleView: NSView {

    var color = RulerColors() {
        didSet {
            resizeHandleView?.color = color
            resizeHandleView?.needsDisplay = true
        }
    }
    let mouseTickLabelResizeHandleSpacing: CGFloat = 8
    private var resizeHandleView: ResizeHandleView?

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
    }

    func installResizeHandle(for orientation: Orientation) {
        let view = ResizeHandleView(orientation: orientation, color: color)
        addSubview(view)
        resizeHandleView = view
        updateResizeHandleFrame()
    }

    func drawMouseTick(at mouseLoc: NSPoint) {
        // required override
        // TODO: is there a better way to do this, maybe via a protocol?
        // AppDelegate needs to be able to infer that any RulerView has this method
        fatalError("RuleView subclass must override drawMouseTick method.")
    }

    func redrawForPreferenceChange() {
        updateResizeHandleFrame()
        setNeedsDisplay(visibleRect)
        resizeHandleView?.needsDisplay = true
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

    private func updateResizeHandleFrame() {
        guard let resizeHandleView = resizeHandleView else { return }

        resizeHandleView.frame = resizeHandleView.frame(in: bounds)
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
        HStack(alignment: .top, spacing: 24) {
            RuleViewPreview(orientation: .horizontal)
                .frame(width: 320, height: Ruler.thickness)

            RuleViewPreview(orientation: .vertical)
                .frame(width: Ruler.thickness, height: 320)
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Rulers")
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
