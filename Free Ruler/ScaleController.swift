//
//  ScaleController.swift
//  Free Ruler
//
//  Created by Kevin Meziere on 1/26/25.
//  Copyright © 2025 Free Ruler. All rights reserved.
//

import Cocoa

class ScaleController: NSWindowController, NSWindowDelegate,
    NSTextFieldDelegate, NotificationPoster
{

    @IBOutlet weak var xScaleTextField: NSTextField!
    @IBOutlet weak var yScaleTextField: NSTextField!
    @IBOutlet weak var lockedRatioButton: NSButton!

    var observers: [NSKeyValueObservation] = []

    public var xRulerWidth: CGFloat = 0
    public var yRulerHeight: CGFloat = 0

    var lockedAspectRatio: Bool = true

    override var windowNibName: String {
        return "ScaleController"
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.isMovableByWindowBackground = true

        lockedAspectRatio = prefs.xscale == prefs.yscale
    }

    func windowDidBecomeKey(_ notification: Notification) {
        lockedRatioButton.state = lockedAspectRatio ? .on : .off
        xScaleTextField.stringValue = String(
            format: "%.5f", xRulerWidth * prefs.xscale)
        yScaleTextField.stringValue = String(
            format: "%.5f", yRulerHeight * prefs.yscale)

    }

    override func showWindow(_ sender: Any?) {
        window?.makeKeyAndOrderFront(sender)
        window?.center()
    }

    override func windowWillLoad() {

    }

    @IBAction func xValueChanged(_ sender: NSTextField) {

    }

    func controlTextDidChange(_ obj: Notification) {

        let textField = obj.object as! NSTextField

        // https://stackoverflow.com/a/52311371
        var stringValue = textField.stringValue

        let charSet = NSCharacterSet(charactersIn: "1234567890.").inverted
        let chars = textField.stringValue.components(separatedBy: charSet)
        stringValue = chars.joined()

        // Second step : only one '.'
        let comma = NSCharacterSet(charactersIn: ".")
        let chuncks = stringValue.components(separatedBy: comma as CharacterSet)
        switch chuncks.count {
        case 0:
            stringValue = ""
        case 1:
            stringValue = "\(chuncks[0])"
        default:
            stringValue = "\(chuncks[0]).\(chuncks[1])"
        }

        // replace string
        textField.stringValue = stringValue

        if textField.identifier?.rawValue == "xscale" {
            if lockedRatioButton.state == .on {
                yScaleTextField.stringValue = String(
                    format: "%.5f",
                    (CGFloat(yRulerHeight * Double(stringValue)!) / xRulerWidth)
                )
            }
        }

        if textField.identifier?.rawValue == "yscale" {
            if lockedRatioButton.state == .on {
                xScaleTextField.stringValue = String(
                    format: "%.5f",
                    (CGFloat(xRulerWidth * Double(stringValue)!) / yRulerHeight)
                )
            }
        }

    }

    @IBAction func lockRatio(_ sender: Any) {
        if lockedRatioButton.state == .on {
            yScaleTextField.stringValue = String(
                format: "%.5f",
                (CGFloat(yRulerHeight * Double(xScaleTextField.stringValue)!)
                    / xRulerWidth))
        }

    }

    @IBAction func saveScale(_ sender: Any) {
        prefs.xscale = Double(xScaleTextField.stringValue)! / xRulerWidth
        prefs.yscale = Double(yScaleTextField.stringValue)! / yRulerHeight
        self.window?.close()
    }

}
