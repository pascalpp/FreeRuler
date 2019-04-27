//
//  HorizontalController.swift
//  Free Ruler
//
//  Created by Jeff Hanbury on 12/04/19.
//

import Cocoa
import Carbon.HIToolbox // For key constants

class HorizontalController: NSWindowController, Synchronisable {

    weak var appDelegate: AppDelegate?

    @IBOutlet weak var rule: HorizontalRule!
    @IBOutlet weak var contentView: NSVisualEffectView!
    
    convenience init() {
        self.init(windowNibName: "HorizontalController")
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        appDelegate = NSApplication.shared.delegate as? AppDelegate
        
        let closeButton = window?.standardWindowButton(.closeButton)
        let miniaturizeButton = window?.standardWindowButton(.miniaturizeButton)
        let zoomButton = window?.standardWindowButton(.zoomButton)
        closeButton?.isHidden = true
        miniaturizeButton?.isHidden = true
        zoomButton?.isHidden = true
        
        window?.backgroundColor = .clear
        window?.isMovableByWindowBackground = true
        print("window?.canBecomeKey", window?.canBecomeKey as Any)
        
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = 0.0

        setupKeyboardListening()
    }
    
}

// Note: window.delegate is set in IB, as it's not loaded in time to do so in
// NSWindowController's init or such.
extension HorizontalController: NSWindowDelegate {
    
    func windowWillStartLiveResize(_ notification: Notification) {
        rule.showMouseTick = false
    }
    
    func windowDidEndLiveResize(_ notification: Notification) {
        rule.showMouseTick = true
    }

    func windowDidMove(_ notification: Notification) {
        guard
            let window = window,
            window.isKeyWindow
            else { return }

        appDelegate?.synchroniseWindows()
    }

}


// MARK: - Keyboard

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
