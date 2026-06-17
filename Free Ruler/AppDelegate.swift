import Cocoa
import Carbon.HIToolbox
#if DEBUG
import Darwin
#endif
#if SPARKLE
import Sparkle
#endif

private enum HotkeyBezelLocalizationKey: String {
    case rulersFloated = "HotkeyBezel.RulersFloated"
    case rulersUnfloated = "HotkeyBezel.RulersUnfloated"
    case rulersGrouped = "HotkeyBezel.RulersGrouped"
    case rulersUngrouped = "HotkeyBezel.RulersUngrouped"
    case shadowEnabled = "HotkeyBezel.ShadowEnabled"
    case shadowDisabled = "HotkeyBezel.ShadowDisabled"
    case flipHorizontal = "HotkeyBezel.FlipHorizontal"
    case flipVertical = "HotkeyBezel.FlipVertical"
    case unitsFormat = "HotkeyBezel.UnitsFormat"
    case pixelsUnit = "Unit.Pixels.Abbreviation"
    case millimetersUnit = "Unit.Millimeters.Abbreviation"
    case inchesUnit = "Unit.Inches.Abbreviation"

    var localizedString: String {
        NSLocalizedString(rawValue, comment: comment)
    }

    private var comment: String {
        switch self {
        case .rulersFloated:
            return "Hotkey status bezel text indicating rulers now float above other windows"
        case .rulersUnfloated:
            return "Hotkey status bezel text indicating rulers no longer float above other windows"
        case .rulersGrouped:
            return "Hotkey status bezel text indicating rulers are grouped"
        case .rulersUngrouped:
            return "Hotkey status bezel text indicating rulers are ungrouped"
        case .shadowEnabled:
            return "Hotkey status bezel text indicating ruler shadow is enabled"
        case .shadowDisabled:
            return "Hotkey status bezel text indicating ruler shadow is disabled"
        case .flipHorizontal:
            return "Hotkey status bezel text indicating the horizontal ruler was flipped"
        case .flipVertical:
            return "Hotkey status bezel text indicating the vertical ruler was flipped"
        case .unitsFormat:
            return "Hotkey status bezel format for the selected measurement unit"
        case .pixelsUnit:
            return "Pixels unit abbreviation"
        case .millimetersUnit:
            return "Millimeters unit abbreviation"
        case .inchesUnit:
            return "Inches unit abbreviation"
        }
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var observers: [NSKeyValueObservation] = []

    var rulers: [RulerController] = []
    var groupedRulerController: GroupedRulerController?
    lazy var rulerManager: RulerManager = {
        let manager = RulerManager()
        manager.onActiveControllerChanged = { [weak self] controller in
            guard let self = self else { return }

            self.groupedRulerController = controller
            self.updateDisplay()

            guard let settingsController = self.rulerSettingsController,
                  settingsController.window?.isVisible == true else { return }

            if let controller = controller {
                settingsController.show(attachedTo: controller, sender: self)
            } else {
                settingsController.close()
            }
        }
        manager.onStateChanged = { [weak self] _ in
            self?.saveRulerSetState()
        }
        return manager
    }()

    var timer: Timer?
    private var timerInterval: TimeInterval?
    private let mouseTickDrawingSuppressedOwners = NSHashTable<AnyObject>.weakObjects()
    let foregroundTimerInterval: TimeInterval = 1 / 60 // 60 fps
    let backgroundTimerInterval: TimeInterval = 1 / 30 // 30 fps

    let rulerCursorController = RulerCursorController()
    lazy var mouseTickTimerPolicy = MouseTickTimerPolicy(
        foregroundInterval: foregroundTimerInterval,
        backgroundInterval: backgroundTimerInterval
    )

    @IBOutlet weak var pixelsMenuItem: NSMenuItem!
    @IBOutlet weak var millimetersMenuItem: NSMenuItem!
    @IBOutlet weak var inchesMenuItem: NSMenuItem!
    @IBOutlet weak var cycleUnitsMenuItem: NSMenuItem!

    @IBOutlet weak var floatRulersMenuItem: NSMenuItem!
    @IBOutlet weak var groupRulersMenuItem: NSMenuItem!
    @IBOutlet weak var rulerShadowMenuItem: NSMenuItem!
    @IBOutlet weak var alignRulersMenuItem: NSMenuItem!

    var preferencesController: PreferencesController? = nil
    var rulerSettingsController: RulerSettingsController? = nil
    private let hotkeyBezel = HotkeyBezel()
    private var uiTestSupport: UITestSupport?
    private var interfaceStyleObserver: NSObjectProtocol?
#if SPARKLE
    private var updaterController: SPUStandardUpdaterController?
#endif

    private enum RulerWindowMode {
        case grouped
        case separate
    }

    private struct RulerVisibility {
        var horizontal = true
        var vertical = true

        var hasVisibleRuler: Bool {
            return horizontal || vertical
        }

        mutating func showAll() {
            horizontal = true
            vertical = true
        }

        mutating func hideAll() {
            horizontal = false
            vertical = false
        }

        mutating func toggle(_ orientation: Orientation) {
            set(orientation, isVisible: !isVisible(orientation))
        }

        mutating func set(_ orientation: Orientation, isVisible: Bool) {
            switch orientation {
            case .horizontal:
                horizontal = isVisible
            case .vertical:
                vertical = isVisible
            }
        }

        func isVisible(_ orientation: Orientation) -> Bool {
            switch orientation {
            case .horizontal:
                return horizontal
            case .vertical:
                return vertical
            }
        }
    }

    private var rulerVisibility = RulerVisibility()

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        configureOpaqueColorPicking()
        configureApplicationIconAppearance()

#if DEBUG
        if let outputDirectory = appStoreScreenshotOutputDirectory() {
            generateAppStoreScreenshots(to: outputDirectory)
            return
        }
#endif

        uiTestSupport = UITestSupport.installIfNeeded()
        uiTestSupport?.resetApplicationState()
        uiTestSupport?.writeCursorState("none")

        subscribeToPrefs()
        updateDisplay()
        uiTestSupport?.writePreferencesState()
#if SPARKLE
        configureUpdater()
#endif

        restoreSavedRulers()
        showRulers()
    }

