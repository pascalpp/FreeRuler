import Cocoa
import Carbon.HIToolbox
#if DEBUG
import Darwin
#endif
#if SPARKLE
import Sparkle
#endif

private enum HotkeyBezelLocalizationKey: String {
    case rulerFloated = "HotkeyBezel.RulerFloated"
    case rulerUnfloated = "HotkeyBezel.RulerUnfloated"
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
        case .rulerFloated:
            return "Hotkey status bezel text indicating the ruler now floats above other windows"
        case .rulerUnfloated:
            return "Hotkey status bezel text indicating the ruler no longer floats above other windows"
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

    lazy var rulerManager: RulerManager = {
        let manager = RulerManager()
        manager.onActiveControllerChanged = { [weak self] controller in
            guard let self = self else { return }

            self.updateDisplay()

            guard let settingsController = self.rulerSettingsController,
                  settingsController.window?.isVisible == true else { return }

            if let controller = controller {
                settingsController.show(attachedTo: controller, sender: self)
            } else {
                settingsController.close()
            }
        }
        manager.onStateChanged = { [weak self] manager in
            guard let self = self else { return }

            self.saveRulerSetState()

            let activeController = manager.activeController
            guard let settingsController = self.rulerSettingsController,
                  settingsController.currentRulerController === activeController,
                  settingsController.window?.isVisible == true else { return }

            settingsController.updateView()
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

        rulerManager.setApplicationActive(NSApp.isActive)
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
                self.uiTestSupport?.writePreferencesState()
            },
            prefs.observe(\Prefs.groupRulers, options: .new) { prefs, changed in
                self.updateGroupRulersMenuItem()
                self.uiTestSupport?.writePreferencesState()
            },
            prefs.observe(\Prefs.rulerShadow, options: .new) { prefs, changed in
                self.updateRulerShadowMenuItem()
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
        for controller in rulerManager.controllers {
            controller.redrawForPreferenceChange()
        }
    }

    func redrawDefaultBackedRulers() {
        redrawRulers()
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
        uiTestSupport?.writePreferencesState(activeSettings: controller.state.settings)
        return true
    }

    func createRulersIfNeeded() {
        guard !rulerManager.hasRulers else { return }

        rulerManager.createRuler()
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
        let defaults = Prefs.userDefaults
        let horizontalAutosaveName = "horizontal-ruler"
        let verticalAutosaveName = "vertical-ruler"
        let hasLegacyAutosave = defaults.object(forKey: "NSWindow Frame \(horizontalAutosaveName)") != nil
            || defaults.object(forKey: "NSWindow Frame \(verticalAutosaveName)") != nil
        guard hasLegacyAutosave else { return nil }

        let settings = RulerSettings(defaults: prefs)
        let horizontalFrame = legacyAutosavedFrame(
            name: horizontalAutosaveName,
            fallback: getDefaultContentRect(orientation: .horizontal, zeroCorner: settings.zeroCorner)
        )
        let verticalFrame = legacyAutosavedFrame(
            name: verticalAutosaveName,
            fallback: getDefaultContentRect(orientation: .vertical, zeroCorner: settings.zeroCorner)
        )

        return RulerInstanceState(
            settings: settings,
            layout: RulerLayoutState(
                horizontalFrame: horizontalFrame,
                verticalFrame: verticalFrame,
                zeroCorner: settings.zeroCorner
            )
        )
    }

    private func legacyAutosavedFrame(name: String, fallback: NSRect) -> NSRect {
        let window = NSWindow(
            contentRect: fallback,
            styleMask: [.borderless, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        _ = window.setFrameUsingName(NSWindow.FrameAutosaveName(name))
        let frame = window.frame
        window.close()
        return frame
    }

    func toggleRuler(orientation: Orientation) {
        createRulersIfNeeded()

        let controller = rulerManager.activeController ?? rulerManager.createRuler()
        controller.toggleWing(orientation)
        updateDisplay()
        updateMouseTickTimer()
    }

    private var hasVisibleRuler: Bool {
        return rulerManager.hasVisibleRulers
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showRulers()
            return false
        }

        return true
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        rulerManager.setApplicationActive(true)

        for controller in rulerManager.controllers {
            controller.foreground()
        }

        mouseTickTimerPolicy.applicationDidBecomeActive()
        updateMouseTickTimer()

        rulerCursorController.applicationDidBecomeActive()
    }

    func applicationDidResignActive(_ notification: Notification) {
        rulerManager.setApplicationActive(false)

        for controller in rulerManager.controllers {
            controller.background()
        }

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
            uiTestSupport?.writePreferencesState(activeSettings: controller.state.settings)
            showHotkeyBezel(
                shouldFloat ? .rulerFloated : .rulerUnfloated,
                on: bezelScreen(for: sender)
            )
            return
        }

        prefs.floatRulers = !prefs.floatRulers
        showHotkeyBezel(
            prefs.floatRulers ? .rulerFloated : .rulerUnfloated,
            on: bezelScreen(for: sender)
        )
    }

    @IBAction func toggleGroupRulers(_ sender: Any) {
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
            uiTestSupport?.writePreferencesState(activeSettings: controller.state.settings)
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

    @IBAction func cycleRulers(_ sender: Any) {
        guard rulerManager.cycleActiveRuler() != nil else { return }

        updateDisplay()
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

        NSApp.keyWindow?.performClose(sender)
    }

    @IBAction func alignRulersAtMouseLocation(_ sender: Any) {
        var mouseLoc = NSEvent.mouseLocation
        mouseLoc.x = mouseLoc.x.rounded()
        mouseLoc.y = mouseLoc.y.rounded()

        createRulersIfNeeded()

        if let controller = rulerManager.activeController {
            controller.align(at: mouseLoc)
        }
    }

    @IBAction func resetRulerPositions(_ sender: Any) {
        createRulersIfNeeded()

        if let controller = rulerManager.activeController {
            controller.resetPosition()
            updateDisplay()
            updateMouseTickTimer()
        }
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
        createRulersIfNeeded()

        if let controller = rulerManager.activeController {
            let flippedCorner = controller.state.settings.zeroCorner.flipped(along: orientation)
            controller.prepareForZeroCornerChange(to: flippedCorner)
            controller.redrawForPreferenceChange()
            updateDisplay()
        }
    }

    private func setUnit(_ unit: Unit) {
        if updateActiveRulerSettings({ settings in
            settings.unit = unit
        }) {
            return
        }

        prefs.unit = unit
    }

    func performRulerHotkey(
        keyCode: Int,
        modifierFlags: NSEvent.ModifierFlags,
        sender: Any
    ) -> Bool {
        if let controller = sender as? RulerController {
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

        if keyboardModifiers == .command {
            switch keyCode {
            case kVK_ANSI_Grave:
                cycleRulers(sender)
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

        if let activeController = rulerManager.activeController {
            return activeController.rulerWindow.screen
        }

        return nil
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
            return true
        case #selector(toggleHorizontalRuler(_:)):
            if let controller = rulerManager.activeController {
                let isVisible = controller.state.isWingVisible(.horizontal)
                menuItem.title = isVisible
                    ? NSLocalizedString("Hide Horizontal Ruler", comment: "Menu item title to hide the horizontal ruler")
                    : NSLocalizedString("Show Horizontal Ruler", comment: "Menu item title to show the horizontal ruler")
                return !isVisible || controller.state.isWingVisible(.vertical)
            }

            menuItem.title = NSLocalizedString(
                "Show Horizontal Ruler",
                comment: "Menu item title to show the horizontal ruler"
            )
            return true
        case #selector(toggleVerticalRuler(_:)):
            if let controller = rulerManager.activeController {
                let isVisible = controller.state.isWingVisible(.vertical)
                menuItem.title = isVisible
                    ? NSLocalizedString("Hide Vertical Ruler", comment: "Menu item title to hide the vertical ruler")
                    : NSLocalizedString("Show Vertical Ruler", comment: "Menu item title to show the vertical ruler")
                return !isVisible || controller.state.isWingVisible(.horizontal)
            }

            menuItem.title = NSLocalizedString(
                "Show Vertical Ruler",
                comment: "Menu item title to show the vertical ruler"
            )
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
        for controller in rulerManager.controllers {
            controller.setMouseTickDrawingEnabled(isEnabled)
        }
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
        let mouseLoc = NSEvent.mouseLocation

        for controller in rulerManager.controllers where controller.isVisible {
            controller.drawMouseTick(at: mouseLoc)
        }
    }

}
