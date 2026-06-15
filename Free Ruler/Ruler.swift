import Cocoa

enum Orientation: String {
    case horizontal
    case vertical
}

@objc enum ZeroCorner: Int {
    case topLeft = 0
    case topRight = 1
    case bottomLeft = 2
    case bottomRight = 3
}

extension ZeroCorner {
    func flipped(along orientation: Orientation) -> ZeroCorner {
        switch (self, orientation) {
        case (.topLeft, .horizontal):
            return .topRight
        case (.topRight, .horizontal):
            return .topLeft
        case (.bottomLeft, .horizontal):
            return .bottomRight
        case (.bottomRight, .horizontal):
            return .bottomLeft
        case (.topLeft, .vertical):
            return .bottomLeft
        case (.topRight, .vertical):
            return .bottomRight
        case (.bottomLeft, .vertical):
            return .topLeft
        case (.bottomRight, .vertical):
            return .topRight
        }
    }
}

enum RulerGrowthDirection: Equatable {
    case positive
    case negative
}

enum RulerHorizontalSide: Equatable {
    case left
    case right

    var opposite: RulerHorizontalSide {
        switch self {
        case .left:
            return .right
        case .right:
            return .left
        }
    }
}

enum RulerVerticalSide: Equatable {
    case top
    case bottom

    var opposite: RulerVerticalSide {
        switch self {
        case .top:
            return .bottom
        case .bottom:
            return .top
        }
    }
}

struct RulerCornerPlacement: Equatable {
    let xSide: RulerHorizontalSide
    let ySide: RulerVerticalSide
}

struct ZeroCornerGeometry {
    let zeroCorner: ZeroCorner

    private let borderCompensation: CGFloat = 1.0

    init(zeroCorner: ZeroCorner) {
        self.zeroCorner = zeroCorner
    }

    func growthDirection(for orientation: Orientation) -> RulerGrowthDirection {
        switch orientation {
        case .horizontal:
            return horizontalZeroSide == .left ? .positive : .negative
        case .vertical:
            return verticalZeroSide == .bottom ? .positive : .negative
        }
    }

    var horizontalTickSide: RulerVerticalSide {
        return verticalZeroSide.opposite
    }

    var verticalTickSide: RulerHorizontalSide {
        return horizontalZeroSide.opposite
    }

    var horizontalResizeSide: RulerHorizontalSide {
        return horizontalZeroSide.opposite
    }

    var verticalResizeSide: RulerVerticalSide {
        return verticalZeroSide.opposite
    }

    func resizeHandlePlacement(for orientation: Orientation) -> RulerCornerPlacement {
        switch orientation {
        case .horizontal:
            return RulerCornerPlacement(
                xSide: horizontalZeroSide.opposite,
                ySide: verticalZeroSide
            )
        case .vertical:
            return RulerCornerPlacement(
                xSide: horizontalZeroSide,
                ySide: verticalZeroSide.opposite
            )
        }
    }

    func unitLabelPlacement(for orientation: Orientation) -> RulerCornerPlacement {
        return RulerCornerPlacement(
            xSide: horizontalZeroSide,
            ySide: verticalZeroSide
        )
    }

    func zeroPoint(in frame: NSRect, for orientation: Orientation) -> NSPoint {
        switch orientation {
        case .horizontal:
            return NSPoint(
                x: horizontalZeroSide == .left ? frame.minX : frame.maxX,
                y: verticalZeroSide == .top ? frame.minY + borderCompensation : frame.maxY - borderCompensation
            )
        case .vertical:
            return NSPoint(
                x: horizontalZeroSide == .left ? frame.maxX - borderCompensation : frame.minX,
                y: verticalZeroSide == .top ? frame.maxY : frame.minY
            )
        }
    }

    func frame(for orientation: Orientation, zeroPoint: NSPoint, size: NSSize) -> NSRect {
        switch orientation {
        case .horizontal:
            return NSRect(
                x: horizontalZeroSide == .left ? zeroPoint.x : zeroPoint.x - size.width,
                y: verticalZeroSide == .top ? zeroPoint.y - borderCompensation : zeroPoint.y - size.height + borderCompensation,
                width: size.width,
                height: size.height
            )
        case .vertical:
            return NSRect(
                x: horizontalZeroSide == .left ? zeroPoint.x - size.width + borderCompensation : zeroPoint.x,
                y: verticalZeroSide == .top ? zeroPoint.y - size.height : zeroPoint.y,
                width: size.width,
                height: size.height
            )
        }
    }

