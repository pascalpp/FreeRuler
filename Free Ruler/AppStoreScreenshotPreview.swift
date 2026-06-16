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

private enum AppStoreScreenshotFontFamily {
    case system
    case helveticaNeue
}

private enum AppStoreScreenshotScenario {
    case measure
    case units
    case colors
    case groups
    case flipRulers
    case preferences
}

private struct AppStoreScreenshotScreen {
    let scenario: AppStoreScreenshotScenario
    let title: String
    let subtitle: String
    let previewName: String
    let outputFilename: String
    let backgroundColor: NSColor
    let bottomBackgroundColor: NSColor
    let usesDarkCopy: Bool

    static let measure = AppStoreScreenshotScreen(
        scenario: .measure,
        title: AppStoreMeasureScreenshotLayout.title,
        subtitle: AppStoreMeasureScreenshotLayout.subtitle,
        previewName: AppStoreMeasureScreenshotLayout.previewName,
        outputFilename: AppStoreMeasureScreenshotLayout.outputFilename,
        backgroundColor: AppStoreMeasureScreenshotLayout.backgroundColor,
        bottomBackgroundColor: AppStoreMeasureScreenshotLayout.bottomBackgroundColor,
        usesDarkCopy: false
    )

    static let units = AppStoreScreenshotScreen(
        scenario: .units,
        title: AppStoreUnitsScreenshotLayout.title,
        subtitle: AppStoreUnitsScreenshotLayout.subtitle,
        previewName: AppStoreUnitsScreenshotLayout.previewName,
        outputFilename: AppStoreUnitsScreenshotLayout.outputFilename,
        backgroundColor: AppStoreUnitsScreenshotLayout.backgroundColor,
        bottomBackgroundColor: AppStoreUnitsScreenshotLayout.bottomBackgroundColor,
        usesDarkCopy: false
    )

    static let colors = AppStoreScreenshotScreen(
        scenario: .colors,
        title: AppStoreColorsScreenshotLayout.title,
        subtitle: AppStoreColorsScreenshotLayout.subtitle,
        previewName: AppStoreColorsScreenshotLayout.previewName,
        outputFilename: AppStoreColorsScreenshotLayout.outputFilename,
        backgroundColor: AppStoreColorsScreenshotLayout.backgroundColor,
        bottomBackgroundColor: AppStoreColorsScreenshotLayout.bottomBackgroundColor,
        usesDarkCopy: true
    )

    static let groups = AppStoreScreenshotScreen(
        scenario: .groups,
        title: AppStoreGroupsScreenshotLayout.title,
        subtitle: AppStoreGroupsScreenshotLayout.subtitle,
        previewName: AppStoreGroupsScreenshotLayout.previewName,
        outputFilename: AppStoreGroupsScreenshotLayout.outputFilename,
        backgroundColor: AppStoreGroupsScreenshotLayout.backgroundColor,
        bottomBackgroundColor: AppStoreGroupsScreenshotLayout.bottomBackgroundColor,
        usesDarkCopy: true
    )

    static let flipRulers = AppStoreScreenshotScreen(
        scenario: .flipRulers,
        title: AppStoreFlipScreenshotLayout.title,
        subtitle: AppStoreFlipScreenshotLayout.subtitle,
        previewName: AppStoreFlipScreenshotLayout.previewName,
        outputFilename: AppStoreFlipScreenshotLayout.outputFilename,
        backgroundColor: AppStoreFlipScreenshotLayout.backgroundColor,
        bottomBackgroundColor: AppStoreFlipScreenshotLayout.bottomBackgroundColor,
        usesDarkCopy: false
    )

    static let preferences = AppStoreScreenshotScreen(
        scenario: .preferences,
        title: AppStorePreferencesScreenshotLayout.title,
        subtitle: AppStorePreferencesScreenshotLayout.subtitle,
        previewName: AppStorePreferencesScreenshotLayout.previewName,
        outputFilename: AppStorePreferencesScreenshotLayout.outputFilename,
        backgroundColor: AppStorePreferencesScreenshotLayout.backgroundColor,
        bottomBackgroundColor: AppStorePreferencesScreenshotLayout.bottomBackgroundColor,
        usesDarkCopy: false
    )

