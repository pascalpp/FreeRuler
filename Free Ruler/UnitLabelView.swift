import Cocoa

final class UnitLabelView: NSView {
    var label: NSAttributedString {
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

        label.draw(with: bounds, context: nil)
    }

    func frame(in bounds: NSRect) -> NSRect {
        return frame(in: bounds, zeroCorner: prefs.zeroCorner)
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
        let topInset: CGFloat = 2
        let bottomInset: CGFloat = 9
        let leftInset: CGFloat = 8
        let rightInset: CGFloat = 8
        let x: CGFloat
        let y: CGFloat

        switch (placement.xSide, placement.ySide) {
        case (.left, .top):
            x = leftInset
            y = rulerSize.height - labelSize.height - topInset
        case (.right, .top):
            x = rulerSize.width - labelSize.width - rightInset
            y = rulerSize.height - labelSize.height - topInset
        case (.left, .bottom):
            x = leftInset
            y = bottomInset
        case (.right, .bottom):
            x = rulerSize.width - labelSize.width - rightInset
            y = bottomInset
        case (_, _):
            assertionFailure("Unit label must be anchored to left/right and top/bottom sides")
            x = leftInset
            y = topInset
        }

        return NSRect(x: x, y: y, width: labelSize.width, height: labelSize.height)
    }
}