    deinit {
        if let interfaceStyleObserver = interfaceStyleObserver {
            DistributedNotificationCenter.default().removeObserver(interfaceStyleObserver)
        }
    }

    private func configureApplicationIconAppearance() {
        interfaceStyleObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateApplicationIconForCurrentAppearance()
        }

        updateApplicationIconForCurrentAppearance()
    }

    private func updateApplicationIconForCurrentAppearance() {
        NSApp.applicationIconImage = AppIconRenderer.applicationIconImage(for: NSApp.effectiveAppearance)
    }

#if DEBUG
    private func appStoreScreenshotOutputDirectory() -> URL? {
        let arguments = CommandLine.arguments
        guard let flagIndex = arguments.firstIndex(of: "--generate-app-store-screenshots"),
              arguments.indices.contains(flagIndex + 1) else {
            return nil
        }

        return URL(fileURLWithPath: arguments[flagIndex + 1])
    }

    private func generateAppStoreScreenshots(to outputDirectory: URL) {
        do {
            try AppStoreScreenshotRenderer.exportAll(to: outputDirectory)
            NSApp.terminate(nil)
        } catch {
            printError("Could not generate App Store screenshots: \(error.localizedDescription)")
            exit(1)
        }
    }

    private func printError(_ message: String) {
        FileHandle.standardError.write(Data((message + "\n").utf8))
    }
#endif

