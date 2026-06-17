import Cocoa
#if DEBUG
import SwiftUI
#endif

private struct AppIconPalette {
    let fill: NSColor
    let numbers: NSColor
    let ticks: NSColor
    let border: NSColor

    static let standard = AppIconPalette(
        fill: #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1),
        numbers: #colorLiteral(red: 0.4, green: 0.2637678268, blue: 0.05685021017, alpha: 1),
        ticks: #colorLiteral(red: 0.8, green: 0.5275675571, blue: 0.1081081074, alpha: 1),
        border: #colorLiteral(red: 0.8, green: 0.5275675571, blue: 0.1081081074, alpha: 1)
    )

    static let dark = AppIconPalette(
        fill: #colorLiteral(red: 0.1192771084, green: 0.2277108433, blue: 0.6, alpha: 1),
        numbers: #colorLiteral(red: 0.85, green: 0.88, blue: 1, alpha: 1),
        ticks: #colorLiteral(red: 0.4893433073, green: 0.5829650408, blue: 0.9519448138, alpha: 1),
        border: #colorLiteral(red: 0.4893433073, green: 0.5829650408, blue: 0.9519448138, alpha: 1)
    )
}

private enum AppIconVariant: CaseIterable {
    case standard
    case dark

    var palette: AppIconPalette {
        switch self {
        case .standard:
            return .standard
        case .dark:
            return .dark
        }
    }
}

private struct AppIconSetImage {
    let size: String
    let scale: String
    let pixels: Int

    var filename: String {
        let scaleSuffix = scale == "1x" ? "" : "@\(scale)"

        return "icon_\(size)\(scaleSuffix).png"
    }
}

private struct AppIconImageSetImage {
    let filename: String
    let scale: String
    let pixels: Int
}

private struct AppIconSetContents: Encodable {
    let images: [AppIconSetContentsImage]
    let info = AppIconSetInfo()
}

private struct AppIconSetContentsImage: Encodable {
    let size: String
    let idiom = "mac"
    let filename: String
    let scale: String
}

private struct AppIconImageSetContents: Encodable {
    let images: [AppIconImageSetContentsImage]
    let info = AppIconSetInfo()
}

private struct AppIconImageSetContentsImage: Encodable {
    let filename: String
    let idiom = "universal"
    let scale: String
}

private struct AppIconSetInfo: Encodable {
    let version = 1
    let author = "xcode"
}

private enum AppIconFontFamily {
    case helveticaNeue
    case system
}

private enum AppIconLayout {
    static let canvasSize: CGFloat = 1024
    static let iconInset: CGFloat = 84
    static let cornerRadius: CGFloat = 225
    static let rulerStartTick: CGFloat = 2
    static let rulerEndTick: CGFloat = 68.5

    static let tickWidth: CGFloat = 20
    static let largeTickLength: CGFloat = 200
    static let mediumTickLength: CGFloat = 150
    static let smallTickLength: CGFloat = 100
    static let smallTickWidth: CGFloat = 20

    static let borderEnabled = true
    static let borderWidth: CGFloat = 30
    static let borderOpacity: CGFloat = 1
    static let insetBorderWidth: CGFloat = 30
    static let insetBorderOpacity: CGFloat = 0.25

    static let shadowEnabled = true
    static let shadowYOffset: CGFloat = -18
    static let shadowBlurRadius: CGFloat = 24
    static let shadowOpacity: CGFloat = 0.28

    static let unitLabelFontSize: CGFloat = 260
    static let tickLabelFontSize: CGFloat = 200
    static let labelFontFamily: AppIconFontFamily = .system
    static let labelFontWeight: NSFont.Weight = .semibold

    static let unitLabelLeftPadding: CGFloat = 150
    static let unitLabelTopPadding: CGFloat = 20

    static let tickLabelWidth: CGFloat = 440
    static let tickLabelHeight: CGFloat = 240
    static let tickLabelBottomOffset: CGFloat = 250
}

enum AppIconRenderer {
    private static let darkImageSetName = "AppIconDark"

    private static let appIconSetImages: [AppIconSetImage] = [
        AppIconSetImage(size: "16x16", scale: "1x", pixels: 16),
        AppIconSetImage(size: "16x16", scale: "2x", pixels: 32),
        AppIconSetImage(size: "32x32", scale: "1x", pixels: 32),
        AppIconSetImage(size: "32x32", scale: "2x", pixels: 64),
        AppIconSetImage(size: "128x128", scale: "1x", pixels: 128),
        AppIconSetImage(size: "128x128", scale: "2x", pixels: 256),
        AppIconSetImage(size: "256x256", scale: "1x", pixels: 256),
        AppIconSetImage(size: "256x256", scale: "2x", pixels: 512),
        AppIconSetImage(size: "512x512", scale: "1x", pixels: 512),
        AppIconSetImage(size: "512x512", scale: "2x", pixels: 1024),
    ]

