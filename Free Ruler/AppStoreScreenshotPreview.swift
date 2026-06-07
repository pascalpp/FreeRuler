import Cocoa
#if DEBUG
import SwiftUI

private struct AppStoreScreenshotPalette {
    let screen1Background = #colorLiteral(red: 0.4796547203, green: 0.5864364802, blue: 0.8, alpha: 1)
    let screen2Background = #colorLiteral(red: 0.3084420562, green: 0.521068275, blue: 0.509829402, alpha: 1)
    let text = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    let secondaryText = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.78)

    let sampleWindowFill = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    let sampleWindowBorder = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.35)
    let sampleWindowTitlebar = #colorLiteral(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
    let sampleWindowTitlebarBorder = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.2)

    let rulerBorder = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5)

    let closeButton = #colorLiteral(red: 0.9803921569, green: 0.3803921569, blue: 0.3607843137, alpha: 1)
    let minimizeButton = #colorLiteral(red: 0.9882352941, green: 0.737254902, blue: 0.2470588235, alpha: 1)
    let zoomButton = #colorLiteral(red: 0.231372549, green: 0.7843137255, blue: 0.2862745098, alpha: 1)
}

private enum AppStoreScreenshotFontFamily {
    case system
    case helveticaNeue
}

private enum AppStoreScreenshotScreen {
    case screen1
    case screen2

    func background(in palette: AppStoreScreenshotPalette) -> NSColor {
        switch self {
        case .screen1:
            return palette.screen1Background
        case .screen2:
            return palette.screen2Background
        }
    }

    var headline: String {
        switch self {
        case .screen1:
            return "A ruler for your Mac"
        case .screen2:
            return "Switch units instantly"
        }
    }

    var description: String {
        switch self {
        case .screen1:
            return "Measure anything on your screen."
        case .screen2:
            return "Use pixels, millimeters, or inches."
        }
    }

    var previewName: String {
        switch self {
        case .screen1:
            return "Screen 1 - Measure anything"
        case .screen2:
            return "Screen 2 - Units"
        }
    }
}

private enum AppStoreScreenshotLayout {
    static let canvasWidth: CGFloat = 2880
    static let canvasHeight: CGFloat = 1800
    static let previewWidth: CGFloat = 960
    static let previewHeight: CGFloat = 600

    static let iconX: CGFloat = 640
    static let iconY: CGFloat = 80
    static let iconSize: CGFloat = 360

    static let headlineX: CGFloat = 1050
    static let headlineY: CGFloat = 140
    static let headlineWidth: CGFloat = 1800
    static let headlineHeight: CGFloat = 120
    static let headlineFontSize: CGFloat = 100
    static let headlineFontWeight: NSFont.Weight = .semibold

    static let descriptionX: CGFloat = 1050
    static let descriptionY: CGFloat = 270
    static let descriptionWidth: CGFloat = 1600
    static let descriptionHeight: CGFloat = 100
    static let descriptionFontSize: CGFloat = 80
    static let textFontFamily: AppStoreScreenshotFontFamily = .system
    static let textFontWeight: NSFont.Weight = .regular

    static let rulerScale: CGFloat = 4.4
    static let rulerBorderWidth: CGFloat = 1

    static let rulerCornerX: CGFloat = 420
    static let rulerCornerY: CGFloat = 500
    static let horizontalRulerLength: CGFloat = 1850
    static let verticalRulerLength: CGFloat = 1040

    static let sampleWindowCornerRadius: CGFloat = 34
    static let sampleWindowBorderWidth: CGFloat = 1
    static let sampleWindowShadowBlur: CGFloat = 26
    static let sampleWindowShadowXOffset: CGFloat = 0
    static let sampleWindowShadowYOffset: CGFloat = 12
    static let sampleWindowShadowOpacity: CGFloat = 0.28

    static let titlebarHorizontalOutset: CGFloat = 0
    static let titlebarHeight: CGFloat = 150
    static let trafficLightDiameter: CGFloat = 48
    static let trafficLightSpacing: CGFloat = 80
    static let trafficLightXPadding: CGFloat = 56
    static let trafficLightYPadding: CGFloat = 52

