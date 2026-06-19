import Cocoa

private let colorPanelOpaqueConfigurationRetryDelays: [TimeInterval] = [0.1, 0.3]
private let rulerColorPanelIdentifier = NSUserInterfaceItemIdentifier("ruler-color-panel")
private let rulerColorPanelOpaqueAccessibilityValue = "ruler-color-panel-alpha-hidden"
private weak var activeRulerColorWell: RulerColorWell?

func configureOpaqueColorPicking() {
    let colorPanel = NSColorPanel.shared
    colorPanel.identifier = rulerColorPanelIdentifier
    colorPanel.setAccessibilityIdentifier(rulerColorPanelIdentifier.rawValue)
    if UITestSupport.isEnabled {
        colorPanel.setAccessibilityValue(rulerColorPanelOpaqueAccessibilityValue)
    }
    setColorPickingIgnoresAlpha(true)
    colorPanel.showsAlpha = false
    colorPanel.isContinuous = true
    colorPanel.animationBehavior = .none
    colorPanel.isRestorable = false
}

private func configureOpaqueColorPickingAfterPanelUpdates() {
    configureOpaqueColorPicking()

    // The shared color panel can rebuild picker controls shortly after opening; reapply during
    // that churn so alpha controls stay hidden without doing work for every color change.
    for delay in colorPanelOpaqueConfigurationRetryDelays {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            configureOpaqueColorPicking()
        }
    }
}

private func setColorPickingIgnoresAlpha(_ ignoresAlpha: Bool) {
    // AppKit still consults this deprecated global switch when deciding whether color wells support alpha.
    NSColor.ignoresAlpha = ignoresAlpha
}

class RulerColorWell: NSColorWell {

    override func awakeFromNib() {
        super.awakeFromNib()
        configureForOpaqueColors()
    }

    override func activate(_ exclusive: Bool) {
        configureForOpaqueColors()
        super.activate(exclusive)
        configureForOpaqueColors()
    }

    override func mouseDown(with event: NSEvent) {
        configureForOpaqueColors()

        let colorPanel = NSColorPanel.shared
        guard !colorPanel.isVisible else {
            closeRulerColorPanel()
            return
        }

        activeRulerColorWell = self
        colorPanel.animationBehavior = .none
        colorPanel.color = color
        colorPanel.setTarget(self)
        colorPanel.setAction(#selector(takeColorFrom(_:)))
        colorPanel.orderFront(self)
        configureForOpaqueColors()
        configureOpaqueColorPickingAfterPanelUpdates()
    }

    override func draw(_ dirtyRect: NSRect) {
        let bounds = bounds.insetBy(dx: 3, dy: 3)
        let path = NSBezierPath(roundedRect: bounds, xRadius: 5, yRadius: 5)

        NSColor.controlBackgroundColor.setFill()
        path.fill()

        color.setFill()
        path.fill()

        (window?.firstResponder == self ? NSColor.keyboardFocusIndicatorColor : NSColor.separatorColor).setStroke()
        path.lineWidth = window?.firstResponder == self ? 3 : 1
        path.stroke()
    }

    private func configureForOpaqueColors() {
        supportsAlpha = false
        configureOpaqueColorPicking()
    }

}

private func configureResetRulerColorButtonAppearance(_ button: NSButton, identifier: String) {
    let resetRulerColorLabel = NSLocalizedString(
        "Reset ruler color",
        comment: "Tooltip and accessibility label for the button that restores the default ruler color"
    )
    let symbol = NSImage(
        systemSymbolName: "arrow.counterclockwise",
        accessibilityDescription: resetRulerColorLabel
    )?.withSymbolConfiguration(
        NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
    ) ?? NSImage()
    symbol.isTemplate = true

    button.image = symbol
    button.isBordered = false
    button.imagePosition = .imageOnly
    button.imageScaling = .scaleProportionallyDown
    button.contentTintColor = .secondaryLabelColor
    button.toolTip = resetRulerColorLabel
    button.identifier = NSUserInterfaceItemIdentifier(identifier)
    button.setAccessibilityIdentifier(identifier)
    button.setAccessibilityLabel(resetRulerColorLabel)
}

protocol RulerSettingsControlsViewDelegate: AnyObject {
    func rulerSettingsControlsDidChangeRulerColor(_ controlsView: RulerSettingsControlsView)
    func rulerSettingsControlsDidResetRulerColor(_ controlsView: RulerSettingsControlsView)
    func rulerSettingsControlsDidChangeForegroundOpacity(_ controlsView: RulerSettingsControlsView)
    func rulerSettingsControlsDidChangeBackgroundOpacity(_ controlsView: RulerSettingsControlsView)
    func rulerSettingsControlsDidChangeFloatRulers(_ controlsView: RulerSettingsControlsView)
    func rulerSettingsControlsDidChangeRulerShadow(_ controlsView: RulerSettingsControlsView)
}

final class RulerSettingsControlsView: NSView {