    private static let darkImageSetImages: [AppIconImageSetImage] = [
        AppIconImageSetImage(filename: "app-icon-dark.png", scale: "1x", pixels: 512),
        AppIconImageSetImage(filename: "app-icon-dark@2x.png", scale: "2x", pixels: 1024),
    ]

    static func image(size: CGFloat) -> NSImage {
        image(size: size, variant: .standard)
    }

    fileprivate static func image(size: CGFloat, variant: AppIconVariant) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        draw(in: NSRect(x: 0, y: 0, width: size, height: size), variant: variant)
        image.unlockFocus()
        return image
    }

    static func applicationIconImage(for appearance: NSAppearance) -> NSImage {
        if usesDarkAppIcon(for: appearance),
           let image = NSImage(named: darkImageSetName) {
            return image
        }

        return image(size: AppIconLayout.canvasSize)
    }

    private static func usesDarkAppIcon(for appearance: NSAppearance) -> Bool {
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    static func exportAppIconSet(to outputDirectory: URL) throws {
        try FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        for icon in appIconSetImages {
            let data = try pngData(pixels: icon.pixels, variant: .standard)
            try data.write(to: outputDirectory.appendingPathComponent(icon.filename))
        }

        let contents = try appIconSetContentsData()
        try contents.write(to: outputDirectory.appendingPathComponent("Contents.json"))
    }

    static func exportDarkAppIconImageSet(to outputDirectory: URL) throws {
        try FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        for icon in darkImageSetImages {
            let data = try pngData(pixels: icon.pixels, variant: .dark)
            try data.write(to: outputDirectory.appendingPathComponent(icon.filename))
        }

        let contents = try darkImageSetContentsData()
        try contents.write(to: outputDirectory.appendingPathComponent("Contents.json"))
    }

    private static func pngData(pixels: Int, variant: AppIconVariant) throws -> Data {
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixels,
            pixelsHigh: pixels,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw AppIconRendererError.couldNotCreateBitmap(pixels)
        }

        bitmap.size = NSSize(width: pixels, height: pixels)

        guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
            throw AppIconRendererError.couldNotCreateGraphicsContext(pixels)
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        image(size: AppIconLayout.canvasSize, variant: variant).draw(
            in: NSRect(x: 0, y: 0, width: pixels, height: pixels),
            from: NSRect(x: 0, y: 0, width: AppIconLayout.canvasSize, height: AppIconLayout.canvasSize),
            operation: .sourceOver,
            fraction: 1
        )
        NSGraphicsContext.restoreGraphicsState()

        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw AppIconRendererError.couldNotEncodePNG(pixels)
        }

        return data
    }

    private static func appIconSetContentsData() throws -> Data {
        let images = appIconSetImages.map { icon in
            AppIconSetContentsImage(
                size: icon.size,
                filename: icon.filename,
                scale: icon.scale
            )
        }

        return try encodedJSONData(AppIconSetContents(images: images))
    }

    private static func darkImageSetContentsData() throws -> Data {
        let images = darkImageSetImages.map { icon in
            AppIconImageSetContentsImage(filename: icon.filename, scale: icon.scale)
        }

        return try encodedJSONData(AppIconImageSetContents(images: images))
    }

    private static func encodedJSONData<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        var data = try encoder.encode(value)
        data.append(0x0A)

        return data
    }

    private static func draw(in canvas: NSRect, variant: AppIconVariant) {
        let scale = canvas.width / AppIconLayout.canvasSize
        let iconRect = canvas.insetBy(
            dx: AppIconLayout.iconInset * scale,
            dy: AppIconLayout.iconInset * scale
        )
        let cornerRadius = AppIconLayout.cornerRadius * scale
        let iconShape = NSBezierPath(
            roundedRect: iconRect,
            xRadius: cornerRadius,
            yRadius: cornerRadius
        )
        let colors = variant.palette

        drawShadow(for: iconShape, scale: scale)

        NSGraphicsContext.saveGraphicsState()
        iconShape.addClip()

        colors.fill.setFill()
        iconRect.fill()

        drawTicks(in: iconRect, colors: colors, scale: scale)
        drawUnitLabel(in: iconRect, colors: colors, scale: scale)
        drawBorder(in: iconRect, colors: colors, scale: scale)
        NSGraphicsContext.restoreGraphicsState()
    }

    private static func drawShadow(for path: NSBezierPath, scale: CGFloat) {
        guard AppIconLayout.shadowEnabled else { return }

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(AppIconLayout.shadowOpacity)
        shadow.shadowBlurRadius = AppIconLayout.shadowBlurRadius * scale
        shadow.shadowOffset = NSSize(
            width: 0,
            height: AppIconLayout.shadowYOffset * scale
        )
        shadow.set()

        NSColor.black.setFill()
        path.fill()
        NSGraphicsContext.restoreGraphicsState()
    }

    private static func drawTicks(in rect: NSRect, colors: AppIconPalette, scale: CGFloat) {
        let path = NSBezierPath()
        path.lineWidth = AppIconLayout.tickWidth * scale
        let smallTickPath = NSBezierPath()
        smallTickPath.lineWidth = AppIconLayout.smallTickWidth * scale

        let rulerTickSpan = AppIconLayout.rulerEndTick - AppIconLayout.rulerStartTick
        guard rulerTickSpan > 0 else { return }

        let tickSpacing = rect.width / rulerTickSpan
        let largeTickLength = AppIconLayout.largeTickLength * scale
        let mediumTickLength = AppIconLayout.mediumTickLength * scale
        let smallTickLength = AppIconLayout.smallTickLength * scale
        let startTick = Int(floor(AppIconLayout.rulerStartTick)) + 1
        let endTick = Int(floor(AppIconLayout.rulerEndTick))
        guard startTick <= endTick else { return }

        for i in startTick...endTick {
            let x = rect.minX + ((CGFloat(i) - AppIconLayout.rulerStartTick) * tickSpacing)

            if i.isMultiple(of: 50) {
                path.move(to: CGPoint(x: x, y: rect.minY + scale))
                path.line(to: CGPoint(x: x, y: rect.minY + largeTickLength))
                drawTickLabel(String(i), at: x, in: rect, colors: colors, scale: scale)
            } else if i.isMultiple(of: 10) {
                path.move(to: CGPoint(x: x, y: rect.minY + scale))
                path.line(to: CGPoint(x: x, y: rect.minY + mediumTickLength))
            } else if i % 10 == 5 {
                smallTickPath.move(to: CGPoint(x: x, y: rect.minY + scale))
                smallTickPath.line(to: CGPoint(x: x, y: rect.minY + smallTickLength))
            }
        }

        path.transform(using: AffineTransform(translationByX: 0.5 * scale, byY: 0))
        smallTickPath.transform(using: AffineTransform(translationByX: 0.5 * scale, byY: 0))

        colors.ticks.setStroke()
        path.stroke()
        smallTickPath.stroke()
    }

    private static func drawBorder(in rect: NSRect, colors: AppIconPalette, scale: CGFloat) {
        guard AppIconLayout.borderEnabled else { return }

        let borderWidth = AppIconLayout.borderWidth * scale
        let insetBorderWidth = AppIconLayout.insetBorderWidth * scale
        strokeBorder(
            in: rect,
            colors: colors,
            scale: scale,
            inset: borderWidth / 2,
            opacity: AppIconLayout.borderOpacity,
            lineWidth: borderWidth
        )
        strokeBorder(
            in: rect,
            colors: colors,
            scale: scale,
            inset: borderWidth + insetBorderWidth / 2,
            opacity: AppIconLayout.insetBorderOpacity,
            lineWidth: insetBorderWidth
        )
    }

    private static func strokeBorder(
        in rect: NSRect,
        colors: AppIconPalette,
        scale: CGFloat,
        inset: CGFloat,
        opacity: CGFloat,
        lineWidth: CGFloat
    ) {
        guard opacity > 0 else { return }

        let borderPath = NSBezierPath(
            roundedRect: rect.insetBy(dx: inset, dy: inset),
            xRadius: max(0, (AppIconLayout.cornerRadius * scale) - inset),
            yRadius: max(0, (AppIconLayout.cornerRadius * scale) - inset)
        )
        borderPath.lineWidth = lineWidth

        colors.border.withAlphaComponent(opacity).setStroke()
        borderPath.stroke()
    }

    private static func drawTickLabel(
        _ label: String,
        at x: CGFloat,
        in rect: NSRect,
        colors: AppIconPalette,
        scale: CGFloat
    ) {
        let labelRect = CGRect(
            x: x - ((AppIconLayout.tickLabelWidth / 2) * scale),
            y: rect.minY + (AppIconLayout.tickLabelBottomOffset * scale),
            width: AppIconLayout.tickLabelWidth * scale,
            height: AppIconLayout.tickLabelHeight * scale
        )

        label.draw(
            with: labelRect,
            attributes: labelAttributes(
                fontSize: AppIconLayout.tickLabelFontSize * scale,
                alignment: .center,
                foregroundColor: colors.numbers
            ),
            context: nil
        )
    }

    private static func drawUnitLabel(in rect: NSRect, colors: AppIconPalette, scale: CGFloat) {
        let label = NSAttributedString(
            string: "px",
            attributes: labelAttributes(
                fontSize: AppIconLayout.unitLabelFontSize * scale,
                alignment: .left,
                foregroundColor: colors.numbers
            )
        )
        let labelSize = label.size()
        let labelRect = CGRect(
            x: rect.minX + (AppIconLayout.unitLabelLeftPadding * scale),
            y: rect.maxY - labelSize.height - (AppIconLayout.unitLabelTopPadding * scale),
            width: labelSize.width,
            height: labelSize.height
        )

        label.draw(with: labelRect, context: nil)
    }

    private static func labelAttributes(
        fontSize: CGFloat,
        alignment: NSTextAlignment,
        foregroundColor: NSColor
    ) -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        let font = labelFont(size: fontSize)

        return [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: foregroundColor,
        ]
    }

    private static func labelFont(size: CGFloat) -> NSFont {
        switch AppIconLayout.labelFontFamily {
        case .helveticaNeue:
            return NSFontManager.shared.font(
                withFamily: "Helvetica Neue",
                traits: [],
                weight: fontManagerWeight(for: AppIconLayout.labelFontWeight),
                size: size
            ) ?? NSFont.systemFont(ofSize: size, weight: AppIconLayout.labelFontWeight)
        case .system:
            return NSFont.systemFont(ofSize: size, weight: AppIconLayout.labelFontWeight)
        }
    }

    private static func fontManagerWeight(for weight: NSFont.Weight) -> Int {
        switch weight {
        case .ultraLight:
            return 2
        case .thin:
            return 3
        case .light:
            return 4
        case .regular:
            return 5
        case .medium:
            return 6
        case .semibold:
            return 8
        case .bold:
            return 9
        case .heavy:
            return 12
        case .black:
            return 14
        default:
            return 5
        }
    }
}