    static let screen2RulerScale: CGFloat = 6
    static let screen2RulerX: CGFloat = 550
    static let screen2RulerXOffset: CGFloat = -200
    static let screen2FirstRulerY: CGFloat = 620
    static let screen2RulerVerticalSpacing: CGFloat = 350
    static let screen2RulerLength: CGFloat = 2200

    static var canvasSize: NSSize {
        NSSize(width: canvasWidth, height: canvasHeight)
    }

    static var iconRect: NSRect {
        NSRect(x: iconX, y: iconY, width: iconSize, height: iconSize)
    }

    static var headlineRect: NSRect {
        NSRect(x: headlineX, y: headlineY, width: headlineWidth, height: headlineHeight)
    }

    static var descriptionRect: NSRect {
        NSRect(x: descriptionX, y: descriptionY, width: descriptionWidth, height: descriptionHeight)
    }

    static var scaledRulerThickness: CGFloat {
        Ruler.thickness * rulerScale
    }

    static var horizontalRulerRect: NSRect {
        NSRect(
            x: rulerCornerX + scaledRulerThickness - rulerScale,
            y: rulerCornerY,
            width: horizontalRulerLength,
            height: scaledRulerThickness
        )
    }

    static var verticalRulerRect: NSRect {
        NSRect(
            x: rulerCornerX,
            y: rulerCornerY + scaledRulerThickness - rulerScale,
            width: scaledRulerThickness,
            height: verticalRulerLength
        )
    }

    static var sampleWindowRect: NSRect {
        NSRect(
            x: horizontalRulerRect.minX,
            y: verticalRulerRect.minY,
            width: horizontalRulerLength,
            height: verticalRulerLength
        )
    }

    static var titlebarRect: NSRect {
        NSRect(
            x: sampleWindowRect.minX - titlebarHorizontalOutset,
            y: sampleWindowRect.minY,
            width: sampleWindowRect.width + (titlebarHorizontalOutset * 2),
            height: titlebarHeight
        )
    }

    static var trafficLightOrigin: CGPoint {
        CGPoint(
            x: sampleWindowRect.minX + trafficLightXPadding,
            y: sampleWindowRect.minY + trafficLightYPadding
        )
    }

    static var screen2ScaledRulerThickness: CGFloat {
        Ruler.thickness * screen2RulerScale
    }

    static func screen2RulerRect(index: Int) -> NSRect {
        NSRect(
            x: screen2RulerX + CGFloat(index) * screen2RulerXOffset,
            y: screen2FirstRulerY + CGFloat(index) * screen2RulerVerticalSpacing,
            width: screen2RulerLength,
            height: screen2ScaledRulerThickness
        )
    }

}

struct AppStoreScreenshotPreview: PreviewProvider {
    static var previews: some View {
        Group {
            AppStoreScreenshotScenarioView(screen: .screen1)
                .previewDisplayName(AppStoreScreenshotScreen.screen1.previewName)
            AppStoreScreenshotScenarioView(screen: .screen2)
                .previewDisplayName(AppStoreScreenshotScreen.screen2.previewName)
        }
        .aspectRatio(16.0 / 10.0, contentMode: .fit)
        .frame(width: AppStoreScreenshotLayout.previewWidth, height: AppStoreScreenshotLayout.previewHeight)
        .previewLayout(.fixed(
            width: AppStoreScreenshotLayout.previewWidth,
            height: AppStoreScreenshotLayout.previewHeight
        ))
    }
}

private struct AppStoreScreenshotScenarioView: NSViewRepresentable {
    let screen: AppStoreScreenshotScreen

    func makeNSView(context: Context) -> AppStoreScreenshotScenarioNSView {
        AppStoreScreenshotScenarioNSView(screen: screen)
    }

    func updateNSView(_ nsView: AppStoreScreenshotScenarioNSView, context: Context) {}
}

