import Cocoa

let titlebarHeight: CGFloat = 22

class AppIconHelper: NSObject {
    
    func show() {
        self.showAppIconBackdrop()
        self.showAppIconRulers()
        self.showAppIconRulersEffShape()
        self.showAppIconRulersEffShapeAsViews()
    }
    
    func showAppIconBackdrop() {
        guard
            let screen = NSScreen.main?.frame
            else { return }
        
        let backdrop = NSWindow(contentRect: screen, styleMask: [], backing: .buffered, defer: false)
        backdrop.backgroundColor = NSColor.white
        backdrop.orderFront(nil)
    }
    
    func showAppIconRulers() {
        guard
            let screen = NSScreen.main?.frame
            else { return }
        
        let titlebarHeight: CGFloat = 22
        
        let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]
        let frame = NSRect(x: 200, y: screen.height - 700, width: 215, height: 265 - titlebarHeight)
        let window = NSWindow(contentRect: frame, styleMask: styleMask, backing: .buffered, defer: false)
        
        let topRect = NSRect(x: frame.minX, y: frame.maxY + titlebarHeight, width: frame.width, height: Ruler.thickness)
        let topRuler = Ruler(.horizontal, frame: topRect)
        let top = RulerController(ruler: topRuler)
        top.showWindow()
        
        let leftRect = NSRect(x: frame.minX - Ruler.thickness, y: frame.minY, width: Ruler.thickness, height: frame.height + titlebarHeight)
        let leftRuler = Ruler(.vertical, frame: leftRect)
        let left = RulerController(ruler: leftRuler)
        left.showWindow()
        
        window.addChildWindow(top.rulerWindow, ordered: .below)
        window.addChildWindow(left.rulerWindow, ordered: .below)
        
        top.rulerWindow.hasShadow = false
        left.rulerWindow.hasShadow = false
        window.hasShadow = false
        window.orderFront(nil)
        window.makeKey()
        window.makeMain()
        
    }
    
    func showAppIconRulersEffShape() {
        guard
            let screen = NSScreen.main?.frame
            else { return }
        
        let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]
        let frame = NSRect(x: 500, y: screen.height - 700, width: 200, height: 250)
        let window = NSWindow(contentRect: frame, styleMask: styleMask, backing: .buffered, defer: false)
        
        let topRect = NSRect(x: frame.minX, y: frame.maxY - Ruler.thickness, width: frame.width, height: Ruler.thickness)
        let topRuler = Ruler(.horizontal, frame: topRect)
        let top = RulerController(ruler: topRuler)
        top.showWindow()
        
        let leftRect = NSRect(x: frame.minX, y: frame.minY, width: Ruler.thickness, height: frame.height)
        let leftRuler = Ruler(.vertical, frame: leftRect)
        let left = RulerController(ruler: leftRuler)
        left.showWindow()
        
        let middleRect = NSRect(x: frame.minX, y: frame.minY + frame.height / 2 - Ruler.thickness / 2, width: frame.width - Ruler.thickness, height: Ruler.thickness)
        let middleRuler = Ruler(.horizontal, frame: middleRect)
        let middle = RulerController(ruler: middleRuler)
        middle.showWindow()
        
        window.orderFront(nil)
        window.makeKey()
        window.makeMain()
        
        window.addChildWindow(middle.rulerWindow, ordered: .above)
        window.addChildWindow(top.rulerWindow, ordered: .above)
        window.addChildWindow(left.rulerWindow, ordered: .above)
        
    }
    
    func showAppIconRulersEffShapeAsViews() {
        guard
            let screen = NSScreen.main?.frame
            else { return }
        
        let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        let frame = NSRect(x: 800, y: screen.height - 700, width: 150, height: 220)
        let window = NSWindow(contentRect: frame, styleMask: styleMask, backing: .buffered, defer: false)
        
        window.hasShadow = false
        window.orderFront(nil)
        window.makeKey()
        window.makeMain()
        
        window.contentView = EffRulerView(frame: frame)
        
    }
    
}


class EffRulerView: NSView {
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        
        let topRect = NSRect(x: Ruler.thickness / 2, y: frame.height - Ruler.thickness - titlebarHeight, width: frame.width - Ruler.thickness / 2, height: Ruler.thickness)
        let topRuler = Ruler(.horizontal, frame: topRect)
        let top = getRulerView(ruler: topRuler)
        addBorder(view: top)
        
        let leftRect = NSRect(x: 0, y: 0, width: Ruler.thickness, height: frame.height - titlebarHeight)
        let leftRuler = Ruler(.vertical, frame: leftRect)
        let left = getRulerView(ruler: leftRuler)
        addBorder(view: left)
        
        let middleRect = NSRect(x: Ruler.thickness / 2, y: 0 + frame.height / 2 - Ruler.thickness + 10, width: frame.width - Ruler.thickness - Ruler.thickness / 2, height: Ruler.thickness)
        let middleRuler = Ruler(.horizontal, frame: middleRect)
        let middle = getRulerView(ruler: middleRuler)
        addBorder(view: middle)
        
        self.addSubview(top)
        self.addSubview(middle)
        self.addSubview(left)
        
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
}

func addBorder(view: NSView) {
    let frame = view.frame
    let border = NSBox(frame: NSRect(x: 0, y: 0, width: frame.width, height: frame.height))
    border.boxType = .custom
    border.borderColor = #colorLiteral(red: 0.3098039329, green: 0.2039215714, blue: 0.03921568766, alpha: 0.5)
    border.borderType = .lineBorder
    border.borderWidth = 1
    view.addSubview(border)
}