#if SPARKLE
    private func configureUpdater() {
        guard hasSparkleConfiguration else { return }

        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        installCheckForUpdatesMenuItem()
    }

    private var hasSparkleConfiguration: Bool {
        let info = Bundle.main.infoDictionary ?? [:]
        let feedURL = info["SUFeedURL"] as? String
        let publicKey = info["SUPublicEDKey"] as? String

        return feedURL?.isEmpty == false && publicKey?.isEmpty == false
    }

    private func installCheckForUpdatesMenuItem() {
        guard let appMenu = NSApp.mainMenu?.item(at: 0)?.submenu else { return }
        guard !appMenu.items.contains(where: { $0.action == #selector(checkForUpdates(_:)) }) else { return }

        let title = NSLocalizedString(
            "Check for Updates…",
            comment: "Application menu item title for manually checking for software updates"
        )
        let item = NSMenuItem(
            title: title,
            action: #selector(checkForUpdates(_:)),
            keyEquivalent: ""
        )
        item.target = self

        let insertionIndex = appMenu.items.firstIndex { $0.isSeparatorItem } ?? appMenu.items.count
        appMenu.insertItem(item, at: insertionIndex)
    }

    @objc private func checkForUpdates(_ sender: Any?) {
        updaterController?.checkForUpdates(sender)
    }
#endif

    func subscribeToPrefs() {
        observers = [
            prefs.observe(\Prefs.unit, options: .new) { prefs, changed in
                self.updateUnitMenu()
                self.redrawDefaultBackedRulers()
                self.uiTestSupport?.writePreferencesState()
            },
            prefs.observe(\Prefs.floatRulers, options: .new) { prefs, changed in
                self.updateFloatRulersMenuItem()
                self.legacyGroupedRulerController?.updateIsFloatingPanel()
                self.uiTestSupport?.writePreferencesState()
            },
            prefs.observe(\Prefs.groupRulers, options: .new) { prefs, changed in
                self.updateGroupRulersMenuItem()
                self.applyRulerWindowMode()
                self.uiTestSupport?.writePreferencesState()
            },
            prefs.observe(\Prefs.rulerShadow, options: .new) { prefs, changed in
                self.updateRulerShadowMenuItem()
                self.legacyGroupedRulerController?.updateHasShadow()
                self.uiTestSupport?.writePreferencesState()
            },
            prefs.observe(\Prefs.rulerColor, options: .new) { prefs, changed in
                self.redrawDefaultBackedRulers()
            },
            prefs.observe(\Prefs.zeroCorner, options: .new) { prefs, changed in
                self.redrawDefaultBackedRulers()
            },
        ]
    }

    func updateDisplay() {
        updateUnitMenu()
        updateFloatRulersMenuItem()
        updateGroupRulersMenuItem()
        updateRulerShadowMenuItem()
    }
    
    func updateUnitMenu() {
        let unit = activeRulerSettings.unit
        pixelsMenuItem?.state      = unit == .pixels ? .on : .off
        millimetersMenuItem?.state = unit == .millimeters ? .on : .off
        inchesMenuItem?.state      = unit == .inches ? .on : .off
    }

    func redrawRulers() {
        for ruler in rulers {
            ruler.rulerWindow.rule.redrawForPreferenceChange()
        }
        for controller in rulerManager.controllers {
            controller.redrawForPreferenceChange()
        }
        legacyGroupedRulerController?.redrawForPreferenceChange()
    }

    func redrawDefaultBackedRulers() {
        for ruler in rulers {
            ruler.rulerWindow.rule.redrawForPreferenceChange()
        }
        legacyGroupedRulerController?.redrawForPreferenceChange()
    }

    func updateFloatRulersMenuItem() {
        floatRulersMenuItem?.state = activeRulerSettings.floatRulers ? .on : .off
    }

    func updateGroupRulersMenuItem() {
        groupRulersMenuItem?.state = prefs.groupRulers ? .on : .off
    }

    func updateRulerShadowMenuItem() {
        rulerShadowMenuItem?.state = activeRulerSettings.rulerShadow ? .on : .off
    }

    private var activeRulerSettings: RulerSettings {
        return rulerManager.activeController?.state.settings ?? RulerSettings(defaults: prefs)
    }

    @discardableResult
    private func updateActiveRulerSettings(_ update: (inout RulerSettings) -> Void) -> Bool {
        guard let controller = rulerManager.activeController else { return false }

        controller.updateSettings(update)
        updateDisplay()
        return true
    }

    func createRulersIfNeeded() {
        guard !rulerManager.hasRulers else { return }

        rulerManager.createRuler()
    }

    private func createLegacyRulersIfNeeded() {
        guard rulers.isEmpty else { return }

        rulers = [
            RulerController(Ruler(.vertical, name: "vertical-ruler")),
            RulerController(Ruler(.horizontal, name: "horizontal-ruler")),
        ]

        // let rulers know about each other
        // TODO: provide each ruler with otherRulers: [RulerWindow]
        rulers[0].otherWindow = rulers[1].rulerWindow
        rulers[1].otherWindow = rulers[0].rulerWindow

        let groupedFrame = GroupedRulerLayout.joined(
            horizontalFrame: rulers[1].rulerWindow.frame,
            verticalFrame: rulers[0].rulerWindow.frame,
            zeroCorner: prefs.zeroCorner
        ).groupFrame
        groupedRulerController = GroupedRulerController(frame: groupedFrame)
    }

    func showRulers() {
        createRulersIfNeeded()
        rulerManager.showAll()
        updateMouseTickTimer()
    }

    func restoreSavedRulers() {
        if let restoredState = prefs.loadRulerSetState() {
            rulerManager.restore(
                restoredState.rulers,
                activeRulerID: restoredState.activeRulerID
            )
            return
        }

        if let migratedState = migratedLegacyRulerState() {
            rulerManager.restore([migratedState], activeRulerID: migratedState.id)
        }
    }

    private func saveRulerSetState() {
        prefs.saveRulerSetState(
            rulers: rulerManager.states,
            activeRulerID: rulerManager.activeRulerID
        )
    }

    private func migratedLegacyRulerState() -> RulerInstanceState? {
        let defaults = UserDefaults.standard
        let horizontalAutosaveName = "horizontal-ruler"
        let verticalAutosaveName = "vertical-ruler"
        let hasLegacyAutosave = defaults.object(forKey: "NSWindow Frame \(horizontalAutosaveName)") != nil
            || defaults.object(forKey: "NSWindow Frame \(verticalAutosaveName)") != nil
        guard hasLegacyAutosave else { return nil }

        let settings = RulerSettings(defaults: prefs)
        let horizontalWindow = RulerWindow(
            ruler: Ruler(.horizontal, name: horizontalAutosaveName)
        )
        let verticalWindow = RulerWindow(
            ruler: Ruler(.vertical, name: verticalAutosaveName)
        )
        _ = horizontalWindow.setFrameUsingName(NSWindow.FrameAutosaveName(horizontalAutosaveName))
        _ = verticalWindow.setFrameUsingName(NSWindow.FrameAutosaveName(verticalAutosaveName))

        return RulerInstanceState(
            settings: settings,
            layout: RulerLayoutState(
                horizontalFrame: horizontalWindow.frame,
                verticalFrame: verticalWindow.frame,
                zeroCorner: settings.zeroCorner
            )
        )
    }

    func toggleRuler(orientation: Orientation) {
        if !rulerManager.hasRulers && rulers.isEmpty {
            createRulersIfNeeded()
        }

        if rulerManager.hasRulers {
            let controller = rulerManager.activeController ?? rulerManager.createRuler()
            controller.toggleWing(orientation)
            updateDisplay()
            updateMouseTickTimer()
            return
        }

        guard canToggleRulerVisibility else { return }
        guard rulerController(orientation: orientation) != nil else { return }

        if prefs.groupRulers {
            syncGroupedRulerFramesToRulerWindows(persistAutosave: true)
        }

        let shouldShowRulersIfNeeded = !hasVisibleRuler
        rulerVisibility.toggle(orientation)
        applyRulerWindowMode(showRulersIfNeeded: shouldShowRulersIfNeeded)
    }

    private func detachRulerWindows() {
        for ruler in rulers {
            detachRulerWindow(ruler.rulerWindow)
        }
    }

    private func rulerController(orientation: Orientation) -> RulerController? {
        createLegacyRulersIfNeeded()
        return existingRulerController(orientation: orientation)
    }

    private func existingRulerController(orientation: Orientation) -> RulerController? {
        return rulers.first { $0.ruler.orientation == orientation }
    }

    private func showRuler(_ ruler: RulerController, updateMode: Bool = true) {
        ruler.showWindow(self)
        ruler.rulerWindow.orderFrontRegardless()
        if updateMode {
            applyRulerWindowMode()
        }
    }

    private func detachRulerWindow(_ window: RulerWindow) {
        for ruler in rulers {
            guard ruler.rulerWindow != window else { continue }

            ruler.rulerWindow.removeChildWindow(window)
            window.removeChildWindow(ruler.rulerWindow)
        }
    }

    private var rulerWindowMode: RulerWindowMode {
        return prefs.groupRulers ? .grouped : .separate
    }

    private func applyRulerWindowMode(showRulersIfNeeded: Bool = false) {
        if rulerManager.hasRulers {
            rulerManager.showAll()
            updateMouseTickTimer()
            return
        }

        createLegacyRulersIfNeeded()
        detachRulerWindows()

        switch rulerWindowMode {
        case .grouped:
            showGroupedRulerWindow(showRulersIfNeeded: showRulersIfNeeded)
        case .separate:
            showSeparateRulerWindows()
        }

        updateMouseTickTimer()
    }

    private func showGroupedRulerWindow(showRulersIfNeeded: Bool) {
        guard let groupedRulerController = groupedRulerController,
              let horizontalRuler = existingRulerController(orientation: .horizontal),
              let verticalRuler = existingRulerController(orientation: .vertical) else {
            return
        }

        guard rulerVisibility.hasVisibleRuler else {
            groupedRulerController.hide()
            horizontalRuler.rulerWindow.orderOut(self)
            verticalRuler.rulerWindow.orderOut(self)
            return
        }

        let shouldShowGroupedRuler = showRulersIfNeeded
            || groupedRulerController.isVisible
            || horizontalRuler.rulerWindow.isVisible
            || verticalRuler.rulerWindow.isVisible

        guard shouldShowGroupedRuler else { return }

        let horizontalFrame = groupedRulerController.isVisible
            && groupedRulerController.groupedWindow.isRuleVisible(.horizontal)
            ? groupedRulerController.groupedWindow.screenFrame(for: .horizontal)
            : horizontalRuler.rulerWindow.frame
        let verticalFrame = groupedRulerController.isVisible
            && groupedRulerController.groupedWindow.isRuleVisible(.vertical)
            ? groupedRulerController.groupedWindow.screenFrame(for: .vertical)
            : verticalRuler.rulerWindow.frame

        groupedRulerController.show(
            horizontalFrame: horizontalFrame,
            verticalFrame: verticalFrame,
            showsHorizontalRule: rulerVisibility.horizontal,
            showsVerticalRule: rulerVisibility.vertical
        )
        horizontalRuler.rulerWindow.orderOut(self)
        verticalRuler.rulerWindow.orderOut(self)
    }

    private func showSeparateRulerWindows() {
        guard let groupedRulerController = groupedRulerController else {
            return
        }

        if groupedRulerController.isVisible {
            syncGroupedRulerFramesToRulerWindows(persistAutosave: true)
            groupedRulerController.hide()
        }

        for ruler in rulers {
            if rulerVisibility.isVisible(ruler.ruler.orientation) {
                showRuler(ruler, updateMode: false)
            } else {
                ruler.rulerWindow.orderOut(self)
            }
        }

        for ruler in rulers {
            ruler.updateChildWindow()
        }
    }

    func syncGroupedRulerFramesToRulerWindows(persistAutosave: Bool = false) {
        guard let groupedRulerController = groupedRulerController,
              let horizontalRuler = existingRulerController(orientation: .horizontal),
              let verticalRuler = existingRulerController(orientation: .vertical) else {
            return
        }

        groupedRulerController.syncFrames(
            to: horizontalRuler.rulerWindow,
            and: verticalRuler.rulerWindow,
            persistAutosave: persistAutosave
        )
    }

    private var isGroupedRulerVisible: Bool {
        return groupedRulerController?.isVisible == true
    }

    private var legacyGroupedRulerController: GroupedRulerController? {
        guard let groupedRulerController = groupedRulerController,
              !rulerManager.controllers.contains(where: { $0 === groupedRulerController }) else {
            return nil
        }

        return groupedRulerController
    }

    private func isRulerVisible(_ ruler: RulerController?) -> Bool {
        guard let ruler = ruler else { return false }
        return rulerVisibility.isVisible(ruler.ruler.orientation)
    }

    private var isRulerFrontmost: Bool {
        if rulerManager.controllers.contains(where: { $0.groupedWindow.isKeyWindow }) {
            return true
        }

        if groupedRulerController?.groupedWindow.isKeyWindow == true {
            return true
        }

        return rulers.contains { $0.rulerWindow.isKeyWindow }
    }

    private var hasVisibleRuler: Bool {
        return rulerManager.hasVisibleRulers
            || isGroupedRulerVisible
            || rulers.contains { $0.rulerWindow.isVisible }
    }

    private var canToggleRulerVisibility: Bool {
        return isRulerFrontmost || !hasVisibleRuler
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showRulers()
            return false
        }

        return true
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        for ruler in rulers {
            ruler.foreground()
        }
        for controller in rulerManager.controllers {
            controller.foreground()
        }
        legacyGroupedRulerController?.foreground()

        mouseTickTimerPolicy.applicationDidBecomeActive()
        updateMouseTickTimer()

        rulerCursorController.applicationDidBecomeActive()
    }

    func applicationDidResignActive(_ notification: Notification) {
        for ruler in rulers {
            ruler.background()
        }
        for controller in rulerManager.controllers {
            controller.background()
        }
        legacyGroupedRulerController?.background()

        mouseTickTimerPolicy.applicationDidResignActive()
        updateMouseTickTimer()

        rulerCursorController.applicationDidResignActive()
    }
    
    @IBAction func setUnitPixels(_ sender: Any) {
        setUnit(.pixels)
    }
    @IBAction func setUnitMillimetres(_ sender: Any) {
        setUnit(.millimeters)
    }
    @IBAction func setUnitInches(_ sender: Any) {
        setUnit(.inches)
    }
    @IBAction func cycleUnits(_ sender: Any) {
        let nextUnit: Unit
        switch activeRulerSettings.unit {
        case .pixels:
            nextUnit = .millimeters
        case .millimeters:
            nextUnit = .inches
        case .inches:
            nextUnit = .pixels
        }

        setUnit(nextUnit)
        showHotkeyBezel(format: .unitsFormat, unitLabel(nextUnit), on: bezelScreen(for: sender))
    }

    @IBAction func toggleFloatRulers(_ sender: Any) {
        if let controller = rulerManager.activeController {
            let shouldFloat = !controller.state.settings.floatRulers
            controller.updateSettings { settings in
                settings.floatRulers = shouldFloat
            }
            updateFloatRulersMenuItem()
            showHotkeyBezel(
                shouldFloat ? .rulersFloated : .rulersUnfloated,
                on: bezelScreen(for: sender)
            )
            return
        }

        prefs.floatRulers = !prefs.floatRulers
        showHotkeyBezel(
            prefs.floatRulers ? .rulersFloated : .rulersUnfloated,
            on: bezelScreen(for: sender)
        )
    }

    @IBAction func toggleGroupRulers(_ sender: Any) {
        guard !rulerManager.hasRulers else { return }

        prefs.groupRulers = !prefs.groupRulers
        showGroupRulersHotkeyBezel(on: bezelScreen(for: sender))
    }
    @IBAction func toggleRulerShadow(_ sender: Any) {
        if let controller = rulerManager.activeController {
            let shouldShowShadow = !controller.state.settings.rulerShadow
            controller.updateSettings { settings in
                settings.rulerShadow = shouldShowShadow
            }
            updateRulerShadowMenuItem()
            showHotkeyBezel(
                shouldShowShadow ? .shadowEnabled : .shadowDisabled,
                on: bezelScreen(for: sender)
            )
            return
        }

        prefs.rulerShadow = !prefs.rulerShadow
        showHotkeyBezel(
            prefs.rulerShadow ? .shadowEnabled : .shadowDisabled,
            on: bezelScreen(for: sender)
        )
    }

    @IBAction func openPreferences(_ sender: Any) {
        if preferencesController == nil {
            preferencesController = PreferencesController()
        }

        if preferencesController != nil {
            preferencesController?.showWindow(self)
        }
    }

    @IBAction func openRulerSettings(_ sender: Any) {
        guard let controller = rulerManager.activeController else { return }

        if rulerSettingsController == nil {
            rulerSettingsController = RulerSettingsController(rulerController: controller)
        }

        rulerSettingsController?.show(attachedTo: controller, sender: sender)
    }

    @IBAction func newRuler(_ sender: Any) {
        let controller = rulerManager.createRuler()
        controller.show()
        updateMouseTickTimer()
    }

    @IBAction func closeKeyWindow(_ sender: Any) {
        if let controller = rulerManager.controller(containing: NSApp.keyWindow) {
            rulerManager.close(controller)
            updateMouseTickTimer()
            return
        }

        if rulerManager.hasRulers,
           NSApp.keyWindow == nil,
           rulerManager.closeActiveRuler() {
            updateMouseTickTimer()
            return
        }

        if let groupedRulerController = groupedRulerController,
           groupedRulerController.groupedWindow.isKeyWindow {
            syncGroupedRulerFramesToRulerWindows(persistAutosave: true)
            rulerVisibility.hideAll()
            applyRulerWindowMode()
            return
        }

        if let ruler = rulers.first(where: { $0.rulerWindow.isKeyWindow }) {
            rulerVisibility.set(ruler.ruler.orientation, isVisible: false)
            applyRulerWindowMode()
            return
        }

        NSApp.keyWindow?.performClose(sender)
    }

    @IBAction func alignRulersAtMouseLocation(_ sender: Any) {
        var mouseLoc = NSEvent.mouseLocation
        mouseLoc.x = mouseLoc.x.rounded()
        mouseLoc.y = mouseLoc.y.rounded()

        if let controller = rulerManager.activeController {
            controller.align(at: mouseLoc)
            return
        }

        if prefs.groupRulers,
           let groupedRulerController = groupedRulerController,
           groupedRulerController.isVisible {
            groupedRulerController.align(at: mouseLoc)
            syncGroupedRulerFramesToRulerWindows(persistAutosave: true)
            return
        }

        for ruler in rulers {
            ruler.alignRuler(at: mouseLoc)
        }
    }

    @IBAction func resetRulerPositions(_ sender: Any) {
        if let controller = rulerManager.activeController {
            controller.state.settings.zeroCorner = Prefs.defaultZeroCorner
            controller.state.layout = RulerLayoutState.defaults(
                zeroCorner: Prefs.defaultZeroCorner
            )
            controller.state.visibility = RulerWingVisibility()
            controller.show()
            updateDisplay()
            updateMouseTickTimer()
            return
        }

        createLegacyRulersIfNeeded()

        prefs.zeroCorner = Prefs.defaultZeroCorner

        // ungroup rulers during reset operation
        prefs.groupRulers = false
        rulerVisibility.showAll()
        for ruler in rulers {
            ruler.resetPosition()
            showRuler(ruler, updateMode: false)
        }

        prefs.groupRulers = Prefs.defaultGroupRulers
        applyRulerWindowMode()
    }

    @IBAction func showRulers(_ sender: Any) {
        showRulers()
    }

    @IBAction func toggleHorizontalRuler(_ sender: Any) {
        toggleRuler(orientation: .horizontal)
    }

    @IBAction func toggleVerticalRuler(_ sender: Any) {
        toggleRuler(orientation: .vertical)
    }

    @IBAction func flipHorizontalRuler(_ sender: Any) {
        flipRulers(along: .horizontal)
        showHorizontalOriginHotkeyBezel(on: bezelScreen(for: sender))
    }

    @IBAction func flipVerticalRuler(_ sender: Any) {
        flipRulers(along: .vertical)
        showVerticalOriginHotkeyBezel(on: bezelScreen(for: sender))
    }

    func flipRulers(along orientation: Orientation) {
        if !rulerManager.hasRulers && rulers.isEmpty {
            createRulersIfNeeded()
        }

        if let controller = rulerManager.activeController {
            let flippedCorner = controller.state.settings.zeroCorner.flipped(along: orientation)
            controller.prepareForZeroCornerChange(to: flippedCorner)
            controller.redrawForPreferenceChange()
            updateDisplay()
            return
        }

        createLegacyRulersIfNeeded()

        let oldGeometry = ZeroCornerGeometry(zeroCorner: prefs.zeroCorner)
        let flippedCorner = prefs.zeroCorner.flipped(along: orientation)
        let flippedRuler = existingRulerController(orientation: orientation)
        let otherOrientation: Orientation = orientation == .horizontal ? .vertical : .horizontal
        let otherRuler = existingRulerController(orientation: otherOrientation)
        let zeroPointOffset = zeroPointOffset(
            from: flippedRuler?.rulerWindow,
            to: otherRuler?.rulerWindow,
            geometry: oldGeometry
        )

        if prefs.groupRulers,
           let groupedRulerController = groupedRulerController,
           groupedRulerController.isVisible {
            groupedRulerController.prepareForZeroCornerChange(to: flippedCorner)
            prefs.zeroCorner = flippedCorner
            syncGroupedRulerFramesToRulerWindows(persistAutosave: true)
            return
        }

        prefs.zeroCorner = flippedCorner

        guard prefs.groupRulers,
              let flippedWindow = flippedRuler?.rulerWindow,
              let otherWindow = otherRuler?.rulerWindow,
              isRulerWindowShown(otherWindow),
              let zeroPointOffset = zeroPointOffset else { return }

        let newGeometry = ZeroCornerGeometry(zeroCorner: flippedCorner)
        let flippedZeroPoint = newGeometry.zeroPoint(in: flippedWindow.frame, for: orientation)
        let targetOtherZeroPoint = NSPoint(
            x: flippedZeroPoint.x + zeroPointOffset.width,
            y: flippedZeroPoint.y + zeroPointOffset.height
        )
        let otherFrame = newGeometry.frame(
            for: otherOrientation,
            zeroPoint: targetOtherZeroPoint,
            size: otherWindow.frame.size
        )

        detachRulerWindows()
        otherWindow.setFrame(otherFrame, display: true)
        applyRulerWindowMode()
    }

    private func setUnit(_ unit: Unit) {
        if updateActiveRulerSettings({ settings in
            settings.unit = unit
        }) {
            return
        }

        prefs.unit = unit
    }

    func isRulerWindowShown(_ window: RulerWindow) -> Bool {
        return window.isVisible || window.parent != nil || rulers.contains {
            $0.rulerWindow.childWindows?.contains(window) == true
        }
    }

    private func zeroPointOffset(
        from sourceWindow: RulerWindow?,
        to targetWindow: RulerWindow?,
        geometry: ZeroCornerGeometry
    ) -> NSSize? {
        guard let sourceWindow = sourceWindow,
              let targetWindow = targetWindow else { return nil }

        let sourceZeroPoint = geometry.zeroPoint(
            in: sourceWindow.frame,
            for: sourceWindow.ruler.orientation
        )
        let targetZeroPoint = geometry.zeroPoint(
            in: targetWindow.frame,
            for: targetWindow.ruler.orientation
        )

        return NSSize(
            width: targetZeroPoint.x - sourceZeroPoint.x,
            height: targetZeroPoint.y - sourceZeroPoint.y
        )
    }

    func performRulerHotkey(
        keyCode: Int,
        modifierFlags: NSEvent.ModifierFlags,
        sender: Any
    ) -> Bool {
        if let controller = sender as? GroupedRulerController {
            rulerManager.markActive(controller)
        }

        let keyboardModifiers = modifierFlags
            .intersection(.deviceIndependentFlagsMask)
            .subtracting(.capsLock)

        if keyboardModifiers == .shift {
            switch keyCode {
            case kVK_ANSI_H:
                flipHorizontalRuler(sender)
            case kVK_ANSI_V:
                flipVerticalRuler(sender)
            default:
                return false
            }

            return true
        }

        guard keyboardModifiers.isEmpty else { return false }

        switch keyCode {
        case kVK_ANSI_H:
            toggleHorizontalRuler(sender)
        case kVK_ANSI_V:
            toggleVerticalRuler(sender)
        case kVK_ANSI_U:
            cycleUnits(sender)
        case kVK_ANSI_F:
            toggleFloatRulers(sender)
        case kVK_ANSI_G:
            guard !rulerManager.hasRulers else { return true }
            toggleGroupRulers(sender)
        case kVK_ANSI_S:
            toggleRulerShadow(sender)
        case kVK_ANSI_O:
            alignRulersAtMouseLocation(sender)
        default:
            return false
        }

        return true
    }

    private func showHotkeyBezel(_ key: HotkeyBezelLocalizationKey, on screen: NSScreen?) {
        hotkeyBezel.show(key.localizedString, on: screen)
    }

    private func showHotkeyBezel(format key: HotkeyBezelLocalizationKey, _ value: String, on screen: NSScreen?) {
        hotkeyBezel.show(String(format: key.localizedString, value), on: screen)
    }

    private func showGroupRulersHotkeyBezel(on screen: NSScreen?) {
        showHotkeyBezel(prefs.groupRulers ? .rulersGrouped : .rulersUngrouped, on: screen)
    }

    private func showHorizontalOriginHotkeyBezel(on screen: NSScreen?) {
        showHotkeyBezel(.flipHorizontal, on: screen)
    }

    private func showVerticalOriginHotkeyBezel(on screen: NSScreen?) {
        showHotkeyBezel(.flipVertical, on: screen)
    }

    private func bezelScreen(for sender: Any) -> NSScreen? {
        if let rulerController = sender as? RulerController {
            return rulerController.rulerWindow.screen
        }

        if let groupedRulerController = sender as? GroupedRulerController {
            return groupedRulerController.groupedWindow.screen
        }

        if let activeController = rulerManager.activeController {
            return activeController.groupedWindow.screen
        }

        return rulers.first { $0.rulerWindow.isKeyWindow }?.rulerWindow.screen
    }

    private func unitLabel(_ unit: Unit) -> String {
        switch unit {
        case .pixels:
            return HotkeyBezelLocalizationKey.pixelsUnit.localizedString
        case .millimeters:
            return HotkeyBezelLocalizationKey.millimetersUnit.localizedString
        case .inches:
            return HotkeyBezelLocalizationKey.inchesUnit.localizedString
        }
    }

    // MARK: - Application Quit

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        closeRulerColorPanel()
        return .terminateNow
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        closeRulerColorPanel()
        saveRulerSetState()
        prefs.save()
    }

}