private struct AppStoreRulerPlacement {
    let container: NSView
    let view: RuleView
    let frame: NSRect
    let boundsSize: NSSize

    init(view: RuleView, frame: NSRect, boundsSize: NSSize) {
        self.container = NSView(frame: NSRect(origin: .zero, size: boundsSize))
        self.view = view
        self.frame = frame
        self.boundsSize = boundsSize
        self.container.addSubview(view)
    }
}

private final class AppStoreHorizontalRule: HorizontalRule {
    private let unit: Unit

    init(unit: Unit, frame: NSRect) {
        self.unit = unit
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        let originalUnit = prefs.unit
        prefs.unit = unit
        defer {
            prefs.unit = originalUnit
        }
        super.draw(dirtyRect)
    }
}

private final class AppStoreVerticalRule: VerticalRule {
    private let unit: Unit

    init(unit: Unit, frame: NSRect) {
        self.unit = unit
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        let originalUnit = prefs.unit
        prefs.unit = unit
        defer {
            prefs.unit = originalUnit
        }
        super.draw(dirtyRect)
    }
}

private final class AppStoreScreenshotScenarioNSView: NSView {
    private let screen: AppStoreScreenshotScreen
    private let palette = AppStoreScreenshotPalette()
    private let rulerPlacements: [AppStoreRulerPlacement]

