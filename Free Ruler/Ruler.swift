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
            x: xOffset + rulerThickness,
            y: screenHeight - yOffset - rulerThickness,
            width: horizontalLength,
            height: rulerThickness
        )
    case .vertical:
        return NSRect(
            x: xOffset,
            y: screenHeight - yOffset - rulerThickness - verticalLength,
            width: rulerThickness,
            height: verticalLength
        )
    }
    
}