    weak var delegate: RulerSettingsControlsViewDelegate?

    @IBOutlet var contentView: NSView!
    @IBOutlet weak var rulerColorWell: RulerColorWell!
    @IBOutlet weak var resetRulerColorButton: NSButton!
    @IBOutlet weak var foregroundOpacitySlider: NSSlider!
    @IBOutlet weak var backgroundOpacitySlider: NSSlider!
    @IBOutlet weak var foregroundOpacityLabel: NSTextField!
    @IBOutlet weak var backgroundOpacityLabel: NSTextField!
    @IBOutlet weak var floatRulersCheckbox: NSButton!
    @IBOutlet weak var rulerShadowCheckbox: NSButton!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadContentView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadContentView()
    }

    func configureForPreferences() {
        configureControls(
            colorWellIdentifier: "ruler-color-well",
            resetButtonIdentifier: "reset-ruler-color-button",
            foregroundSliderIdentifier: "ruler-foreground-opacity-slider",
            backgroundSliderIdentifier: "ruler-background-opacity-slider",
            foregroundLabelIdentifier: "ruler-foreground-opacity-label",
            backgroundLabelIdentifier: "ruler-background-opacity-label",
            floatCheckboxIdentifier: "float-rulers-checkbox",
            shadowCheckboxIdentifier: "ruler-shadow-checkbox"
        )
    }

    func configureForRulerSettings() {
        configureControls(
            colorWellIdentifier: "ruler-settings-color-well",
            resetButtonIdentifier: "reset-ruler-settings-color-button",
            foregroundSliderIdentifier: "ruler-settings-foreground-opacity-slider",
            backgroundSliderIdentifier: "ruler-settings-background-opacity-slider",
            foregroundLabelIdentifier: "ruler-settings-foreground-opacity-label",
            backgroundLabelIdentifier: "ruler-settings-background-opacity-label",
            floatCheckboxIdentifier: "ruler-settings-float-rulers-checkbox",
            shadowCheckboxIdentifier: "ruler-settings-ruler-shadow-checkbox"
        )
    }

    func update(
        rulerColor: NSColor,
        foregroundOpacity: Int,
        backgroundOpacity: Int,
        floatRulers: Bool,
        rulerShadow: Bool,
        isEnabled: Bool = true
    ) {
        rulerColorWell.supportsAlpha = false
        rulerColorWell.color = rulerColor
        rulerColorWell.isEnabled = isEnabled

        resetRulerColorButton.isEnabled = isEnabled
        resetRulerColorButton.isHidden = Prefs.colorsMatch(rulerColor, Prefs.defaultRulerFillColor)

        foregroundOpacitySlider.integerValue = foregroundOpacity
        foregroundOpacitySlider.isEnabled = isEnabled
        foregroundOpacityLabel.stringValue = "\(foregroundOpacity)%"

        backgroundOpacitySlider.integerValue = backgroundOpacity
        backgroundOpacitySlider.isEnabled = isEnabled
        backgroundOpacityLabel.stringValue = "\(backgroundOpacity)%"

        floatRulersCheckbox.state = floatRulers ? .on : .off
        floatRulersCheckbox.isEnabled = isEnabled

        rulerShadowCheckbox.state = rulerShadow ? .on : .off
        rulerShadowCheckbox.isEnabled = isEnabled

        configureKeyViewLoop()
    }

