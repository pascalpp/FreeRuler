#if DEBUG
import Cocoa
import SwiftUI

private struct AppStoreScreenshotPalette {
    let text = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    let secondaryText = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.78)
    let darkText = #colorLiteral(red: 0.13, green: 0.14, blue: 0.17, alpha: 1)
    let darkSecondaryText = #colorLiteral(red: 0.13, green: 0.14, blue: 0.17, alpha: 0.68)

    let sampleWindowFill = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    let sampleWindowBorder = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.35)
    let sampleWindowTitlebar = #colorLiteral(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
    let sampleWindowTitlebarBorder = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.2)

    let rulerBorder = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5)

    let closeButton = #colorLiteral(red: 0.9803921569, green: 0.3803921569, blue: 0.3607843137, alpha: 1)
    let minimizeButton = #colorLiteral(red: 0.9882352941, green: 0.737254902, blue: 0.2470588235, alpha: 1)
    let zoomButton = #colorLiteral(red: 0.231372549, green: 0.7843137255, blue: 0.2862745098, alpha: 1)
}

enum AppStoreScreenshotFontFamily {
    case system
    case helveticaNeue
}

private struct AppStoreScreenshotScreen {
    let title: String
    let subtitle: String
    let previewName: String
    let outputFilename: String
    let backgroundColor: NSColor
    let bottomBackgroundColor: NSColor
    let usesDarkCopy: Bool
    let makeView: () -> NSView

    static let allInOutputOrder: [AppStoreScreenshotScreen] = [
        AppStoreMeasureScreenshotView.screen,
        AppStoreColorsScreenshotView.screen,
        AppStoreInfinityScreenshotView.screen,
        AppStoreGroupsScreenshotView.screen,
        AppStoreFlipScreenshotView.screen,
        AppStoreUnitsScreenshotView.screen,
        AppStorePreferencesScreenshotView.screen,
    ]

    func titleColor(in palette: AppStoreScreenshotPalette) -> NSColor {
        usesDarkCopy ? palette.darkText : palette.text
    }

    func subtitleColor(in palette: AppStoreScreenshotPalette) -> NSColor {
        usesDarkCopy ? palette.darkSecondaryText : palette.secondaryText
    }
}

private struct AppStoreFlipRulerSet {
    let zeroCorner: ZeroCorner
    let x: CGFloat
    let y: CGFloat
    let horizontalLength: CGFloat
    let verticalLength: CGFloat
    let fillColor: NSColor
    let layoutSize: NSSize

    func horizontalFrame(rulerScale: CGFloat) -> NSRect {
        let x = zeroCornerX
        let y = zeroCornerY
        let thickness = Ruler.thickness * rulerScale
        let overlap = rulerScale
        let frameX: CGFloat
        let frameY: CGFloat

        switch zeroCorner {
        case .topLeft:
            frameX = x - overlap
            frameY = y - thickness
        case .topRight:
            frameX = x - horizontalLength
            frameY = y - thickness
        case .bottomLeft:
            frameX = x - overlap
            frameY = y - overlap
        case .bottomRight:
            frameX = x - horizontalLength
            frameY = y - overlap
        }

        return NSRect(x: frameX, y: frameY, width: horizontalLength, height: thickness)
    }

    func verticalFrame(rulerScale: CGFloat) -> NSRect {
        let x = zeroCornerX
        let y = zeroCornerY
        let thickness = Ruler.thickness * rulerScale
        let overlap = rulerScale
        let frameX: CGFloat
        let frameY: CGFloat

        switch zeroCorner {
        case .topLeft:
            frameX = x - thickness
            frameY = y - overlap
        case .topRight:
            frameX = x - overlap
            frameY = y - overlap
        case .bottomLeft:
            frameX = x - thickness
            frameY = y - verticalLength
        case .bottomRight:
            frameX = x - overlap
            frameY = y - verticalLength
        }

        return NSRect(x: frameX, y: frameY, width: thickness, height: verticalLength)
    }

    func groupedFrame(rulerScale: CGFloat) -> NSRect {
        horizontalFrame(rulerScale: rulerScale)
            .union(verticalFrame(rulerScale: rulerScale))
    }

    private var zeroCornerX: CGFloat {
        switch zeroCorner {
        case .topLeft, .bottomLeft:
            return x
        case .topRight, .bottomRight:
            return layoutSize.width - x
        }
    }

    private var zeroCornerY: CGFloat {
        switch zeroCorner {
        case .topLeft, .topRight:
            return y
        case .bottomLeft, .bottomRight:
            return layoutSize.height - y
        }
    }
}

enum AppStoreScreenshotRenderer {
    static func exportAll(to outputDirectory: URL) throws {
        try FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true
        )

        for screen in AppStoreScreenshotScreen.allInOutputOrder {
            let image = try render(screen: screen)
            let outputURL = outputDirectory.appendingPathComponent(screen.outputFilename)
            try writePNG(image, to: outputURL)
            print("Generated \(outputURL.path)")
        }
    }

    private static func render(screen: AppStoreScreenshotScreen) throws -> NSImage {
        let view = screen.makeView()
        view.frame = NSRect(origin: .zero, size: AppStoreScreenshotLayout.canvasSize)
        view.needsLayout = true
        view.layoutSubtreeIfNeeded()
        view.needsDisplay = true
        view.displayIfNeeded()

        guard let representation = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(AppStoreScreenshotLayout.canvasWidth),
            pixelsHigh: Int(AppStoreScreenshotLayout.canvasHeight),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw AppStoreScreenshotRendererError.couldNotCreateBitmap
        }
        representation.size = AppStoreScreenshotLayout.canvasSize
        view.cacheDisplay(in: view.bounds, to: representation)

        let image = NSImage(size: AppStoreScreenshotLayout.canvasSize)
        image.addRepresentation(representation)
        return image
    }

    private static func writePNG(_ image: NSImage, to outputURL: URL) throws {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw AppStoreScreenshotRendererError.couldNotEncodePNG
        }

        try pngData.write(to: outputURL, options: .atomic)
    }
}

enum AppStoreScreenshotRendererError: LocalizedError {
    case couldNotCreateBitmap
    case couldNotEncodePNG

    var errorDescription: String? {
        switch self {
        case .couldNotCreateBitmap:
            return "Could not create an App Store screenshot bitmap."
        case .couldNotEncodePNG:
            return "Could not encode an App Store screenshot as PNG."
        }
    }
}

struct AppStoreScreenshotCopyViewLayout {
    let viewX: CGFloat
    let viewY: CGFloat
    let iconX: CGFloat
    let iconY: CGFloat
    let iconSize: CGFloat
    let titleX: CGFloat
    let titleY: CGFloat
    let titleWidth: CGFloat
    let titleHeight: CGFloat
    let subtitleX: CGFloat
    let subtitleY: CGFloat
    let subtitleWidth: CGFloat
    let subtitleHeight: CGFloat

    var frame: NSRect {
        NSRect(x: viewX, y: viewY, width: boundsSize.width, height: boundsSize.height)
    }

    var boundsSize: NSSize {
        NSSize(
            width: max(iconX + iconSize, titleX + titleWidth, subtitleX + subtitleWidth),
            height: max(iconY + iconSize, titleY + titleHeight, subtitleY + subtitleHeight)
        )
    }

    var iconRect: NSRect {
        rect(x: iconX, y: iconY, width: iconSize, height: iconSize)
    }

    var titleRect: NSRect {
        rect(x: titleX, y: titleY, width: titleWidth, height: titleHeight)
    }

    var subtitleRect: NSRect {
        rect(x: subtitleX, y: subtitleY, width: subtitleWidth, height: subtitleHeight)
    }

    private func rect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> NSRect {
        NSRect(x: x, y: y, width: width, height: height)
    }
}