    func defaultFrame(for orientation: Orientation, screenFrame: NSRect) -> NSRect {
        let xOffset: CGFloat = 30
        let yOffset: CGFloat = 50
        let horizontalLength = screenFrame.width / 2
        let aspectRatio = screenFrame.width / screenFrame.height
        let verticalLength = horizontalLength / aspectRatio
        let topLeftZeroPoint = NSPoint(
            x: screenFrame.minX + xOffset + Ruler.thickness - borderCompensation,
            y: screenFrame.maxY - yOffset - Ruler.thickness + borderCompensation
        )
        let zeroPoint = zeroPointMatchingSelectedCorner(
            topLeftZeroPoint: topLeftZeroPoint,
            horizontalLength: horizontalLength,
            verticalLength: verticalLength
        )

        switch orientation {
        case .horizontal:
            return frame(
                for: orientation,
                zeroPoint: zeroPoint,
                size: NSSize(width: horizontalLength, height: Ruler.thickness)
            )
        case .vertical:
            return frame(
                for: orientation,
                zeroPoint: zeroPoint,
                size: NSSize(width: Ruler.thickness, height: verticalLength)
            )
        }
    }

    private var horizontalZeroSide: RulerHorizontalSide {
        switch zeroCorner {
        case .topLeft, .bottomLeft:
            return .left
        case .topRight, .bottomRight:
            return .right
        }
    }

    private var verticalZeroSide: RulerVerticalSide {
        switch zeroCorner {
        case .topLeft, .topRight:
            return .top
        case .bottomLeft, .bottomRight:
            return .bottom
        }
    }

    private func zeroPointMatchingSelectedCorner(
        topLeftZeroPoint: NSPoint,
        horizontalLength: CGFloat,
        verticalLength: CGFloat
    ) -> NSPoint {
        var point = topLeftZeroPoint

        if horizontalZeroSide == .right {
            point.x += horizontalLength
        }

        if verticalZeroSide == .bottom {
            point.y -= verticalLength
        }

        return point
    }
}

class Ruler {
    static let thickness: CGFloat = 40

    let orientation: Orientation
    let frame: NSRect
    let name: String? // used for frameAutosaveName

    init(orientation: Orientation, frame: NSRect?, name: String?) {
        self.orientation = orientation
        self.name = name
        self.frame = frame ?? getDefaultContentRect(orientation: orientation)
    }

    convenience init(_ orientation: Orientation, frame: NSRect?, name: String?) {
        self.init(orientation: orientation, frame: frame, name: name)
    }

    convenience init(_ orientation: Orientation, name: String) {
        self.init(orientation, frame: nil, name: name)
    }

    convenience init(_ orientation: Orientation, frame: NSRect) {
        self.init(orientation, frame: frame, name: nil)
    }

    convenience init(_ orientation: Orientation) {
        self.init(orientation, frame: nil, name: nil)
    }

}

// MARK: - Ruler size helpers

func getDefaultContentRect(orientation: Orientation) -> NSRect {
    return getDefaultContentRect(orientation: orientation, zeroCorner: .topLeft)
}

func getDefaultContentRect(orientation: Orientation, zeroCorner: ZeroCorner) -> NSRect {
    let fallbackScreenFrame = NSRect(x: 0, y: 0, width: 1000, height: 800)
    let screenFrame = NSScreen.main?.frame ?? fallbackScreenFrame

    return ZeroCornerGeometry(zeroCorner: zeroCorner).defaultFrame(
        for: orientation,
        screenFrame: screenFrame
    )
}

func getMinSize(ruler: Ruler) -> NSSize {
    switch ruler.orientation {
    case .horizontal:
        return NSSize(width: 200, height: 40)
    case .vertical:
        return NSSize(width: 40, height: 200)
    }
}

func getMaxSize(ruler: Ruler) -> NSSize {
    switch ruler.orientation {
    case .horizontal:
        return NSSize(width: 4000, height: 40)
    case .vertical:
        return NSSize(width: 40, height: 4000)
    }
}

func getRulerView(ruler: Ruler) -> RuleView {
    switch ruler.orientation {
    case .horizontal:
        return HorizontalRule(frame: ruler.frame)
    case .vertical:
        return VerticalRule(frame: ruler.frame)
    }
}
