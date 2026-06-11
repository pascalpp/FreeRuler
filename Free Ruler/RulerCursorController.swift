import Cocoa

final class RulerCursorController {
    enum CursorStyle: Equatable {
        case arrow
        case crosshair
        case openHand
        case closedHand

        var accessibilityValue: String {
            switch self {
            case .arrow:
                return "arrow"
            case .crosshair:
                return "crosshair"
            case .openHand:
                return "open-hand"
            case .closedHand:
                return "closed-hand"
            }
        }

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

    private func updateCursor() {
        guard appIsActive else { return }

        if mouseIsDraggingRuler {
            setCursor(.closedHand)
        } else if mouseIsOverRuler {
            setCursor(.openHand)
        } else {
            setCursor(.crosshair)
        }
    }

    private func setCursor(_ cursor: CursorStyle) {
        guard cursor != currentCursor else { return }

        currentCursor = cursor
        applyCursor(cursor)
        cursor.writeUITestStateIfNeeded()
    }
}

private extension RulerCursorController.CursorStyle {
    func writeUITestStateIfNeeded() {
        writeUITestCursorState(accessibilityValue)
    }
}
