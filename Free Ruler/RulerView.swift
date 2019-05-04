import Cocoa

class RulerView: NSView {

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