enum AppIconRendererError: LocalizedError {
    case couldNotCreateBitmap(Int)
    case couldNotCreateGraphicsContext(Int)
    case couldNotEncodePNG(Int)

    var errorDescription: String? {
        switch self {
        case let .couldNotCreateBitmap(pixels):
            return "Could not create a \(pixels)x\(pixels) bitmap for app icon generation."
        case let .couldNotCreateGraphicsContext(pixels):
            return "Could not create a graphics context for the \(pixels)x\(pixels) app icon bitmap."
        case let .couldNotEncodePNG(pixels):
            return "Could not encode the \(pixels)x\(pixels) app icon as PNG."
        }
    }
}

#if DEBUG
private extension AppIconVariant {
    var previewBackgroundColor: Color {
        switch self {
        case .standard:
            return Color(nsColor: #colorLiteral(red: 0.9490196078, green: 0.9490196078, blue: 0.968627451, alpha: 1))
        case .dark:
            return Color(nsColor: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1))
        }
    }
}

struct AppIconPreview: View {
    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 24) {
                previewIcon(size: 256, variant: .standard)
                previewIcon(size: 256, variant: .dark)
            }

            HStack(spacing: 20) {
                previewIcon(size: 128, variant: .standard)
                previewIcon(size: 128, variant: .dark)
                previewIcon(size: 64, variant: .standard)
                previewIcon(size: 64, variant: .dark)
                previewIcon(size: 32, variant: .standard)
                previewIcon(size: 32, variant: .dark)
            }
        }
        .padding(32)
        .background(.regularMaterial)
    }

    private func previewIcon(size: CGFloat, variant: AppIconVariant) -> some View {
        Image(nsImage: AppIconRenderer.image(size: size, variant: variant))
            .resizable()
            .frame(width: size, height: size)
            .padding(max(8, size * 0.08))
            .background(variant.previewBackgroundColor)
    }
}

struct AppIconPreview_Previews: PreviewProvider {
    static var previews: some View {
        AppIconPreview()
            .previewLayout(.sizeThatFits)
    }
}
#endif
