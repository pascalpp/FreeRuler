import Cocoa
import SwiftUI

final class HotkeyBezel {

    private enum AccessibilityIdentifier {
        static let contentView = "hotkey-bezel"
        static let hostingView = "hotkey-bezel-hosting-view"
        static let panel = "hotkey-bezel-panel"
    }

    private let panel: NSPanel
    private let hostingView: NSHostingView<HotkeyBezelView>
    private var hideWorkItem: DispatchWorkItem?

    init() {
        hostingView = NSHostingView(rootView: HotkeyBezelView(message: ""))
        hostingView.frame = NSRect(x: 0, y: 0, width: 420, height: 116)
        hostingView.setAccessibilityElement(true)
        hostingView.setAccessibilityIdentifier(AccessibilityIdentifier.hostingView)
        hostingView.setAccessibilityLabel("")
        hostingView.setAccessibilityValue("")

        let contentView = NSView(frame: hostingView.frame)
        contentView.setAccessibilityElement(true)
        contentView.setAccessibilityIdentifier(AccessibilityIdentifier.contentView)
        contentView.setAccessibilityLabel("")
        contentView.setAccessibilityValue("")
        contentView.addSubview(hostingView)

        panel = NSPanel(
            contentRect: contentView.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = contentView
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.setAccessibilityIdentifier(AccessibilityIdentifier.panel)
        panel.alphaValue = 0
    }

    func show(_ message: String, on screen: NSScreen? = nil) {
        hideWorkItem?.cancel()
        hostingView.rootView = HotkeyBezelView(message: message)
        hostingView.setAccessibilityLabel(message)
        hostingView.setAccessibilityValue(message)
        panel.contentView?.setAccessibilityLabel(message)
        panel.contentView?.setAccessibilityValue(message)

        panel.setFrame(centeredFrame(on: screen), display: true)
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            panel.animator().alphaValue = 1
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.hide()
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: workItem)
    }

    private func hide() {
        hideWorkItem?.cancel()
        hideWorkItem = nil

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.18
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.panel.orderOut(nil)
        })
    }

    private func centeredFrame(on screen: NSScreen?) -> NSRect {
        let screenFrame = (screen ?? panel.screen ?? NSScreen.main ?? NSScreen.screens.first)?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1024, height: 768)
        let size = NSSize(width: 420, height: 116)

        return NSRect(
            x: screenFrame.midX - (size.width / 2),
            y: screenFrame.midY - (size.height / 2),
            width: size.width,
            height: size.height
        )
    }

}

struct HotkeyBezelView: View {

    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 36, weight: .semibold))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 48).padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                  .fill(.black.opacity(0.3))
            )
            .accessibilityLabel(message)
            .accessibilityValue(message)
            .accessibilityIdentifier("hotkey-bezel-label")
    }

}

struct HotkeyBezelView_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            HotkeyBezelView(message: "Rulers grouped")
            HotkeyBezelView(message: "Units: mm")
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }

}