    func deactivateColorWell() {
        rulerColorWell.deactivate()
    }

    private func loadContentView() {
        guard contentView == nil else { return }

        var topLevelObjects: NSArray?
        Bundle.main.loadNibNamed(
            "RulerSettingsControlsView",
            owner: self,
            topLevelObjects: &topLevelObjects
        )

        guard let contentView = contentView else { return }

        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        configureBaseControls()
    }

    private func configureBaseControls() {
        rulerColorWell.isContinuous = true
        rulerColorWell.supportsAlpha = false
        rulerColorWell.target = self
        rulerColorWell.action = #selector(setRulerColor(_:))

        resetRulerColorButton.target = self
        resetRulerColorButton.action = #selector(resetRulerColor(_:))

        foregroundOpacitySlider.minValue = 5
        foregroundOpacitySlider.maxValue = 100
        foregroundOpacitySlider.numberOfTickMarks = 20
        foregroundOpacitySlider.allowsTickMarkValuesOnly = true
        foregroundOpacitySlider.tickMarkPosition = .below
        foregroundOpacitySlider.isContinuous = true
        foregroundOpacitySlider.target = self
        foregroundOpacitySlider.action = #selector(setForegroundOpacity(_:))

        backgroundOpacitySlider.minValue = 5
        backgroundOpacitySlider.maxValue = 100
        backgroundOpacitySlider.numberOfTickMarks = 20
        backgroundOpacitySlider.allowsTickMarkValuesOnly = true
        backgroundOpacitySlider.tickMarkPosition = .below
        backgroundOpacitySlider.isContinuous = true
        backgroundOpacitySlider.target = self
        backgroundOpacitySlider.action = #selector(setBackgroundOpacity(_:))

        floatRulersCheckbox.target = self
        floatRulersCheckbox.action = #selector(setFloatRulers(_:))

        rulerShadowCheckbox.target = self
        rulerShadowCheckbox.action = #selector(setRulerShadow(_:))

        configureKeyViewLoop()
    }

    private func configureControls(
        colorWellIdentifier: String,
        resetButtonIdentifier: String,
        foregroundSliderIdentifier: String,
        backgroundSliderIdentifier: String,
        foregroundLabelIdentifier: String,
        backgroundLabelIdentifier: String,
        floatCheckboxIdentifier: String,
        shadowCheckboxIdentifier: String
    ) {
        rulerColorWell.identifier = NSUserInterfaceItemIdentifier(colorWellIdentifier)
        rulerColorWell.setAccessibilityIdentifier(colorWellIdentifier)
        configureResetRulerColorButtonAppearance(resetRulerColorButton, identifier: resetButtonIdentifier)

        foregroundOpacitySlider.identifier = NSUserInterfaceItemIdentifier(foregroundSliderIdentifier)
        foregroundOpacitySlider.setAccessibilityIdentifier(foregroundSliderIdentifier)
        foregroundOpacityLabel.identifier = NSUserInterfaceItemIdentifier(foregroundLabelIdentifier)
        foregroundOpacityLabel.setAccessibilityIdentifier(foregroundLabelIdentifier)

        backgroundOpacitySlider.identifier = NSUserInterfaceItemIdentifier(backgroundSliderIdentifier)
        backgroundOpacitySlider.setAccessibilityIdentifier(backgroundSliderIdentifier)
        backgroundOpacityLabel.identifier = NSUserInterfaceItemIdentifier(backgroundLabelIdentifier)
        backgroundOpacityLabel.setAccessibilityIdentifier(backgroundLabelIdentifier)

        floatRulersCheckbox.identifier = NSUserInterfaceItemIdentifier(floatCheckboxIdentifier)
        floatRulersCheckbox.setAccessibilityIdentifier(floatCheckboxIdentifier)
        rulerShadowCheckbox.identifier = NSUserInterfaceItemIdentifier(shadowCheckboxIdentifier)
        rulerShadowCheckbox.setAccessibilityIdentifier(shadowCheckboxIdentifier)
    }

