import Cocoa

func windowAlphaValue(_ value: Int) -> CGFloat {
    return CGFloat(value) / 100.0
}

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

struct RulerSettings: Equatable, Codable {
    var unit: Unit
    var rulerColor: NSColor
    var foregroundOpacity: Int
    var backgroundOpacity: Int
    var floatRulers: Bool
    var rulerShadow: Bool
    var zeroCorner: ZeroCorner

    init(
        unit: Unit = .pixels,
        rulerColor: NSColor = Prefs.defaultRulerFillColor,
        foregroundOpacity: Int = 90,
        backgroundOpacity: Int = 50,
        floatRulers: Bool = true,
        rulerShadow: Bool = false,
        zeroCorner: ZeroCorner = Prefs.defaultZeroCorner
    ) {
        self.unit = unit
        self.rulerColor = RulerSettings.normalizedColor(rulerColor)
        self.foregroundOpacity = foregroundOpacity
        self.backgroundOpacity = backgroundOpacity
        self.floatRulers = floatRulers
        self.rulerShadow = rulerShadow
        self.zeroCorner = zeroCorner
    }

    init(defaults: Prefs = prefs) {
        self.init(
            unit: defaults.unit,
            rulerColor: defaults.rulerColor,
            foregroundOpacity: defaults.foregroundOpacity,
            backgroundOpacity: defaults.backgroundOpacity,
            floatRulers: defaults.floatRulers,
            rulerShadow: defaults.rulerShadow,
            zeroCorner: defaults.zeroCorner
        )
    }

    static func == (lhs: RulerSettings, rhs: RulerSettings) -> Bool {
        return lhs.unit == rhs.unit
            && Prefs.colorsMatch(lhs.rulerColor, rhs.rulerColor)
            && lhs.foregroundOpacity == rhs.foregroundOpacity
            && lhs.backgroundOpacity == rhs.backgroundOpacity
            && lhs.floatRulers == rhs.floatRulers
            && lhs.rulerShadow == rhs.rulerShadow
            && lhs.zeroCorner == rhs.zeroCorner
    }

    private enum CodingKeys: String, CodingKey {
        case unit
        case rulerColor
        case foregroundOpacity
        case backgroundOpacity
        case floatRulers
        case rulerShadow
        case zeroCorner
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let unitRawValue = try container.decodeIfPresent(Int.self, forKey: .unit) ?? Unit.pixels.rawValue
        let zeroCornerRawValue = try container.decodeIfPresent(Int.self, forKey: .zeroCorner)
            ?? Prefs.defaultZeroCorner.rawValue
        let colorComponents = try container.decodeIfPresent(RulerColorComponents.self, forKey: .rulerColor)

        self.init(
            unit: Unit(rawValue: unitRawValue) ?? .pixels,
            rulerColor: colorComponents?.color ?? Prefs.defaultRulerFillColor,
            foregroundOpacity: try container.decodeIfPresent(Int.self, forKey: .foregroundOpacity) ?? 90,
            backgroundOpacity: try container.decodeIfPresent(Int.self, forKey: .backgroundOpacity) ?? 50,
            floatRulers: try container.decodeIfPresent(Bool.self, forKey: .floatRulers) ?? true,
            rulerShadow: try container.decodeIfPresent(Bool.self, forKey: .rulerShadow) ?? false,
            zeroCorner: Prefs.zeroCorner(fromRawValue: zeroCornerRawValue)
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(unit.rawValue, forKey: .unit)
        try container.encode(RulerColorComponents(color: rulerColor), forKey: .rulerColor)
        try container.encode(foregroundOpacity, forKey: .foregroundOpacity)
        try container.encode(backgroundOpacity, forKey: .backgroundOpacity)
        try container.encode(floatRulers, forKey: .floatRulers)
        try container.encode(rulerShadow, forKey: .rulerShadow)
        try container.encode(zeroCorner.rawValue, forKey: .zeroCorner)
    }

    mutating func setRulerColor(_ color: NSColor) {
        rulerColor = RulerSettings.normalizedColor(color)
    }

    private static func normalizedColor(_ color: NSColor) -> NSColor {
        guard let rgbColor = color.usingColorSpace(.deviceRGB) else {
            return Prefs.defaultRulerFillColor
        }

        return NSColor(
            deviceRed: rgbColor.redComponent,
            green: rgbColor.greenComponent,
            blue: rgbColor.blueComponent,
            alpha: 1
        )
    }
}

private struct RulerColorComponents: Equatable, Codable {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat

