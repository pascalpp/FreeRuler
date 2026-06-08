#if DEBUG
import Cocoa
import SwiftUI

private struct AppStoreScreenshotPalette {
    let screen1Background = #colorLiteral(red: 0.385, green: 0.49, blue: 0.7, alpha: 1)
    let screen2Background = #colorLiteral(red: 0.3084420562, green: 0.521068275, blue: 0.509829402, alpha: 1)
    let screen3Background = #colorLiteral(red: 0.5181607008, green: 0.4312165375, blue: 0.6487324834, alpha: 1)
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
    case screen3

    func background(in palette: AppStoreScreenshotPalette) -> NSColor {
        switch self {
        case .screen1:
            return palette.screen1Background
        case .screen2:
            return palette.screen2Background
        case .screen3:
            return palette.screen3Background
        }
    }

    var headline: String {
        switch self {
        case .screen1:
            return "A ruler for your Mac"
        case .screen2:
            return "Switch units instantly"
        case .screen3:
            return "Make it yours"
        }
    }

    var description: String {
        switch self {
        case .screen1:
            return "Measure anything on your screen."
        case .screen2:
            return "Use pixels, millimeters, or inches."
        case .screen3:
            return "Tune opacity, grouping, and shadows."
        }
    }

    var previewName: String {
        switch self {
        case .screen1:
            return "Screen 1 - Measure anything"
        case .screen2:
            return "Screen 2 - Units"
        case .screen3:
            return "Screen 3 - Preferences"
        }
    }

    var outputFilename: String {
        switch self {
        case .screen1:
            return "01-measure-anything.png"
        case .screen2:
            return "02-switch-units.png"
        case .screen3:
            return "03-customize-rulers.png"
        }
    }
}

enum AppStoreScreenshotRenderer {
    static func exportAll(to outputDirectory: URL) throws {
        try FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true
        )