    private func configureKeyViewLoop() {
        rulerColorWell.nextKeyView = resetRulerColorButton.isHidden
            ? foregroundOpacitySlider
            : resetRulerColorButton
        resetRulerColorButton.nextKeyView = foregroundOpacitySlider
        foregroundOpacitySlider.nextKeyView = backgroundOpacitySlider
        backgroundOpacitySlider.nextKeyView = floatRulersCheckbox
        floatRulersCheckbox.nextKeyView = rulerShadowCheckbox
        rulerShadowCheckbox.nextKeyView = rulerColorWell
    }

    @objc private func setRulerColor(_ sender: Any) {
        delegate?.rulerSettingsControlsDidChangeRulerColor(self)
    }

    @objc private func resetRulerColor(_ sender: Any) {
        delegate?.rulerSettingsControlsDidResetRulerColor(self)
    }

    @objc private func setForegroundOpacity(_ sender: Any) {
        delegate?.rulerSettingsControlsDidChangeForegroundOpacity(self)
    }

    @objc private func setBackgroundOpacity(_ sender: Any) {
        delegate?.rulerSettingsControlsDidChangeBackgroundOpacity(self)
    }

    @objc private func setFloatRulers(_ sender: Any) {
        delegate?.rulerSettingsControlsDidChangeFloatRulers(self)
    }

    @objc private func setRulerShadow(_ sender: Any) {
        delegate?.rulerSettingsControlsDidChangeRulerShadow(self)
    }
}

class PreferencesController: NSWindowController, NSWindowDelegate, NotificationPoster {

    var observers: [NSKeyValueObservation] = []
    private var colorPanelObserver: NSObjectProtocol?

    @IBOutlet weak var settingsControlsView: RulerSettingsControlsView!
    @IBOutlet weak var resetFactoryDefaultsButton: NSButton!

    var foregroundOpacitySlider: NSSlider {
        return settingsControlsView.foregroundOpacitySlider
    }

    var backgroundOpacitySlider: NSSlider {
        return settingsControlsView.backgroundOpacitySlider
    }

    var foregroundOpacityLabel: NSTextField {
        return settingsControlsView.foregroundOpacityLabel
    }

    var backgroundOpacityLabel: NSTextField {
        return settingsControlsView.backgroundOpacityLabel
    }

    var rulerColorWell: RulerColorWell {
        return settingsControlsView.rulerColorWell
    }

    var resetRulerColorButton: NSButton {
        return settingsControlsView.resetRulerColorButton
    }

    var floatRulersCheckbox: NSButton {
        return settingsControlsView.floatRulersCheckbox
    }

    var rulerShadowCheckbox: NSButton {
        return settingsControlsView.rulerShadowCheckbox
    }

    override var windowNibName: String {
        return "PreferencesController"
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        window?.delegate = self
        window?.identifier = NSUserInterfaceItemIdentifier("preferences-window")
        window?.isMovableByWindowBackground = true
        configureOpaqueColorPicking()
        settingsControlsView.delegate = self
        settingsControlsView.configureForPreferences()
        window?.initialFirstResponder = rulerColorWell
        resetFactoryDefaultsButton.identifier = NSUserInterfaceItemIdentifier("reset-factory-defaults-button")
        resetFactoryDefaultsButton.setAccessibilityIdentifier("reset-factory-defaults-button")

        subscribeToPrefs()
        subscribeToColorPanel()
        updateView()
    }

    deinit {
        if let colorPanelObserver = colorPanelObserver {
            NotificationCenter.default.removeObserver(colorPanelObserver)
        }
    }

    override func showWindow(_ sender: Any?) {

        // send opened notification
        post(.preferencesWindowOpened)

        configureOpaqueColorPicking()
        window?.makeKeyAndOrderFront(sender)
        window?.makeFirstResponder(rulerColorWell)
        window?.center()
    }

    func windowWillClose(_ notification: Notification) {
        rulerColorWell.deactivate()
        closeRulerColorPanel()

        // send closed notification
        post(.preferencesWindowClosed)
    }