struct AppStoreScreenshotPreviewContent: View {
    let selection: AppStoreScreenshotPreviewSelection

    var body: some View {
        AppStoreScreenshotPreviewView(screen: screen)
        .aspectRatio(16.0 / 10.0, contentMode: .fit)
        .frame(width: AppStoreScreenshotLayout.previewWidth, height: AppStoreScreenshotLayout.previewHeight)
        .previewLayout(.fixed(
            width: AppStoreScreenshotLayout.previewWidth,
            height: AppStoreScreenshotLayout.previewHeight
        ))
    }

    private var screen: AppStoreScreenshotScreen {
        switch selection {
        case .measureAnything:
            return AppStoreMeasureScreenshotView.screen
        case .colors:
            return AppStoreColorsScreenshotView.screen
        case .infinity:
            return AppStoreInfinityScreenshotView.screen
        case .groups:
            return AppStoreGroupsScreenshotView.screen
        case .flipRulers:
            return AppStoreFlipScreenshotView.screen
        case .units:
            return AppStoreUnitsScreenshotView.screen
        case .preferences:
            return AppStorePreferencesScreenshotView.screen
        }
    }
}

private struct AppStoreScreenshotPreviewView: NSViewRepresentable {
    let screen: AppStoreScreenshotScreen

    func makeNSView(context: Context) -> NSView {
        screen.makeView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private struct AppStoreRulerPlacement {
    let container: NSView
    let view: RuleView
    let borderView: AppStoreRulerBorderView
    let frame: NSRect
    let boundsSize: NSSize
    let style: AppStoreRulerStyle

    init(view: RuleView, frame: NSRect, boundsSize: NSSize, style: AppStoreRulerStyle = AppStoreRulerStyle()) {
        self.container = NSView(frame: NSRect(origin: .zero, size: boundsSize))
        self.view = view
        self.borderView = AppStoreRulerBorderView(frame: NSRect(origin: .zero, size: boundsSize))
        self.frame = frame
        self.boundsSize = boundsSize
        self.style = style
        self.view.color = RulerColors(customFill: style.fillColor)
        self.container.addSubview(view)
        self.container.addSubview(borderView)
    }
}

private struct AppStoreRulerStyle {
    var fillColor: NSColor = Prefs.defaultRulerFillColor
    var opacity: CGFloat = 1
    var borderColor: NSColor?
    var borderWidth: CGFloat?
    var shadowBlur: CGFloat = 0
    var shadowOffset: NSSize = .zero
    var shadowOpacity: CGFloat = 0
}

private final class AppStoreRulerBorderView: NSView {
    var borderColor: NSColor = .clear
    var borderWidth: CGFloat = 0

    override var isFlipped: Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard borderWidth > 0 else { return }

        borderColor.setStroke()
        let path = NSBezierPath(rect: bounds.insetBy(dx: borderWidth / 2, dy: borderWidth / 2))
        path.lineWidth = borderWidth
        path.stroke()
    }
}

private struct AppStoreViewPlacement {
    let container: NSView
    let view: NSView
    let frame: NSRect
    let boundsSize: NSSize

    init(view: NSView, frame: NSRect, boundsSize: NSSize) {
        self.container = NSView(frame: NSRect(origin: .zero, size: boundsSize))
        self.view = view
        self.frame = frame
        self.boundsSize = boundsSize
        self.container.addSubview(view)
    }
}

private final class AppStoreScreenshotCopyView: NSView {
    private let title: String
    private let subtitle: String
    private let titleColor: NSColor
    private let subtitleColor: NSColor
    private let layout: AppStoreScreenshotCopyViewLayout

    override var isFlipped: Bool {
        true
    }

    init(
        title: String,
        subtitle: String,
        titleColor: NSColor,
        subtitleColor: NSColor,
        layout: AppStoreScreenshotCopyViewLayout
    ) {
        self.title = title
        self.subtitle = subtitle
        self.titleColor = titleColor
        self.subtitleColor = subtitleColor
        self.layout = layout
        super.init(frame: NSRect(origin: .zero, size: layout.boundsSize))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let icon = AppIconRenderer.image(size: 128)
        icon.draw(in: layout.iconRect)

        drawText(
            title,
            in: layout.titleRect,
            size: AppStoreScreenshotLayout.titleFontSize,
            color: titleColor,
            weight: AppStoreScreenshotLayout.titleFontWeight
        )
        drawText(
            subtitle,
            in: layout.subtitleRect,
            size: AppStoreScreenshotLayout.subtitleFontSize,
            color: subtitleColor
        )
    }

    private func drawText(
        _ text: String,
        in rect: NSRect,
        size: CGFloat,
        color: NSColor,
        weight: NSFont.Weight = AppStoreScreenshotLayout.textFontWeight
    ) {
        let style = NSMutableParagraphStyle()
        style.alignment = .left

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
            ) ?? NSFont.systemFont(ofSize: size, weight: weight)
        case .system:
            return NSFont.systemFont(ofSize: size, weight: weight)
        }
    }
}

private final class AppStoreActiveSnapshotWindow: NSWindow {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }
}

private final class AppStoreHorizontalRule: HorizontalRule {
    private let screenshotUnit: Unit
    private let screenshotZeroCorner: ZeroCorner

    override var unit: Unit {
        screenshotUnit
    }

    override var zeroCorner: ZeroCorner {
        screenshotZeroCorner
    }

    init(unit: Unit, frame: NSRect, zeroCorner: ZeroCorner = .topLeft) {
        self.screenshotUnit = unit
        self.screenshotZeroCorner = zeroCorner
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        // Force full bounds drawing because HorizontalRule uses dirtyRect to compute tick layout.
        super.draw(bounds)
    }
}

private final class AppStoreVerticalRule: VerticalRule {
    private let screenshotUnit: Unit
    private let screenshotZeroCorner: ZeroCorner

    override var unit: Unit {
        screenshotUnit
    }

    override var zeroCorner: ZeroCorner {
        screenshotZeroCorner
    }

    init(unit: Unit, frame: NSRect, zeroCorner: ZeroCorner = .topLeft) {
        self.screenshotUnit = unit
        self.screenshotZeroCorner = zeroCorner
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        // Force full bounds drawing because VerticalRule uses dirtyRect to compute tick layout.
        super.draw(bounds)
    }
}

private enum AppStoreScreenshotPlacementLayer {
    case views
    case rulers
}

private class AppStoreScreenshotCanvasView: NSView {
    private let screen: AppStoreScreenshotScreen
    private let rulerPlacements: [AppStoreRulerPlacement]
    private let viewPlacements: [AppStoreViewPlacement]
    private let copyViewPlacement: AppStoreViewPlacement
    private let placementLayers: [AppStoreScreenshotPlacementLayer]

    let palette = AppStoreScreenshotPalette()

    override var isFlipped: Bool {
        true
    }

    override var intrinsicContentSize: NSSize {
        NSSize(
            width: AppStoreScreenshotLayout.previewWidth,
            height: AppStoreScreenshotLayout.previewHeight
        )
    }

    init(
        screen: AppStoreScreenshotScreen,
        rulerPlacements: [AppStoreRulerPlacement] = [],
        viewPlacements: [AppStoreViewPlacement] = [],
        copyViewLayout: AppStoreScreenshotCopyViewLayout = AppStoreScreenshotLayout.copyViewLayout,
        placementLayers: [AppStoreScreenshotPlacementLayer] = [.views, .rulers]
    ) {
        self.screen = screen
        self.rulerPlacements = rulerPlacements
        self.viewPlacements = viewPlacements
        self.copyViewPlacement = Self.makeCopyViewPlacement(screen: screen, layout: copyViewLayout)
        self.placementLayers = placementLayers
        super.init(frame: NSRect(origin: .zero, size: AppStoreScreenshotLayout.canvasSize))
        installPlacements()
        addSubview(copyViewPlacement.container)
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

        drawCanvas()

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
        for viewPlacement in viewPlacements {
            layoutView(viewPlacement, frame: viewPlacement.frame, transform: transform)
        }
        layoutView(copyViewPlacement, frame: copyViewPlacement.frame, transform: transform)
    }