    init(color: NSColor) {
        let rgbColor = color.usingColorSpace(.deviceRGB) ?? Prefs.defaultRulerFillColor

        red = rgbColor.redComponent
        green = rgbColor.greenComponent
        blue = rgbColor.blueComponent
        alpha = rgbColor.alphaComponent
    }

    var color: NSColor {
        return NSColor(
            deviceRed: red,
            green: green,
            blue: blue,
            alpha: alpha
        )
    }
}

struct RulerWingVisibility: Equatable, Codable {
    private(set) var showsHorizontal: Bool
    private(set) var showsVertical: Bool

    init(horizontal: Bool = true, vertical: Bool = true) {
        if horizontal || vertical {
            showsHorizontal = horizontal
            showsVertical = vertical
        } else {
            showsHorizontal = true
            showsVertical = true
        }
    }

    var hasVisibleWing: Bool {
        return showsHorizontal || showsVertical
    }

    func isVisible(_ orientation: Orientation) -> Bool {
        switch orientation {
        case .horizontal:
            return showsHorizontal
        case .vertical:
            return showsVertical
        }
    }

    @discardableResult
    mutating func toggle(_ orientation: Orientation) -> Bool {
        return set(orientation, isVisible: !isVisible(orientation))
    }

    @discardableResult
    mutating func set(_ orientation: Orientation, isVisible: Bool) -> Bool {
        guard canSet(orientation, isVisible: isVisible) else { return false }

        switch orientation {
        case .horizontal:
            showsHorizontal = isVisible
        case .vertical:
            showsVertical = isVisible
        }

        return true
    }

    private func canSet(_ orientation: Orientation, isVisible: Bool) -> Bool {
        guard !isVisible, self.isVisible(orientation) else { return true }

        switch orientation {
        case .horizontal:
            return showsVertical
        case .vertical:
            return showsHorizontal
        }
    }

    private enum CodingKeys: String, CodingKey {
        case showsHorizontal
        case showsVertical
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.init(
            horizontal: try container.decodeIfPresent(Bool.self, forKey: .showsHorizontal) ?? true,
            vertical: try container.decodeIfPresent(Bool.self, forKey: .showsVertical) ?? true
        )
    }
}

struct RulerLayoutState: Equatable, Codable {
    var zeroPoint: NSPoint
    var horizontalLength: CGFloat
    var verticalLength: CGFloat

    init(
        zeroPoint: NSPoint,
        horizontalLength: CGFloat,
        verticalLength: CGFloat
    ) {
        self.zeroPoint = zeroPoint
        self.horizontalLength = max(0, horizontalLength)
        self.verticalLength = max(0, verticalLength)
    }

    init(
        horizontalFrame: NSRect,
        verticalFrame: NSRect,
        zeroCorner: ZeroCorner
    ) {
        self.init(
            zeroPoint: ZeroCornerGeometry(zeroCorner: zeroCorner).zeroPoint(
                in: horizontalFrame,
                for: .horizontal
            ),
            horizontalLength: horizontalFrame.width,
            verticalLength: verticalFrame.height
        )
    }

    static func defaults(
        zeroCorner: ZeroCorner,
        screenFrame: NSRect = defaultRulerScreenFrame(),
        horizontalLength: CGFloat? = nil,
        verticalLength: CGFloat? = nil
    ) -> RulerLayoutState {
        let geometry = ZeroCornerGeometry(zeroCorner: zeroCorner)

        return RulerLayoutState(
            horizontalFrame: geometry.defaultFrame(
                for: .horizontal,
                screenFrame: screenFrame,
                horizontalLength: horizontalLength,
                verticalLength: verticalLength
            ),
            verticalFrame: geometry.defaultFrame(
                for: .vertical,
                screenFrame: screenFrame,
                horizontalLength: horizontalLength,
                verticalLength: verticalLength
            ),
            zeroCorner: zeroCorner
        )
    }

    static func defaultLengths(screenFrame: NSRect = defaultRulerScreenFrame()) -> (
        horizontal: CGFloat,
        vertical: CGFloat
    ) {
        let horizontalLength = screenFrame.width / 2
        let aspectRatio = screenFrame.width / screenFrame.height
        let verticalLength = horizontalLength / aspectRatio

        return (horizontalLength, verticalLength)
    }

