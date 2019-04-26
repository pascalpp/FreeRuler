//
//  VerticalController.swift
//  Free Ruler
//
//  Created by Pascal on 2019-04-19.
//

import Cocoa
import Carbon.HIToolbox // For key constants


class VerticalController: NSWindowController, Synchronisable {

    @IBOutlet weak var rule: VerticalRule!
    weak var appDelegate: AppDelegate?

    convenience init() {
        self.init(windowNibName: "VerticalController")
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        appDelegate = NSApplication.shared.delegate as? AppDelegate
        
        setupKeyboardListening()
    }
    
}

// Note: window.delegate is set in IB, as it's not loaded in time to do so in
// NSWindowController's init or such.
extension VerticalController: NSWindowDelegate {

    func windowWillStartLiveResize(_ notification: Notification) {
        rule.showMouseTick = false
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        rule.showMouseTick = true
    }

    func windowDidMove(_ notification: Notification) {
        appDelegate?.synchroniseWindows()
    }

}


// MARK: - Keyboard

extension VerticalController {
    func setupKeyboardListening() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] in
            guard let self = self else {return $0}
            return self.myKeyDown(with: $0)
        }
    }

    // Return nil if the event was handled here.
    func myKeyDown(with event: NSEvent) -> NSEvent? {
        // handle keyDown only if current window has focus, i.e. is keyWindow
//        guard NSApplication.shared.keyWindow === self else { return event }

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

}