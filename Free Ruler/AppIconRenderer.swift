import Cocoa
#if DEBUG
import SwiftUI
#endif

private struct AppIconPalette {
    let fill = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)
    let numbers = #colorLiteral(red: 0.4, green: 0.2637678268, blue: 0.05685021017, alpha: 1)
    let ticks = #colorLiteral(red: 0.8, green: 0.5275675571, blue: 0.1081081074, alpha: 1)
}

private enum AppIconFontFamily {
    case helveticaNeue
    case system
}

private enum AppIconLayout {
    static let canvasSize: CGFloat = 1024
    static let cornerRadius: CGFloat = 200
    static let rulerStartTick: CGFloat = 2
    static let rulerEndTick: CGFloat = 68

    static let tickWidth: CGFloat = 20
    static let largeTickLength: CGFloat = 200
    static let mediumTickLength: CGFloat = 150
    static let smallTickLength: CGFloat = 100
    static let smallTickWidth: CGFloat = 20

    static let borderEnabled = true
    static let borderWidth: CGFloat = 30
    static let borderOpacity: CGFloat = 1
    static let insetBorderWidth: CGFloat = 40
    static let insetBorderOpacity: CGFloat = 0.25

    static let labelFontSize: CGFloat = 260
    static let labelFontFamily: AppIconFontFamily = .system
    static let labelFontWeight: NSFont.Weight = .semibold

    static let unitLabelLeftPadding: CGFloat = 170
    static let unitLabelTopPadding: CGFloat = 40

    static let tickLabelWidth: CGFloat = 440
    static let tickLabelHeight: CGFloat = 240
    static let tickLabelBottomOffset: CGFloat = 250
}

enum AppIconRenderer {
    static let appIconSetSizes: [(filename: String, pixels: Int)] = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]

    static func image(size: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        draw(in: NSRect(x: 0, y: 0, width: size, height: size))
        image.unlockFocus()
        return image
    }

    static func exportAppIconSet(to outputDirectory: URL) throws {
        try FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true
        )

        for icon in appIconSetSizes {
            let data = try pngData(pixels: icon.pixels)
            try data.write(to: outputDirectory.appendingPathComponent(icon.filename))
        }
    }

    private static func pngData(pixels: Int) throws -> Data {
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

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        image(size: AppIconLayout.canvasSize).draw(
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

    private static func draw(in canvas: NSRect) {
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(
            roundedRect: canvas,
            xRadius: AppIconLayout.cornerRadius * (canvas.width / AppIconLayout.canvasSize),
            yRadius: AppIconLayout.cornerRadius * (canvas.height / AppIconLayout.canvasSize)
        ).addClip()

        AppIconPalette().fill.setFill()
        canvas.fill()

        let scale = canvas.width / AppIconLayout.canvasSize
        let colors = AppIconPalette()
        drawTicks(in: canvas, colors: colors, scale: scale)
        drawUnitLabel(in: canvas, colors: colors, scale: scale)
        drawBorder(in: canvas, colors: colors, scale: scale)
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

        let lineWidth = AppIconLayout.borderWidth * scale
        strokeBorder(
            in: rect,
            colors: colors,
            scale: scale,
            inset: lineWidth / 2,
            opacity: AppIconLayout.borderOpacity
        )
        strokeBorder(
            in: rect,
            colors: colors,
            scale: scale,
            inset: lineWidth * 1.5,
            opacity: AppIconLayout.insetBorderOpacity
        )
    }

    private static func strokeBorder(
        in rect: NSRect,
        colors: AppIconPalette,
        scale: CGFloat,
        inset: CGFloat,
        opacity: CGFloat
    ) {
        guard opacity > 0 else { return }

        let lineWidth = AppIconLayout.borderWidth * scale
        let borderPath = NSBezierPath(
            roundedRect: rect.insetBy(dx: inset, dy: inset),
            xRadius: max(0, (AppIconLayout.cornerRadius * scale) - inset),
            yRadius: max(0, (AppIconLayout.cornerRadius * scale) - inset)
        )
        borderPath.lineWidth = lineWidth

        colors.ticks.withAlphaComponent(opacity).setStroke()
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
                fontSize: AppIconLayout.labelFontSize * scale,
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
                fontSize: AppIconLayout.labelFontSize * scale,
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

enum AppIconRendererError: Error {
    case couldNotCreateBitmap(Int)
    case couldNotEncodePNG(Int)
}

#if DEBUG
struct AppIconPreview: View {
    var body: some View {
        VStack(spacing: 24) {
            previewIcon(size: 256)

            HStack(spacing: 20) {
                previewIcon(size: 128)
                previewIcon(size: 64)
                previewIcon(size: 32)
            }
        }
        .padding(32)
        .background(.regularMaterial)
    }

    private func previewIcon(size: CGFloat) -> some View {
        Image(nsImage: AppIconRenderer.image(size: AppIconLayout.canvasSize))
            .resizable()
            .frame(width: size, height: size)
    }
}

struct AppIconPreview_Previews: PreviewProvider {
    static var previews: some View {
        AppIconPreview()
            .previewLayout(.sizeThatFits)
    }
}
#endif