    func drawCanvas() {
        drawBackground()
    }

    func drawBackground() {
        let rect = NSRect(origin: .zero, size: AppStoreScreenshotLayout.canvasSize)

        drawVerticalGradient(
            in: rect,
            topColor: screen.backgroundColor,
            bottomColor: screen.bottomBackgroundColor
        )
    }

    func drawSampleWindow(
        _ rect: NSRect,
        shadowOpacity: CGFloat = AppStoreScreenshotLayout.sampleWindowShadowOpacity,
        shadowYOffset: CGFloat = AppStoreScreenshotLayout.sampleWindowShadowYOffset
    ) {
        let titlebarRect = sampleWindowTitlebarRect(for: rect)
        drawShadow(
            rect,
            radius: AppStoreScreenshotLayout.sampleWindowCornerRadius,
            fill: screen.backgroundColor,
            blur: AppStoreScreenshotLayout.sampleWindowShadowBlur,
            offset: NSSize(
                width: AppStoreScreenshotLayout.sampleWindowShadowXOffset,
                height: shadowYOffset
            ),
            opacity: shadowOpacity
        )
        rounded(
            rect,
            radius: AppStoreScreenshotLayout.sampleWindowCornerRadius,
            fill: palette.sampleWindowFill,
            stroke: nil
        )
        rounded(
            titlebarRect,
            radius: AppStoreScreenshotLayout.sampleWindowCornerRadius,
            fill: palette.sampleWindowTitlebar,
            stroke: nil
        )
        palette.sampleWindowTitlebar.setFill()
        NSRect(
            x: titlebarRect.minX,
            y: titlebarRect.minY + AppStoreScreenshotLayout.titlebarHeight / 2,
            width: titlebarRect.width,
            height: AppStoreScreenshotLayout.titlebarHeight / 2
        ).fill()
        drawTitlebarDivider(in: titlebarRect)
        drawTrafficLights(at: sampleWindowTrafficLightOrigin(for: rect))
    }

    func stroke(_ rect: NSRect, color: NSColor, width: CGFloat) {
        stroke(rect, color: color, width: width, radius: 0)
    }

    func stroke(_ rect: NSRect, color: NSColor, width: CGFloat, radius: CGFloat) {
        color.setStroke()
        let insetRect = rect.insetBy(dx: width / 2, dy: width / 2)
        let path = radius > 0
            ? NSBezierPath(roundedRect: insetRect, xRadius: radius, yRadius: radius)
            : NSBezierPath(rect: insetRect)
        path.lineWidth = width
        path.stroke()
    }

    private static func makeCopyViewPlacement(
        screen: AppStoreScreenshotScreen,
        layout: AppStoreScreenshotCopyViewLayout
    ) -> AppStoreViewPlacement {
        let palette = AppStoreScreenshotPalette()
        let copyView = AppStoreScreenshotCopyView(
            title: screen.title,
            subtitle: screen.subtitle,
            titleColor: screen.titleColor(in: palette),
            subtitleColor: screen.subtitleColor(in: palette),
            layout: layout
        )
        return AppStoreViewPlacement(
            view: copyView,
            frame: layout.frame,
            boundsSize: layout.boundsSize
        )
    }

    private func installPlacements() {
        for placementLayer in placementLayers {
            switch placementLayer {
            case .views:
                installViewPlacements()
            case .rulers:
                installRulerPlacements()
            }
        }
    }

    private func installViewPlacements() {
        for viewPlacement in viewPlacements {
            addSubview(viewPlacement.container)
        }
    }

    private func installRulerPlacements() {
        for rulerPlacement in rulerPlacements {
            configureRuler(rulerPlacement.view)
            addSubview(rulerPlacement.container)
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
        rulerPlacement.container.wantsLayer = true
        if let layer = rulerPlacement.container.layer {
            layer.backgroundColor = NSColor.clear.cgColor
            layer.shadowColor = NSColor.black.cgColor
            layer.shadowRadius = rulerPlacement.style.shadowBlur * transform.scale
            layer.shadowOffset = CGSize(
                width: rulerPlacement.style.shadowOffset.width * transform.scale,
                height: rulerPlacement.style.shadowOffset.height * transform.scale
            )
            layer.shadowOpacity = Float(rulerPlacement.style.shadowOpacity)
            layer.shadowPath = CGPath(
                rect: CGRect(origin: .zero, size: rulerPlacement.container.frame.size),
                transform: nil
            )
        }
        rulerPlacement.container.setBoundsSize(rulerPlacement.boundsSize)
        rulerPlacement.view.frame = NSRect(origin: .zero, size: rulerPlacement.boundsSize)
        rulerPlacement.view.setBoundsSize(rulerPlacement.boundsSize)
        rulerPlacement.view.alphaValue = rulerPlacement.style.opacity
        rulerPlacement.view.needsDisplay = true
        rulerPlacement.borderView.frame = NSRect(origin: .zero, size: rulerPlacement.boundsSize)
        rulerPlacement.borderView.alphaValue = rulerPlacement.style.opacity
        rulerPlacement.borderView.borderColor = rulerPlacement.style.borderColor ?? palette.rulerBorder
        rulerPlacement.borderView.borderWidth = rulerPlacement.style.borderWidth ?? AppStoreScreenshotLayout.rulerBorderWidth
        rulerPlacement.borderView.needsDisplay = true
    }

    private func layoutView(
        _ viewPlacement: AppStoreViewPlacement,
        frame: NSRect,
        transform: (origin: CGPoint, scale: CGFloat)
    ) {
        viewPlacement.container.frame = NSRect(
            x: transform.origin.x + frame.minX * transform.scale,
            y: transform.origin.y + frame.minY * transform.scale,
            width: frame.width * transform.scale,
            height: frame.height * transform.scale
        )
        viewPlacement.container.setBoundsSize(viewPlacement.boundsSize)
        viewPlacement.view.frame = NSRect(origin: .zero, size: viewPlacement.boundsSize)
        viewPlacement.view.setBoundsSize(viewPlacement.boundsSize)
        viewPlacement.view.needsLayout = true
        viewPlacement.view.layoutSubtreeIfNeeded()
        viewPlacement.view.needsDisplay = true
    }

    private func drawVerticalGradient(in rect: NSRect, topColor: NSColor, bottomColor: NSColor) {
        guard let context = NSGraphicsContext.current?.cgContext,
              let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [topColor.cgColor, bottomColor.cgColor] as CFArray,
                locations: [0, 1]
              ) else {
            topColor.setFill()
            rect.fill()
            return
        }

        context.saveGState()
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: rect.midX, y: rect.minY),
            end: CGPoint(x: rect.midX, y: rect.maxY),
            options: []
        )
        context.restoreGState()
    }

    private func configureRuler(_ view: RuleView) {
        view.showMouseTick = false
    }

    private func drawTitlebarDivider(in titlebarRect: NSRect) {
        palette.sampleWindowTitlebarBorder.setFill()
        NSRect(
            x: titlebarRect.minX,
            y: titlebarRect.maxY - AppStoreScreenshotLayout.sampleWindowBorderWidth,
            width: titlebarRect.width,
            height: AppStoreScreenshotLayout.sampleWindowBorderWidth
        ).fill()
    }

    private func sampleWindowTitlebarRect(for rect: NSRect) -> NSRect {
        NSRect(
            x: rect.minX - AppStoreScreenshotLayout.titlebarHorizontalOutset,
            y: rect.minY,
            width: rect.width + (AppStoreScreenshotLayout.titlebarHorizontalOutset * 2),
            height: AppStoreScreenshotLayout.titlebarHeight
        )
    }

    private func sampleWindowTrafficLightOrigin(for rect: NSRect) -> CGPoint {
        CGPoint(
            x: rect.minX + AppStoreScreenshotLayout.trafficLightXPadding,
            y: rect.minY + AppStoreScreenshotLayout.trafficLightYPadding
        )
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

    private func strokeOval(_ rect: NSRect, color: NSColor, width: CGFloat) {
        color.setStroke()
        let path = NSBezierPath(ovalIn: rect.insetBy(dx: width / 2, dy: width / 2))
        path.lineWidth = width
        path.stroke()
    }
}

