import Cocoa

/*
 
 This file draws a special set of windows to be used as the app icon, with some additional image manipulation.
 
 Steps taken to generate the icon:
 - choose the 'App Icon Layout' scheme and run.
 - take screenshot
    - press cmd-shift-4
    - press and release the space bar to switch to object mode
    - click on the window
    - the rulers are set as child windows, so they'll be included in the screenshot
 - create 1024x1024 image in Photoshop, Pixelmator, etc
 - add drop shadow:
    - black, 25% opacity
    - 270° (straight down)
    - 10px offset
    - 30px blur
 - export 1024x1024 png
 - convert to ICNS file with Image2Icon or similar
 
 */

let titlebarHeight = CGFloat(30)

let renderWidth = CGFloat(210)
let targetWidth = CGFloat(680)
let targetHeight = CGFloat(820)
let aspect = targetWidth / targetHeight
let boundsMultiplier = CGFloat(3.3) // used to render the layout at a larger scale

class AppIconLayout: NSObject {
    
    func show() {
        let frame = NSRect(x: 100, y: 100, width: 1024, height: 1024 )
        let window = NSWindow(contentRect: frame, styleMask: [], backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = NSColor(white: 1, alpha: 0)

        window.isMovableByWindowBackground = true
        window.contentView = ScaleView(frame: frame)
        window.orderFront(nil)
    }

}

class ScaleView: NSView {

    required init?(coder decoder: NSCoder) {
        fatalError()
    }

    override init(frame: NSRect) {
        super.init(frame: frame)

        let layoutRect = NSRect(
            x: 240,
            y: 70,
            width: frame.width,
            height: frame.height
        )
        let layout = RulerLayoutView(frame: layoutRect)
        layout.setBoundsSize(NSSize(width: frame.width / boundsMultiplier, height: frame.height / boundsMultiplier))
        layout.rotate(byDegrees: 9)

        self.addSubview(layout)
    }

}

class RulerLayoutView: NSView {

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }

    override init(frame: NSRect) {
        super.init(frame: frame)

        let width = renderWidth
        let height = width / aspect

        let topRect = NSRect(
            x: Ruler.thickness,
            y: height - Ruler.thickness - 1,
            width: width - Ruler.thickness,
            height: Ruler.thickness
        )
        let topRuler = Ruler(.horizontal, frame: topRect)
        let top = getRulerView(ruler: topRuler)
        top.wantsLayer = true
        top.layer?.borderColor = CGColor(gray: 0, alpha: 0.5)
        top.layer?.borderWidth = 1.0

        let leftRect = NSRect(
            x: 1,
            y: 0,
            width: Ruler.thickness,
            height: height - Ruler.thickness
        )
        let leftRuler = Ruler(.vertical, frame: leftRect)
        let left = getRulerView(ruler: leftRuler)
        left.wantsLayer = true
        left.layer?.borderColor = CGColor(gray: 0, alpha: 0.5)
        left.layer?.borderWidth = 1.0

        let paperRect = NSRect(
            x: Ruler.thickness,
            y: 0,
            width: topRect.width,
            height: leftRect.height
        )
        let paperView = NSView(frame: paperRect)
        paperView.wantsLayer = true
        paperView.layer?.borderColor = CGColor(gray: 0, alpha: 0.5)
        paperView.layer?.borderWidth = 1.0
        paperView.layer?.backgroundColor = CGColor(gray: 1, alpha: 1)
        paperView.layer?.cornerRadius = 10.0

        let toolbarRect = NSRect(
            x: -10,
            y: leftRect.height - titlebarHeight + 1,
            width: topRect.width + 20,
            height: titlebarHeight
        )
        let toolbar = NSView(frame: toolbarRect)
        toolbar.wantsLayer = true
        toolbar.layer?.backgroundColor = CGColor(gray: 0.9, alpha: 1)
        toolbar.layer?.borderColor = CGColor(gray: 0, alpha: 0.2)
        toolbar.layer?.borderWidth = 1.0

        let buttonFrame = NSRect(x: 0, y: 0, width: 12, height: 12)
        let buttonsX = CGFloat(20)
        let buttonsY = CGFloat(8.5)
        let buttonSpace = CGFloat(18)

        let closeColor = CGColor(red: 250.0/255.0, green: 97.0/255.0, blue: 92.0/255.0, alpha: 255.0/255.0)
        let closeButton = ButtonView(frame: buttonFrame, color: closeColor)
        closeButton.setFrameOrigin(NSPoint(x: buttonsX, y: buttonsY))
        toolbar.addSubview(closeButton)

        let minimizeColor = CGColor(red: 252.0/255.0, green: 188.0/255.0, blue: 63.0/255.0, alpha: 255.0/255.0)
        let minimizeButton = ButtonView(frame: buttonFrame, color: minimizeColor)
        minimizeButton.setFrameOrigin(NSPoint(x: buttonsX + buttonSpace, y: buttonsY))
        toolbar.addSubview(minimizeButton)

        let zoomColor = CGColor(red: 59.0/255.0, green: 200.0/255.0, blue: 73.0/255.0, alpha: 255.0/255.0)
        let zoomButton = ButtonView(frame: buttonFrame, color: zoomColor)
        zoomButton.setFrameOrigin(NSPoint(x: buttonsX + buttonSpace + buttonSpace, y: buttonsY))
        toolbar.addSubview(zoomButton)

        paperView.addSubview(toolbar)

        self.addSubview(paperView)
        self.addSubview(top)
        self.addSubview(left)

    }

}

class ButtonView: NSView {

    required init?(coder decoder: NSCoder) {
        fatalError()
    }

    init(frame frameRect: NSRect, color: CGColor) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.backgroundColor = color
        self.layer?.cornerRadius = frame.width / 2
        self.layer?.borderColor = CGColor(gray: 0, alpha: 0.2)
        self.layer?.borderWidth = 1.0
    }

}
