#if DEBUG
import Cocoa
import SwiftUI

enum AppStoreScreenshotLayout {
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

enum AppStoreMeasureScreenshotLayout {
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
}

enum AppStoreColorsScreenshotLayout {
    static let title = "Color your world"
    static let subtitle = "Follow your heart. Be hue you want to be."
    static let previewName = "Colors"
    static let outputFilename = "02-custom-colors.png"
    static let bottomBackgroundColor = #colorLiteral(red: 0.6497740259, green: 0.7557746611, blue: 0.9677759309, alpha: 1)
    static let backgroundColor = #colorLiteral(red: 0.875857736, green: 0.8972384907, blue: 0.94, alpha: 1)

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
}

enum AppStoreInfinityScreenshotLayout {
    static let title = "Rulers upon rulers"
    static let subtitle = "Make as many as you want."
    static let previewName = "Infinity"
    static let outputFilename = "03-infinity.png"
    static let bottomBackgroundColor = #colorLiteral(red: 0.49, green: 0.7, blue: 0.63, alpha: 1)
    static let backgroundColor = #colorLiteral(red: 0.3, green: 0.6, blue: 0.4999999999, alpha: 1)

    static let useDarkCopy = false
    static let copyViewX: CGFloat = 780
    static let copyViewY: CGFloat = AppStoreScreenshotLayout.copyViewY
    static let copyTitleX: CGFloat = 390
    static let copySubtitleX: CGFloat = copyTitleX

    static let inset: CGFloat = 80
    static let startScale: CGFloat = 6
    static let endScale: CGFloat = 0.01
    static let steps = 40
    static let startLength: CGFloat = 2486
    static let startHeight: CGFloat = 1400
    static let secondVerticalOffset: CGFloat = 60
    static let secondHorizontalLengthReduction: CGFloat = 60
    static let overlap: CGFloat = 0.5

    static let rulerColor = Prefs.defaultRulerFillColor
    static let startOpacity: CGFloat = 1
    static let endOpacity: CGFloat = 0.1
}

enum AppStoreGroupsScreenshotLayout {
    static let previewName = "Groups"
    static let title = "Be independent, or join forces."
    static let subtitle = "Drag rulers separately or as a group."
    static let outputFilename = "04-groups.png"
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
}

enum AppStoreFlipScreenshotLayout {
    static let previewName = "Flip Rulers"
    static let title = "Don’t flip out. Or do."
    static let subtitle = "Your rulers, in any orientation."
    static let outputFilename = "05-flip-rulers.png"
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
}

enum AppStoreUnitsScreenshotLayout {
    static let title = "Switch units instantly"
    static let subtitle = "Use pixels, millimeters, or inches."
    static let previewName = "Units"
    static let outputFilename = "06-switch-units.png"
    static let backgroundColor = #colorLiteral(red: 0.3528921235, green: 0.5961602394, blue: 0.5833017148, alpha: 1)
    static let bottomBackgroundColor = #colorLiteral(red: 0.3084420562, green: 0.521068275, blue: 0.509829402, alpha: 1)

    static let rulerScale: CGFloat = 6
    static let rulerX: CGFloat = 550
    static let rulerXOffset: CGFloat = -200
    static let firstRulerY: CGFloat = 620
    static let rulerVerticalSpacing: CGFloat = 350
    static let rulerLength: CGFloat = 2200
}

enum AppStorePreferencesScreenshotLayout {
    static let title = "Pick your preferences"
    static let subtitle = "Change dimensions, appearance, and more."
    static let previewName = "Preferences"
    static let outputFilename = "07-customize-rulers.png"
    static let backgroundColor = #colorLiteral(red: 0.5181607008, green: 0.4312165375, blue: 0.6487324834, alpha: 1)
    static let bottomBackgroundColor = #colorLiteral(red: 0.4593747268, green: 0.3822944866, blue: 0.5751329787, alpha: 1)

    static let rulerScale: CGFloat = 5
    static let rulerOpacity: CGFloat = 0.75
    static let verticalRulerX: CGFloat = 250
    static let verticalRulerY: CGFloat = 212
    static let verticalRulerLength: CGFloat = 2050
    static let horizontalRulerX: CGFloat = 80
    static let horizontalRulerY: CGFloat = 1465
    static let horizontalRulerLength: CGFloat = 3000
    static let preferencesWindowX: CGFloat = 800
    static let preferencesWindowY: CGFloat = 520
    static let preferencesWindowScale: CGFloat = 3.5
    static let preferencesContentWidth: CGFloat = 350
    static let preferencesContentHeight: CGFloat = 400
    static let preferencesWindowShadowOpacity: CGFloat = 0.28
    static let preferencesWindowShadowYOffset: CGFloat = -5

    static let backgroundOpacityPercent = 50
    static let floatRulers = true
    static let groupRulers = true
    static let rulerShadow = false
}

enum AppStoreScreenshotPreviewSelection {
    case measureAnything
    case colors
    case infinity
    case groups
    case flipRulers
    case units
    case preferences
}

#Preview("Measure anything") {
    AppStoreScreenshotPreviewContent(selection: .measureAnything)
}

#Preview("Colors") {
    AppStoreScreenshotPreviewContent(selection: .colors)
}

#Preview("Infinity") {
    AppStoreScreenshotPreviewContent(selection: .infinity)
}

#Preview("Groups") {
    AppStoreScreenshotPreviewContent(selection: .groups)
}

#Preview("Flip Rulers") {
    AppStoreScreenshotPreviewContent(selection: .flipRulers)
}

#Preview("Units") {
    AppStoreScreenshotPreviewContent(selection: .units)
}

#Preview("Preferences") {
    AppStoreScreenshotPreviewContent(selection: .preferences)
}

#endif