extension AppDelegate: NSMenuItemValidation {

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(newRuler(_:)):
            return true
        case #selector(openRulerSettings(_:)):
            return rulerManager.activeController != nil
        case #selector(closeKeyWindow(_:)):
            return rulerManager.activeController != nil || NSApp.keyWindow?.isVisible == true
        case #selector(toggleGroupRulers(_:)):
            return !rulerManager.hasRulers
        case #selector(toggleHorizontalRuler(_:)):
            if let controller = rulerManager.activeController {
                let isVisible = controller.state.isWingVisible(.horizontal)
                menuItem.title = isVisible
                    ? NSLocalizedString("Hide Horizontal Ruler", comment: "Menu item title to hide the horizontal ruler")
                    : NSLocalizedString("Show Horizontal Ruler", comment: "Menu item title to show the horizontal ruler")
                return !isVisible || controller.state.isWingVisible(.vertical)
            }

            let ruler = existingRulerController(orientation: .horizontal)
            menuItem.title = isRulerVisible(ruler)
                ? NSLocalizedString("Hide Horizontal Ruler", comment: "Menu item title to hide the horizontal ruler")
                : NSLocalizedString("Show Horizontal Ruler", comment: "Menu item title to show the horizontal ruler")
            return canToggleRulerVisibility
        case #selector(toggleVerticalRuler(_:)):
            if let controller = rulerManager.activeController {
                let isVisible = controller.state.isWingVisible(.vertical)
                menuItem.title = isVisible
                    ? NSLocalizedString("Hide Vertical Ruler", comment: "Menu item title to hide the vertical ruler")
                    : NSLocalizedString("Show Vertical Ruler", comment: "Menu item title to show the vertical ruler")
                return !isVisible || controller.state.isWingVisible(.horizontal)
            }

