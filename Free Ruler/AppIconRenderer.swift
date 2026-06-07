import Cocoa

private struct AppIconPalette {
    let fill = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)
    let numbers = #colorLiteral(red: 0.6829560399, green: 0.4503545761, blue: 0.09706548601, alpha: 1)
    let ticks = #colorLiteral(red: 0.7254902124, green: 0.4784313738, blue: 0.09803921729, alpha: 1)
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
        image(size: 1024).draw(
            in: NSRect(x: 0, y: 0, width: pixels, height: pixels),
            from: NSRect(x: 0, y: 0, width: 1024, height: 1024),
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
        NSColor.clear.setFill()
        canvas.fill()

        let scale = canvas.width / 1024
        let rulerRect = NSRect(
            x: 54 * scale,
            y: 44 * scale,
            width: 1124 * scale,
            height: 936 * scale
        )
        let cornerRadius = 78 * scale
        let colors = AppIconPalette()
        let rulerPath = NSBezierPath(roundedRect: rulerRect, xRadius: cornerRadius, yRadius: cornerRadius)

        drawShadow(for: rulerPath, scale: scale)

        NSGraphicsContext.saveGraphicsState()
        rulerPath.addClip()

        colors.fill.setFill()
        rulerRect.fill()

        drawTicks(in: rulerRect, colors: colors, scale: scale)
        drawUnitLabel(in: rulerRect, colors: colors, scale: scale)

        NSGraphicsContext.restoreGraphicsState()

        rulerPath.lineWidth = 8 * scale
        colors.ticks.setStroke()
        rulerPath.stroke()
    }

    private static func drawShadow(for path: NSBezierPath, scale: CGFloat) {
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowOffset = NSSize(width: 0, height: -18 * scale)
        shadow.shadowBlurRadius = 28 * scale
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.24)
        shadow.set()

        NSColor.black.withAlphaComponent(0.01).setFill()
        path.fill()
        NSGraphicsContext.restoreGraphicsState()
    }

    private static func drawTicks(in rect: NSRect, colors: AppIconPalette, scale: CGFloat) {
        let path = NSBezierPath()
        path.lineWidth = 6 * scale

        let tickSpacing = 14 * scale
        let largeTickLength = 120 * scale
        let mediumTickLength = 84 * scale
        let smallTickLength = 52 * scale
        let tickCount = Int((rect.width - (2 * scale)) / tickSpacing)
        guard tickCount > 0 else { return }

        for i in 1...tickCount {
            let x = rect.minX + (CGFloat(i) * tickSpacing)

            if i.isMultiple(of: 50) {
                path.move(to: CGPoint(x: x, y: rect.minY + scale))
                path.line(to: CGPoint(x: x, y: rect.minY + largeTickLength))
                drawTickLabel(String(i), at: x, in: rect, colors: colors, scale: scale)
            } else if i.isMultiple(of: 10) {
                path.move(to: CGPoint(x: x, y: rect.minY + scale))
                path.line(to: CGPoint(x: x, y: rect.minY + mediumTickLength))
            } else if i.isMultiple(of: 2) {
                path.move(to: CGPoint(x: x, y: rect.minY + scale))
                path.line(to: CGPoint(x: x, y: rect.minY + smallTickLength))
            }
        }

        path.transform(using: AffineTransform(translationByX: 0.5 * scale, byY: 0))

        colors.ticks.setStroke()
        path.stroke()
    }

    private static func drawTickLabel(
        _ label: String,
        at x: CGFloat,
        in rect: NSRect,
        colors: AppIconPalette,
        scale: CGFloat
    ) {
        let labelRect = CGRect(
            x: x - (90 * scale),
            y: rect.minY + (160 * scale),
            width: 180 * scale,
            height: 92 * scale
        )

        label.draw(
            with: labelRect,
            attributes: labelAttributes(
                fontSize: 56 * scale,
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
                fontSize: 56 * scale,
                alignment: .left,
                foregroundColor: colors.ticks
            )
        )
        let labelSize = label.size()
        let labelRect = CGRect(
            x: rect.minX + (64 * scale),
            y: rect.maxY - labelSize.height,
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
        let font = NSFont(name: "HelveticaNeue", size: fontSize) ?? .systemFont(ofSize: fontSize)

        return [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: foregroundColor,
        ]
    }
}

enum AppIconRendererError: Error {
    case couldNotCreateBitmap(Int)
    case couldNotEncodePNG(Int)
}
