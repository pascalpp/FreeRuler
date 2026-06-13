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
        return Self.labelFrame(
            labelSize: Self.labelSize(for: label),
            rulerSize: bounds.size,
            orientation: orientation,
            zeroCorner: prefs.zeroCorner
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

        switch (orientation, placement.xSide) {
        case (.horizontal, .left):
            x = 10
        case (.horizontal, .right):
            x = rulerSize.width - labelSize.width - 10
        case (.vertical, .left):
            x = 8
        case (.vertical, .right):
            x = rulerSize.width - labelSize.width - 8
        case (.horizontal, .top), (.horizontal, .bottom):
            assertionFailure("Horizontal unit label must be anchored to a horizontal corner side")
            x = 10
        case (.vertical, .top), (.vertical, .bottom):
            assertionFailure("Vertical unit label must be anchored to a horizontal corner side")
            x = 8
        }

        switch (orientation, placement.ySide) {
        case (.horizontal, .top):
            y = rulerSize.height - labelSize.height
        case (.horizontal, .bottom):
            y = 8
        case (.vertical, .top):
            y = rulerSize.height - labelSize.height - 2
        case (.vertical, .bottom):
            y = 8
        case (.horizontal, .left), (.horizontal, .right):
            assertionFailure("Horizontal unit label must be anchored to a vertical corner side")
            y = rulerSize.height - labelSize.height
        case (.vertical, .left), (.vertical, .right):
            assertionFailure("Vertical unit label must be anchored to a vertical corner side")
            y = 8
        }

        return NSRect(x: x, y: y, width: labelSize.width, height: labelSize.height)
    }
}