            let ruler = existingRulerController(orientation: .vertical)
            menuItem.title = isRulerVisible(ruler)
                ? NSLocalizedString("Hide Vertical Ruler", comment: "Menu item title to hide the vertical ruler")
                : NSLocalizedString("Show Vertical Ruler", comment: "Menu item title to show the vertical ruler")
            return canToggleRulerVisibility
        case #selector(showRulers(_:)):
            menuItem.title = NSLocalizedString("Show All Rulers", comment: "Menu item title to show all ruler windows")
            return true
        default:
            return true
        }
    }

}



// MARK: - Timer
extension AppDelegate {

    func suspendMouseTickUpdates(owner: AnyObject) {
        mouseTickTimerPolicy.suspend(owner: owner)
        updateMouseTickTimer()
    }

    func resumeMouseTickUpdates(owner: AnyObject) {
        mouseTickTimerPolicy.resume(owner: owner)
        updateMouseTickTimer()
    }

    func suppressMouseTickDrawing(owner: AnyObject) {
        guard !mouseTickDrawingSuppressedOwners.contains(owner) else { return }

        mouseTickDrawingSuppressedOwners.add(owner)
        updateMouseTickDrawingVisibility()
    }

    func unsuppressMouseTickDrawing(owner: AnyObject) {
        guard mouseTickDrawingSuppressedOwners.contains(owner) else { return }

        mouseTickDrawingSuppressedOwners.remove(owner)
        updateMouseTickDrawingVisibility()
    }

