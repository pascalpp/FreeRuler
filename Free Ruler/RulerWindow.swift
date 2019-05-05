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
    }
    
    override var canBecomeKey: Bool {
        return true
    }

}


func getMinSize(ruler: Ruler) -> NSSize {
    switch ruler.orientation {
    case .Horizontal:
        return NSSize(width: 200, height: 40)
    case .Vertical:
        return NSSize(width: 40, height: 200)
    }
}

func getMaxSize(ruler: Ruler) -> NSSize {
    switch ruler.orientation {
    case .Horizontal:
        return NSSize(width: 20000, height: 40)
    case .Vertical:
        return NSSize(width: 40, height: 20000)
    }
}

func getRulerView(ruler: Ruler) -> RuleView {
    switch ruler.orientation {
    case .Horizontal:
        return HorizontalRule(frame: ruler.frame)
    case .Vertical:
        return VerticalRule(frame: ruler.frame)
    }
}
