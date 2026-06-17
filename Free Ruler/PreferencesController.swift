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

class PreferencesController: NSWindowController, NSWindowDelegate, NotificationPoster {

    var observers: [NSKeyValueObservation] = []
    private var colorPanelObserver: NSObjectProtocol?

    @IBOutlet weak var foregroundOpacitySlider: NSSlider!
    @IBOutlet weak var backgroundOpacitySlider: NSSlider!

    @IBOutlet weak var foregroundOpacityLabel: NSTextField!
    @IBOutlet weak var backgroundOpacityLabel: NSTextField!

    @IBOutlet weak var rulerColorWell: NSColorWell!
    @IBOutlet weak var resetRulerColorButton: NSButton!

    @IBOutlet weak var floatRulersCheckbox: NSButton!
    @IBOutlet weak var groupRulersCheckbox: NSButton!
    @IBOutlet weak var rulerShadowCheckbox: NSButton!

    override var windowNibName: String {
        return "PreferencesController"
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        window?.delegate = self
        window?.identifier = NSUserInterfaceItemIdentifier("preferences-window")
        window?.isMovableByWindowBackground = true
        floatRulersCheckbox.identifier = NSUserInterfaceItemIdentifier("float-rulers-checkbox")
        floatRulersCheckbox.setAccessibilityIdentifier("float-rulers-checkbox")
        groupRulersCheckbox.identifier = NSUserInterfaceItemIdentifier("group-rulers-checkbox")
        groupRulersCheckbox.setAccessibilityIdentifier("group-rulers-checkbox")
        rulerShadowCheckbox.identifier = NSUserInterfaceItemIdentifier("ruler-shadow-checkbox")
        rulerShadowCheckbox.setAccessibilityIdentifier("ruler-shadow-checkbox")
        configureOpaqueColorPicking()
        rulerColorWell.isContinuous = true
        rulerColorWell.supportsAlpha = false
        rulerColorWell.identifier = NSUserInterfaceItemIdentifier("ruler-color-well")
        rulerColorWell.setAccessibilityIdentifier("ruler-color-well")
        window?.initialFirstResponder = rulerColorWell
        configureResetRulerColorButton()

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
            prefs.observe(\Prefs.groupRulers, options: .new) { prefs, changed in
                self.updateGroupRulersCheckbox()
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
    @IBAction func setGroupRulers(_ sender: Any) {
        prefs.groupRulers = groupRulersCheckbox.state == .on
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

    func updateView() {
        updateForegroundSlider()
        updateBackgroundSlider()
        updateRulerColorWell()
        updateFloatRulersCheckbox()
        updateGroupRulersCheckbox()
        updateRulerShadowCheckbox()
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

    func updateGroupRulersCheckbox() {
        groupRulersCheckbox.state = prefs.groupRulers ? .on : .off
    }

    func updateRulerShadowCheckbox() {
        rulerShadowCheckbox.state = prefs.rulerShadow ? .on : .off
    }

    private func configureResetRulerColorButton() {
        configureResetRulerColorButtonAppearance(resetRulerColorButton, identifier: "reset-ruler-color-button")
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

final class RulerSettingsController: NSWindowController, NSWindowDelegate {

    private weak var rulerController: GroupedRulerController?
    private var colorPanelObserver: NSObjectProtocol?
    private var hasCenteredWindow = false

    private let colorLabel: NSTextField
    let rulerColorWell: RulerColorWell
    let resetRulerColorButton: NSButton

    var currentRulerController: GroupedRulerController? {
        return rulerController
    }

    init(rulerController: GroupedRulerController) {
        self.rulerController = rulerController

        colorLabel = NSTextField(
            labelWithString: NSLocalizedString(
                "Color",
                comment: "Label for the active ruler color setting"
            )
        )
        rulerColorWell = RulerColorWell(frame: NSRect(x: 0, y: 0, width: 64, height: 30))
        resetRulerColorButton = NSButton(frame: .zero)

        let window = RulerSettingsController.makeWindow(
            colorLabel: colorLabel,
            rulerColorWell: rulerColorWell,
            resetRulerColorButton: resetRulerColorButton
        )

        super.init(window: window)

        window.delegate = self
        window.initialFirstResponder = rulerColorWell
        configureControls()
        subscribeToColorPanel()
        updateView()
    }

    required init?(coder: NSCoder) {
        nil
    }

    deinit {
        if let colorPanelObserver = colorPanelObserver {
            NotificationCenter.default.removeObserver(colorPanelObserver)
        }
    }

    override func showWindow(_ sender: Any?) {
        configureOpaqueColorPicking()
        updateView()
        window?.makeKeyAndOrderFront(sender)
        window?.makeFirstResponder(rulerColorWell)

        if !hasCenteredWindow {
            window?.center()
            hasCenteredWindow = true
        }
    }

    func windowWillClose(_ notification: Notification) {
        rulerColorWell.deactivate()
        closeRulerColorPanel()
    }

    func updateRulerController(_ controller: GroupedRulerController) {
        rulerController = controller
        updateView()
    }

    @objc func setRulerColor(_ sender: Any) {
        applyRulerColor(rulerColorWell.color)
    }

    @objc func resetRulerColor(_ sender: Any) {
        applyRulerColor(Prefs.defaultRulerFillColor)
    }

    func updateView() {
        let currentColor = rulerController?.state.settings.rulerColor ?? Prefs.defaultRulerFillColor
        let hasRuler = rulerController != nil

        rulerColorWell.supportsAlpha = false
        rulerColorWell.color = currentColor
        rulerColorWell.isEnabled = hasRuler
        resetRulerColorButton.isEnabled = hasRuler
        resetRulerColorButton.isHidden = Prefs.colorsMatch(currentColor, Prefs.defaultRulerFillColor)
    }

    private static func makeWindow(
        colorLabel: NSTextField,
        rulerColorWell: RulerColorWell,
        resetRulerColorButton: NSButton
    ) -> NSPanel {
        let contentView = NSView()
        let row = NSStackView(views: [colorLabel, rulerColorWell, resetRulerColorButton])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.distribution = .fill
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false

        colorLabel.alignment = .right
        colorLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        rulerColorWell.translatesAutoresizingMaskIntoConstraints = false
        resetRulerColorButton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(row)
        NSLayoutConstraint.activate([
            colorLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 68),
            rulerColorWell.widthAnchor.constraint(equalToConstant: 64),
            rulerColorWell.heightAnchor.constraint(equalToConstant: 30),
            resetRulerColorButton.widthAnchor.constraint(equalToConstant: 24),
            resetRulerColorButton.heightAnchor.constraint(equalToConstant: 24),
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18),
        ])

        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 72),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        window.title = NSLocalizedString(
            "Ruler Settings",
            comment: "Window title for the active ruler settings panel"
        )
        window.contentView = contentView
        window.identifier = NSUserInterfaceItemIdentifier("ruler-settings-window")
        window.setAccessibilityIdentifier("ruler-settings-window")
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        return window
    }

    private func configureControls() {
        rulerColorWell.isContinuous = true
        rulerColorWell.supportsAlpha = false
        rulerColorWell.identifier = NSUserInterfaceItemIdentifier("ruler-settings-color-well")
        rulerColorWell.setAccessibilityIdentifier("ruler-settings-color-well")
        rulerColorWell.target = self
        rulerColorWell.action = #selector(setRulerColor(_:))

        resetRulerColorButton.target = self
        resetRulerColorButton.action = #selector(resetRulerColor(_:))
        configureResetRulerColorButtonAppearance(
            resetRulerColorButton,
            identifier: "reset-ruler-settings-color-button"
        )
    }

    private func applyRulerColor(_ color: NSColor) {
        rulerController?.updateSettings { settings in
            settings.setRulerColor(color)
        }
        updateView()
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
}

func closeRulerColorPanel() {
    activeRulerColorWell = nil
    let colorPanel = NSColorPanel.shared
    colorPanel.animationBehavior = .none
    colorPanel.setTarget(nil)
    colorPanel.setAction(nil)
    colorPanel.close()
}