    func subscribeToPrefs() {
        observers = [
            prefs.observe(\Prefs.foregroundOpacity, options: .new) { prefs, changed in
                self.updateForegroundSlider()
            },
            prefs.observe(\Prefs.backgroundOpacity, options: .new) { prefs, changed in
                self.updateBackgroundSlider()
            },
            prefs.observe(\Prefs.floatRulers, options: .new) { prefs, changed in
                self.updateFloatRulersCheckbox()
            },
            prefs.observe(\Prefs.rulerShadow, options: .new) { prefs, changed in
                self.updateRulerShadowCheckbox()
            },
            prefs.observe(\Prefs.rulerColor, options: .new) { prefs, changed in
                self.updateRulerColorWell()
            },
        ]
    }

    @IBAction func setForegroundOpacity(_ sender: Any) {
        prefs.foregroundOpacity = foregroundOpacitySlider.integerValue
    }
    @IBAction func setBackgroundOpacity(_ sender: Any) {
        prefs.backgroundOpacity = backgroundOpacitySlider.integerValue
    }
    @IBAction func setFloatRulers(_ sender: Any) {
        prefs.floatRulers = floatRulersCheckbox.state == .on
    }
    @IBAction func setRulerShadow(_ sender: Any) {
        prefs.rulerShadow = rulerShadowCheckbox.state == .on
    }
    @IBAction func setRulerColor(_ sender: Any) {
        prefs.rulerColor = rulerColorWell.color
    }
    @IBAction func resetRulerColor(_ sender: Any) {
        prefs.rulerColor = Prefs.defaultRulerFillColor
    }
    @IBAction func resetToFactoryDefaults(_ sender: Any) {
        prefs.resetRulerDefaultsToFactoryDefaults()
        updateView()
    }

    func updateView() {
        settingsControlsView.update(
            rulerColor: prefs.rulerColor,
            foregroundOpacity: prefs.foregroundOpacity,
            backgroundOpacity: prefs.backgroundOpacity,
            floatRulers: prefs.floatRulers,
            rulerShadow: prefs.rulerShadow
        )
    }

    func updateForegroundSlider() {
        foregroundOpacitySlider.integerValue = prefs.foregroundOpacity
        foregroundOpacityLabel.stringValue = "\(prefs.foregroundOpacity)%"
    }

    func updateBackgroundSlider() {
        backgroundOpacitySlider.integerValue = prefs.backgroundOpacity
        backgroundOpacityLabel.stringValue = "\(prefs.backgroundOpacity)%"
    }

    func updateRulerColorWell() {
        rulerColorWell.supportsAlpha = false
        rulerColorWell.color = prefs.rulerColor
        resetRulerColorButton.isHidden = Prefs.colorsMatch(prefs.rulerColor, Prefs.defaultRulerFillColor)
    }

    func updateFloatRulersCheckbox() {
        floatRulersCheckbox.state = prefs.floatRulers ? .on : .off
    }

    func updateRulerShadowCheckbox() {
        rulerShadowCheckbox.state = prefs.rulerShadow ? .on : .off
    }

    private func subscribeToColorPanel() {
        colorPanelObserver = NotificationCenter.default.addObserver(
            forName: NSColorPanel.colorDidChangeNotification,
            object: NSColorPanel.shared,
            queue: .main
        ) { [weak self] notification in
            self?.updateRulerColorFromColorPanel(notification)
        }
    }

    private func updateRulerColorFromColorPanel(_ notification: Notification) {
        guard window?.isVisible == true,
              let colorPanel = notification.object as? NSColorPanel,
              colorPanel.isVisible,
              activeRulerColorWell === rulerColorWell else { return }

        prefs.rulerColor = colorPanel.color
    }

}

extension PreferencesController: RulerSettingsControlsViewDelegate {
    func rulerSettingsControlsDidChangeRulerColor(_ controlsView: RulerSettingsControlsView) {
        setRulerColor(controlsView.rulerColorWell as Any)
    }