    func layout(zeroCorner: ZeroCorner) -> RulerWindowLayout {
        return RulerWindowLayout.layout(
            horizontalLength: horizontalLength,
            verticalLength: verticalLength,
            zeroPoint: zeroPoint,
            zeroCorner: zeroCorner
        )
    }
}

struct RulerInstanceState: Identifiable, Equatable, Codable {
    var id: UUID
    var settings: RulerSettings
    var visibility: RulerWingVisibility
    var layout: RulerLayoutState

    init(
        id: UUID = UUID(),
        settings: RulerSettings,
        visibility: RulerWingVisibility = RulerWingVisibility(),
        layout: RulerLayoutState
    ) {
        self.id = id
        self.settings = settings
        self.visibility = visibility
        self.layout = layout
    }

    static func createFromDefaults(
        id: UUID = UUID(),
        defaults: RulerSettings = RulerSettings(defaults: prefs),
        screenFrame: NSRect = defaultRulerScreenFrame()
    ) -> RulerInstanceState {
        return RulerInstanceState(
            id: id,
            settings: defaults,
            layout: RulerLayoutState.defaults(
                zeroCorner: defaults.zeroCorner,
                screenFrame: screenFrame,
                horizontalLength: prefs.customDefaultHorizontalLength,
                verticalLength: prefs.customDefaultVerticalLength
            )
        )
    }

    var hasVisibleWing: Bool {
        return visibility.hasVisibleWing
    }

    func isWingVisible(_ orientation: Orientation) -> Bool {
        return visibility.isVisible(orientation)
    }

    @discardableResult
    mutating func toggleWing(_ orientation: Orientation) -> Bool {
        return visibility.toggle(orientation)
    }

    @discardableResult
    mutating func setWing(_ orientation: Orientation, isVisible: Bool) -> Bool {
        return visibility.set(orientation, isVisible: isVisible)
    }
}

struct StoredRulerSetState: Equatable, Codable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int
    var rulers: [RulerInstanceState]
    var activeRulerID: UUID?

    init(
        schemaVersion: Int = StoredRulerSetState.currentSchemaVersion,
        rulers: [RulerInstanceState],
        activeRulerID: UUID?
    ) {
        self.schemaVersion = schemaVersion
        self.rulers = rulers
        self.activeRulerID = activeRulerID
    }

    func sanitizedForRestore() -> StoredRulerSetState? {
        let visibleRulers = rulers.filter(\.hasVisibleWing)
        guard !visibleRulers.isEmpty else { return nil }

        let restoredActiveRulerID = activeRulerID.flatMap { activeRulerID in
            visibleRulers.contains { $0.id == activeRulerID } ? activeRulerID : nil
        }

        return StoredRulerSetState(
            schemaVersion: schemaVersion,
            rulers: visibleRulers,
            activeRulerID: restoredActiveRulerID
        )
    }
}

struct RulerCornerPlacement: Equatable {
    let xSide: RulerHorizontalSide
    let ySide: RulerVerticalSide
}

struct ZeroCornerGeometry {
    let zeroCorner: ZeroCorner

    static let borderCompensation: CGFloat = 1.0
    private let borderCompensation = ZeroCornerGeometry.borderCompensation

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

    func defaultFrame(
        for orientation: Orientation,
        screenFrame: NSRect,
        horizontalLength customHorizontalLength: CGFloat? = nil,
        verticalLength customVerticalLength: CGFloat? = nil
    ) -> NSRect {
        let xOffset: CGFloat = 30
        let yOffset: CGFloat = 50
        let defaultLengths = RulerLayoutState.defaultLengths(screenFrame: screenFrame)
        let horizontalLength = customHorizontalLength ?? defaultLengths.horizontal
        let verticalLength = customVerticalLength ?? defaultLengths.vertical
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

    var horizontalZeroSide: RulerHorizontalSide {
        switch zeroCorner {
        case .topLeft, .bottomLeft:
            return .left
        case .topRight, .bottomRight:
            return .right
        }
    }

    var verticalZeroSide: RulerVerticalSide {
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
    return ZeroCornerGeometry(zeroCorner: zeroCorner).defaultFrame(
        for: orientation,
        screenFrame: defaultRulerScreenFrame()
    )
}

func defaultRulerScreenFrame() -> NSRect {
    let fallbackScreenFrame = NSRect(x: 0, y: 0, width: 1000, height: 800)
    return NSScreen.main?.frame ?? fallbackScreenFrame
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
