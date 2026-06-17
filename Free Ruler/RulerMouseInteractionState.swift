import Cocoa

final class RulerMouseInteractionState {
    private weak var owner: AnyObject?
    private let isMouseInsideRuler: (NSEvent) -> Bool
    private let mouseTickResumeDelay: TimeInterval
    private var mouseTickResumeTimer: Timer?
    private var mouseIsDraggingRuler = false
    private var mouseIsHoveringRuler = false
    private var mouseIsResizingRuler = false

    init(
        owner: AnyObject,
        mouseTickResumeDelay: TimeInterval = 0.15,
        isMouseInsideRuler: @escaping (NSEvent) -> Bool
    ) {
        self.owner = owner
        self.mouseTickResumeDelay = mouseTickResumeDelay
        self.isMouseInsideRuler = isMouseInsideRuler
    }

    deinit {
        invalidate()
    }

    func invalidate() {
        mouseTickResumeTimer?.invalidate()
        mouseTickResumeTimer = nil
    }

    func windowWillStartLiveResize() {
        mouseIsResizingRuler = true
        disableMouseTicks()
    }

    func windowDidEndLiveResize() {
        mouseIsResizingRuler = false
        resumeMouseTicksUnlessHovering()
    }

    func windowWillMove() {
        disableMouseTicks()
    }

    func windowDidMove(isLeftMouseButtonPressed: Bool) {
        guard shouldPersistFrameAutosaveOnWindowMove(
            isLeftMouseButtonPressed: isLeftMouseButtonPressed
        ) else {
            return
        }

        resumeMouseTicksUnlessHovering()
    }

    func shouldPersistFrameAutosaveOnWindowMove(isLeftMouseButtonPressed: Bool) -> Bool {
        return !mouseIsDraggingRuler
            && !mouseIsResizingRuler
            && !isLeftMouseButtonPressed
    }

    func mouseEntered(with event: NSEvent) {
        mouseIsHoveringRuler = true
        hideMouseTicksForHover()
        rulerCursorController?.mouseEnteredRuler()
    }

    func mouseExited(with event: NSEvent) {
        mouseIsHoveringRuler = false
        if !mouseIsDraggingRuler {
            enableMouseTicks()
        }
        rulerCursorController?.mouseExitedRuler()
    }

    func mouseDown(with event: NSEvent) {
        mouseIsDraggingRuler = true
        disableMouseTicks()
        rulerCursorController?.mouseDownInRuler()
    }

    func mouseUp(with event: NSEvent) -> Bool {
        return finishMouseDrag(with: event)
    }

    @discardableResult
    func finishMouseDrag(with event: NSEvent) -> Bool {
        guard mouseIsDraggingRuler else { return false }

        mouseIsDraggingRuler = false
        mouseIsHoveringRuler = isMouseInsideRuler(event)
        resumeMouseTicksUnlessHovering()

        rulerCursorController?.mouseUpInRuler(mouseIsInsideRuler: mouseIsHoveringRuler)
        return true
    }

    func mouseMoved(with event: NSEvent) {
        guard !mouseIsDraggingRuler else { return }

        mouseIsHoveringRuler = isMouseInsideRuler(event)
        if mouseIsHoveringRuler {
            hideMouseTicksForHover()
        } else {
            enableMouseTicks()
        }
    }

    func disableMouseTicks() {
        invalidate()
        guard let owner = owner else { return }

        appDelegate?.suppressMouseTickDrawing(owner: owner)
        appDelegate?.suspendMouseTickUpdates(owner: owner)
    }

    func enableMouseTicks() {
        guard let owner = owner else { return }

        appDelegate?.unsuppressMouseTickDrawing(owner: owner)
        appDelegate?.resumeMouseTickUpdates(owner: owner)
    }

    private func scheduleMouseTickResume() {
        invalidate()
        mouseTickResumeTimer = Timer.scheduledTimer(
            withTimeInterval: mouseTickResumeDelay,
            repeats: false
        ) { [weak self] _ in
            self?.enableMouseTicks()
            self?.mouseTickResumeTimer = nil
        }
    }

    private func resumeMouseTicksUnlessHovering() {
        if mouseIsHoveringRuler {
            hideMouseTicksForHover()
            guard let owner = owner else { return }
            appDelegate?.resumeMouseTickUpdates(owner: owner)
        } else {
            scheduleMouseTickResume()
        }
    }

    private func hideMouseTicksForHover() {
        invalidate()
        guard let owner = owner else { return }

        appDelegate?.suppressMouseTickDrawing(owner: owner)
    }

    private var rulerCursorController: RulerCursorController? {
        return appDelegate?.rulerCursorController
    }

    private var appDelegate: AppDelegate? {
        return NSApp.delegate as? AppDelegate
    }
}