    override var isFlipped: Bool {
        true
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 960, height: 600)
    }

    init(screen: AppStoreScreenshotScreen) {
        self.screen = screen
        self.rulerPlacements = Self.makeRulerPlacements(for: screen)
        super.init(frame: NSRect(origin: .zero, size: AppStoreScreenshotLayout.canvasSize))
        for rulerPlacement in rulerPlacements {
            configureRuler(rulerPlacement.view)
            addSubview(rulerPlacement.container)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        bounds.fill()

        let scale = min(
            bounds.width / AppStoreScreenshotLayout.canvasWidth,
            bounds.height / AppStoreScreenshotLayout.canvasHeight
        )
        let scaledSize = NSSize(
            width: AppStoreScreenshotLayout.canvasWidth * scale,
            height: AppStoreScreenshotLayout.canvasHeight * scale
        )
        let origin = CGPoint(
            x: bounds.midX - scaledSize.width / 2,
            y: bounds.midY - scaledSize.height / 2
        )

        NSGraphicsContext.saveGraphicsState()
        let transform = NSAffineTransform()
        transform.translateX(by: origin.x, yBy: origin.y)
        transform.scale(by: scale)
        transform.concat()

        drawScenario()

        NSGraphicsContext.restoreGraphicsState()
    }

    override func layout() {
        super.layout()
        let transform = previewTransform()
        for rulerPlacement in rulerPlacements {
            layoutRuler(
                rulerPlacement,
                frame: rulerPlacement.frame,
                transform: transform
            )
        }
    }

    private static func makeRulerPlacements(for screen: AppStoreScreenshotScreen) -> [AppStoreRulerPlacement] {
        switch screen {
        case .screen1:
            let horizontalBoundsSize = NSSize(
                width: AppStoreScreenshotLayout.horizontalRulerLength / AppStoreScreenshotLayout.rulerScale,
                height: Ruler.thickness
            )
            let verticalBoundsSize = NSSize(
                width: Ruler.thickness,
                height: AppStoreScreenshotLayout.verticalRulerLength / AppStoreScreenshotLayout.rulerScale
            )
            return [
                AppStoreRulerPlacement(
                    view: AppStoreHorizontalRule(unit: .pixels, frame: NSRect(origin: .zero, size: horizontalBoundsSize)),
                    frame: AppStoreScreenshotLayout.horizontalRulerRect,
                    boundsSize: horizontalBoundsSize
                ),
                AppStoreRulerPlacement(
                    view: AppStoreVerticalRule(unit: .pixels, frame: NSRect(origin: .zero, size: verticalBoundsSize)),
                    frame: AppStoreScreenshotLayout.verticalRulerRect,
                    boundsSize: verticalBoundsSize
                ),
            ]
        case .screen2:
            let rulerBoundsSize = NSSize(
                width: AppStoreScreenshotLayout.screen2RulerLength / AppStoreScreenshotLayout.screen2RulerScale,
                height: Ruler.thickness
            )
            return [Unit.pixels, .millimeters, .inches].enumerated().map { index, unit in
                AppStoreRulerPlacement(
                    view: AppStoreHorizontalRule(unit: unit, frame: NSRect(origin: .zero, size: rulerBoundsSize)),
                    frame: AppStoreScreenshotLayout.screen2RulerRect(index: index),
                    boundsSize: rulerBoundsSize
                )
            }
        }
    }

    private func previewTransform() -> (origin: CGPoint, scale: CGFloat) {
        let scale = min(
            bounds.width / AppStoreScreenshotLayout.canvasWidth,
            bounds.height / AppStoreScreenshotLayout.canvasHeight
        )
        let scaledSize = NSSize(
            width: AppStoreScreenshotLayout.canvasWidth * scale,
            height: AppStoreScreenshotLayout.canvasHeight * scale
        )
        let origin = CGPoint(
            x: bounds.midX - scaledSize.width / 2,
            y: bounds.midY - scaledSize.height / 2
        )
        return (origin, scale)
    }

    private func layoutRuler(
        _ rulerPlacement: AppStoreRulerPlacement,
        frame: NSRect,
        transform: (origin: CGPoint, scale: CGFloat)
    ) {
        rulerPlacement.container.frame = NSRect(
            x: transform.origin.x + frame.minX * transform.scale,
            y: transform.origin.y + frame.minY * transform.scale,
            width: frame.width * transform.scale,
            height: frame.height * transform.scale
        )
        rulerPlacement.container.setBoundsSize(rulerPlacement.boundsSize)
        rulerPlacement.view.frame = NSRect(origin: .zero, size: rulerPlacement.boundsSize)
        rulerPlacement.view.setBoundsSize(rulerPlacement.boundsSize)
        rulerPlacement.view.needsDisplay = true
    }

    private func drawScenario() {
        screen.background(in: palette).setFill()
        NSRect(origin: .zero, size: AppStoreScreenshotLayout.canvasSize).fill()

        drawCopy()
        switch screen {
        case .screen1:
            drawSampleWindow(AppStoreScreenshotLayout.sampleWindowRect)
        case .screen2:
            break
        }
    }

    private func drawCopy() {
        let icon = AppIconRenderer.image(size: 128)
        icon.draw(in: AppStoreScreenshotLayout.iconRect)

        drawText(
            screen.headline,
            in: AppStoreScreenshotLayout.headlineRect,
            size: AppStoreScreenshotLayout.headlineFontSize,
            color: palette.text,
            weight: AppStoreScreenshotLayout.headlineFontWeight
        )
        drawText(
            screen.description,
            in: AppStoreScreenshotLayout.descriptionRect,
            size: AppStoreScreenshotLayout.descriptionFontSize,
            color: palette.secondaryText
        )
    }

    private func configureRuler(_ view: RuleView) {
        view.showMouseTick = false
        view.wantsLayer = true
        view.layer?.borderColor = palette.rulerBorder.cgColor
        view.layer?.borderWidth = AppStoreScreenshotLayout.rulerBorderWidth
    }

    private func drawSampleWindow(_ rect: NSRect) {
        drawShadow(
            rect,
            radius: AppStoreScreenshotLayout.sampleWindowCornerRadius,
            fill: screen.background(in: palette),
            blur: AppStoreScreenshotLayout.sampleWindowShadowBlur,
            offset: NSSize(
                width: AppStoreScreenshotLayout.sampleWindowShadowXOffset,
                height: AppStoreScreenshotLayout.sampleWindowShadowYOffset
            ),
            opacity: AppStoreScreenshotLayout.sampleWindowShadowOpacity
        )
        rounded(
            rect,
            radius: AppStoreScreenshotLayout.sampleWindowCornerRadius,
            fill: palette.sampleWindowFill,
            stroke: palette.sampleWindowBorder
        )
        rounded(
            AppStoreScreenshotLayout.titlebarRect,
            radius: AppStoreScreenshotLayout.sampleWindowCornerRadius,
            fill: palette.sampleWindowTitlebar,
            stroke: nil
        )
        palette.sampleWindowTitlebar.setFill()
        NSRect(
            x: AppStoreScreenshotLayout.titlebarRect.minX,
            y: AppStoreScreenshotLayout.titlebarRect.minY + AppStoreScreenshotLayout.titlebarHeight / 2,
            width: AppStoreScreenshotLayout.titlebarRect.width,
            height: AppStoreScreenshotLayout.titlebarHeight / 2
        ).fill()
        stroke(
            AppStoreScreenshotLayout.titlebarRect,
            color: palette.sampleWindowTitlebarBorder,
            width: AppStoreScreenshotLayout.sampleWindowBorderWidth
        )
        drawTrafficLights(at: AppStoreScreenshotLayout.trafficLightOrigin)
    }

    private func drawTrafficLights(at point: CGPoint) {
        for (index, color) in [palette.closeButton, palette.minimizeButton, palette.zoomButton].enumerated() {
            color.setFill()
            let rect = NSRect(
                x: point.x + CGFloat(index) * AppStoreScreenshotLayout.trafficLightSpacing,
                y: point.y,
                width: AppStoreScreenshotLayout.trafficLightDiameter,
                height: AppStoreScreenshotLayout.trafficLightDiameter
            )
            NSBezierPath(ovalIn: rect).fill()
            strokeOval(rect, color: palette.sampleWindowTitlebarBorder, width: 1)
        }
    }

    private func drawShadow(_ rect: NSRect, radius: CGFloat, fill: NSColor, blur: CGFloat, offset: NSSize, opacity: CGFloat) {
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowBlurRadius = blur
        shadow.shadowOffset = offset
        shadow.shadowColor = NSColor.black.withAlphaComponent(opacity)
        shadow.set()
        fill.setFill()
        NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
        NSGraphicsContext.restoreGraphicsState()
    }

    private func rounded(_ rect: NSRect, radius: CGFloat, fill: NSColor, stroke: NSColor?) {
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        fill.setFill()
        path.fill()

        if let stroke {
            stroke.setStroke()
            path.lineWidth = 1
            path.stroke()
        }
    }

    private func stroke(_ rect: NSRect, color: NSColor, width: CGFloat) {
        color.setStroke()
        let path = NSBezierPath(rect: rect.insetBy(dx: width / 2, dy: width / 2))
        path.lineWidth = width
        path.stroke()
    }

    private func strokeOval(_ rect: NSRect, color: NSColor, width: CGFloat) {
        color.setStroke()
        let path = NSBezierPath(ovalIn: rect.insetBy(dx: width / 2, dy: width / 2))
        path.lineWidth = width
        path.stroke()
    }

    private func drawText(
        _ text: String,
        in rect: NSRect,
        size: CGFloat,
        color: NSColor,
        weight: NSFont.Weight = AppStoreScreenshotLayout.textFontWeight,
        alignment: NSTextAlignment = .left
    ) {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment

        let attributes: [NSAttributedString.Key: Any] = [
            .font: labelFont(size: size, weight: weight),
            .foregroundColor: color,
            .paragraphStyle: style,
        ]

        text.draw(with: rect, options: [.usesLineFragmentOrigin], attributes: attributes)
    }

    private func labelFont(size: CGFloat, weight: NSFont.Weight) -> NSFont {
        switch AppStoreScreenshotLayout.textFontFamily {
        case .helveticaNeue:
            return NSFont(
                name: "HelveticaNeue",
                size: size
            ) ?? .systemFont(ofSize: size, weight: weight)
        case .system:
            return .systemFont(ofSize: size, weight: weight)
        }
    }
}

#endif
