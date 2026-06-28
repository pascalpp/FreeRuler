import Cocoa

final class RulerCursorController {
    enum CursorStyle: Equatable {
        case arrow
        case crosshair
        case openHand
        case closedHand

        var uiTestStateValue: String {
            switch self {
            case .arrow:
                return "arrow"
            case .crosshair:
                return "crosshair"
            case .openHand:
                return "open-hand"
            case .closedHand:
                return "closed-hand"
            }
        }

        var nsCursor: NSCursor {
            switch self {
            case .arrow:
                return .arrow
            case .crosshair:
                return RulerCrosshairCursor.cursor
            case .openHand:
                return .openHand
            case .closedHand:
                return .closedHand
            }
        }
    }

    private var appIsActive = false
    private var mouseIsOverRuler = false
    private var mouseIsDraggingRuler = false
    private let applyCursor: (CursorStyle) -> Void

    private(set) var currentCursor: CursorStyle?

    init(applyCursor: @escaping (CursorStyle) -> Void = { $0.nsCursor.set() }) {
        self.applyCursor = applyCursor
    }

    func applicationDidBecomeActive() {
        appIsActive = true
        updateCursor()
    }

    func applicationDidResignActive() {
        appIsActive = false
        mouseIsOverRuler = false
        mouseIsDraggingRuler = false
        setCursor(.arrow)
    }

    func mouseEnteredRuler() {
        mouseIsOverRuler = true
        updateCursor()
    }

    func mouseExitedRuler() {
        mouseIsOverRuler = false
        updateCursor()
    }

    func mouseDownInRuler() {
        mouseIsOverRuler = true
        mouseIsDraggingRuler = true
        updateCursor()
    }

    func mouseUpInRuler(mouseIsInsideRuler: Bool) {
        mouseIsOverRuler = mouseIsInsideRuler
        mouseIsDraggingRuler = false
        updateCursor()

        if mouseIsInsideRuler {
            DispatchQueue.main.async { [weak self] in
                self?.refreshCurrentCursor()
            }
        }
    }

    func refreshCurrentCursor() {
        guard appIsActive, let currentCursor = currentCursor else { return }

        applyCursor(currentCursor)
    }

    private func updateCursor() {
        guard appIsActive else { return }

        if mouseIsDraggingRuler {
            setCursor(.closedHand)
        } else if mouseIsOverRuler {
            setCursor(.openHand)
        } else {
            setCursor(.crosshair)
        }
    }

    private func setCursor(_ cursor: CursorStyle) {
        guard cursor != currentCursor else { return }

        currentCursor = cursor
        applyCursor(cursor)
        cursor.writeUITestStateIfNeeded()
    }
}

private extension RulerCursorController.CursorStyle {
    func writeUITestStateIfNeeded() {
        UITestSupport.current?.writeCursorState(uiTestStateValue)
    }
}

private enum RulerCrosshairCursor {
    static let cursor = NSCursor(image: image, hotSpot: hotSpot)

    private static let imageSize = NSSize(width: 17, height: 17)
    private static let pixelScale = 2
    private static let pixelSize = Int(imageSize.width) * pixelScale
    private static let hotSpot = NSPoint(x: 8.5, y: 8.5)
    private static let outlineRange = 14...19
    private static let strokeRange = 16...17
    private static let outlineExtent = 2...31
    private static let strokeExtent = 4...29

    private static let image: NSImage = {
        let image = NSImage(size: imageSize)

        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelSize,
            pixelsHigh: pixelSize,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bitmapFormat: [.alphaNonpremultiplied],
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            image.isTemplate = false
            return image
        }

        bitmap.size = imageSize
        drawCrosshair(in: bitmap)
        image.addRepresentation(bitmap)
        image.isTemplate = false

        return image
    }()

    private static func drawCrosshair(in bitmap: NSBitmapImageRep) {
        for offset in outlineExtent {
            for crosshairPixel in outlineRange {
                setPixel(.white, atX: offset, y: crosshairPixel, in: bitmap)
                setPixel(.white, atX: crosshairPixel, y: offset, in: bitmap)
            }
        }

        for offset in strokeExtent {
            for crosshairPixel in strokeRange {
                setPixel(.black, atX: offset, y: crosshairPixel, in: bitmap)
                setPixel(.black, atX: crosshairPixel, y: offset, in: bitmap)
            }
        }
    }

    private enum Pixel {
        case black
        case white

        var rgba: (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
            switch self {
            case .black:
                return (0, 0, 0, 255)
            case .white:
                return (255, 255, 255, 255)
            }
        }
    }

    private static func setPixel(
        _ pixel: Pixel,
        atX x: Int,
        y: Int,
        in bitmap: NSBitmapImageRep
    ) {
        guard (0..<bitmap.pixelsWide).contains(x),
              (0..<bitmap.pixelsHigh).contains(y),
              let bitmapData = bitmap.bitmapData else { return }

        let offset = (y * bitmap.bytesPerRow) + (x * 4)
        let rgba = pixel.rgba

        bitmapData[offset] = rgba.red
        bitmapData[offset + 1] = rgba.green
        bitmapData[offset + 2] = rgba.blue
        bitmapData[offset + 3] = rgba.alpha
    }
}