    private func updateMouseTickDrawingVisibility() {
        setMouseTickDrawingEnabled(!hasMouseTickDrawingSuppressedOwners)
    }

    private var hasMouseTickDrawingSuppressedOwners: Bool {
        guard mouseTickDrawingSuppressedOwners.count > 0 else { return false }
        return mouseTickDrawingSuppressedOwners.anyObject != nil
    }

    private func setMouseTickDrawingEnabled(_ isEnabled: Bool) {
        for ruler in rulers {
            ruler.rulerWindow.rule.showMouseTick = isEnabled
        }

        for controller in rulerManager.controllers {
            controller.setMouseTickDrawingEnabled(isEnabled)
        }
        legacyGroupedRulerController?.setMouseTickDrawingEnabled(isEnabled)
    }

    private func updateMouseTickTimer() {
        mouseTickTimerPolicy.updateVisibleRulers(hasVisibleRuler)

        guard let timeInterval = mouseTickTimerPolicy.desiredInterval else {
            stopTimer()
            return
        }

        startTimer(timeInterval: timeInterval)
    }

    private func startTimer(timeInterval: TimeInterval) {
        guard timer == nil || timerInterval != timeInterval else { return }

        timer?.invalidate()
        timerInterval = timeInterval

        timer = Timer.scheduledTimer(
            timeInterval: timeInterval,
            target: self,
            selector: #selector(self.onInterval),
            userInfo: nil,
            repeats: true
        )
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerInterval = nil
    }

    @objc func onInterval() {
        self.updateMouseLocation()
    }

    private func updateMouseLocation() {
        var mouseLoc = NSEvent.mouseLocation
        mouseLoc.x = mouseLoc.x.rounded()
        mouseLoc.y = mouseLoc.y.rounded()

        if rulerManager.hasRulers {
            for controller in rulerManager.controllers where controller.isVisible {
                controller.drawMouseTick(at: mouseLoc)
            }
            return
        }

        if let groupedRulerController = groupedRulerController,
           groupedRulerController.isVisible {
            groupedRulerController.drawMouseTick(at: mouseLoc)
            return
        }

        for ruler in rulers {
            ruler.rulerWindow.rule.drawMouseTick(at: mouseLoc)
        }
    }

}
