import Cocoa

enum Orientation: String {
    case horizontal
    case vertical
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
    var screenWidth: CGFloat = 1000
    var screenHeight: CGFloat = 800
    if let screen = NSScreen.main?.frame {
        screenWidth = screen.width
        screenHeight = screen.height
    }
    
    let aspectRatio = screenWidth / screenHeight
    let xOffset: CGFloat = 30
    let yOffset: CGFloat = 50
    let rulerThickness: CGFloat = 40
    
    let horizontalLength = screenWidth / 2
    let verticalLength = horizontalLength / aspectRatio
    
    switch orientation {
    case .horizontal:
        return NSRect(
            // offset horizontal by 1px leftward to compensate for ruler border
            x: xOffset + rulerThickness - 1.0,
            y: screenHeight - yOffset - rulerThickness,
            width: horizontalLength,
            height: rulerThickness
        )
    case .vertical:
        return NSRect(
            // offset vertical by 1px upward to compensate for ruler border
            x: xOffset,
            y: screenHeight - yOffset - rulerThickness - verticalLength + 1.0,
            width: rulerThickness,
            height: verticalLength
        )
    }
    
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
