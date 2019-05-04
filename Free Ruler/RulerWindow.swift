import Cocoa

class RulerWindow: NSPanel {
    
    var type: RulerType
    var rule: RulerView
    
    init(type: RulerType) {
        self.type = type

        let contentRect = getContentRect(type: type)
        self.rule = getRulerView(type: type, contentRect: contentRect)

        let styleMask: NSWindow.StyleMask = [
            .borderless,
            .resizable,
            .fullSizeContentView,
        ]

        super.init(
            contentRect: contentRect,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        
        self.minSize = getMinSize(type: type)
        self.maxSize = getMaxSize(type: type)
        
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

func getContentRect(type: RulerType) -> NSRect {
    var screenHeight: CGFloat = 1000
    if let screen = NSScreen.main?.frame {
        screenHeight = screen.height
    }
    
    let initialOffset: CGFloat = 50
    let rulerLength: CGFloat = 600
    let rulerThickness: CGFloat = 40
    
    switch type {
    case .Horizontal:
        return NSRect(
            x: initialOffset + rulerThickness,
            y: screenHeight - initialOffset - rulerThickness,
            width: rulerLength,
            height: rulerThickness
        )
    case .Vertical:
        return NSRect(
            x: initialOffset,
            y: screenHeight - initialOffset - rulerThickness - rulerLength,
            width: rulerThickness,
            height: rulerLength
        )
    }
    
}

func getMinSize(type: RulerType) -> NSSize {
    switch type {
    case .Horizontal:
        return NSSize(width: 200, height: 40)
    case .Vertical:
        return NSSize(width: 40, height: 200)
    }
}

func getMaxSize(type: RulerType) -> NSSize {
    switch type {
    case .Horizontal:
        return NSSize(width: 20000, height: 40)
    case .Vertical:
        return NSSize(width: 40, height: 20000)
    }
}

func getRulerView(type: RulerType, contentRect: NSRect) -> RulerView {
    switch type {
    case .Horizontal:
        return HorizontalRule(frame: contentRect)
    case .Vertical:
        return VerticalRule(frame: contentRect)
    }
}