    static let allInOutputOrder: [AppStoreScreenshotScreen] = [
        .measure,
        .colors,
        .groups,
        .flipRulers,
        .units,
        .preferences,
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

private struct AppStoreScreenshotCopyViewLayout {
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

private enum AppStoreScreenshotLayout {
    static let canvasWidth: CGFloat = 2880
    static let canvasHeight: CGFloat = 1800
    static let previewWidth: CGFloat = 960
    static let previewHeight: CGFloat = 600

    static let copyViewX: CGFloat = 640
    static let copyViewY: CGFloat = 80
    static let copyIconX: CGFloat = 0
    static let copyIconY: CGFloat = 0
    static let copyIconSize: CGFloat = 360
    static let copyTitleX: CGFloat = 410
    static let copyTitleY: CGFloat = 60
    static let titleWidth: CGFloat = 1800
    static let titleHeight: CGFloat = 120
    static let titleFontSize: CGFloat = 100
    static let titleFontWeight: NSFont.Weight = .semibold

    static let copySubtitleX: CGFloat = 410
    static let copySubtitleY: CGFloat = 190
    static let subtitleWidth: CGFloat = 1600
    static let subtitleHeight: CGFloat = 100
    static let subtitleFontSize: CGFloat = 80
    static let textFontFamily: AppStoreScreenshotFontFamily = .system
    static let textFontWeight: NSFont.Weight = .regular

    static let rulerBorderWidth: CGFloat = 1

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

    static var copyViewLayout: AppStoreScreenshotCopyViewLayout {
        copyViewLayout(viewX: copyViewX, viewY: copyViewY)
    }

    static func copyViewLayout(viewX: CGFloat, viewY: CGFloat) -> AppStoreScreenshotCopyViewLayout {
        AppStoreScreenshotCopyViewLayout(
            viewX: viewX,
            viewY: viewY,
            iconX: copyIconX,
            iconY: copyIconY,
            iconSize: copyIconSize,
            titleX: copyTitleX,
            titleY: copyTitleY,
            titleWidth: titleWidth,
            titleHeight: titleHeight,
            subtitleX: copySubtitleX,
            subtitleY: copySubtitleY,
            subtitleWidth: subtitleWidth,
            subtitleHeight: subtitleHeight
        )
    }
}

private enum AppStoreMeasureScreenshotLayout {
    static let title = "A ruler for your Mac"
    static let subtitle = "Measure anything on your screen."
    static let previewName = "Measure anything"
    static let outputFilename = "01-measure-anything.png"
    static let backgroundColor = #colorLiteral(red: 0.385, green: 0.49, blue: 0.7, alpha: 1)
    static let bottomBackgroundColor = #colorLiteral(red: 0.2844348404, green: 0.3620079787, blue: 0.5171542553, alpha: 1)

    static let rulerScale: CGFloat = 4.4
    static let rulerCornerX: CGFloat = 420
    static let rulerCornerY: CGFloat = 500
    static let horizontalRulerLength: CGFloat = 1860
    static let verticalRulerLength: CGFloat = 1050
    static let sampleWindowWidth: CGFloat = 1850
    static let sampleWindowHeight: CGFloat = 1040

    static let boxGutter: CGFloat = 70
    static let box1Width: CGFloat = 800
    static let box2Height: CGFloat = 180
    static let boxBorderColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.24)
    static let boxBorderWidth: CGFloat = 4
    static let boxBorderRadius: CGFloat = 16

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

private enum AppStoreUnitsScreenshotLayout {
    static let title = "Switch units instantly"
    static let subtitle = "Use pixels, millimeters, or inches."
    static let previewName = "Units"
    static let outputFilename = "05-switch-units.png"
    static let backgroundColor = #colorLiteral(red: 0.3528921235, green: 0.5961602394, blue: 0.5833017148, alpha: 1)
    static let bottomBackgroundColor = #colorLiteral(red: 0.3084420562, green: 0.521068275, blue: 0.509829402, alpha: 1)

    static let rulerScale: CGFloat = 6
    static let rulerX: CGFloat = 550
    static let rulerXOffset: CGFloat = -200
    static let firstRulerY: CGFloat = 620
    static let rulerVerticalSpacing: CGFloat = 350
    static let rulerLength: CGFloat = 2200

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

private enum AppStoreColorsScreenshotLayout {
    static let title = "Color your world"
    static let subtitle = "Follow your heart. Be hue you want to be."
    static let previewName = "Colors"
    static let outputFilename = "02-custom-colors.png"
    static let backgroundColor = #colorLiteral(red: 0.6497740259, green: 0.7557746611, blue: 0.9677759309, alpha: 1)
    static let bottomBackgroundColor = #colorLiteral(red: 0.875857736, green: 0.8972384907, blue: 0.94, alpha: 1)

    static let rulerOpacity: CGFloat = 1
    static let rulerCount = 7
    static let rulerGap: CGFloat = 50
    static let firstRulerStart: CGFloat = rulerGap
    static let lastRulerEnd: CGFloat = AppStoreScreenshotLayout.canvasWidth - rulerGap
    static let rulerArcTop: CGFloat = 450
    static let rulerArcBottom: CGFloat = 1000
    static let rulerCurvature: CGFloat = 1.5
    static let rulerOffscreenBottom: CGFloat = 2230
    static let rulerBorderWidth: CGFloat = 2
    static let rulerShadowBlur: CGFloat = 0
    static let rulerShadowXOffset: CGFloat = 0
    static let rulerShadowYOffset: CGFloat = 0
    static let rulerShadowOpacity: CGFloat = 0
    static let rulerColors = [
        #colorLiteral(red: 0.961, green: 0.294, blue: 0.333, alpha: 1),
        #colorLiteral(red: 0.984, green: 0.545, blue: 0.224, alpha: 1),
        #colorLiteral(red: 0.957, green: 0.796, blue: 0.247, alpha: 1),
        #colorLiteral(red: 0.322, green: 0.686, blue: 0.416, alpha: 1),
        #colorLiteral(red: 0.227, green: 0.62, blue: 0.804, alpha: 1),
        #colorLiteral(red: 0.357, green: 0.408, blue: 0.827, alpha: 1),
        #colorLiteral(red: 0.667, green: 0.404, blue: 0.753, alpha: 1),
    ]

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

private enum AppStoreGroupsScreenshotLayout {
    static let previewName = "Groups"
    static let title = "Be independent, or join forces."
    static let subtitle = "Drag rulers separately or as a group."
    static let outputFilename = "03-groups.png"
    static let backgroundColor = #colorLiteral(red: 0.9411402926, green: 0.8768328317, blue: 0.7612973936, alpha: 1)
    static let bottomBackgroundColor = #colorLiteral(red: 0.8283244681, green: 0.7442385697, blue: 0.5931689895, alpha: 1)

    static let rulerScale: CGFloat = 5.5
    static let rulerColor = #colorLiteral(red: 0.1046039086, green: 0.2732335166, blue: 0.7791223404, alpha: 1)
    static let rulerOpacity: CGFloat = 0.85

    static let ungroupedVerticalRulerX: CGFloat = 250
    static let ungroupedVerticalRulerY: CGFloat = 150
    static let ungroupedVerticalRulerLength: CGFloat = 1450

    static let ungroupedHorizontalRulerX: CGFloat = 125
    static let ungroupedHorizontalRulerY: CGFloat = 1100
    static let ungroupedHorizontalRulerLength: CGFloat = 2600

    static let groupedRulerX: CGFloat = 630
    static let groupedRulerY: CGFloat = 525
    static let groupedRulerLength: CGFloat = 1630
    static let groupedRulerWidth: CGFloat = 975


    static let copyViewX: CGFloat = 640
    static let copyViewY: CGFloat = 80
    static let copyIconX: CGFloat = AppStoreScreenshotLayout.copyIconX
    static let copyIconY: CGFloat = AppStoreScreenshotLayout.copyIconY
    static let copyIconSize: CGFloat = AppStoreScreenshotLayout.copyIconSize
    static let copyTitleX: CGFloat = AppStoreScreenshotLayout.copyTitleX
    static let copyTitleY: CGFloat = AppStoreScreenshotLayout.copyTitleY
    static let copyTitleWidth: CGFloat = 2100
    static let copyTitleHeight: CGFloat = AppStoreScreenshotLayout.titleHeight
    static let copySubtitleX: CGFloat = AppStoreScreenshotLayout.copySubtitleX
    static let copySubtitleY: CGFloat = AppStoreScreenshotLayout.copySubtitleY
    static let copySubtitleWidth: CGFloat = 2200
    static let copySubtitleHeight: CGFloat = AppStoreScreenshotLayout.subtitleHeight

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

private enum AppStoreFlipScreenshotLayout {
    static let previewName = "Flip Rulers"
    static let title = "Don’t flip out. Or do."
    static let subtitle = "Your rulers, in any orientation."
    static let outputFilename = "04-flip-rulers.png"
    static let backgroundColor = #colorLiteral(red: 0.7959441489, green: 0.3479741865, blue: 0.516690138, alpha: 1)
    static let bottomBackgroundColor = #colorLiteral(red: 0.7124833777, green: 0.311486458, blue: 0.4625112644, alpha: 1)

    static let rulerScale: CGFloat = 4.5
    static let copyViewX: CGFloat = 700
    static let copyViewY: CGFloat = 700

    // Canvas edge to the outside edge of the outer grouped rulers.
    static let outerGap: CGFloat = 80
    // Outside edge of an outer grouped ruler to the nearest nested grouped ruler.
    static let innerGap: CGFloat = 80

    static let topLeftRulerColor = #colorLiteral(red: 0.95, green: 0.7125, blue: 0.8019480475, alpha: 1)

    static let topRightRulerColor = #colorLiteral(red: 0.98, green: 0.735, blue: 0.8272727226, alpha: 1)

    static let bottomRightRulerColor = #colorLiteral(red: 0.95, green: 0.7125, blue: 0.8019480475, alpha: 1)

    static let bottomLeftRulerColor = #colorLiteral(red: 0.98, green: 0.735, blue: 0.8272727227, alpha: 1)

    private static var scaledRulerThickness: CGFloat {
        Ruler.thickness * rulerScale
    }

    private static var overlap: CGFloat {
        rulerScale
    }

    private static var outerLeadingZeroInset: CGFloat {
        outerGap + scaledRulerThickness
    }

    private static var outerTrailingZeroInset: CGFloat {
        outerGap + scaledRulerThickness - overlap
    }

    private static var innerLeadingZeroInset: CGFloat {
        innerRulerEdgeInset + scaledRulerThickness
    }

    private static var innerTrailingZeroInset: CGFloat {
        innerRulerEdgeInset + scaledRulerThickness - overlap
    }

    private static var innerRulerEdgeInset: CGFloat {
        outerGap + scaledRulerThickness + innerGap
    }

    private static var leadingOuterVerticalMaxX: CGFloat {
        outerLeadingZeroInset
    }

    private static var trailingOuterVerticalMinX: CGFloat {
        AppStoreScreenshotLayout.canvasWidth - outerTrailingZeroInset - overlap
    }

    private static var leadingInnerVerticalMaxX: CGFloat {
        innerLeadingZeroInset
    }

    private static var trailingInnerVerticalMinX: CGFloat {
        AppStoreScreenshotLayout.canvasWidth - innerTrailingZeroInset - overlap
    }

    private static func horizontalLength(
        from minX: CGFloat,
        stoppingBefore verticalMinX: CGFloat
    ) -> CGFloat {
        verticalMinX - innerGap - minX
    }

    private static func horizontalLength(
        to maxX: CGFloat,
        stoppingAfter verticalMaxX: CGFloat
    ) -> CGFloat {
        maxX - innerGap - verticalMaxX
    }

    private static var outerVerticalLength: CGFloat {
        verticalLength(forEdgeInset: outerGap)
    }

    private static var innerVerticalLength: CGFloat {
        verticalLength(forEdgeInset: innerRulerEdgeInset)
    }

    private static func verticalLength(forEdgeInset edgeInset: CGFloat) -> CGFloat {
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

private enum AppStorePreferencesScreenshotLayout {
    static let title = "Pick your preferences"
    static let subtitle = "Change opacity, add shadows, and more."
    static let previewName = "Preferences"
    static let outputFilename = "06-customize-rulers.png"
    static let backgroundColor = #colorLiteral(red: 0.5181607008, green: 0.4312165375, blue: 0.6487324834, alpha: 1)
    static let bottomBackgroundColor = #colorLiteral(red: 0.4593747268, green: 0.3822944866, blue: 0.5751329787, alpha: 1)

    static let rulerScale: CGFloat = 6
    static let rulerOpacity: CGFloat = 0.75
    static let verticalRulerX: CGFloat = 250
    static let verticalRulerY: CGFloat = 212
    static let verticalRulerLength: CGFloat = 2050
    static let horizontalRulerX: CGFloat = 100
    static let horizontalRulerY: CGFloat = 1180
    static let horizontalRulerLength: CGFloat = 3000
    static let preferencesWindowX: CGFloat = 680
    static let preferencesWindowY: CGFloat = 540
    static let preferencesWindowScale: CGFloat = 4
    static let preferencesContentWidth: CGFloat = 350
    static let preferencesContentHeight: CGFloat = 333
    static let preferencesWindowShadowOpacity: CGFloat = 0.28
    static let preferencesWindowShadowYOffset: CGFloat = -5

    static var foregroundOpacityPercent: Int {
        Int((rulerOpacity * 100).rounded())
    }

    static let backgroundOpacityPercent = 50
    static let floatRulers = true
    static let groupRulers = true
    static let rulerShadow = false

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

struct AppStoreScreenshotPreview: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(AppStoreScreenshotScreen.allInOutputOrder, id: \.outputFilename) { screen in
                AppStoreScreenshotScenarioView(screen: screen)
                    .previewDisplayName(screen.previewName)
            }
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

private final class AppStoreScreenshotScenarioNSView: NSView {
    private let screen: AppStoreScreenshotScreen
    private let palette = AppStoreScreenshotPalette()
    private let rulerPlacements: [AppStoreRulerPlacement]
    private let preferencesController: PreferencesController?
    private let viewPlacements: [AppStoreViewPlacement]
    private let copyViewPlacement: AppStoreViewPlacement

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
        let preferencesController = screen.scenario == .preferences ? Self.makePreferencesController() : nil
        self.preferencesController = preferencesController
        self.viewPlacements = Self.makeViewPlacements(for: screen, preferencesController: preferencesController)
        self.copyViewPlacement = Self.makeCopyViewPlacement(for: screen)
        super.init(frame: NSRect(origin: .zero, size: AppStoreScreenshotLayout.canvasSize))
        installPlacements()
        addSubview(copyViewPlacement.container)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func installPlacements() {
        switch screen.scenario {
        case .groups:
            installRulerPlacements()
            installViewPlacements()
        case .measure, .units, .colors, .flipRulers, .preferences:
            installViewPlacements()
            installRulerPlacements()
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
        layoutView(copyViewPlacement, frame: copyViewPlacement.frame, transform: transform)
    }

    private static func makeRulerPlacements(for screen: AppStoreScreenshotScreen) -> [AppStoreRulerPlacement] {
        switch screen.scenario {
        case .measure:
            return []
        case .units:
            let rulerBoundsSize = NSSize(
                width: AppStoreUnitsScreenshotLayout.rulerLength / AppStoreUnitsScreenshotLayout.rulerScale,
                height: Ruler.thickness
            )
            return [Unit.pixels, .millimeters, .inches].enumerated().map { index, unit in
                AppStoreRulerPlacement(
                    view: AppStoreHorizontalRule(unit: unit, frame: NSRect(origin: .zero, size: rulerBoundsSize)),
                    frame: AppStoreUnitsScreenshotLayout.rulerRect(index: index),
                    boundsSize: rulerBoundsSize
                )
            }
        case .colors:
            return (0..<AppStoreColorsScreenshotLayout.rulerCount).map { index in
                let fillColor = AppStoreColorsScreenshotLayout.rulerColors[
                    index % AppStoreColorsScreenshotLayout.rulerColors.count
                ]
                let frame = AppStoreColorsScreenshotLayout.rulerRect(index: index)
                let rulerBoundsSize = NSSize(
                    width: Ruler.thickness,
                    height: frame.height / AppStoreColorsScreenshotLayout.rulerScale
                )
                let style = AppStoreRulerStyle(
                    fillColor: fillColor,
                    opacity: AppStoreColorsScreenshotLayout.rulerOpacity,
                    borderColor: fillColor.shadow(withLevel: 0.25),
                    borderWidth: AppStoreColorsScreenshotLayout.rulerBorderWidth,
                    shadowBlur: AppStoreColorsScreenshotLayout.rulerShadowBlur,
                    shadowOffset: NSSize(
                        width: AppStoreColorsScreenshotLayout.rulerShadowXOffset,
                        height: AppStoreColorsScreenshotLayout.rulerShadowYOffset
                    ),
                    shadowOpacity: AppStoreColorsScreenshotLayout.rulerShadowOpacity
                )
                return AppStoreRulerPlacement(
                    view: AppStoreVerticalRule(unit: .pixels, frame: NSRect(origin: .zero, size: rulerBoundsSize)),
                    frame: frame,
                    boundsSize: rulerBoundsSize,
                    style: style
                )
            }
        case .groups:
            let style = AppStoreRulerStyle(
                fillColor: AppStoreGroupsScreenshotLayout.rulerColor,
                opacity: AppStoreGroupsScreenshotLayout.rulerOpacity
            )
            return [
                AppStoreRulerPlacement(
                    view: AppStoreVerticalRule(
                        unit: .pixels,
                        frame: NSRect(origin: .zero, size: AppStoreGroupsScreenshotLayout.ungroupedVerticalBoundsSize)
                    ),
                    frame: AppStoreGroupsScreenshotLayout.ungroupedVerticalRulerRect,
                    boundsSize: AppStoreGroupsScreenshotLayout.ungroupedVerticalBoundsSize,
                    style: style
                ),
                AppStoreRulerPlacement(
                    view: AppStoreHorizontalRule(
                        unit: .pixels,
                        frame: NSRect(origin: .zero, size: AppStoreGroupsScreenshotLayout.ungroupedHorizontalBoundsSize)
                    ),
                    frame: AppStoreGroupsScreenshotLayout.ungroupedHorizontalRulerRect,
                    boundsSize: AppStoreGroupsScreenshotLayout.ungroupedHorizontalBoundsSize,
                    style: style
                ),
            ]
        case .flipRulers:
            return []
        case .preferences:
            let horizontalBoundsSize = NSSize(
                width: AppStorePreferencesScreenshotLayout.horizontalRulerLength / AppStorePreferencesScreenshotLayout.rulerScale,
                height: Ruler.thickness
            )
            let verticalBoundsSize = NSSize(
                width: Ruler.thickness,
                height: AppStorePreferencesScreenshotLayout.verticalRulerLength / AppStorePreferencesScreenshotLayout.rulerScale
            )
            return [
                AppStoreRulerPlacement(
                    view: AppStoreVerticalRule(unit: .pixels, frame: NSRect(origin: .zero, size: verticalBoundsSize)),
                    frame: AppStorePreferencesScreenshotLayout.verticalRulerRect,
                    boundsSize: verticalBoundsSize,
                    style: AppStoreRulerStyle(opacity: AppStorePreferencesScreenshotLayout.rulerOpacity)
                ),
                AppStoreRulerPlacement(
                    view: AppStoreHorizontalRule(unit: .pixels, frame: NSRect(origin: .zero, size: horizontalBoundsSize)),
                    frame: AppStorePreferencesScreenshotLayout.horizontalRulerRect,
                    boundsSize: horizontalBoundsSize,
                    style: AppStoreRulerStyle(opacity: AppStorePreferencesScreenshotLayout.rulerOpacity)
                ),
            ]
        }
    }

    private static func makeMeasureGroupedRulerPlacement() -> AppStoreViewPlacement {
        let horizontalBoundsSize = NSSize(
            width: AppStoreMeasureScreenshotLayout.horizontalRulerLength / AppStoreMeasureScreenshotLayout.rulerScale,
            height: Ruler.thickness
        )
        let verticalBoundsSize = NSSize(
            width: Ruler.thickness,
            height: AppStoreMeasureScreenshotLayout.verticalRulerLength / AppStoreMeasureScreenshotLayout.rulerScale
        )
        let boundsSize = AppStoreMeasureScreenshotLayout.groupedRulerBoundsSize
        let horizontalRule = AppStoreHorizontalRule(
            unit: .pixels,
            frame: NSRect(origin: .zero, size: horizontalBoundsSize)
        )
        let verticalRule = AppStoreVerticalRule(
            unit: .pixels,
            frame: NSRect(origin: .zero, size: verticalBoundsSize)
        )
        let color = RulerColors(customFill: Prefs.defaultRulerFillColor)
        let groupedView = GroupedRulerContentView(
            frame: NSRect(origin: .zero, size: boundsSize),
            horizontalRule: horizontalRule,
            verticalRule: verticalRule
        )

        horizontalRule.color = color
        verticalRule.color = color
        horizontalRule.showMouseTick = false
        verticalRule.showMouseTick = false
        groupedView.color = color
        groupedView.zeroCorner = .topLeft
        groupedView.needsLayout = true
        groupedView.layoutSubtreeIfNeeded()

        return AppStoreViewPlacement(
            view: groupedView,
            frame: AppStoreMeasureScreenshotLayout.groupedRulerRect,
            boundsSize: boundsSize
        )
    }

    private static func makeGroupsGroupedRulerPlacement() -> AppStoreViewPlacement {
        let horizontalBoundsSize = AppStoreGroupsScreenshotLayout.horizontalBoundsSize
        let verticalBoundsSize = AppStoreGroupsScreenshotLayout.verticalBoundsSize
        let boundsSize = AppStoreGroupsScreenshotLayout.groupedBoundsSize
        let horizontalRule = AppStoreHorizontalRule(
            unit: .pixels,
            frame: NSRect(origin: .zero, size: horizontalBoundsSize)
        )
        let verticalRule = AppStoreVerticalRule(
            unit: .pixels,
            frame: NSRect(origin: .zero, size: verticalBoundsSize)
        )
        let color = RulerColors(customFill: AppStoreGroupsScreenshotLayout.rulerColor)
        let groupedView = GroupedRulerContentView(
            frame: NSRect(origin: .zero, size: boundsSize),
            horizontalRule: horizontalRule,
            verticalRule: verticalRule
        )

        horizontalRule.color = color
        verticalRule.color = color
        horizontalRule.showMouseTick = false
        verticalRule.showMouseTick = false
        groupedView.color = color
        groupedView.alphaValue = AppStoreGroupsScreenshotLayout.rulerOpacity
        groupedView.zeroCorner = .topLeft
        groupedView.needsLayout = true
        groupedView.layoutSubtreeIfNeeded()

        return AppStoreViewPlacement(
            view: groupedView,
            frame: AppStoreGroupsScreenshotLayout.groupedRulerRect,
            boundsSize: boundsSize
        )
    }

    private static func makeFlipGroupedRulerPlacements() -> [AppStoreViewPlacement] {
        AppStoreFlipScreenshotLayout.rulerSets.map { rulerSet in
            let horizontalBoundsSize = AppStoreFlipScreenshotLayout.horizontalBoundsSize(for: rulerSet)
            let verticalBoundsSize = AppStoreFlipScreenshotLayout.verticalBoundsSize(for: rulerSet)
            let boundsSize = AppStoreFlipScreenshotLayout.groupedBoundsSize(for: rulerSet)
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
            let groupedView = GroupedRulerContentView(
                frame: NSRect(origin: .zero, size: boundsSize),
                horizontalRule: horizontalRule,
                verticalRule: verticalRule
            )

            horizontalRule.color = color
            verticalRule.color = color
            horizontalRule.showMouseTick = false
            verticalRule.showMouseTick = false
            groupedView.color = color
            groupedView.zeroCorner = rulerSet.zeroCorner
            groupedView.needsLayout = true
            groupedView.layoutSubtreeIfNeeded()

            return AppStoreViewPlacement(
                view: groupedView,
                frame: rulerSet.groupedFrame(rulerScale: AppStoreFlipScreenshotLayout.rulerScale),
                boundsSize: boundsSize
            )
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
        switch screen.scenario {
        case .measure:
            return [makeMeasureGroupedRulerPlacement()]
        case .groups:
            return [makeGroupsGroupedRulerPlacement()]
        case .flipRulers:
            return makeFlipGroupedRulerPlacements()
        case .units, .colors:
            return []
        case .preferences:
            guard let preferencesView = preferencesController?.window?.contentView else {
                return []
            }
            let originalForegroundOpacity = prefs.foregroundOpacity
            let originalBackgroundOpacity = prefs.backgroundOpacity
            let originalFloatRulers = prefs.floatRulers
            let originalGroupRulers = prefs.groupRulers
            let originalRulerShadow = prefs.rulerShadow
            prefs.foregroundOpacity = AppStorePreferencesScreenshotLayout.foregroundOpacityPercent
            prefs.backgroundOpacity = AppStorePreferencesScreenshotLayout.backgroundOpacityPercent
            prefs.floatRulers = AppStorePreferencesScreenshotLayout.floatRulers
            prefs.groupRulers = AppStorePreferencesScreenshotLayout.groupRulers
            prefs.rulerShadow = AppStorePreferencesScreenshotLayout.rulerShadow
            preferencesController?.updateView()
            preferencesController?.window?.contentView?.layoutSubtreeIfNeeded()
            defer {
                prefs.foregroundOpacity = originalForegroundOpacity
                prefs.backgroundOpacity = originalBackgroundOpacity
                prefs.floatRulers = originalFloatRulers
                prefs.groupRulers = originalGroupRulers
                prefs.rulerShadow = originalRulerShadow
            }

            let imageView = NSImageView(frame: NSRect(origin: .zero, size: AppStorePreferencesScreenshotLayout.preferencesContentSize))
            imageView.image = snapshot(preferencesView, preferencesController: preferencesController)
            imageView.imageScaling = .scaleAxesIndependently

            return [AppStoreViewPlacement(
                view: imageView,
                frame: AppStorePreferencesScreenshotLayout.preferencesContentRect,
                boundsSize: AppStorePreferencesScreenshotLayout.preferencesContentSize
            )]
        }
    }

    private static func makeCopyViewPlacement(for screen: AppStoreScreenshotScreen) -> AppStoreViewPlacement {
        let palette = AppStoreScreenshotPalette()
        let layout = copyViewLayout(for: screen)
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

    private static func copyViewLayout(for screen: AppStoreScreenshotScreen) -> AppStoreScreenshotCopyViewLayout {
        switch screen.scenario {
        case .groups:
            return AppStoreGroupsScreenshotLayout.copyViewLayout
        case .flipRulers:
            return AppStoreFlipScreenshotLayout.copyViewLayout
        case .measure, .units, .colors, .preferences:
            return AppStoreScreenshotLayout.copyViewLayout
        }
    }

    private static func snapshot(_ view: NSView, preferencesController: PreferencesController?) -> NSImage {
        let snapshotWindow = AppStoreActiveSnapshotWindow(
            contentRect: NSRect(origin: .zero, size: AppStorePreferencesScreenshotLayout.preferencesContentSize),
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
        if let preferencesController {
            drawActiveSliderOverlay(
                for: preferencesController.foregroundOpacitySlider,
                in: image,
                value: CGFloat(AppStorePreferencesScreenshotLayout.foregroundOpacityPercent)
            )
            drawActiveSliderOverlay(
                for: preferencesController.backgroundOpacitySlider,
                in: image,
                value: CGFloat(AppStorePreferencesScreenshotLayout.backgroundOpacityPercent)
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

    private func drawScenario() {
        drawBackground()

        switch screen.scenario {
        case .measure:
            drawSampleWindow(AppStoreMeasureScreenshotLayout.sampleWindowRect)
            drawMeasureBoxes()
        case .groups:
            break
        case .units:
            break
        case .colors:
            break
        case .flipRulers:
            break
        case .preferences:
            drawSampleWindow(AppStorePreferencesScreenshotLayout.preferencesWindowRect)
        }
    }

    private func drawBackground() {
        let rect = NSRect(origin: .zero, size: AppStoreScreenshotLayout.canvasSize)

        drawVerticalGradient(
            in: rect,
            topColor: screen.backgroundColor,
            bottomColor: screen.bottomBackgroundColor
        )
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

    private func drawSampleWindow(_ rect: NSRect) {
        let titlebarRect = sampleWindowTitlebarRect(for: rect)
        drawShadow(
            rect,
            radius: AppStoreScreenshotLayout.sampleWindowCornerRadius,
            fill: screen.backgroundColor,
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

    private func drawMeasureBoxes() {
        for rect in [
            AppStoreMeasureScreenshotLayout.box1Rect,
            AppStoreMeasureScreenshotLayout.box2Rect,
            AppStoreMeasureScreenshotLayout.box3Rect,
        ] {
            stroke(
                rect,
                color: AppStoreMeasureScreenshotLayout.boxBorderColor,
                width: AppStoreMeasureScreenshotLayout.boxBorderWidth,
                radius: AppStoreMeasureScreenshotLayout.boxBorderRadius
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
        switch screen.scenario {
        case .measure, .units, .colors, .groups, .flipRulers:
            return AppStoreScreenshotLayout.sampleWindowShadowOpacity
        case .preferences:
            return AppStorePreferencesScreenshotLayout.preferencesWindowShadowOpacity
        }
    }

    private var sampleWindowShadowYOffset: CGFloat {
        switch screen.scenario {
        case .measure, .units, .colors, .groups, .flipRulers:
            return AppStoreScreenshotLayout.sampleWindowShadowYOffset
        case .preferences:
            return AppStorePreferencesScreenshotLayout.preferencesWindowShadowYOffset
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

}

#endif