        for screen in screens {
            let image = try render(screen: screen)
            let outputURL = outputDirectory.appendingPathComponent(screen.outputFilename)
            try writePNG(image, to: outputURL)
            print("Generated \(outputURL.path)")
        }
    }

    private static let screens: [AppStoreScreenshotScreen] = [
        .screen1,
        .screen2,
        .screen3,
    ]

    private static func render(screen: AppStoreScreenshotScreen) throws -> NSImage {
        let view = AppStoreScreenshotScenarioNSView(screen: screen)
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
            colorSpaceName: .calibratedRGB,
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

    static let screen1BoxGutter: CGFloat = 70
    static let screen1Box1Width: CGFloat = 800
    static let screen1Box2Height: CGFloat = 180
    static let screen1BoxBorderColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.24)
    static let screen1BoxBorderWidth: CGFloat = 4
    static let screen1BoxBorderRadius: CGFloat = 16

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

    static let screen3RulerScale: CGFloat = 6
    static let screen3RulerOpacity: CGFloat = 0.75
    static let screen3VerticalRulerX: CGFloat = 250
    static let screen3VerticalRulerY: CGFloat = 170
    static let screen3VerticalRulerLength: CGFloat = 2050
    static let screen3HorizontalRulerX: CGFloat = 50
    static let screen3HorizontalRulerY: CGFloat = 1100
    static let screen3HorizontalRulerLength: CGFloat = 3000
    static let screen3PreferencesWindowX: CGFloat = 620
    static let screen3PreferencesWindowY: CGFloat = 560
    static let screen3PreferencesWindowScale: CGFloat = 4.5
    static let screen3PreferencesContentWidth: CGFloat = 400
    static let screen3PreferencesContentHeight: CGFloat = 295
    static let screen3PreferencesWindowShadowOpacity: CGFloat = 0.28
    static let screen3PreferencesWindowShadowYOffset: CGFloat = -5

    static var screen3ForegroundOpacityPercent: Int {
        Int((screen3RulerOpacity * 100).rounded())
    }

    static let screen3BackgroundOpacityPercent = 50

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

    static var sampleWindowContentRect: NSRect {
        NSRect(
            x: sampleWindowRect.minX,
            y: sampleWindowRect.minY + titlebarHeight,
            width: sampleWindowRect.width,
            height: sampleWindowRect.height - titlebarHeight
        )
    }

    static var screen1Box1Rect: NSRect {
        NSRect(
            x: sampleWindowContentRect.minX + screen1BoxGutter,
            y: sampleWindowContentRect.minY + screen1BoxGutter,
            width: screen1Box1Width,
            height: sampleWindowContentRect.height - (screen1BoxGutter * 2)
        )
    }

    static var screen1Box2Rect: NSRect {
        let x = screen1Box1Rect.maxX + screen1BoxGutter
        return NSRect(
            x: x,
            y: sampleWindowContentRect.minY + screen1BoxGutter,
            width: sampleWindowContentRect.maxX - x - screen1BoxGutter,
            height: screen1Box2Height
        )
    }

    static var screen1Box3Rect: NSRect {
        let y = screen1Box2Rect.maxY + screen1BoxGutter
        return NSRect(
            x: screen1Box2Rect.minX,
            y: y,
            width: screen1Box2Rect.width,
            height: sampleWindowContentRect.maxY - y - screen1BoxGutter
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

    static var screen3ScaledRulerThickness: CGFloat {
        Ruler.thickness * screen3RulerScale
    }

    static var screen3VerticalRulerRect: NSRect {
        NSRect(
            x: screen3VerticalRulerX,
            y: screen3VerticalRulerY,
            width: screen3ScaledRulerThickness,
            height: screen3VerticalRulerLength
        )
    }

    static var screen3HorizontalRulerRect: NSRect {
        NSRect(
            x: screen3HorizontalRulerX,
            y: screen3HorizontalRulerY,
            width: screen3HorizontalRulerLength,
            height: screen3ScaledRulerThickness
        )
    }

    static var screen3PreferencesContentSize: NSSize {
        NSSize(width: screen3PreferencesContentWidth, height: screen3PreferencesContentHeight)
    }

    static var screen3PreferencesWindowRect: NSRect {
        NSRect(
            x: screen3PreferencesWindowX,
            y: screen3PreferencesWindowY,
            width: screen3PreferencesContentWidth * screen3PreferencesWindowScale,
            height: titlebarHeight + screen3PreferencesContentHeight * screen3PreferencesWindowScale
        )
    }

    static var screen3PreferencesContentRect: NSRect {
        NSRect(
            x: screen3PreferencesWindowX,
            y: screen3PreferencesWindowY + titlebarHeight,
            width: screen3PreferencesContentWidth * screen3PreferencesWindowScale,
            height: screen3PreferencesContentHeight * screen3PreferencesWindowScale
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
            AppStoreScreenshotScenarioView(screen: .screen3)
                .previewDisplayName(AppStoreScreenshotScreen.screen3.previewName)
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
    let borderView: AppStoreRulerBorderView
    let frame: NSRect
    let boundsSize: NSSize

    init(view: RuleView, frame: NSRect, boundsSize: NSSize) {
        self.container = NSView(frame: NSRect(origin: .zero, size: boundsSize))
        self.view = view
        self.borderView = AppStoreRulerBorderView(frame: NSRect(origin: .zero, size: boundsSize))
        self.frame = frame
        self.boundsSize = boundsSize
        self.container.addSubview(view)
        self.container.addSubview(borderView)
    }
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

    override var unit: Unit {
        screenshotUnit
    }

    init(unit: Unit, frame: NSRect) {
        self.screenshotUnit = unit
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

    override var unit: Unit {
        screenshotUnit
    }

    init(unit: Unit, frame: NSRect) {
        self.screenshotUnit = unit
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

private final class AppStoreScreenshotScenarioNSView: NSView {
    private let screen: AppStoreScreenshotScreen
    private let palette = AppStoreScreenshotPalette()
    private let rulerPlacements: [AppStoreRulerPlacement]
    private let preferencesController: PreferencesController?
    private let viewPlacements: [AppStoreViewPlacement]

    override var isFlipped: Bool {
        true
    }

    override var intrinsicContentSize: NSSize {
        NSSize(
            width: AppStoreScreenshotLayout.previewWidth,
            height: AppStoreScreenshotLayout.previewHeight
        )
    }

    init(screen: AppStoreScreenshotScreen) {
        self.screen = screen
        self.rulerPlacements = Self.makeRulerPlacements(for: screen)
        let preferencesController = screen == .screen3 ? Self.makePreferencesController() : nil
        self.preferencesController = preferencesController
        self.viewPlacements = Self.makeViewPlacements(for: screen, preferencesController: preferencesController)
        super.init(frame: NSRect(origin: .zero, size: AppStoreScreenshotLayout.canvasSize))
        for viewPlacement in viewPlacements {
            addSubview(viewPlacement.container)
        }
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
        for viewPlacement in viewPlacements {
            layoutView(viewPlacement, frame: viewPlacement.frame, transform: transform)
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
        case .screen3:
            let horizontalBoundsSize = NSSize(
                width: AppStoreScreenshotLayout.screen3HorizontalRulerLength / AppStoreScreenshotLayout.screen3RulerScale,
                height: Ruler.thickness
            )
            let verticalBoundsSize = NSSize(
                width: Ruler.thickness,
                height: AppStoreScreenshotLayout.screen3VerticalRulerLength / AppStoreScreenshotLayout.screen3RulerScale
            )
            return [
                AppStoreRulerPlacement(
                    view: AppStoreVerticalRule(unit: .pixels, frame: NSRect(origin: .zero, size: verticalBoundsSize)),
                    frame: AppStoreScreenshotLayout.screen3VerticalRulerRect,
                    boundsSize: verticalBoundsSize
                ),
                AppStoreRulerPlacement(
                    view: AppStoreHorizontalRule(unit: .pixels, frame: NSRect(origin: .zero, size: horizontalBoundsSize)),
                    frame: AppStoreScreenshotLayout.screen3HorizontalRulerRect,
                    boundsSize: horizontalBoundsSize
                ),
            ]
        }
    }

    private static func makePreferencesController() -> PreferencesController {
        let controller = PreferencesController()
        controller.loadWindow()
        controller.updateView()
        controller.window?.contentView?.layoutSubtreeIfNeeded()
        return controller
    }

    private static func makeViewPlacements(
        for screen: AppStoreScreenshotScreen,
        preferencesController: PreferencesController?
    ) -> [AppStoreViewPlacement] {
        guard screen == .screen3,
              let preferencesView = preferencesController?.window?.contentView else {
            return []
        }
        let originalForegroundOpacity = prefs.foregroundOpacity
        let originalBackgroundOpacity = prefs.backgroundOpacity
        prefs.foregroundOpacity = AppStoreScreenshotLayout.screen3ForegroundOpacityPercent
        prefs.backgroundOpacity = AppStoreScreenshotLayout.screen3BackgroundOpacityPercent
        preferencesController?.updateView()
        preferencesController?.window?.contentView?.layoutSubtreeIfNeeded()
        defer {
            prefs.foregroundOpacity = originalForegroundOpacity
            prefs.backgroundOpacity = originalBackgroundOpacity
        }

        let imageView = NSImageView(frame: NSRect(origin: .zero, size: AppStoreScreenshotLayout.screen3PreferencesContentSize))
        imageView.image = snapshot(preferencesView, preferencesController: preferencesController)
        imageView.imageScaling = .scaleAxesIndependently

        return [
            AppStoreViewPlacement(
                view: imageView,
                frame: AppStoreScreenshotLayout.screen3PreferencesContentRect,
                boundsSize: AppStoreScreenshotLayout.screen3PreferencesContentSize
            ),
        ]
    }

    private static func snapshot(_ view: NSView, preferencesController: PreferencesController?) -> NSImage {
        let snapshotWindow = AppStoreActiveSnapshotWindow(
            contentRect: NSRect(origin: .zero, size: AppStoreScreenshotLayout.screen3PreferencesContentSize),
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
        if let preferencesController {
            drawActiveSliderOverlay(
                for: preferencesController.foregroundOpacitySlider,
                in: image,
                value: CGFloat(AppStoreScreenshotLayout.screen3ForegroundOpacityPercent)
            )
            drawActiveSliderOverlay(
                for: preferencesController.backgroundOpacitySlider,
                in: image,
                value: CGFloat(AppStoreScreenshotLayout.screen3BackgroundOpacityPercent)
            )
        }
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
        let knobPath = NSBezierPath(roundedRect: knobRect.insetBy(dx: 0.5, dy: 0.5), xRadius: knobSize.width / 2, yRadius: knobSize.width / 2)
        knobPath.lineWidth = 1
        knobPath.stroke()
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
        rulerPlacement.borderView.frame = NSRect(origin: .zero, size: rulerPlacement.boundsSize)
        rulerPlacement.borderView.borderColor = palette.rulerBorder
        rulerPlacement.borderView.borderWidth = AppStoreScreenshotLayout.rulerBorderWidth
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

    private func drawScenario() {
        screen.background(in: palette).setFill()
        NSRect(origin: .zero, size: AppStoreScreenshotLayout.canvasSize).fill()

        drawCopy()
        switch screen {
        case .screen1:
            drawSampleWindow(AppStoreScreenshotLayout.sampleWindowRect)
            drawScreen1Boxes()
        case .screen2:
            break
        case .screen3:
            drawSampleWindow(AppStoreScreenshotLayout.screen3PreferencesWindowRect)
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
        view.alphaValue = screen == .screen3 ? AppStoreScreenshotLayout.screen3RulerOpacity : 1
    }

    private func drawSampleWindow(_ rect: NSRect) {
        let titlebarRect = sampleWindowTitlebarRect(for: rect)
        drawShadow(
            rect,
            radius: AppStoreScreenshotLayout.sampleWindowCornerRadius,
            fill: screen.background(in: palette),
            blur: AppStoreScreenshotLayout.sampleWindowShadowBlur,
            offset: NSSize(
                width: AppStoreScreenshotLayout.sampleWindowShadowXOffset,
                height: sampleWindowShadowYOffset
            ),
            opacity: sampleWindowShadowOpacity
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

    private func drawScreen1Boxes() {
        for rect in [
            AppStoreScreenshotLayout.screen1Box1Rect,
            AppStoreScreenshotLayout.screen1Box2Rect,
            AppStoreScreenshotLayout.screen1Box3Rect,
        ] {
            stroke(
                rect,
                color: AppStoreScreenshotLayout.screen1BoxBorderColor,
                width: AppStoreScreenshotLayout.screen1BoxBorderWidth,
                radius: AppStoreScreenshotLayout.screen1BoxBorderRadius
            )
        }
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

    private var sampleWindowShadowOpacity: CGFloat {
        switch screen {
        case .screen1, .screen2:
            return AppStoreScreenshotLayout.sampleWindowShadowOpacity
        case .screen3:
            return AppStoreScreenshotLayout.screen3PreferencesWindowShadowOpacity
        }
    }

    private var sampleWindowShadowYOffset: CGFloat {
        switch screen {
        case .screen1, .screen2:
            return AppStoreScreenshotLayout.sampleWindowShadowYOffset
        case .screen3:
            return AppStoreScreenshotLayout.screen3PreferencesWindowShadowYOffset
        }
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
        stroke(rect, color: color, width: width, radius: 0)
    }

    private func stroke(_ rect: NSRect, color: NSColor, width: CGFloat, radius: CGFloat) {
        color.setStroke()
        let insetRect = rect.insetBy(dx: width / 2, dy: width / 2)
        let path = radius > 0
            ? NSBezierPath(roundedRect: insetRect, xRadius: radius, yRadius: radius)
            : NSBezierPath(rect: insetRect)
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
