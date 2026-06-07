import Cocoa

struct RulerTickLayout {
    let tickScale: CGFloat
    let textScale: Int
    let largeTicks: Int
    let mediumTicks: Int
    let smallTicks: Int
    let tinyTicks: Int?

    init(unit: Unit, screen: NSScreen?) {
        self.init(
            unit: unit,
            dpi: screen?.dpi.width ?? NSScreen.defaultDpi,
            dpmm: screen?.dpmm.width ?? NSScreen.defaultDpmm
        )
    }

    init(unit: Unit, dpi: CGFloat, dpmm: CGFloat) {
        switch unit {
        case .millimeters:
            tickScale = dpmm
            textScale = 1
            largeTicks = 10
            mediumTicks = 5
            smallTicks = 1
            tinyTicks = nil
        case .inches:
            tickScale = dpi / 16
            textScale = 16
            largeTicks = 16
            mediumTicks = 8
            smallTicks = 4
            tinyTicks = 1
        case .pixels:
            tickScale = 1
            textScale = 1
            largeTicks = 50
            mediumTicks = 10
            smallTicks = 2
            tinyTicks = nil
        }
    }
}