private extension AppStoreMeasureScreenshotLayout {
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

    static var groupedRulerRect: NSRect {
        horizontalRulerRect.union(verticalRulerRect)
    }

    static var groupedRulerBoundsSize: NSSize {
        NSSize(
            width: groupedRulerRect.width / rulerScale,
            height: groupedRulerRect.height / rulerScale
        )
    }

    static var sampleWindowRect: NSRect {
        NSRect(
            x: horizontalRulerRect.minX,
            y: verticalRulerRect.minY,
            width: sampleWindowWidth,
            height: sampleWindowHeight
        )
    }

    static var sampleWindowContentRect: NSRect {
        NSRect(
            x: sampleWindowRect.minX,
            y: sampleWindowRect.minY + AppStoreScreenshotLayout.titlebarHeight,
            width: sampleWindowRect.width,
            height: sampleWindowRect.height - AppStoreScreenshotLayout.titlebarHeight
        )
    }

    static var box1Rect: NSRect {
        NSRect(
            x: sampleWindowContentRect.minX + boxGutter,
            y: sampleWindowContentRect.minY + boxGutter,
            width: box1Width,
            height: sampleWindowContentRect.height - (boxGutter * 2)
        )
    }

    static var box2Rect: NSRect {
        let x = box1Rect.maxX + boxGutter
        return NSRect(
            x: x,
            y: sampleWindowContentRect.minY + boxGutter,
            width: sampleWindowContentRect.maxX - x - boxGutter,
            height: box2Height
        )
    }

    static var box3Rect: NSRect {
        let y = box2Rect.maxY + boxGutter
        return NSRect(
            x: box2Rect.minX,
            y: y,
            width: box2Rect.width,
            height: sampleWindowContentRect.maxY - y - boxGutter
        )
    }
}

private final class AppStoreMeasureScreenshotView: AppStoreScreenshotCanvasView {
    private typealias Layout = AppStoreMeasureScreenshotLayout

    static let screen = AppStoreScreenshotScreen(
        title: Layout.title,
        subtitle: Layout.subtitle,
        previewName: Layout.previewName,
        outputFilename: Layout.outputFilename,
        backgroundColor: Layout.backgroundColor,
        bottomBackgroundColor: Layout.bottomBackgroundColor,
        usesDarkCopy: false,
        makeView: { AppStoreMeasureScreenshotView() }
    )

