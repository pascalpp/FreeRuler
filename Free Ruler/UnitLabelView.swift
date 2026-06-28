import Cocoa

final class UnitLabelView: NSView {
    private struct Padding {
        let top: CGFloat
        let bottom: CGFloat
        let left: CGFloat
        let right: CGFloat
    }

    private static let padding = Padding(top: 4, bottom: 9, left: 8, right: 8)
    private static let descenderSafetyPadding: CGFloat = 2

    var label: NSAttributedString {
        didSet {
            needsDisplay = true
        }
    }
    var zeroCorner = prefs.zeroCorner {
        didSet {
            needsDisplay = true
        }
    }

    private let orientation: Orientation

    init(orientation: Orientation, label: NSAttributedString) {
        self.orientation = orientation
        self.label = label
        super.init(frame: .zero)

        setAccessibilityElement(false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init(orientation:label:)")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let placement = ZeroCornerGeometry(zeroCorner: zeroCorner)
            .unitLabelPlacement(for: orientation)
        let labelRect = Self.labelDrawRect(
            labelSize: Self.labelSize(for: label),
            bounds: bounds,
            placement: placement
        )

        label.draw(with: labelRect, context: nil)
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        return rulerContextMenu(for: self)
    }

    func frame(in bounds: NSRect) -> NSRect {
        return frame(in: bounds, zeroCorner: zeroCorner)
    }

    func frame(in bounds: NSRect, zeroCorner: ZeroCorner) -> NSRect {
        return Self.labelFrame(
            labelSize: Self.labelSize(for: label),
            rulerSize: bounds.size,
            orientation: orientation,
            zeroCorner: zeroCorner
        )
    }

    static func labelSize(for label: NSAttributedString) -> NSSize {
        var size = label.size()
        guard label.length > 0,
              let font = label.attribute(.font, at: 0, effectiveRange: nil) as? NSFont else {
            return size
        }

        size.height = ceil(font.ascender - font.descender + font.leading)
        return size
    }

    static func labelFrame(
        labelSize: NSSize,
        rulerSize: NSSize,
        orientation: Orientation,
        zeroCorner: ZeroCorner
    ) -> NSRect {
        let placement = ZeroCornerGeometry(zeroCorner: zeroCorner)
            .unitLabelPlacement(for: orientation)
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let height: CGFloat

        switch placement.xSide {
        case .left:
            x = 0
            width = Self.padding.left + labelSize.width
        case .right:
            x = rulerSize.width - labelSize.width - Self.padding.right
            width = labelSize.width + Self.padding.right
        }

        switch placement.ySide {
        case .top:
            y = rulerSize.height - labelSize.height - Self.padding.top
            height = labelSize.height + Self.padding.top
        case .bottom:
            y = 0
            height = Self.padding.bottom + labelSize.height
        }

        return NSRect(x: x, y: y, width: width, height: height)
    }

    static func labelDrawRect(
        labelSize: NSSize,
        bounds: NSRect,
        placement: RulerCornerPlacement
    ) -> NSRect {
        let x: CGFloat
        let y: CGFloat

        switch placement.xSide {
        case .left:
            x = bounds.maxX - labelSize.width
        case .right:
            x = bounds.minX
        }

        switch placement.ySide {
        case .top:
            y = bounds.minY + min(
                Self.descenderSafetyPadding,
                max(0, bounds.height - labelSize.height)
            )
        case .bottom:
            y = bounds.maxY - labelSize.height
        }

        return NSRect(x: x, y: y, width: labelSize.width, height: labelSize.height)
    }
}