    func rulerSettingsControlsDidResetRulerColor(_ controlsView: RulerSettingsControlsView) {
        resetRulerColor(controlsView.resetRulerColorButton as Any)
    }

    func rulerSettingsControlsDidChangeForegroundOpacity(_ controlsView: RulerSettingsControlsView) {
        setForegroundOpacity(controlsView.foregroundOpacitySlider as Any)
    }

    func rulerSettingsControlsDidChangeBackgroundOpacity(_ controlsView: RulerSettingsControlsView) {
        setBackgroundOpacity(controlsView.backgroundOpacitySlider as Any)
    }

    func rulerSettingsControlsDidChangeFloatRulers(_ controlsView: RulerSettingsControlsView) {
        setFloatRulers(controlsView.floatRulersCheckbox as Any)
    }

    func rulerSettingsControlsDidChangeRulerShadow(_ controlsView: RulerSettingsControlsView) {
        setRulerShadow(controlsView.rulerShadowCheckbox as Any)
    }
}

final class RulerSettingsController: NSWindowController, NSWindowDelegate {

    private weak var rulerController: GroupedRulerController?
    private var colorPanelObserver: NSObjectProtocol?

    @IBOutlet weak var settingsControlsView: RulerSettingsControlsView!
    @IBOutlet weak var resetDefaultsButton: NSButton!
    @IBOutlet weak var setDefaultsButton: NSButton!

    var rulerColorWell: RulerColorWell {
        return settingsControlsView.rulerColorWell
    }

    var resetRulerColorButton: NSButton {
        return settingsControlsView.resetRulerColorButton
    }

    var foregroundOpacitySlider: NSSlider {
        return settingsControlsView.foregroundOpacitySlider
    }

    var backgroundOpacitySlider: NSSlider {
        return settingsControlsView.backgroundOpacitySlider
    }

    var foregroundOpacityLabel: NSTextField {
        return settingsControlsView.foregroundOpacityLabel
    }

    var backgroundOpacityLabel: NSTextField {
        return settingsControlsView.backgroundOpacityLabel
    }

    var floatRulersCheckbox: NSButton {
        return settingsControlsView.floatRulersCheckbox
    }

    var rulerShadowCheckbox: NSButton {
        return settingsControlsView.rulerShadowCheckbox
    }

    var currentRulerController: GroupedRulerController? {
        return rulerController
    }

    override var windowNibName: String {
        return "RulerSettingsController"
    }

    init(rulerController: GroupedRulerController) {
        self.rulerController = rulerController
        super.init(window: nil)
        loadWindow()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        window?.delegate = self
        window?.identifier = NSUserInterfaceItemIdentifier("ruler-settings-window")
        window?.setAccessibilityIdentifier("ruler-settings-window")
        window?.isMovableByWindowBackground = true
        window?.isReleasedWhenClosed = false
        window?.initialFirstResponder = rulerColorWell
        settingsControlsView.delegate = self
        settingsControlsView.configureForRulerSettings()
        resetDefaultsButton.identifier = NSUserInterfaceItemIdentifier("reset-ruler-settings-to-default-button")
        resetDefaultsButton.setAccessibilityIdentifier("reset-ruler-settings-to-default-button")
        setDefaultsButton.identifier = NSUserInterfaceItemIdentifier("save-ruler-settings-as-default-button")
        setDefaultsButton.setAccessibilityIdentifier("save-ruler-settings-as-default-button")
        subscribeToColorPanel()
        updateView()
    }

    deinit {
        if let colorPanelObserver = colorPanelObserver {
            NotificationCenter.default.removeObserver(colorPanelObserver)
        }
    }

    override func showWindow(_ sender: Any?) {
        detachWindowIfNeeded()
        configureOpaqueColorPicking()
        updateView()
        window?.makeKeyAndOrderFront(sender)
        window?.makeFirstResponder(rulerColorWell)
        window?.center()
    }

