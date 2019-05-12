import Cocoa

struct RulerColors {
    let fill = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)
    let numbers = #colorLiteral(red: 0.6829560399, green: 0.4503545761, blue: 0.09706548601, alpha: 1)
    let ticks = #colorLiteral(red: 0.7254902124, green: 0.4784313738, blue: 0.09803921729, alpha: 1)
    let mouseTick = #colorLiteral(red: 0.3098039329, green: 0.2039215714, blue: 0.03921568766, alpha: 0.75)
    let mouseNumber = #colorLiteral(red: 0.3098039329, green: 0.2039215714, blue: 0.03921568766, alpha: 1)
}

class RuleView: NSView {

    let color = RulerColors()
    var trackingArea: NSTrackingArea?
    let trackingAreaOptions: NSTrackingArea.Options = [
        .mouseMoved,
        .activeInKeyWindow,
        .inVisibleRect,
    ]

    override func updateTrackingAreas() {
        if trackingArea != nil {
            removeTrackingArea(trackingArea!)
        }

        trackingArea = NSTrackingArea(
            rect: self.bounds,
            options: trackingAreaOptions,
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }
    
    func drawMouseTick(at mouseLoc: NSPoint) {
        // required override
        // TODO: is there a better way to do this, maybe via a protocol?
        // AppDelegate needs to be able to infer that any RulerView has this method
        fatalError("RuleView subclass must override drawMouseTick method.")
    }

    var showMouseTick: Bool = true {
        didSet {
            if showMouseTick != oldValue {
                needsDisplay = true
            }
        }
    }

}
