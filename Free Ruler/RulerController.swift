import Cocoa
import SwiftyUserDefaults

class RulerController: NSCoder, NSWindowDelegate {
    
    let defaults = UserDefaults.standard

    var type: RulerType
    var rulerWindow: RulerWindow
    var otherWindow: RulerWindow?
    
    init(type: RulerType) {
        self.type = type
        self.rulerWindow = RulerWindow(type: type)

        super.init()

        rulerWindow.delegate = self
    }
    
    func showWindow() {
        rulerWindow.orderFront(nil)
    }

    func windowWillStartLiveResize(_ notification: Notification) {
//        print(self.type, "windowWillStartLiveResize")
    }
    
    func windowDidEndLiveResize(_ notification: Notification) {
//        print(self.type, "windowDidEndLiveResize")
    }
    
    func windowWillMove(_ notification: Notification) {
//        print(self.type, "windowWillMove")
    }
    
    func windowDidMove(_ notification: Notification) {
//        print(self.type, "windowDidMove")
        rulerWindow.invalidateShadow()
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
//        print(self.type, "windowDidBecomeKey")
        updateChildWindow()
    }
    
    func windowDidResignKey(_ notification: Notification) {
//        print(self.type, "windowDidResignKey")
        updateChildWindow()
    }
    
    func updateChildWindow() {
        guard let other = otherWindow else { return }
        
        let grouped = Defaults[.groupedRulers]
        if grouped && rulerWindow.isKeyWindow {
            self.rulerWindow.addChildWindow(other, ordered: .below)
        } else {
            self.rulerWindow.removeChildWindow(other)
        }
    }

}


/*
 
 extension HorizontalController {
 func setupKeyboardListening() {
 NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] in
 guard let self = self else {return $0}
 return self.myKeyDown(with: $0)
 }
 }
 
 // Return nil if the event was handled here.
 func myKeyDown(with event: NSEvent) -> NSEvent? {
 // handle keyDown only if current window has focus, i.e. is keyWindow
 // guard NSApplication.shared.keyWindow === self else { return event }
 
 let shiftPressed = event.modifierFlags.contains(.shift)
 
 switch Int( event.keyCode) {
 case kVK_LeftArrow:
 event.window?.nudgeLeft(withShift: shiftPressed)
 return nil
 case kVK_RightArrow:
 event.window?.nudgeRight(withShift: shiftPressed)
 return nil
 case kVK_UpArrow:
 event.window?.nudgeUp(withShift: shiftPressed)
 return nil
 case kVK_DownArrow:
 event.window?.nudgeDown(withShift: shiftPressed)
 return nil
 default:
 return event
 }
 }
 
 func moveWith(_ otherWindow: NSWindow?) {
 guard let vWindow = otherWindow,
 let hWindow = window
 else { return }
 
 let point = CGPoint(
 x: vWindow.frame.maxX,
 y: vWindow.frame.maxY + hWindow.frame.height
 )
 hWindow.setFrameTopLeftPoint(point)
 }
 
 
 }

 */
