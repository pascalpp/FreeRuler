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

    var colorDidChange: ((RulerColorWell) -> Void)?
    var colorPanelPresenter: ((RulerColorWell, NSColorPanel) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        configureForOpaqueColors()
    }

    override func activate(_ exclusive: Bool) {
        configureForOpaqueColors()
        openColorPanel()
        configureForOpaqueColors()
    }

    override func keyDown(with event: NSEvent) {
        guard event.charactersIgnoringModifiers == " " else {
            super.keyDown(with: event)
            return
        }

        configureForOpaqueColors()
        openColorPanel()
    }

    override func takeColorFrom(_ sender: Any?) {
        if let colorPanel = sender as? NSColorPanel {
            color = colorPanel.color
        } else if let colorWell = sender as? NSColorWell {
            color = colorWell.color
        } else {
            super.takeColorFrom(sender)
        }
        configureForOpaqueColors()
        needsDisplay = true
        if let colorDidChange = colorDidChange {
            colorDidChange(self)
        } else {
            sendAction(action, to: target)
        }
    }

    override func mouseDown(with event: NSEvent) {
        configureForOpaqueColors()
        openColorPanel()
    }

    private func openColorPanel() {
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
        if let colorPanelPresenter = colorPanelPresenter {
            colorPanelPresenter(self, colorPanel)
        } else {
            colorPanel.orderFront(self)
        }
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

private func rulerDimensionValue(fromPixelLength pixelLength: CGFloat, unit: Unit, screen: NSScreen?) -> CGFloat {
    switch unit {
    case .pixels:
        return pixelLength
    case .millimeters:
        return pixelLength / (screen?.dpmm.width ?? NSScreen.defaultDpmm)
    case .inches:
        return pixelLength / (screen?.dpi.width ?? NSScreen.defaultDpi)
    }
}

private func rulerPixelLength(fromDimensionValue dimensionValue: CGFloat, unit: Unit, screen: NSScreen?) -> CGFloat {
    let pixelLength: CGFloat
    switch unit {
    case .pixels:
        pixelLength = dimensionValue
    case .millimeters:
        pixelLength = dimensionValue * (screen?.dpmm.width ?? NSScreen.defaultDpmm)
    case .inches:
        pixelLength = dimensionValue * (screen?.dpi.width ?? NSScreen.defaultDpi)
    }

    return pixelLength.rounded()
}

private func rulerDimensionString(fromPixelLength pixelLength: CGFloat, unit: Unit, screen: NSScreen?) -> String {
    let value = rulerDimensionValue(fromPixelLength: pixelLength, unit: unit, screen: screen)

    switch unit {
    case .pixels:
        return "\(Int(value.rounded()))"
    case .millimeters:
        return String(format: "%.1f", value)
    case .inches:
        return String(format: "%.3f", value)
    }
}

protocol RulerSettingsControlsViewDelegate: AnyObject {
    func rulerSettingsControlsDidChangeUnit(_ controlsView: RulerSettingsControlsView)
    func rulerSettingsControlsDidChangeDimensions(_ controlsView: RulerSettingsControlsView)
    func rulerSettingsControlsDidChangeRulerColor(_ controlsView: RulerSettingsControlsView)
    func rulerSettingsControlsDidResetRulerColor(_ controlsView: RulerSettingsControlsView)
    func rulerSettingsControlsDidChangeForegroundOpacity(_ controlsView: RulerSettingsControlsView)
    func rulerSettingsControlsDidChangeBackgroundOpacity(_ controlsView: RulerSettingsControlsView)
    func rulerSettingsControlsDidChangeFloatRulers(_ controlsView: RulerSettingsControlsView)
    func rulerSettingsControlsDidChangeRulerShadow(_ controlsView: RulerSettingsControlsView)
}

final class RulerSettingsControlsView: NSView, NSTextFieldDelegate {

    weak var delegate: RulerSettingsControlsViewDelegate?

    @IBOutlet var contentView: NSView!
    @IBOutlet weak var unitLabel: NSTextField!
    @IBOutlet weak var unitSegmentedControl: NSSegmentedControl!
    @IBOutlet weak var dimensionsLabel: NSTextField!
    @IBOutlet weak var dimensionWidthField: NSTextField!
    @IBOutlet weak var dimensionsSeparatorLabel: NSTextField!
    @IBOutlet weak var dimensionHeightField: NSTextField!
    @IBOutlet weak var rulerColorLabel: NSTextField!
    @IBOutlet weak var rulerColorWell: RulerColorWell!
    @IBOutlet weak var resetRulerColorButton: NSButton!
    @IBOutlet weak var foregroundOpacityTitleLabel: NSTextField!
    @IBOutlet weak var foregroundOpacitySlider: NSSlider!
    @IBOutlet weak var backgroundOpacityTitleLabel: NSTextField!
    @IBOutlet weak var backgroundOpacitySlider: NSSlider!
    @IBOutlet weak var foregroundOpacityLabel: NSTextField!
    @IBOutlet weak var backgroundOpacityLabel: NSTextField!
    @IBOutlet weak var floatRulersCheckbox: NSButton!
    @IBOutlet weak var rulerShadowCheckbox: NSButton!

    private var dimensionScreen: NSScreen?

    var selectedUnit: Unit {
        return Unit(rawValue: unitSegmentedControl.selectedSegment) ?? .pixels
    }

    var selectedHorizontalLength: CGFloat {
        return rulerPixelLength(
            fromDimensionValue: CGFloat(dimensionWidthField.doubleValue),
            unit: selectedUnit,
            screen: dimensionScreen
        )
    }

    var selectedVerticalLength: CGFloat {
        return rulerPixelLength(
            fromDimensionValue: CGFloat(dimensionHeightField.doubleValue),
            unit: selectedUnit,
            screen: dimensionScreen
        )
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadContentView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadContentView()
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if performRulerSettingsKeyEquivalent(with: event) {
            return true
        }

        return super.performKeyEquivalent(with: event)
    }

    func configureForPreferences() {
        configureControls(
            unitSegmentedControlIdentifier: "ruler-unit-segmented-control",
            widthFieldIdentifier: "ruler-width-field",
            heightFieldIdentifier: "ruler-height-field",
            colorWellIdentifier: "ruler-color-well",
            resetButtonIdentifier: "reset-ruler-color-button",
            foregroundSliderIdentifier: "ruler-foreground-opacity-slider",
            backgroundSliderIdentifier: "ruler-background-opacity-slider",
            foregroundLabelIdentifier: "ruler-foreground-opacity-label",
            backgroundLabelIdentifier: "ruler-background-opacity-label",
            floatCheckboxIdentifier: "float-rulers-checkbox",
            shadowCheckboxIdentifier: "ruler-shadow-checkbox"
        )
        configureCheckboxKeyEquivalents(float: "", shadow: "")
        rulerColorWell.colorPanelPresenter = nil
    }

    func configureForRulerSettings() {
        configureControls(
            unitSegmentedControlIdentifier: "ruler-settings-unit-segmented-control",
            widthFieldIdentifier: "ruler-settings-width-field",
            heightFieldIdentifier: "ruler-settings-height-field",
            colorWellIdentifier: "ruler-settings-color-well",
            resetButtonIdentifier: "reset-ruler-settings-color-button",
            foregroundSliderIdentifier: "ruler-settings-foreground-opacity-slider",
            backgroundSliderIdentifier: "ruler-settings-background-opacity-slider",
            foregroundLabelIdentifier: "ruler-settings-foreground-opacity-label",
            backgroundLabelIdentifier: "ruler-settings-background-opacity-label",
            floatCheckboxIdentifier: "ruler-settings-float-rulers-checkbox",
            shadowCheckboxIdentifier: "ruler-settings-ruler-shadow-checkbox"
        )
        configureCheckboxKeyEquivalents(float: "f", shadow: "s")
    }

    func update(
        unit: Unit,
        horizontalLength: CGFloat? = nil,
        verticalLength: CGFloat? = nil,
        dimensionScreen: NSScreen? = nil,
        rulerColor: NSColor,
        foregroundOpacity: Int,
        backgroundOpacity: Int,
        floatRulers: Bool,
        rulerShadow: Bool,
        isEnabled: Bool = true
    ) {
        self.dimensionScreen = dimensionScreen
        unitSegmentedControl.selectedSegment = unit.rawValue
        unitSegmentedControl.isEnabled = isEnabled

        updateDimensions(
            unit: unit,
            horizontalLength: horizontalLength,
            verticalLength: verticalLength,
            dimensionScreen: dimensionScreen
        )
        dimensionWidthField.isEnabled = isEnabled
        dimensionHeightField.isEnabled = isEnabled

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

    func updateDimensions(
        unit: Unit,
        horizontalLength: CGFloat? = nil,
        verticalLength: CGFloat? = nil,
        dimensionScreen: NSScreen? = nil
    ) {
        self.dimensionScreen = dimensionScreen
        unitSegmentedControl.selectedSegment = unit.rawValue

        if let horizontalLength = horizontalLength {
            dimensionWidthField.stringValue = rulerDimensionString(
                fromPixelLength: horizontalLength,
                unit: unit,
                screen: dimensionScreen
            )
        }
        if let verticalLength = verticalLength {
            dimensionHeightField.stringValue = rulerDimensionString(
                fromPixelLength: verticalLength,
                unit: unit,
                screen: dimensionScreen
            )
        }
    }

    func performRulerSettingsKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.type == .keyDown,
              event.modifierFlags
                  .intersection(.deviceIndependentFlagsMask)
                  .subtracting([.shift, .capsLock, .function])
                  .isEmpty,
              let character = event.charactersIgnoringModifiers?.lowercased() else {
            return false
        }

        switch character {
        case floatRulersCheckbox.keyEquivalent.lowercased() where !floatRulersCheckbox.keyEquivalent.isEmpty:
            return toggleFloatRulersFromKeyEquivalent()
        case rulerShadowCheckbox.keyEquivalent.lowercased() where !rulerShadowCheckbox.keyEquivalent.isEmpty:
            return toggleRulerShadowFromKeyEquivalent()
        default:
            return false
        }
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
        unitSegmentedControl.target = self
        unitSegmentedControl.action = #selector(setUnit(_:))
        unitSegmentedControl.segmentStyle = .rounded

        dimensionsSeparatorLabel.alignment = .center
        configureDimensionField(dimensionWidthField)
        configureDimensionField(dimensionHeightField)

        rulerColorWell.isContinuous = true
        rulerColorWell.supportsAlpha = false
        rulerColorWell.colorDidChange = { [weak self] _ in
            guard let self = self else { return }
            self.setRulerColor(self.rulerColorWell as Any)
        }
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
        unitSegmentedControlIdentifier: String,
        widthFieldIdentifier: String,
        heightFieldIdentifier: String,
        colorWellIdentifier: String,
        resetButtonIdentifier: String,
        foregroundSliderIdentifier: String,
        backgroundSliderIdentifier: String,
        foregroundLabelIdentifier: String,
        backgroundLabelIdentifier: String,
        floatCheckboxIdentifier: String,
        shadowCheckboxIdentifier: String
    ) {
        unitSegmentedControl.identifier = NSUserInterfaceItemIdentifier(unitSegmentedControlIdentifier)
        unitSegmentedControl.setAccessibilityIdentifier(unitSegmentedControlIdentifier)
        dimensionWidthField.identifier = NSUserInterfaceItemIdentifier(widthFieldIdentifier)
        dimensionWidthField.setAccessibilityIdentifier(widthFieldIdentifier)
        dimensionHeightField.identifier = NSUserInterfaceItemIdentifier(heightFieldIdentifier)
        dimensionHeightField.setAccessibilityIdentifier(heightFieldIdentifier)

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

    private func configureCheckboxKeyEquivalents(float: String, shadow: String) {
        floatRulersCheckbox.keyEquivalent = float
        floatRulersCheckbox.keyEquivalentModifierMask = []
        rulerShadowCheckbox.keyEquivalent = shadow
        rulerShadowCheckbox.keyEquivalentModifierMask = []
    }

    private func configureKeyViewLoop() {
        unitSegmentedControl.nextKeyView = dimensionWidthField
        dimensionWidthField.nextKeyView = dimensionHeightField
        dimensionHeightField.nextKeyView = rulerColorWell
        rulerColorWell.nextKeyView = resetRulerColorButton.isHidden
            ? foregroundOpacitySlider
            : resetRulerColorButton
        resetRulerColorButton.nextKeyView = foregroundOpacitySlider
        foregroundOpacitySlider.nextKeyView = backgroundOpacitySlider
        backgroundOpacitySlider.nextKeyView = floatRulersCheckbox
        floatRulersCheckbox.nextKeyView = rulerShadowCheckbox
        rulerShadowCheckbox.nextKeyView = unitSegmentedControl
    }

    private func configureDimensionField(_ field: NSTextField) {
        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        formatter.minimum = 0
        formatter.maximum = 4000
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 3
        formatter.numberStyle = .decimal

        field.formatter = formatter
        field.alignment = .right
        field.bezelStyle = .roundedBezel
        field.delegate = self
        field.target = self
        field.action = #selector(setDimensions(_:))
    }

    private func toggleFloatRulersFromKeyEquivalent() -> Bool {
        guard floatRulersCheckbox.isEnabled else { return false }

        floatRulersCheckbox.state = floatRulersCheckbox.state == .on ? .off : .on
        setFloatRulers(floatRulersCheckbox as Any)
        return true
    }

    private func toggleRulerShadowFromKeyEquivalent() -> Bool {
        guard rulerShadowCheckbox.isEnabled else { return false }

        rulerShadowCheckbox.state = rulerShadowCheckbox.state == .on ? .off : .on
        setRulerShadow(rulerShadowCheckbox as Any)
        return true
    }

    @objc private func setUnit(_ sender: Any) {
        delegate?.rulerSettingsControlsDidChangeUnit(self)
    }

    @objc private func setDimensions(_ sender: Any) {
        delegate?.rulerSettingsControlsDidChangeDimensions(self)
    }

    func controlTextDidEndEditing(_ notification: Notification) {
        guard let field = notification.object as? NSTextField,
              field === dimensionWidthField || field === dimensionHeightField else { return }

        setDimensions(field as Any)
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

    var unitSegmentedControl: NSSegmentedControl {
        return settingsControlsView.unitSegmentedControl
    }

    var dimensionWidthField: NSTextField {
        return settingsControlsView.dimensionWidthField
    }

    var dimensionHeightField: NSTextField {
        return settingsControlsView.dimensionHeightField
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
        window?.setAccessibilityIdentifier("preferences-window")
        window?.isMovableByWindowBackground = true
        configureOpaqueColorPicking()
        settingsControlsView.delegate = self
        settingsControlsView.configureForPreferences()
        window?.initialFirstResponder = unitSegmentedControl
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
        window?.makeFirstResponder(unitSegmentedControl)
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
            prefs.observe(\Prefs.unit, options: .new) { prefs, changed in
                self.updateUnitSegmentedControl()
                self.updateDimensionFields()
            },
            prefs.observe(\Prefs.defaultHorizontalLength, options: .new) { prefs, changed in
                self.updateDimensionFields()
            },
            prefs.observe(\Prefs.defaultVerticalLength, options: .new) { prefs, changed in
                self.updateDimensionFields()
            },
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

    @IBAction func setUnit(_ sender: Any) {
        prefs.unit = settingsControlsView.selectedUnit
    }

    @IBAction func setDimensions(_ sender: Any) {
        let horizontalLength = settingsControlsView.selectedHorizontalLength
        let verticalLength = settingsControlsView.selectedVerticalLength

        prefs.defaultHorizontalLength = Double(horizontalLength)
        prefs.defaultVerticalLength = Double(verticalLength)
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
            unit: prefs.unit,
            horizontalLength: prefs.effectiveDefaultHorizontalLength(),
            verticalLength: prefs.effectiveDefaultVerticalLength(),
            dimensionScreen: window?.screen ?? NSScreen.main,
            rulerColor: prefs.rulerColor,
            foregroundOpacity: prefs.foregroundOpacity,
            backgroundOpacity: prefs.backgroundOpacity,
            floatRulers: prefs.floatRulers,
            rulerShadow: prefs.rulerShadow
        )
    }

    func updateUnitSegmentedControl() {
        unitSegmentedControl.selectedSegment = prefs.unit.rawValue
    }

    func updateDimensionFields() {
        settingsControlsView.updateDimensions(
            unit: prefs.unit,
            horizontalLength: prefs.effectiveDefaultHorizontalLength(),
            verticalLength: prefs.effectiveDefaultVerticalLength(),
            dimensionScreen: window?.screen ?? NSScreen.main
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
    func rulerSettingsControlsDidChangeUnit(_ controlsView: RulerSettingsControlsView) {
        setUnit(controlsView.unitSegmentedControl as Any)
    }

    func rulerSettingsControlsDidChangeDimensions(_ controlsView: RulerSettingsControlsView) {
        setDimensions(controlsView.dimensionWidthField as Any)
    }

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

final class RulerSettingsWindow: NSPanel {
    weak var settingsController: RulerSettingsController?

    override var canBecomeKey: Bool {
        return true
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if settingsController?.performSettingsKeyEquivalent(with: event) == true {
            return true
        }

        return super.performKeyEquivalent(with: event)
    }
}

final class RulerSettingsController: NSWindowController, NSWindowDelegate {

    private weak var rulerController: RulerController?
    private weak var interactionSuspendedRulerController: RulerController?
    private var colorPanelObserver: NSObjectProtocol?
    private var didConfigureWindow = false

    @IBOutlet weak var settingsControlsView: RulerSettingsControlsView!
    @IBOutlet weak var resetDefaultsButton: NSButton!
    @IBOutlet weak var setDefaultsButton: NSButton!

    var rulerColorWell: RulerColorWell {
        return settingsControlsView.rulerColorWell
    }

    var unitSegmentedControl: NSSegmentedControl {
        return settingsControlsView.unitSegmentedControl
    }

    var dimensionWidthField: NSTextField {
        return settingsControlsView.dimensionWidthField
    }

    var dimensionHeightField: NSTextField {
        return settingsControlsView.dimensionHeightField
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

    var currentRulerController: RulerController? {
        return rulerController
    }

    override var windowNibName: String {
        return "RulerSettingsController"
    }

    init(rulerController: RulerController) {
        self.rulerController = rulerController
        super.init(window: nil)
        loadWindow()
        configureWindowIfNeeded()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        configureWindowIfNeeded()
    }

    private func configureWindowIfNeeded() {
        guard !didConfigureWindow,
              isWindowLoaded,
              settingsControlsView != nil else { return }

        didConfigureWindow = true
        window?.delegate = self
        window?.identifier = NSUserInterfaceItemIdentifier("ruler-settings-window")
        window?.setAccessibilityIdentifier("ruler-settings-window")
        window?.isMovableByWindowBackground = true
        window?.isReleasedWhenClosed = false
        window?.initialFirstResponder = unitSegmentedControl
        configureFloatingPanelWindow()
        settingsControlsView.delegate = self
        settingsControlsView.configureForRulerSettings()
        rulerColorWell.colorPanelPresenter = { [weak self] colorWell, colorPanel in
            self?.presentColorPanel(colorPanel, for: colorWell)
        }
        rulerColorWell.target = self
        rulerColorWell.action = #selector(setRulerColor(_:))
        resetDefaultsButton.identifier = NSUserInterfaceItemIdentifier("reset-ruler-settings-to-default-button")
        resetDefaultsButton.setAccessibilityIdentifier("reset-ruler-settings-to-default-button")
        setDefaultsButton.identifier = NSUserInterfaceItemIdentifier("save-ruler-settings-as-default-button")
        setDefaultsButton.setAccessibilityIdentifier("save-ruler-settings-as-default-button")
        subscribeToColorPanel()
        updateView()
    }

    deinit {
        clearRulerInteractionSuspension()
        if let colorPanelObserver = colorPanelObserver {
            NotificationCenter.default.removeObserver(colorPanelObserver)
        }
    }

    override func showWindow(_ sender: Any?) {
        detachWindowIfNeeded()
        configureOpaqueColorPicking()
        updateView()
        window?.makeKeyAndOrderFront(sender)
        window?.makeFirstResponder(unitSegmentedControl)
        window?.center()
        updateRulerInteractionSuspension()
    }

    func show(attachedTo controller: RulerController, sender: Any?) {
        updateRulerController(controller)
        guard let settingsWindow = window else { return }

        configureOpaqueColorPicking()

        if settingsWindow.parent === controller.rulerWindow {
            position(settingsWindow, attachedTo: controller)
            settingsWindow.orderFront(sender)
            settingsWindow.makeKey()
            settingsWindow.makeFirstResponder(unitSegmentedControl)
            updateRulerInteractionSuspension()
            return
        }

        detachWindowIfNeeded()

        guard controller.rulerWindow.isVisible else {
            showWindow(sender)
            return
        }

        if settingsWindow.isVisible {
            settingsWindow.orderOut(sender)
        }

        position(settingsWindow, attachedTo: controller)
        controller.rulerWindow.addChildWindow(settingsWindow, ordered: .above)
        settingsWindow.orderFront(sender)
        settingsWindow.makeKey()
        settingsWindow.makeFirstResponder(unitSegmentedControl)
        updateRulerInteractionSuspension()
    }

    override func close() {
        clearRulerInteractionSuspension()
        detachWindowIfNeeded()
        super.close()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        true
    }

    func windowWillClose(_ notification: Notification) {
        clearRulerInteractionSuspension()
        detachWindowIfNeeded()
        closeSheetColorControls()
    }

    func updateRulerController(_ controller: RulerController) {
        rulerController = controller
        updateRulerInteractionSuspension()
        updateView()
    }

    @objc func setUnit(_ sender: Any) {
        applySettings { settings in
            settings.unit = settingsControlsView.selectedUnit
        }
        updateView()
    }

    @objc func setDimensions(_ sender: Any) {
        let horizontalLength = settingsControlsView.selectedHorizontalLength
        let verticalLength = settingsControlsView.selectedVerticalLength

        rulerController?.updateDimensions(
            horizontalLength: horizontalLength,
            verticalLength: verticalLength
        )
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
        let defaultSettings = RulerSettings(defaults: prefs)
        applySettings { settings in
            settings = defaultSettings
        }
        rulerController?.updateDimensions(
            horizontalLength: prefs.effectiveDefaultHorizontalLength(),
            verticalLength: prefs.effectiveDefaultVerticalLength()
        )
        rulerController?.opacity = defaultSettings.foregroundOpacity
        updateView()
    }

    @IBAction func setDefaultsForNewRulers(_ sender: Any) {
        guard let controller = rulerController else { return }

        prefs.applyDefaults(from: controller.state.settings, layout: controller.state.layout)
    }

    func updateView() {
        configureWindowIfNeeded()
        guard isWindowLoaded,
              settingsControlsView != nil else { return }

        let currentSettings = rulerController?.state.settings
        let hasRuler = rulerController != nil

        settingsControlsView.update(
            unit: currentSettings?.unit ?? Prefs.defaultUnit,
            horizontalLength: rulerController?.state.layout.horizontalLength,
            verticalLength: rulerController?.state.layout.verticalLength,
            dimensionScreen: rulerController?.rulerWindow.screen ?? window?.screen ?? NSScreen.main,
            rulerColor: currentSettings?.rulerColor ?? Prefs.defaultRulerFillColor,
            foregroundOpacity: currentSettings?.foregroundOpacity ?? Prefs.defaultForegroundOpacity,
            backgroundOpacity: currentSettings?.backgroundOpacity ?? Prefs.defaultBackgroundOpacity,
            floatRulers: currentSettings?.floatRulers ?? Prefs.defaultFloatRulers,
            rulerShadow: currentSettings?.rulerShadow ?? Prefs.defaultRulerShadow,
            isEnabled: hasRuler
        )
        resetDefaultsButton.isEnabled = hasRuler
        setDefaultsButton.isEnabled = hasRuler
        repositionAttachedWindowsIfNeeded()
    }

    func performSettingsKeyEquivalent(with event: NSEvent) -> Bool {
        return settingsControlsView.performRulerSettingsKeyEquivalent(with: event)
    }

    private func configureFloatingPanelWindow() {
        guard let settingsWindow = window else { return }

        settingsWindow.styleMask.insert(.utilityWindow)
        settingsWindow.animationBehavior = .utilityWindow

        guard let panel = settingsWindow as? RulerSettingsWindow else { return }

        panel.settingsController = self
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
    }

    func presentColorPanel(_ colorPanel: NSColorPanel, for colorWell: RulerColorWell) {
        guard let settingsWindow = window else {
            colorPanel.orderFront(colorWell)
            return
        }

        if let parentWindow = colorPanel.parent, parentWindow !== settingsWindow {
            parentWindow.removeChildWindow(colorPanel)
        }

        position(colorPanel, attachedTo: settingsWindow)

        if colorPanel.parent == nil {
            settingsWindow.addChildWindow(colorPanel, ordered: .above)
        }

        colorPanel.orderFront(colorWell)
    }

    private func position(_ colorPanel: NSColorPanel, attachedTo settingsWindow: NSWindow) {
        let margin: CGFloat = 8
        let zeroCorner = rulerController?.state.settings.zeroCorner ?? Prefs.defaultZeroCorner
        let colorPanelSize = colorPanel.frame.size
        let defaultTopLeft = colorPanelTopLeftPoint(
            for: colorPanelSize,
            attachedTo: settingsWindow.frame,
            zeroCorner: zeroCorner,
            margin: margin
        )
        guard let visibleFrame = settingsWindow.screen?.visibleFrame ?? colorPanel.screen?.visibleFrame else {
            colorPanel.setFrameTopLeftPoint(defaultTopLeft)
            return
        }

        var topLeftPoint = defaultTopLeft
        if topLeftPoint.x < visibleFrame.minX {
            topLeftPoint.x = min(settingsWindow.frame.maxX + margin, visibleFrame.maxX - colorPanelSize.width)
        } else if topLeftPoint.x + colorPanelSize.width > visibleFrame.maxX {
            topLeftPoint.x = max(settingsWindow.frame.minX - colorPanelSize.width - margin, visibleFrame.minX)
        }

        if colorPanelSize.height <= visibleFrame.height {
            topLeftPoint.y = clamp(
                topLeftPoint.y,
                lower: visibleFrame.minY + colorPanelSize.height,
                upper: visibleFrame.maxY
            )
        } else {
            topLeftPoint.y = visibleFrame.maxY
        }

        colorPanel.setFrameTopLeftPoint(topLeftPoint)
    }

    private func colorPanelTopLeftPoint(
        for colorPanelSize: NSSize,
        attachedTo settingsFrame: NSRect,
        zeroCorner: ZeroCorner,
        margin: CGFloat
    ) -> NSPoint {
        let x: CGFloat
        let y: CGFloat

        switch zeroCorner {
        case .topLeft, .bottomLeft:
            x = settingsFrame.maxX + margin
        case .topRight, .bottomRight:
            x = settingsFrame.minX - colorPanelSize.width - margin
        }

        switch zeroCorner {
        case .topLeft, .topRight:
            y = settingsFrame.maxY
        case .bottomLeft, .bottomRight:
            y = settingsFrame.minY + colorPanelSize.height
        }

        return NSPoint(x: x, y: y)
    }

    private func applyRulerColor(_ color: NSColor) {
        applySettings { settings in
            settings.setRulerColor(color)
        }
        updateView()
    }

    private func repositionAttachedWindowsIfNeeded() {
        guard let controller = rulerController,
              let settingsWindow = window,
              settingsWindow.isVisible,
              settingsWindow.parent === controller.rulerWindow else { return }

        position(settingsWindow, attachedTo: controller)

        let colorPanel = NSColorPanel.shared
        if colorPanel.parent === settingsWindow {
            position(colorPanel, attachedTo: settingsWindow)
        }
    }

    private func updateRulerInteractionSuspension() {
        guard window?.isVisible == true,
              let controller = rulerController else {
            clearRulerInteractionSuspension()
            return
        }

        guard interactionSuspendedRulerController !== controller else { return }

        clearRulerInteractionSuspension()
        controller.suspendRulerInteraction(owner: self)
        interactionSuspendedRulerController = controller
    }

    private func clearRulerInteractionSuspension() {
        interactionSuspendedRulerController?.resumeRulerInteraction(owner: self)
        interactionSuspendedRulerController = nil
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

    private func position(_ settingsWindow: NSWindow, attachedTo controller: RulerController) {
        let settingsSize = settingsWindow.frame.size
        let frame = settingsFrame(
            size: settingsSize,
            zeroPoint: controller.rulerWindow.zeroPoint(),
            zeroCorner: controller.state.settings.zeroCorner
        )

        settingsWindow.setFrame(frame, display: true)
    }

    private func settingsFrame(size: NSSize, zeroPoint: NSPoint, zeroCorner: ZeroCorner) -> NSRect {
        let origin: NSPoint

        switch zeroCorner {
        case .topLeft:
            origin = NSPoint(x: zeroPoint.x, y: zeroPoint.y - size.height)
        case .topRight:
            origin = NSPoint(x: zeroPoint.x - size.width, y: zeroPoint.y - size.height)
        case .bottomLeft:
            origin = zeroPoint
        case .bottomRight:
            origin = NSPoint(x: zeroPoint.x - size.width, y: zeroPoint.y)
        }

        return NSRect(origin: origin, size: size)
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
    func rulerSettingsControlsDidChangeUnit(_ controlsView: RulerSettingsControlsView) {
        setUnit(controlsView.unitSegmentedControl as Any)
    }

    func rulerSettingsControlsDidChangeDimensions(_ controlsView: RulerSettingsControlsView) {
        setDimensions(controlsView.dimensionWidthField as Any)
    }

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
    if let parentWindow = colorPanel.parent {
        parentWindow.removeChildWindow(colorPanel)
    }
    colorPanel.animationBehavior = .none
    colorPanel.setTarget(nil)
    colorPanel.setAction(nil)
    colorPanel.close()
}