    func show(attachedTo controller: GroupedRulerController, sender: Any?) {
        updateRulerController(controller)
        guard let settingsWindow = window else { return }

        configureOpaqueColorPicking()

        if settingsWindow.parent === controller.groupedWindow {
            position(settingsWindow, attachedTo: controller)
            settingsWindow.orderFront(sender)
            settingsWindow.makeKey()
            settingsWindow.makeFirstResponder(rulerColorWell)
            return
        }

        detachWindowIfNeeded()

        guard controller.groupedWindow.isVisible else {
            showWindow(sender)
            return
        }

        if settingsWindow.isVisible {
            settingsWindow.orderOut(sender)
        }

        position(settingsWindow, attachedTo: controller)
        controller.groupedWindow.addChildWindow(settingsWindow, ordered: .above)
        settingsWindow.orderFront(sender)
        settingsWindow.makeKey()
        settingsWindow.makeFirstResponder(rulerColorWell)
    }

    override func close() {
        detachWindowIfNeeded()
        super.close()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        true
    }

    func windowWillClose(_ notification: Notification) {
        detachWindowIfNeeded()
        closeSheetColorControls()
    }

    func updateRulerController(_ controller: GroupedRulerController) {
        rulerController = controller
        updateView()
    }

    @objc func setForegroundOpacity(_ sender: Any) {
        applySettings { settings in
            settings.foregroundOpacity = foregroundOpacitySlider.integerValue
        }
        rulerController?.opacity = foregroundOpacitySlider.integerValue
        updateView()
    }

    @objc func setBackgroundOpacity(_ sender: Any) {
        applySettings { settings in
            settings.backgroundOpacity = backgroundOpacitySlider.integerValue
        }
        rulerController?.opacity = backgroundOpacitySlider.integerValue
        updateView()
    }

    @objc func setFloatRulers(_ sender: Any) {
        applySettings { settings in
            settings.floatRulers = floatRulersCheckbox.state == .on
        }
        updateView()
    }

    @objc func setRulerShadow(_ sender: Any) {
        applySettings { settings in
            settings.rulerShadow = rulerShadowCheckbox.state == .on
        }
        updateView()
    }

    @objc func setRulerColor(_ sender: Any) {
        applyRulerColor(rulerColorWell.color)
    }

    @objc func resetRulerColor(_ sender: Any) {
        applyRulerColor(Prefs.defaultRulerFillColor)
    }

    @IBAction func resetToDefault(_ sender: Any) {
        applySettings { settings in
            settings = RulerSettings(defaults: prefs)
        }
        updateView()
    }

    @IBAction func setDefaultsForNewRulers(_ sender: Any) {
        guard let settings = rulerController?.state.settings else { return }

        prefs.applyDefaults(from: settings)
    }

    func updateView() {
        let currentSettings = rulerController?.state.settings
        let hasRuler = rulerController != nil

        settingsControlsView.update(
            rulerColor: currentSettings?.rulerColor ?? Prefs.defaultRulerFillColor,
            foregroundOpacity: currentSettings?.foregroundOpacity ?? Prefs.defaultForegroundOpacity,
            backgroundOpacity: currentSettings?.backgroundOpacity ?? Prefs.defaultBackgroundOpacity,
            floatRulers: currentSettings?.floatRulers ?? Prefs.defaultFloatRulers,
            rulerShadow: currentSettings?.rulerShadow ?? Prefs.defaultRulerShadow,
            isEnabled: hasRuler
        )
        resetDefaultsButton.isEnabled = hasRuler
        setDefaultsButton.isEnabled = hasRuler
    }

    private func applyRulerColor(_ color: NSColor) {
        applySettings { settings in
            settings.setRulerColor(color)
        }
        updateView()
    }

    private func applySettings(_ update: (inout RulerSettings) -> Void) {
        rulerController?.updateSettings(update)
    }

    private func subscribeToColorPanel() {
        colorPanelObserver = NotificationCenter.default.addObserver(
            forName: NSColorPanel.colorDidChangeNotification,
            object: NSColorPanel.shared,
            queue: .main
        ) { [weak self] notification in
            self?.updateRulerColorFromColorPanel(notification)
        }
    }

