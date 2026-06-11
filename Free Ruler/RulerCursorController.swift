import Cocoa

final class RulerCursorController {
    enum CursorStyle: Equatable {
        case arrow
        case crosshair
        case openHand
        case closedHand

        var nsCursor: NSCursor {
            switch self {
            case .arrow:
                return .arrow
            case .crosshair:
                return .crosshair
            case .openHand:
                return .openHand
            case .closedHand:
                return .closedHand
            }
        }
    }

    private var appIsActive = false
    private var mouseIsOverRuler = false
    private var mouseIsDraggingRuler = false
    private let applyCursor: (CursorStyle) -> Void

    private(set) var currentCursor: CursorStyle?

    init(applyCursor: @escaping (CursorStyle) -> Void = { $0.nsCursor.set() }) {
        self.applyCursor = applyCursor
    }

    func applicationDidBecomeActive() {
        appIsActive = true
        updateCursor()
    }

    func applicationDidResignActive() {
        appIsActive = false
        mouseIsOverRuler = false
        mouseIsDraggingRuler = false
        setCursor(.arrow)
    }

    func mouseEnteredRuler() {
        mouseIsOverRuler = true
        updateCursor()
    }

    func mouseMovedInRuler() {
        mouseIsOverRuler = true
        updateCursor(force: true)
    }

    func mouseExitedRuler() {
        mouseIsOverRuler = false
        updateCursor()
    }

    func mouseDownInRuler() {
        mouseIsOverRuler = true
        mouseIsDraggingRuler = true
        updateCursor()
    }

    func mouseUpInRuler(mouseIsInsideRuler: Bool) {
        mouseIsOverRuler = mouseIsInsideRuler
        mouseIsDraggingRuler = false
        updateCursor()
    }

    private func updateCursor(force: Bool = false) {
        guard appIsActive else { return }

        if mouseIsDraggingRuler {
            setCursor(.closedHand, force: force)
        } else if mouseIsOverRuler {
            setCursor(.openHand, force: force)
        } else {
            setCursor(.crosshair, force: force)
        }
    }

    private func setCursor(_ cursor: CursorStyle, force: Bool = false) {
        guard force || cursor != currentCursor else { return }

        currentCursor = cursor
        applyCursor(cursor)
    }
}
