import Cocoa
#if DEBUG
import SwiftUI

private struct AppStoreScreenshotPalette {
    let background = #colorLiteral(red: 0.4796547203, green: 0.5864364802, blue: 0.8, alpha: 1)
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

private enum AppStoreScreenshotLayout {
    static let canvasWidth: CGFloat = 2880
    static let canvasHeight: CGFloat = 1800
    static let previewWidth: CGFloat = 960
    static let previewHeight: CGFloat = 600

    static let headline = "A ruler for your Mac"
    static let description = "Measure anything on your screen."

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
}

struct AppStoreScreenshotPreview: PreviewProvider {
    static var previews: some View {
        AppStoreScreenshotScenarioView()
            .aspectRatio(16.0 / 10.0, contentMode: .fit)
            .frame(width: AppStoreScreenshotLayout.previewWidth, height: AppStoreScreenshotLayout.previewHeight)
            .previewLayout(.fixed(
                width: AppStoreScreenshotLayout.previewWidth,
                height: AppStoreScreenshotLayout.previewHeight
            ))
    }
}

private struct AppStoreScreenshotScenarioView: NSViewRepresentable {
    func makeNSView(context: Context) -> AppStoreScreenshotScenarioNSView {
        AppStoreScreenshotScenarioNSView()
    }

    func updateNSView(_ nsView: AppStoreScreenshotScenarioNSView, context: Context) {}
}

private final class AppStoreScreenshotScenarioNSView: NSView {
    private let palette = AppStoreScreenshotPalette()
    private let horizontalRuler = getRulerView(ruler: Ruler(.horizontal, frame: NSRect(
        x: 0,
        y: 0,
        width: AppStoreScreenshotLayout.horizontalRulerLength / AppStoreScreenshotLayout.rulerScale,
        height: Ruler.thickness
    )))
    private let verticalRuler = getRulerView(ruler: Ruler(.vertical, frame: NSRect(
        x: 0,
        y: 0,
        width: Ruler.thickness,
        height: AppStoreScreenshotLayout.verticalRulerLength / AppStoreScreenshotLayout.rulerScale
    )))

    override var isFlipped: Bool {
        true
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 960, height: 600)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: NSRect(origin: .zero, size: AppStoreScreenshotLayout.canvasSize))
        configureRuler(horizontalRuler)
        configureRuler(verticalRuler)
        addSubview(horizontalRuler)
        addSubview(verticalRuler)
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
        layoutRuler(
            horizontalRuler,
            frame: AppStoreScreenshotLayout.horizontalRulerRect,
            boundsSize: NSSize(
                width: AppStoreScreenshotLayout.horizontalRulerLength / AppStoreScreenshotLayout.rulerScale,
                height: Ruler.thickness
            ),
            transform: transform
        )
        layoutRuler(
            verticalRuler,
            frame: AppStoreScreenshotLayout.verticalRulerRect,
            boundsSize: NSSize(
                width: Ruler.thickness,
                height: AppStoreScreenshotLayout.verticalRulerLength / AppStoreScreenshotLayout.rulerScale
            ),
            transform: transform
        )
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
        _ view: RuleView,
        frame: NSRect,
        boundsSize: NSSize,
        transform: (origin: CGPoint, scale: CGFloat)
    ) {
        view.frame = NSRect(
            x: transform.origin.x + frame.minX * transform.scale,
            y: transform.origin.y + frame.minY * transform.scale,
            width: frame.width * transform.scale,
            height: frame.height * transform.scale
        )
        view.setBoundsSize(boundsSize)
        view.needsDisplay = true
    }

    private func drawScenario() {
        palette.background.setFill()
        NSRect(origin: .zero, size: AppStoreScreenshotLayout.canvasSize).fill()

        drawCopy()
        drawSampleWindow(AppStoreScreenshotLayout.sampleWindowRect)
    }

    private func drawCopy() {
        let icon = AppIconRenderer.image(size: 128)
        icon.draw(in: AppStoreScreenshotLayout.iconRect)

        drawText(
            AppStoreScreenshotLayout.headline,
            in: AppStoreScreenshotLayout.headlineRect,
            size: AppStoreScreenshotLayout.headlineFontSize,
            color: palette.text,
            weight: AppStoreScreenshotLayout.headlineFontWeight
        )
        drawText(
            AppStoreScreenshotLayout.description,
            in: AppStoreScreenshotLayout.descriptionRect,
            size: AppStoreScreenshotLayout.descriptionFontSize,
            color: palette.secondaryText
        )
    }

    private func configureRuler(_ view: RuleView) {
        let originalUnit = prefs.unit
        prefs.unit = .pixels
        defer {
            prefs.unit = originalUnit
        }

        view.showMouseTick = false
        view.wantsLayer = true
        view.layer?.borderColor = palette.rulerBorder.cgColor
        view.layer?.borderWidth = AppStoreScreenshotLayout.rulerBorderWidth
    }

    private func drawSampleWindow(_ rect: NSRect) {
        drawShadow(
            rect,
            radius: AppStoreScreenshotLayout.sampleWindowCornerRadius,
            fill: palette.background,
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