    private func updateRulerColorFromColorPanel(_ notification: Notification) {
        guard window?.isVisible == true,
              let colorPanel = notification.object as? NSColorPanel,
              colorPanel.isVisible,
              activeRulerColorWell === rulerColorWell else { return }

        applyRulerColor(colorPanel.color)
    }

    private func position(_ settingsWindow: NSWindow, attachedTo controller: GroupedRulerController) {
        let parentFrame = controller.groupedWindow.frame
        let settingsSize = settingsWindow.frame.size
        let margin: CGFloat = 12
        let frame: NSRect

        if controller.state.visibility.showsHorizontal {
            let horizontalFrame = controller.groupedWindow.screenFrame(for: .horizontal)
            let x = clamp(
                horizontalFrame.midX - settingsSize.width / 2,
                lower: parentFrame.minX + margin,
                upper: parentFrame.maxX - settingsSize.width - margin
            )
            let belowY = horizontalFrame.minY - settingsSize.height - margin
            let aboveY = horizontalFrame.maxY + margin
            let y = belowY >= parentFrame.minY + margin
                ? belowY
                : min(aboveY, parentFrame.maxY - settingsSize.height - margin)
            frame = NSRect(origin: NSPoint(x: x, y: y), size: settingsSize)
        } else {
            let verticalFrame = controller.groupedWindow.screenFrame(for: .vertical)
            let y = clamp(
                verticalFrame.midY - settingsSize.height / 2,
                lower: parentFrame.minY + margin,
                upper: parentFrame.maxY - settingsSize.height - margin
            )
            let rightX = verticalFrame.maxX + margin
            let leftX = verticalFrame.minX - settingsSize.width - margin
            let x = rightX + settingsSize.width <= parentFrame.maxX - margin
                ? rightX
                : max(leftX, parentFrame.minX + margin)
            frame = NSRect(origin: NSPoint(x: x, y: y), size: settingsSize)
        }

        settingsWindow.setFrame(frame, display: true)
    }

    private func clamp(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        guard lower <= upper else { return lower }

        return min(max(value, lower), upper)
    }

    private func detachWindowIfNeeded() {
        guard let settingsWindow = window else { return }

        if let sheetParent = settingsWindow.sheetParent {
            sheetParent.endSheet(settingsWindow)
        }
        if let parentWindow = settingsWindow.parent {
            parentWindow.removeChildWindow(settingsWindow)
        }
    }

    private func closeSheetColorControls() {
        if let foregroundOpacity = rulerController?.state.settings.foregroundOpacity {
            rulerController?.opacity = foregroundOpacity
        }
        settingsControlsView.deactivateColorWell()
        closeRulerColorPanel()
    }
}

extension RulerSettingsController: RulerSettingsControlsViewDelegate {
    func rulerSettingsControlsDidChangeRulerColor(_ controlsView: RulerSettingsControlsView) {
        setRulerColor(controlsView.rulerColorWell as Any)
    }

    func rulerSettingsControlsDidResetRulerColor(_ controlsView: RulerSettingsControlsView) {
        resetRulerColor(controlsView.resetRulerColorButton as Any)
    }

    func rulerSettingsControlsDidChangeForegroundOpacity(_ controlsView: RulerSettingsControlsView) {
        setForegroundOpacity(controlsView.foregroundOpacitySlider as Any)
    }

    func rulerSettingsControlsDidChangeBackgroundOpacity(_ controlsView: RulerSettingsControlsView) {
        setBackgroundOpacity(controlsView.backgroundOpacitySlider as Any)
    }

    func rulerSettingsControlsDidChangeFloatRulers(_ controlsView: RulerSettingsControlsView) {
        setFloatRulers(controlsView.floatRulersCheckbox as Any)
    }

    func rulerSettingsControlsDidChangeRulerShadow(_ controlsView: RulerSettingsControlsView) {
        setRulerShadow(controlsView.rulerShadowCheckbox as Any)
    }
}

func closeRulerColorPanel() {
    activeRulerColorWell = nil
    let colorPanel = NSColorPanel.shared
    colorPanel.animationBehavior = .none
    colorPanel.setTarget(nil)
    colorPanel.setAction(nil)
    colorPanel.close()
}
