import Cocoa
import SwiftyUserDefaults

enum Orientation: String {
    case Horizontal
    case Vertical
}


struct Ruler {
    let orientation: Orientation
    var frame: NSRect
    
    init(orientation: Orientation, frame: NSRect?) {
        self.orientation = orientation
        if let frame = frame {
            self.frame = frame
        } else {
            self.frame = getDefaultContentRect(orientation: orientation)
        }
    }
    
    init(orientation: Orientation) {
        self.init(orientation: orientation, frame: nil)
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
    case .Horizontal:
        return NSRect(
            x: xOffset + rulerThickness,
            y: screenHeight - yOffset - rulerThickness,
            width: horizontalLength,
            height: rulerThickness
        )
    case .Vertical:
        return NSRect(
            x: xOffset,
            y: screenHeight - yOffset - rulerThickness - verticalLength,
            width: rulerThickness,
            height: verticalLength
        )
    }
    
}
