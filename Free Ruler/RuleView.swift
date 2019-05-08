import Cocoa

class RuleView: NSView {

    // TODO research layer-backed view rendering
//    override var wantsLayer: Bool {
//        get { return true }
//        set {}
//    }
    
//    override func viewDidMoveToWindow() {
//        print("viewDidMoveToWindow")
//        super.viewDidMoveToWindow()
//        self.addCursorRect(self.frame, cursor: .crosshair)
//    }
    
    func drawMouseTick(at mouseLoc: NSPoint) {
        // required override
        // TODO is there a better way to do this, maybe via a protocol?
        // AppDelegate needs to be able to infer that any RulerView has this method
    }

    var showMouseTick: Bool = true {
        didSet {
            if showMouseTick != oldValue {
                needsDisplay = true
            }
        }
    }

    // Hide the ruler tick when the mouse is clicked on the ruler, for example
    // during window drag.
    override func mouseDown(with event: NSEvent) {
        showMouseTick = false
    }
    
    override func mouseUp(with event: NSEvent) {
        showMouseTick = true
    }

}