    init() {
        super.init(
            screen: Self.screen,
            viewPlacements: [Self.makeRulerWindowPlacement()]
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawCanvas() {
        drawBackground()
        drawSampleWindow(Layout.sampleWindowRect)
        drawMeasureBoxes()
    }

    private static func makeRulerWindowPlacement() -> AppStoreViewPlacement {
        let horizontalBoundsSize = NSSize(
            width: Layout.horizontalRulerLength / Layout.rulerScale,
            height: Ruler.thickness
        )
        let verticalBoundsSize = NSSize(
            width: Ruler.thickness,
            height: Layout.verticalRulerLength / Layout.rulerScale
        )
        let boundsSize = Layout.groupedRulerBoundsSize
        let horizontalRule = AppStoreHorizontalRule(
            unit: .pixels,
            frame: NSRect(origin: .zero, size: horizontalBoundsSize)
        )
        let verticalRule = AppStoreVerticalRule(
            unit: .pixels,
            frame: NSRect(origin: .zero, size: verticalBoundsSize)
        )
        let color = RulerColors(customFill: Prefs.defaultRulerFillColor)
        let rulerWindowView = RulerContentView(
            frame: NSRect(origin: .zero, size: boundsSize),
            horizontalRule: horizontalRule,
            verticalRule: verticalRule
        )

        horizontalRule.color = color
        verticalRule.color = color
        horizontalRule.showMouseTick = false
        verticalRule.showMouseTick = false
        rulerWindowView.color = color
        rulerWindowView.zeroCorner = .topLeft
        rulerWindowView.needsLayout = true
        rulerWindowView.layoutSubtreeIfNeeded()

        return AppStoreViewPlacement(
            view: rulerWindowView,
            frame: Layout.groupedRulerRect,
            boundsSize: boundsSize
        )
    }

    private func drawMeasureBoxes() {
        for rect in [
            Layout.box1Rect,
            Layout.box2Rect,
            Layout.box3Rect,
        ] {
            stroke(
                rect,
                color: Layout.boxBorderColor,
                width: Layout.boxBorderWidth,
                radius: Layout.boxBorderRadius
            )
        }
    }
}

private extension AppStoreUnitsScreenshotLayout {
    static var scaledRulerThickness: CGFloat {
        Ruler.thickness * rulerScale
    }

    static func rulerRect(index: Int) -> NSRect {
        NSRect(
            x: rulerX + CGFloat(index) * rulerXOffset,
            y: firstRulerY + CGFloat(index) * rulerVerticalSpacing,
            width: rulerLength,
            height: scaledRulerThickness
        )
    }
}

private final class AppStoreUnitsScreenshotView: AppStoreScreenshotCanvasView {
    private typealias Layout = AppStoreUnitsScreenshotLayout

    static let screen = AppStoreScreenshotScreen(
        title: Layout.title,
        subtitle: Layout.subtitle,
        previewName: Layout.previewName,
        outputFilename: Layout.outputFilename,
        backgroundColor: Layout.backgroundColor,
        bottomBackgroundColor: Layout.bottomBackgroundColor,
        usesDarkCopy: false,
        makeView: { AppStoreUnitsScreenshotView() }
    )

    init() {
        super.init(
            screen: Self.screen,
            rulerPlacements: Self.makeRulerPlacements()
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func makeRulerPlacements() -> [AppStoreRulerPlacement] {
        let rulerBoundsSize = NSSize(
            width: Layout.rulerLength / Layout.rulerScale,
            height: Ruler.thickness
        )
        return [Unit.pixels, .millimeters, .inches].enumerated().map { index, unit in
            AppStoreRulerPlacement(
                view: AppStoreHorizontalRule(unit: unit, frame: NSRect(origin: .zero, size: rulerBoundsSize)),
                frame: Layout.rulerRect(index: index),
                boundsSize: rulerBoundsSize
            )
        }
    }
}

private extension AppStoreColorsScreenshotLayout {
    static var rulerScale: CGFloat {
        scaledRulerThickness / Ruler.thickness
    }

    private static var availableRulerWidth: CGFloat {
        lastRulerEnd - firstRulerStart - (CGFloat(rulerCount - 1) * rulerGap)
    }

    static var scaledRulerThickness: CGFloat {
        availableRulerWidth / CGFloat(rulerCount)
    }

    static func rulerRect(index: Int) -> NSRect {
        let top = rulerTopY(index: index)
        return NSRect(
            x: firstRulerStart + CGFloat(index) * (scaledRulerThickness + rulerGap),
            y: top,
            width: scaledRulerThickness,
            height: rulerOffscreenBottom - top
        )
    }

    static func rulerTopY(index: Int) -> CGFloat {
        guard rulerCount > 1 else { return rulerArcTop }

        let midpoint = CGFloat(rulerCount - 1) / 2
        let distanceFromCenter = abs(CGFloat(index) - midpoint) / midpoint
        let curvedDistance = pow(distanceFromCenter, rulerCurvature)
        return rulerArcTop + (rulerArcBottom - rulerArcTop) * curvedDistance
    }
}

private final class AppStoreColorsScreenshotView: AppStoreScreenshotCanvasView {
    private typealias Layout = AppStoreColorsScreenshotLayout

    static let screen = AppStoreScreenshotScreen(
        title: Layout.title,
        subtitle: Layout.subtitle,
        previewName: Layout.previewName,
        outputFilename: Layout.outputFilename,
        backgroundColor: Layout.backgroundColor,
        bottomBackgroundColor: Layout.bottomBackgroundColor,
        usesDarkCopy: true,
        makeView: { AppStoreColorsScreenshotView() }
    )

    init() {
        super.init(
            screen: Self.screen,
            rulerPlacements: Self.makeRulerPlacements()
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func makeRulerPlacements() -> [AppStoreRulerPlacement] {
        (0..<Layout.rulerCount).map { index in
            let fillColor = Layout.rulerColors[index % Layout.rulerColors.count]
            let frame = Layout.rulerRect(index: index)
            let rulerBoundsSize = NSSize(
                width: Ruler.thickness,
                height: frame.height / Layout.rulerScale
            )
            let style = AppStoreRulerStyle(
                fillColor: fillColor,
                opacity: Layout.rulerOpacity,
                borderColor: fillColor.shadow(withLevel: 0.25),
                borderWidth: Layout.rulerBorderWidth,
                shadowBlur: Layout.rulerShadowBlur,
                shadowOffset: NSSize(
                    width: Layout.rulerShadowXOffset,
                    height: Layout.rulerShadowYOffset
                ),
                shadowOpacity: Layout.rulerShadowOpacity
            )
            return AppStoreRulerPlacement(
                view: AppStoreVerticalRule(unit: .pixels, frame: NSRect(origin: .zero, size: rulerBoundsSize)),
                frame: frame,
                boundsSize: rulerBoundsSize,
                style: style
            )
        }
    }
}

private extension AppStoreInfinityScreenshotLayout {
    static var clampedOverlap: CGFloat {
        min(max(overlap, 0), 1)
    }

    static var minimumRulerLength: CGFloat {
        Ruler.thickness
    }

    static func zeroCorner(index: Int) -> ZeroCorner {
        index.isMultiple(of: 2) ? .bottomLeft : .bottomRight
    }

    static func rulerScale(index: Int) -> CGFloat {
        guard steps > 1 else { return startScale }

        let fraction = CGFloat(index) / CGFloat(steps - 1)
        return startScale + (endScale - startScale) * fraction
    }

    static func horizontalLength(index: Int) -> CGFloat {
        max(minimumRulerLength, startLength - CGFloat(index) * decrementLength)
    }

    static func verticalLength(index: Int) -> CGFloat {
        max(minimumRulerLength, startHeight - CGFloat(index) * decrementHeight)
    }

    static func opacity(index: Int) -> CGFloat {
        guard steps > 1 else { return 1 }

        let fraction = CGFloat(index) / CGFloat(steps - 1)
        return 1 + (endOpacity - 1) * fraction
    }

    static func rulerFrame(index: Int, size: NSSize) -> NSRect {
        let x: CGFloat
        switch zeroCorner(index: index) {
        case .bottomLeft:
            x = sideInset(index: index)
        case .bottomRight:
            x = AppStoreScreenshotLayout.canvasWidth - sideInset(index: index) - size.width
        case .topLeft, .topRight:
            x = sideInset(index: index)
        }

        return NSRect(
            x: x,
            y: AppStoreScreenshotLayout.canvasHeight - bottomInset(index: index) - size.height,
            width: size.width,
            height: size.height
        )
    }

    private static func sideInset(index: Int) -> CGFloat {
        let pairIndex = index / 2
        guard pairIndex > 0 else { return inset }

        let revealDistance = (1...pairIndex).reduce(CGFloat.zero) { distance, pair in
            distance + rulerRevealDistance(index: pair * 2)
        }
        return inset + revealDistance
    }

    private static func bottomInset(index: Int) -> CGFloat {
        guard index > 0 else { return inset }

        let revealDistance = (1...index).reduce(CGFloat.zero) { distance, rulerIndex in
            distance + rulerRevealDistance(index: rulerIndex) / 2
        }
        return inset + revealDistance
    }

    private static func rulerRevealDistance(index: Int) -> CGFloat {
        Ruler.thickness * rulerScale(index: index) * (1 - clampedOverlap)
    }
}

private final class AppStoreInfinityScreenshotView: AppStoreScreenshotCanvasView {
    private typealias Layout = AppStoreInfinityScreenshotLayout

    static let screen = AppStoreScreenshotScreen(
        title: Layout.title,
        subtitle: Layout.subtitle,
        previewName: Layout.previewName,
        outputFilename: Layout.outputFilename,
        backgroundColor: Layout.backgroundColor,
        bottomBackgroundColor: Layout.bottomBackgroundColor,
        usesDarkCopy: true,
        makeView: { AppStoreInfinityScreenshotView() }
    )

    init() {
        super.init(
            screen: Self.screen,
            viewPlacements: Self.makeRulerWindowPlacements()
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func makeRulerWindowPlacements() -> [AppStoreViewPlacement] {
        (0..<Layout.steps).reversed().map { index in
            makeRulerWindowPlacement(index: index)
        }
    }

    private static func makeRulerWindowPlacement(index: Int) -> AppStoreViewPlacement {
        let scale = Layout.rulerScale(index: index)
        let zeroCorner = Layout.zeroCorner(index: index)
        let horizontalBoundsSize = NSSize(
            width: Layout.horizontalLength(index: index) / scale,
            height: Ruler.thickness
        )
        let verticalBoundsSize = NSSize(
            width: Ruler.thickness,
            height: Layout.verticalLength(index: index) / scale
        )
        let boundsSize = RulerWindowLayout.layout(
            horizontalLength: horizontalBoundsSize.width,
            verticalLength: verticalBoundsSize.height,
            zeroPoint: .zero,
            zeroCorner: zeroCorner
        ).groupFrame.size
        let frameSize = NSSize(
            width: boundsSize.width * scale,
            height: boundsSize.height * scale
        )
        let horizontalRule = AppStoreHorizontalRule(
            unit: .pixels,
            frame: NSRect(origin: .zero, size: horizontalBoundsSize),
            zeroCorner: zeroCorner
        )
        let verticalRule = AppStoreVerticalRule(
            unit: .pixels,
            frame: NSRect(origin: .zero, size: verticalBoundsSize),
            zeroCorner: zeroCorner
        )
        let color = RulerColors(customFill: Layout.rulerColor)
        let rulerWindowView = RulerContentView(
            frame: NSRect(origin: .zero, size: boundsSize),
            horizontalRule: horizontalRule,
            verticalRule: verticalRule
        )

        horizontalRule.color = color
        verticalRule.color = color
        horizontalRule.showMouseTick = false
        verticalRule.showMouseTick = false
        rulerWindowView.color = color
        rulerWindowView.alphaValue = 1
        rulerWindowView.zeroCorner = zeroCorner
        rulerWindowView.needsLayout = true
        rulerWindowView.layoutSubtreeIfNeeded()

        return AppStoreViewPlacement(
            view: rulerWindowView,
            frame: Layout.rulerFrame(index: index, size: frameSize),
            boundsSize: boundsSize
        )
    }
}

private extension AppStoreGroupsScreenshotLayout {
    static var scaledRulerThickness: CGFloat {
        Ruler.thickness * rulerScale
    }

    static var ungroupedHorizontalRulerRect: NSRect {
        NSRect(
            x: ungroupedHorizontalRulerX,
            y: ungroupedHorizontalRulerY,
            width: ungroupedHorizontalRulerLength,
            height: scaledRulerThickness
        )
    }

    static var ungroupedVerticalRulerRect: NSRect {
        NSRect(
            x: ungroupedVerticalRulerX,
            y: ungroupedVerticalRulerY,
            width: scaledRulerThickness,
            height: ungroupedVerticalRulerLength
        )
    }

    static var groupedHorizontalRulerRect: NSRect {
        NSRect(
            x: groupedRulerX + scaledRulerThickness - rulerScale,
            y: groupedRulerY,
            width: groupedRulerLength,
            height: scaledRulerThickness
        )
    }

    static var groupedVerticalRulerRect: NSRect {
        NSRect(
            x: groupedRulerX,
            y: groupedRulerY + scaledRulerThickness - rulerScale,
            width: scaledRulerThickness,
            height: groupedRulerWidth
        )
    }

    static var groupedRulerRect: NSRect {
        groupedHorizontalRulerRect.union(groupedVerticalRulerRect)
    }

    static var horizontalBoundsSize: NSSize {
        NSSize(width: groupedRulerLength / rulerScale, height: Ruler.thickness)
    }

    static var verticalBoundsSize: NSSize {
        NSSize(width: Ruler.thickness, height: groupedRulerWidth / rulerScale)
    }

    static var ungroupedHorizontalBoundsSize: NSSize {
        NSSize(width: ungroupedHorizontalRulerLength / rulerScale, height: Ruler.thickness)
    }

    static var ungroupedVerticalBoundsSize: NSSize {
        NSSize(width: Ruler.thickness, height: ungroupedVerticalRulerLength / rulerScale)
    }

    static var groupedBoundsSize: NSSize {
        NSSize(
            width: groupedRulerRect.width / rulerScale,
            height: groupedRulerRect.height / rulerScale
        )
    }

    static var copyViewLayout: AppStoreScreenshotCopyViewLayout {
        AppStoreScreenshotCopyViewLayout(
            viewX: copyViewX,
            viewY: copyViewY,
            iconX: copyIconX,
            iconY: copyIconY,
            iconSize: copyIconSize,
            titleX: copyTitleX,
            titleY: copyTitleY,
            titleWidth: copyTitleWidth,
            titleHeight: copyTitleHeight,
            subtitleX: copySubtitleX,
            subtitleY: copySubtitleY,
            subtitleWidth: copySubtitleWidth,
            subtitleHeight: copySubtitleHeight
        )
    }
}

private final class AppStoreGroupsScreenshotView: AppStoreScreenshotCanvasView {
    private typealias Layout = AppStoreGroupsScreenshotLayout

    static let screen = AppStoreScreenshotScreen(
        title: Layout.title,
        subtitle: Layout.subtitle,
        previewName: Layout.previewName,
        outputFilename: Layout.outputFilename,
        backgroundColor: Layout.backgroundColor,
        bottomBackgroundColor: Layout.bottomBackgroundColor,
        usesDarkCopy: true,
        makeView: { AppStoreGroupsScreenshotView() }
    )

    init() {
        super.init(
            screen: Self.screen,
            rulerPlacements: Self.makeRulerPlacements(),
            viewPlacements: [Self.makeRulerWindowPlacement()],
            copyViewLayout: Layout.copyViewLayout,
            placementLayers: [.rulers, .views]
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func makeRulerPlacements() -> [AppStoreRulerPlacement] {
        let style = AppStoreRulerStyle(
            fillColor: Layout.rulerColor,
            opacity: Layout.rulerOpacity
        )
        return [
            AppStoreRulerPlacement(
                view: AppStoreVerticalRule(
                    unit: .pixels,
                    frame: NSRect(origin: .zero, size: Layout.ungroupedVerticalBoundsSize)
                ),
                frame: Layout.ungroupedVerticalRulerRect,
                boundsSize: Layout.ungroupedVerticalBoundsSize,
                style: style
            ),
            AppStoreRulerPlacement(
                view: AppStoreHorizontalRule(
                    unit: .pixels,
                    frame: NSRect(origin: .zero, size: Layout.ungroupedHorizontalBoundsSize)
                ),
                frame: Layout.ungroupedHorizontalRulerRect,
                boundsSize: Layout.ungroupedHorizontalBoundsSize,
                style: style
            ),
        ]
    }

    private static func makeRulerWindowPlacement() -> AppStoreViewPlacement {
        let horizontalBoundsSize = Layout.horizontalBoundsSize
        let verticalBoundsSize = Layout.verticalBoundsSize
        let boundsSize = Layout.groupedBoundsSize
        let horizontalRule = AppStoreHorizontalRule(
            unit: .pixels,
            frame: NSRect(origin: .zero, size: horizontalBoundsSize)
        )
        let verticalRule = AppStoreVerticalRule(
            unit: .pixels,
            frame: NSRect(origin: .zero, size: verticalBoundsSize)
        )
        let color = RulerColors(customFill: Layout.rulerColor)
        let rulerWindowView = RulerContentView(
            frame: NSRect(origin: .zero, size: boundsSize),
            horizontalRule: horizontalRule,
            verticalRule: verticalRule
        )

        horizontalRule.color = color
        verticalRule.color = color
        horizontalRule.showMouseTick = false
        verticalRule.showMouseTick = false
        rulerWindowView.color = color
        rulerWindowView.alphaValue = Layout.rulerOpacity
        rulerWindowView.zeroCorner = .topLeft
        rulerWindowView.needsLayout = true
        rulerWindowView.layoutSubtreeIfNeeded()

        return AppStoreViewPlacement(
            view: rulerWindowView,
            frame: Layout.groupedRulerRect,
            boundsSize: boundsSize
        )
    }
}

private extension AppStoreFlipScreenshotLayout {
    static var scaledRulerThickness: CGFloat {
        Ruler.thickness * rulerScale
    }

    static var overlap: CGFloat {
        rulerScale
    }

    static var outerLeadingZeroInset: CGFloat {
        outerGap + scaledRulerThickness
    }

    static var outerTrailingZeroInset: CGFloat {
        outerGap + scaledRulerThickness - overlap
    }

    static var innerLeadingZeroInset: CGFloat {
        innerRulerEdgeInset + scaledRulerThickness
    }

    static var innerTrailingZeroInset: CGFloat {
        innerRulerEdgeInset + scaledRulerThickness - overlap
    }

    static var innerRulerEdgeInset: CGFloat {
        outerGap + scaledRulerThickness + innerGap
    }

    static var leadingOuterVerticalMaxX: CGFloat {
        outerLeadingZeroInset
    }

    static var trailingOuterVerticalMinX: CGFloat {
        AppStoreScreenshotLayout.canvasWidth - outerTrailingZeroInset - overlap
    }

    static var leadingInnerVerticalMaxX: CGFloat {
        innerLeadingZeroInset
    }

    static var trailingInnerVerticalMinX: CGFloat {
        AppStoreScreenshotLayout.canvasWidth - innerTrailingZeroInset - overlap
    }

    static func horizontalLength(
        from minX: CGFloat,
        stoppingBefore verticalMinX: CGFloat
    ) -> CGFloat {
        verticalMinX - innerGap - minX
    }

    static func horizontalLength(
        to maxX: CGFloat,
        stoppingAfter verticalMaxX: CGFloat
    ) -> CGFloat {
        maxX - innerGap - verticalMaxX
    }

    static var outerVerticalLength: CGFloat {
        verticalLength(forEdgeInset: outerGap)
    }

    static var innerVerticalLength: CGFloat {
        verticalLength(forEdgeInset: innerRulerEdgeInset)
    }

    static func verticalLength(forEdgeInset edgeInset: CGFloat) -> CGFloat {
        AppStoreScreenshotLayout.canvasHeight
            - (edgeInset * 2)
            - scaledRulerThickness
            + overlap
    }

    static var copyViewLayout: AppStoreScreenshotCopyViewLayout {
        AppStoreScreenshotLayout.copyViewLayout(viewX: copyViewX, viewY: copyViewY)
    }

    static var rulerSets: [AppStoreFlipRulerSet] {
        let layoutSize = AppStoreScreenshotLayout.canvasSize
        return [
            AppStoreFlipRulerSet(
                zeroCorner: .topLeft,
                x: outerLeadingZeroInset,
                y: outerLeadingZeroInset,
                horizontalLength: horizontalLength(
                    from: outerLeadingZeroInset - overlap,
                    stoppingBefore: trailingOuterVerticalMinX
                ),
                verticalLength: outerVerticalLength,
                fillColor: topLeftRulerColor,
                layoutSize: layoutSize
            ),
            AppStoreFlipRulerSet(
                zeroCorner: .topRight,
                x: innerTrailingZeroInset,
                y: innerLeadingZeroInset,
                horizontalLength: horizontalLength(
                    to: AppStoreScreenshotLayout.canvasWidth - innerTrailingZeroInset,
                    stoppingAfter: leadingInnerVerticalMaxX
                ),
                verticalLength: innerVerticalLength,
                fillColor: topRightRulerColor,
                layoutSize: layoutSize
            ),
            AppStoreFlipRulerSet(
                zeroCorner: .bottomLeft,
                x: innerLeadingZeroInset,
                y: innerTrailingZeroInset,
                horizontalLength: horizontalLength(
                    from: innerLeadingZeroInset - overlap,
                    stoppingBefore: trailingInnerVerticalMinX
                ),
                verticalLength: innerVerticalLength,
                fillColor: bottomLeftRulerColor,
                layoutSize: layoutSize
            ),
            AppStoreFlipRulerSet(
                zeroCorner: .bottomRight,
                x: outerTrailingZeroInset,
                y: outerTrailingZeroInset,
                horizontalLength: horizontalLength(
                    to: AppStoreScreenshotLayout.canvasWidth - outerTrailingZeroInset,
                    stoppingAfter: leadingOuterVerticalMaxX
                ),
                verticalLength: outerVerticalLength,
                fillColor: bottomRightRulerColor,
                layoutSize: layoutSize
            ),
        ]
    }

    static func horizontalBoundsSize(for rulerSet: AppStoreFlipRulerSet) -> NSSize {
        NSSize(
            width: rulerSet.horizontalLength / rulerScale,
            height: Ruler.thickness
        )
    }

    static func verticalBoundsSize(for rulerSet: AppStoreFlipRulerSet) -> NSSize {
        NSSize(
            width: Ruler.thickness,
            height: rulerSet.verticalLength / rulerScale
        )
    }

    static func groupedBoundsSize(for rulerSet: AppStoreFlipRulerSet) -> NSSize {
        let groupedFrame = rulerSet.groupedFrame(rulerScale: rulerScale)
        return NSSize(
            width: groupedFrame.width / rulerScale,
            height: groupedFrame.height / rulerScale
        )
    }
}

private final class AppStoreFlipScreenshotView: AppStoreScreenshotCanvasView {
    private typealias Layout = AppStoreFlipScreenshotLayout

    static let screen = AppStoreScreenshotScreen(
        title: Layout.title,
        subtitle: Layout.subtitle,
        previewName: Layout.previewName,
        outputFilename: Layout.outputFilename,
        backgroundColor: Layout.backgroundColor,
        bottomBackgroundColor: Layout.bottomBackgroundColor,
        usesDarkCopy: false,
        makeView: { AppStoreFlipScreenshotView() }
    )

    init() {
        super.init(
            screen: Self.screen,
            viewPlacements: Self.makeRulerWindowPlacements(),
            copyViewLayout: Layout.copyViewLayout
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func makeRulerWindowPlacements() -> [AppStoreViewPlacement] {
        Layout.rulerSets.map { rulerSet in
            let horizontalBoundsSize = Layout.horizontalBoundsSize(for: rulerSet)
            let verticalBoundsSize = Layout.verticalBoundsSize(for: rulerSet)
            let boundsSize = Layout.groupedBoundsSize(for: rulerSet)
            let horizontalRule = AppStoreHorizontalRule(
                unit: .pixels,
                frame: NSRect(origin: .zero, size: horizontalBoundsSize),
                zeroCorner: rulerSet.zeroCorner
            )
            let verticalRule = AppStoreVerticalRule(
                unit: .pixels,
                frame: NSRect(origin: .zero, size: verticalBoundsSize),
                zeroCorner: rulerSet.zeroCorner
            )
            let color = RulerColors(customFill: rulerSet.fillColor)
            let rulerWindowView = RulerContentView(
                frame: NSRect(origin: .zero, size: boundsSize),
                horizontalRule: horizontalRule,
                verticalRule: verticalRule
            )

            horizontalRule.color = color
            verticalRule.color = color
            horizontalRule.showMouseTick = false
            verticalRule.showMouseTick = false
            rulerWindowView.color = color
            rulerWindowView.zeroCorner = rulerSet.zeroCorner
            rulerWindowView.needsLayout = true
            rulerWindowView.layoutSubtreeIfNeeded()

            return AppStoreViewPlacement(
                view: rulerWindowView,
                frame: rulerSet.groupedFrame(rulerScale: Layout.rulerScale),
                boundsSize: boundsSize
            )
        }
    }
}

private extension AppStorePreferencesScreenshotLayout {
    static var foregroundOpacityPercent: Int {
        Int((rulerOpacity * 100).rounded())
    }

    static var scaledRulerThickness: CGFloat {
        Ruler.thickness * rulerScale
    }

    static var verticalRulerRect: NSRect {
        NSRect(
            x: verticalRulerX,
            y: verticalRulerY,
            width: scaledRulerThickness,
            height: verticalRulerLength
        )
    }

    static var horizontalRulerRect: NSRect {
        NSRect(
            x: horizontalRulerX,
            y: horizontalRulerY,
            width: horizontalRulerLength,
            height: scaledRulerThickness
        )
    }

    static var preferencesContentSize: NSSize {
        NSSize(width: preferencesContentWidth, height: preferencesContentHeight)
    }

    static var preferencesWindowRect: NSRect {
        NSRect(
            x: preferencesWindowX,
            y: preferencesWindowY,
            width: preferencesContentWidth * preferencesWindowScale,
            height: AppStoreScreenshotLayout.titlebarHeight + preferencesContentHeight * preferencesWindowScale
        )
    }

    static var preferencesContentRect: NSRect {
        NSRect(
            x: preferencesWindowX,
            y: preferencesWindowY + AppStoreScreenshotLayout.titlebarHeight,
            width: preferencesContentWidth * preferencesWindowScale,
            height: preferencesContentHeight * preferencesWindowScale
        )
    }
}

private final class AppStorePreferencesScreenshotView: AppStoreScreenshotCanvasView {
    private typealias Layout = AppStorePreferencesScreenshotLayout

    static let screen = AppStoreScreenshotScreen(
        title: Layout.title,
        subtitle: Layout.subtitle,
        previewName: Layout.previewName,
        outputFilename: Layout.outputFilename,
        backgroundColor: Layout.backgroundColor,
        bottomBackgroundColor: Layout.bottomBackgroundColor,
        usesDarkCopy: false,
        makeView: { AppStorePreferencesScreenshotView() }
    )

    private let preferencesController: PreferencesController

    init() {
        let preferencesController = Self.makePreferencesController()
        self.preferencesController = preferencesController
        super.init(
            screen: Self.screen,
            rulerPlacements: Self.makeRulerPlacements(),
            viewPlacements: Self.makeViewPlacements(preferencesController: preferencesController)
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawCanvas() {
        drawBackground()
        drawSampleWindow(
            Layout.preferencesWindowRect,
            shadowOpacity: Layout.preferencesWindowShadowOpacity,
            shadowYOffset: Layout.preferencesWindowShadowYOffset
        )
    }

    private static func makeRulerPlacements() -> [AppStoreRulerPlacement] {
        let horizontalBoundsSize = NSSize(
            width: Layout.horizontalRulerLength / Layout.rulerScale,
            height: Ruler.thickness
        )
        let verticalBoundsSize = NSSize(
            width: Ruler.thickness,
            height: Layout.verticalRulerLength / Layout.rulerScale
        )
        return [
            AppStoreRulerPlacement(
                view: AppStoreVerticalRule(unit: .pixels, frame: NSRect(origin: .zero, size: verticalBoundsSize)),
                frame: Layout.verticalRulerRect,
                boundsSize: verticalBoundsSize,
                style: AppStoreRulerStyle(opacity: Layout.rulerOpacity)
            ),
            AppStoreRulerPlacement(
                view: AppStoreHorizontalRule(unit: .pixels, frame: NSRect(origin: .zero, size: horizontalBoundsSize)),
                frame: Layout.horizontalRulerRect,
                boundsSize: horizontalBoundsSize,
                style: AppStoreRulerStyle(opacity: Layout.rulerOpacity)
            ),
        ]
    }

    private static func makePreferencesController() -> PreferencesController {
        let controller = PreferencesController()
        controller.loadWindow()
        controller.updateView()
        controller.window?.contentView?.layoutSubtreeIfNeeded()
        return controller
    }

    private static func makeViewPlacements(preferencesController: PreferencesController) -> [AppStoreViewPlacement] {
        guard let preferencesView = preferencesController.window?.contentView else {
            return []
        }
        let originalForegroundOpacity = prefs.foregroundOpacity
        let originalBackgroundOpacity = prefs.backgroundOpacity
        let originalFloatRulers = prefs.floatRulers
        let originalGroupRulers = prefs.groupRulers
        let originalRulerShadow = prefs.rulerShadow
        prefs.foregroundOpacity = Layout.foregroundOpacityPercent
        prefs.backgroundOpacity = Layout.backgroundOpacityPercent
        prefs.floatRulers = Layout.floatRulers
        prefs.groupRulers = Layout.groupRulers
        prefs.rulerShadow = Layout.rulerShadow
        preferencesController.updateView()
        preferencesController.window?.contentView?.layoutSubtreeIfNeeded()
        defer {
            prefs.foregroundOpacity = originalForegroundOpacity
            prefs.backgroundOpacity = originalBackgroundOpacity
            prefs.floatRulers = originalFloatRulers
            prefs.groupRulers = originalGroupRulers
            prefs.rulerShadow = originalRulerShadow
        }

        let imageView = NSImageView(frame: NSRect(origin: .zero, size: Layout.preferencesContentSize))
        imageView.image = snapshot(preferencesView, preferencesController: preferencesController)
        imageView.imageScaling = .scaleAxesIndependently

        return [AppStoreViewPlacement(
            view: imageView,
            frame: Layout.preferencesContentRect,
            boundsSize: Layout.preferencesContentSize
        )]
    }

    private static func snapshot(_ view: NSView, preferencesController: PreferencesController) -> NSImage {
        let snapshotWindow = AppStoreActiveSnapshotWindow(
            contentRect: NSRect(origin: .zero, size: Layout.preferencesContentSize),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: true
        )
        snapshotWindow.setFrameOrigin(NSPoint(x: -10_000, y: -10_000))
        snapshotWindow.alphaValue = 0.01
        snapshotWindow.isReleasedWhenClosed = false
        snapshotWindow.contentView = view
        snapshotWindow.orderFrontRegardless()
        snapshotWindow.makeKeyAndOrderFront(nil)
        snapshotWindow.makeFirstResponder(nil)
        defer {
            snapshotWindow.orderOut(nil)
            snapshotWindow.contentView = nil
            snapshotWindow.close()
        }

        view.frame = NSRect(origin: .zero, size: snapshotWindow.contentRect(forFrameRect: snapshotWindow.frame).size)
        view.needsLayout = true
        view.layoutSubtreeIfNeeded()
        view.needsDisplay = true
        view.displayIfNeeded()
        snapshotWindow.displayIfNeeded()

        guard let representation = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
            return NSImage(size: view.bounds.size)
        }
        view.cacheDisplay(in: view.bounds, to: representation)

        let image = NSImage(size: view.bounds.size)
        image.addRepresentation(representation)
        drawActiveSliderOverlay(
            for: preferencesController.foregroundOpacitySlider,
            in: image,
            value: CGFloat(Layout.foregroundOpacityPercent)
        )
        drawActiveSliderOverlay(
            for: preferencesController.backgroundOpacitySlider,
            in: image,
            value: CGFloat(Layout.backgroundOpacityPercent)
        )
        return image
    }

    private static func drawActiveSliderOverlay(for slider: NSSlider, in image: NSImage, value: CGFloat) {
        guard let superview = slider.superview else { return }

        let sliderRect = superview.convert(slider.frame, to: nil)
        let minValue = CGFloat(slider.minValue)
        let maxValue = CGFloat(slider.maxValue)
        let fraction = max(0, min(1, (value - minValue) / (maxValue - minValue)))

        let trackInset: CGFloat = 4
        let trackStartX = sliderRect.minX + trackInset
        let trackEndX = sliderRect.maxX - trackInset
        let trackY = sliderRect.midY + 1
        let trackWidth = trackEndX - trackStartX
        let knobX = trackStartX + trackWidth * fraction
        let trackHeight: CGFloat = 4
        let tickHeight: CGFloat = 10
        let knobSize = NSSize(width: 14, height: 28)

        image.lockFocus()
        defer {
            image.unlockFocus()
        }

        let trackColor = NSColor(calibratedWhite: 0.78, alpha: 1)
        let knobStroke = NSColor(calibratedWhite: 0.72, alpha: 1)

        trackColor.setFill()
        NSBezierPath(
            roundedRect: NSRect(
                x: trackStartX,
                y: trackY - trackHeight / 2,
                width: trackWidth,
                height: trackHeight
            ),
            xRadius: trackHeight / 2,
            yRadius: trackHeight / 2
        ).fill()

        let tickCount = slider.numberOfTickMarks
        if tickCount > 1 {
            for index in 0..<tickCount {
                let tickFraction = CGFloat(index) / CGFloat(tickCount - 1)
                let tickX = trackStartX + trackWidth * tickFraction
                trackColor.setFill()
                NSBezierPath(
                    roundedRect: NSRect(
                        x: tickX - 1.5,
                        y: trackY - tickHeight / 2,
                        width: 3,
                        height: tickHeight
                    ),
                    xRadius: 1.5,
                    yRadius: 1.5
                ).fill()
            }
        }

        let knobRect = NSRect(
            x: knobX - knobSize.width / 2,
            y: trackY - knobSize.height / 2,
            width: knobSize.width,
            height: knobSize.height
        )
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowBlurRadius = 4
        shadow.shadowOffset = NSSize(width: 0, height: -1)
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
        shadow.set()
        NSColor.white.setFill()
        NSBezierPath(roundedRect: knobRect, xRadius: knobSize.width / 2, yRadius: knobSize.width / 2).fill()
        NSGraphicsContext.restoreGraphicsState()

        knobStroke.setStroke()
        let knobPath = NSBezierPath(
            roundedRect: knobRect.insetBy(dx: 0.5, dy: 0.5),
            xRadius: knobSize.width / 2,
            yRadius: knobSize.width / 2
        )
        knobPath.lineWidth = 1
        knobPath.stroke()
    }
}

#endif
