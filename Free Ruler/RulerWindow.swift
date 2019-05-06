import Cocoa

class RulerWindow: NSPanel {
    
    var ruler: Ruler
    var rule: RuleView
    
    init(ruler: Ruler) {
        self.ruler = ruler
        self.rule = getRulerView(ruler: ruler)

        let styleMask: NSWindow.StyleMask = [
            .borderless,
            .resizable,
            .fullSizeContentView,
        ]

        super.init(
            contentRect: ruler.frame,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        
        self.minSize = getMinSize(ruler: ruler)
        self.maxSize = getMaxSize(ruler: ruler)
        
        self.isFloatingPanel = true
        self.hidesOnDeactivate = false
        self.isMovableByWindowBackground = true
        // self.hasShadow = false
        
        self.contentView = self.rule
        if let frameAutosaveName = ruler.name {
            self.setFrameAutosaveName(frameAutosaveName)
        }
    }
    
    override var canBecomeKey: Bool {
        return true
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
        return NSSize(width: 20000, height: 40)
    case .vertical:
        return NSSize(width: 40, height: 20000)
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

extension RulerWindow {
    private enum Distance: CGFloat {
        case aLittle = 1
        case aLot = 10
    }

    func moveHorizontally(by pixels: CGFloat) {
        var position = frame.origin
        position.x = position.x + pixels
        setFrameOrigin(position)
    }

    func moveVertically(by pixels: CGFloat) {
        var position = frame.origin
        position.y = position.y + pixels
        setFrameOrigin(position)
    }

    private func distance(withShift: Bool) -> CGFloat {
        let distance = withShift ? Distance.aLot : Distance.aLittle
        return distance.rawValue
    }

    func nudgeLeft(withShift shiftPressed: Bool) {
        let distance = self.distance(withShift: shiftPressed)
        moveHorizontally(by: distance * -1)
    }

    func nudgeRight(withShift shiftPressed: Bool) {
        let distance = self.distance(withShift: shiftPressed)
        moveHorizontally(by: distance)
    }

    func nudgeDown(withShift shiftPressed: Bool) {
        let distance = self.distance(withShift: shiftPressed)
        moveVertically(by: distance * -1)
    }

    func nudgeUp(withShift shiftPressed: Bool) {
        let distance = self.distance(withShift: shiftPressed)
        moveVertically(by: distance)
    }

}
