import AppKit
import Carbon.HIToolbox
import XCTest
@testable import Free_Ruler

final class RulerCoreTests: XCTestCase {

    func testWindowAlphaValueConvertsPercentToAlpha() {
        XCTAssertEqual(windowAlphaValue(0), 0.0)
        XCTAssertEqual(windowAlphaValue(50), 0.5)
        XCTAssertEqual(windowAlphaValue(100), 1.0)
    }

    func testUnitTestsUseIsolatedUserDefaults() {
        XCTAssertFalse(Prefs.userDefaults === UserDefaults.standard)
    }

    func testRulerStoresOrientationFrameAndAutosaveName() {
        let frame = NSRect(x: 10, y: 20, width: 300, height: 40)
        let ruler = Ruler(.horizontal, frame: frame, name: "test-ruler")

        XCTAssertEqual(ruler.orientation, .horizontal)
        XCTAssertEqual(ruler.frame, frame)
        XCTAssertEqual(ruler.name, "test-ruler")
    }

    func testRulerInstanceCreationCopiesDefaultsWithoutControllers() {
        withRestoredRulerPreferences {
            prefs.unit = .inches
            prefs.rulerColor = NSColor(deviceRed: 0.25, green: 0.5, blue: 0.75, alpha: 0.4)
            prefs.foregroundOpacity = 82
            prefs.backgroundOpacity = 38
            prefs.floatRulers = false
            prefs.rulerShadow = true
            prefs.zeroCorner = .bottomRight
            prefs.defaultHorizontalLength = Prefs.unsetDefaultRulerLength
            prefs.defaultVerticalLength = Prefs.unsetDefaultRulerLength

            let id = UUID(uuidString: "B74A48A7-235A-43DB-8C01-A7D8F44B1976")!
            let screenFrame = NSRect(x: 0, y: 0, width: 1000, height: 800)
            let state = RulerInstanceState.createFromDefaults(
                id: id,
                screenFrame: screenFrame
            )

            XCTAssertEqual(state.id, id)
            XCTAssertEqual(state.settings.unit, .inches)
            assertColor(
                state.settings.rulerColor,
                equals: NSColor(deviceRed: 0.25, green: 0.5, blue: 0.75, alpha: 1)
            )
            XCTAssertEqual(state.settings.foregroundOpacity, 82)
            XCTAssertEqual(state.settings.backgroundOpacity, 38)
            XCTAssertFalse(state.settings.floatRulers)
            XCTAssertTrue(state.settings.rulerShadow)
            XCTAssertEqual(state.settings.zeroCorner, .bottomRight)
            XCTAssertTrue(state.isWingVisible(.horizontal))
            XCTAssertTrue(state.isWingVisible(.vertical))
            XCTAssertEqual(state.layout.horizontalLength, 500)
            XCTAssertEqual(state.layout.verticalLength, 400)
        }
    }

    func testRulerWingVisibilityPreservesAtLeastOneVisibleWing() {
        var visibility = RulerWingVisibility(horizontal: true, vertical: false)

        XCTAssertFalse(visibility.set(.horizontal, isVisible: false))
        XCTAssertTrue(visibility.showsHorizontal)
        XCTAssertFalse(visibility.showsVertical)

        XCTAssertTrue(visibility.set(.vertical, isVisible: true))
        XCTAssertTrue(visibility.set(.horizontal, isVisible: false))
        XCTAssertFalse(visibility.showsHorizontal)
        XCTAssertTrue(visibility.showsVertical)

        XCTAssertFalse(visibility.toggle(.vertical))
        XCTAssertFalse(visibility.showsHorizontal)
        XCTAssertTrue(visibility.showsVertical)

        let decodedFallback = RulerWingVisibility(horizontal: false, vertical: false)
        XCTAssertTrue(decodedFallback.showsHorizontal)
        XCTAssertTrue(decodedFallback.showsVertical)
    }

    func testRulerInstanceStateStoresHorizontalOnlyVerticalOnlyAndBothWingRulers() {
        let settings = RulerSettings(zeroCorner: .topLeft)
        let layout = RulerLayoutState(
            zeroPoint: NSPoint(x: 200, y: 300),
            horizontalLength: 320,
            verticalLength: 180
        )
        let both = RulerInstanceState(
            settings: settings,
            visibility: RulerWingVisibility(horizontal: true, vertical: true),
            layout: layout
        )
        let horizontalOnly = RulerInstanceState(
            settings: settings,
            visibility: RulerWingVisibility(horizontal: true, vertical: false),
            layout: layout
        )
        let verticalOnly = RulerInstanceState(
            settings: settings,
            visibility: RulerWingVisibility(horizontal: false, vertical: true),
            layout: layout
        )

        XCTAssertTrue(both.isWingVisible(.horizontal))
        XCTAssertTrue(both.isWingVisible(.vertical))
        XCTAssertTrue(horizontalOnly.isWingVisible(.horizontal))
        XCTAssertFalse(horizontalOnly.isWingVisible(.vertical))
        XCTAssertFalse(verticalOnly.isWingVisible(.horizontal))
        XCTAssertTrue(verticalOnly.isWingVisible(.vertical))
    }

    func testRulerInstanceStateRoundTripsThroughJSON() throws {
        let id = UUID(uuidString: "CBAB5338-CB56-42C5-9B76-F7B7B57D8013")!
        let state = RulerInstanceState(
            id: id,
            settings: RulerSettings(
                unit: .millimeters,
                rulerColor: NSColor(deviceRed: 0.1, green: 0.2, blue: 0.3, alpha: 1),
                foregroundOpacity: 70,
                backgroundOpacity: 25,
                floatRulers: false,
                rulerShadow: true,
                zeroCorner: .bottomLeft
            ),
            visibility: RulerWingVisibility(horizontal: false, vertical: true),
            layout: RulerLayoutState(
                zeroPoint: NSPoint(x: 120, y: 440),
                horizontalLength: 640,
                verticalLength: 260
            )
        )

        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(RulerInstanceState.self, from: data)

        XCTAssertEqual(decoded, state)
        assertColor(
            decoded.settings.rulerColor,
            equals: NSColor(deviceRed: 0.1, green: 0.2, blue: 0.3, alpha: 1)
        )
    }

    func testRulerManagerCreatesTracksActivatesAndClosesRulers() {
        let manager = RulerManager()
        defer {
            for controller in manager.controllers {
                controller.hide()
            }
        }

        let first = manager.createRuler(
            defaults: RulerSettings(unit: .pixels),
            screenFrame: NSRect(x: 0, y: 0, width: 1000, height: 800)
        )
        let second = manager.createRuler(
            defaults: RulerSettings(unit: .inches),
            screenFrame: NSRect(x: 0, y: 0, width: 1000, height: 800)
        )

        XCTAssertEqual(manager.controllers.count, 2)
        XCTAssertTrue(manager.activeController === second)

        manager.markActive(first)
        XCTAssertTrue(manager.activeController === first)

        XCTAssertTrue(manager.closeActiveRuler())
        XCTAssertEqual(manager.controllers.count, 1)
        XCTAssertTrue(manager.activeController === second)
        XCTAssertEqual(manager.states.map(\.settings.unit), [.inches])
    }

    func testRulerManagerDrawsActiveBorderOnlyOnActiveRuler() {
        let manager = RulerManager()
        defer {
            for controller in manager.controllers {
                controller.hide()
            }
        }

        let first = manager.createRuler(
            defaults: RulerSettings(unit: .pixels),
            screenFrame: NSRect(x: 0, y: 0, width: 1000, height: 800)
        )
        let second = manager.createRuler(
            defaults: RulerSettings(unit: .inches),
            screenFrame: NSRect(x: 0, y: 0, width: 1000, height: 800)
        )

        XCTAssertFalse(first.rulerWindow.drawsActiveBorder)
        XCTAssertTrue(second.rulerWindow.drawsActiveBorder)

        manager.markActive(first)

        XCTAssertTrue(first.rulerWindow.drawsActiveBorder)
        XCTAssertFalse(second.rulerWindow.drawsActiveBorder)

        manager.setApplicationActive(false)

        XCTAssertFalse(first.rulerWindow.drawsActiveBorder)
        XCTAssertFalse(second.rulerWindow.drawsActiveBorder)

        manager.setApplicationActive(true)

        XCTAssertTrue(first.rulerWindow.drawsActiveBorder)
        XCTAssertFalse(second.rulerWindow.drawsActiveBorder)

        XCTAssertTrue(manager.closeActiveRuler())

        XCTAssertTrue(second.rulerWindow.drawsActiveBorder)
    }

    func testRulerManagerStaggersNewRulersWhenDefaultPositionIsOccupied() {
        let manager = RulerManager()
        defer {
            for controller in manager.controllers {
                controller.hide()
            }
        }

        let screenFrame = NSRect(x: 0, y: 0, width: 1000, height: 800)
        let first = manager.createRuler(screenFrame: screenFrame)
        let second = manager.createRuler(screenFrame: screenFrame)
        let third = manager.createRuler(screenFrame: screenFrame)
        let staggerOffset = Ruler.thickness / 2

        XCTAssertEqual(second.state.layout.zeroPoint.x, first.state.layout.zeroPoint.x + staggerOffset)
        XCTAssertEqual(second.state.layout.zeroPoint.y, first.state.layout.zeroPoint.y - staggerOffset)
        XCTAssertEqual(third.state.layout.zeroPoint.x, first.state.layout.zeroPoint.x + (staggerOffset * 2))
        XCTAssertEqual(third.state.layout.zeroPoint.y, first.state.layout.zeroPoint.y - (staggerOffset * 2))
    }

    func testRulerManagerMovesVisibleRulersTogetherDuringGroupedDrag() {
        withRestoredRulerPreferences {
            withRestoredRulerSetState {
                prefs.groupRulers = true
                prefs.zeroCorner = .topLeft
                let appDelegate = AppDelegate()
                let first = appDelegate.rulerManager.createRuler(
                    screenFrame: NSRect(x: 0, y: 0, width: 1000, height: 800)
                )
                let second = appDelegate.rulerManager.createRuler(
                    screenFrame: NSRect(x: 0, y: 0, width: 1000, height: 800)
                )
                let hidden = appDelegate.rulerManager.createRuler(
                    screenFrame: NSRect(x: 0, y: 0, width: 1000, height: 800)
                )
                defer {
                    first.hide()
                    second.hide()
                    hidden.hide()
                }
                first.show()
                second.show()

                let firstFrame = first.rulerWindow.frame
                let secondFrame = second.rulerWindow.frame
                let hiddenFrame = hidden.rulerWindow.frame
                let dragOffset = NSSize(width: 37, height: -24)
                var movedFirstFrame = firstFrame
                movedFirstFrame.origin.x += dragOffset.width
                movedFirstFrame.origin.y += dragOffset.height

                appDelegate.rulerManager.beginGroupedDrag(from: first)
                XCTAssertTrue(first.rulerWindow.childWindows?.contains(second.rulerWindow) ?? false)
                XCTAssertTrue(second.rulerWindow.parent === first.rulerWindow)
                XCTAssertFalse(first.rulerWindow.childWindows?.contains(hidden.rulerWindow) ?? false)

                first.move(to: movedFirstFrame)
                appDelegate.rulerManager.syncGroupedDrag(from: first)
                appDelegate.rulerManager.finishGroupedDrag(from: first)

                XCTAssertEqual(first.rulerWindow.frame, movedFirstFrame)
                XCTAssertEqual(second.rulerWindow.frame.minX, secondFrame.minX + dragOffset.width)
                XCTAssertEqual(second.rulerWindow.frame.minY, secondFrame.minY + dragOffset.height)
                XCTAssertEqual(hidden.rulerWindow.frame, hiddenFrame)
                XCTAssertEqual(
                    second.state.layout.zeroPoint,
                    ZeroCornerGeometry(zeroCorner: second.state.settings.zeroCorner).zeroPoint(
                        in: second.rulerWindow.screenFrame(for: .horizontal),
                        for: .horizontal
                    )
                )
                XCTAssertFalse(first.rulerWindow.childWindows?.contains(second.rulerWindow) ?? false)
                XCTAssertNil(second.rulerWindow.parent)
            }
        }
    }

    func testRulerManagerMovesGroupedActiveRulerToTopOfStack() {
        withRestoredRulerPreferences {
            prefs.groupRulers = true
            let manager = RulerManager()
            let first = manager.createRuler(
                defaults: RulerSettings(unit: .pixels),
                screenFrame: NSRect(x: 0, y: 0, width: 1000, height: 800)
            )
            let second = manager.createRuler(
                defaults: RulerSettings(unit: .inches),
                screenFrame: NSRect(x: 0, y: 0, width: 1000, height: 800)
            )
            defer {
                first.hide()
                second.hide()
            }
            first.show()
            second.show()

            XCTAssertTrue(manager.controllers.last === second)

            manager.markActive(first)

            XCTAssertTrue(manager.activeController === first)
            XCTAssertTrue(manager.controllers.last === first)

            manager.beginGroupedDrag(from: first)
            XCTAssertTrue(first.rulerWindow.childWindows?.contains(second.rulerWindow) ?? false)

            manager.finishGroupedDrag(from: first)

            XCTAssertFalse(first.rulerWindow.childWindows?.contains(second.rulerWindow) ?? false)
            XCTAssertNil(second.rulerWindow.parent)
            XCTAssertTrue(manager.controllers.last === first)
        }
    }

    func testRulerManagerCyclesVisibleRulers() {
        let manager = RulerManager()
        let first = manager.createRuler()
        let second = manager.createRuler()
        let hidden = manager.createRuler()
        defer {
            first.hide()
            second.hide()
            hidden.hide()
        }
        first.show()
        second.show()
        manager.markActive(first)

        XCTAssertTrue(manager.cycleActiveRuler() === second)
        XCTAssertTrue(manager.activeController === second)

        XCTAssertTrue(manager.cycleActiveRuler() === first)
        XCTAssertTrue(manager.activeController === first)
    }

    func testRulerContextMenuActivatesClickedRulerAndShowsSettingsCommand() {
        withInstalledAppDelegate { appDelegate in
            let manager = appDelegate.rulerManager
            defer {
                appDelegate.rulerSettingsController?.close()
                for controller in manager.controllers {
                    controller.hide()
                }
            }

            let first = manager.createRuler(
                defaults: RulerSettings(unit: .pixels),
                screenFrame: NSRect(x: 0, y: 0, width: 1000, height: 800)
            )
            let second = manager.createRuler(
                defaults: RulerSettings(unit: .inches),
                screenFrame: NSRect(x: 0, y: 0, width: 1000, height: 800)
            )
            manager.markActive(second)

            let menu = first.rulerWindow.horizontalRule.menu(for: mouseEvent(
                type: .rightMouseDown,
                location: .zero,
                windowNumber: first.rulerWindow.windowNumber,
                timestamp: 0
            ))

            XCTAssertTrue(manager.activeController === first)
            XCTAssertEqual(menu?.items.count, 1)

            let item = menu?.items.first
            XCTAssertEqual(item?.identifier, rulerSettingsContextMenuItemIdentifier)
            XCTAssertEqual(item?.title, rulerSettingsContextMenuTitle())
            XCTAssertEqual(item?.action, #selector(AppDelegate.openRulerSettings(_:)))
            XCTAssertEqual(item?.keyEquivalent, "")
            XCTAssertTrue(item?.target === appDelegate)
        }
    }

    func testRulerManagerRestoresStatesAndShowsAllControllers() {
        let firstID = UUID(uuidString: "F775A858-ED72-4242-B84B-E08B27EE1C9F")!
        let secondID = UUID(uuidString: "D922071D-D02B-4DF7-8762-3497D9FD90B4")!
        let manager = RulerManager(initialStates: [
            RulerInstanceState(
                id: firstID,
                settings: RulerSettings(unit: .pixels),
                visibility: RulerWingVisibility(horizontal: true, vertical: false),
                layout: RulerLayoutState(
                    zeroPoint: NSPoint(x: 200, y: 300),
                    horizontalLength: 320,
                    verticalLength: 180
                )
            ),
            RulerInstanceState(
                id: secondID,
                settings: RulerSettings(unit: .millimeters),
                visibility: RulerWingVisibility(horizontal: false, vertical: true),
                layout: RulerLayoutState(
                    zeroPoint: NSPoint(x: 400, y: 500),
                    horizontalLength: 220,
                    verticalLength: 280
                )
            ),
        ])
        defer {
            for controller in manager.controllers {
                controller.hide()
            }
        }

        XCTAssertEqual(manager.controllers.map(\.state.id), [firstID, secondID])
        XCTAssertTrue(manager.activeController === manager.controllers.last)

        manager.showAll()

        XCTAssertTrue(manager.hasVisibleRulers)
        XCTAssertTrue(manager.controllers[0].rulerWindow.isRuleVisible(.horizontal))
        XCTAssertFalse(manager.controllers[0].rulerWindow.isRuleVisible(.vertical))
        XCTAssertFalse(manager.controllers[1].rulerWindow.isRuleVisible(.horizontal))
        XCTAssertTrue(manager.controllers[1].rulerWindow.isRuleVisible(.vertical))
    }

    func testRulerControllerAppliesPerRulerSettingsToWindowAndRules() {
        let color = NSColor(deviceRed: 0.1, green: 0.4, blue: 0.8, alpha: 1)
        let settings = RulerSettings(
            unit: .inches,
            rulerColor: color,
            foregroundOpacity: 73,
            backgroundOpacity: 31,
            floatRulers: false,
            rulerShadow: true,
            zeroCorner: .bottomRight
        )
        let controller = RulerController(
            state: RulerInstanceState(
                settings: settings,
                layout: RulerLayoutState(
                    zeroPoint: NSPoint(x: 200, y: 300),
                    horizontalLength: 260,
                    verticalLength: 180
                )
            )
        )
        defer {
            controller.hide()
        }

        XCTAssertEqual(controller.rulerWindow.horizontalRule.unit, .inches)
        XCTAssertEqual(controller.rulerWindow.verticalRule.unit, .inches)
        XCTAssertEqual(controller.rulerWindow.horizontalRule.zeroCorner, .bottomRight)
        XCTAssertEqual(controller.rulerWindow.verticalRule.zeroCorner, .bottomRight)
        assertColor(controller.rulerWindow.horizontalRule.color.fill, equals: color)
        assertColor(controller.rulerWindow.verticalRule.color.fill, equals: color)
        XCTAssertEqual(controller.rulerWindow.alphaValue, 0.73, accuracy: 0.0001)
        XCTAssertFalse(controller.rulerWindow.isFloatingPanel)
        XCTAssertTrue(controller.rulerWindow.hasShadow)

        controller.background()

        XCTAssertEqual(controller.rulerWindow.alphaValue, 0.31, accuracy: 0.0001)
    }

    func testRulerControllerIgnoresDefaultPreferenceChanges() {
        withRestoredRulerPreferences {
            let color = NSColor(deviceRed: 0.2, green: 0.3, blue: 0.7, alpha: 1)
            let controller = RulerController(
                state: RulerInstanceState(
                    settings: RulerSettings(
                        unit: .inches,
                        rulerColor: color,
                        foregroundOpacity: 64,
                        backgroundOpacity: 28,
                        floatRulers: false,
                        rulerShadow: false,
                        zeroCorner: .bottomLeft
                    ),
                    layout: RulerLayoutState(
                        zeroPoint: NSPoint(x: 240, y: 320),
                        horizontalLength: 260,
                        verticalLength: 180
                    )
                )
            )
            defer {
                controller.hide()
            }

            prefs.unit = .millimeters
            prefs.rulerColor = NSColor(deviceRed: 0.9, green: 0.1, blue: 0.2, alpha: 1)
            prefs.foregroundOpacity = 12
            prefs.backgroundOpacity = 9
            prefs.floatRulers = true
            prefs.rulerShadow = true
            prefs.zeroCorner = .topRight

            XCTAssertEqual(controller.state.settings.unit, .inches)
            XCTAssertEqual(controller.rulerWindow.horizontalRule.unit, .inches)
            XCTAssertEqual(controller.rulerWindow.horizontalRule.zeroCorner, .bottomLeft)
            assertColor(controller.rulerWindow.horizontalRule.color.fill, equals: color)
            XCTAssertEqual(controller.rulerWindow.alphaValue, 0.64, accuracy: 0.0001)
            XCTAssertFalse(controller.rulerWindow.isFloatingPanel)
            XCTAssertFalse(controller.rulerWindow.hasShadow)
        }
    }

    func testRulerSettingsControllerUpdatesRulerSettingsWithoutChangingDefaults() {
        withRestoredRulerPreferences {
            let defaultColor = NSColor(deviceRed: 0.15, green: 0.25, blue: 0.35, alpha: 1)
            prefs.unit = .pixels
            prefs.rulerColor = defaultColor
            prefs.foregroundOpacity = 90
            prefs.backgroundOpacity = 50
            prefs.floatRulers = true
            prefs.rulerShadow = false
            prefs.defaultHorizontalLength = 640
            prefs.defaultVerticalLength = 280

            let controller = RulerController(
                state: RulerInstanceState(
                    settings: RulerSettings(
                        unit: .inches,
                        rulerColor: NSColor(deviceRed: 0.4, green: 0.5, blue: 0.6, alpha: 1),
                        foregroundOpacity: 80,
                        backgroundOpacity: 45,
                        floatRulers: false,
                        rulerShadow: false
                    ),
                    layout: RulerLayoutState(
                        zeroPoint: NSPoint(x: 240, y: 320),
                        horizontalLength: 260,
                        verticalLength: 180
                    )
                )
            )
            let settingsController = RulerSettingsController(rulerController: controller)
            defer {
                settingsController.close()
                controller.hide()
            }

            settingsController.unitSegmentedControl.selectedSegment = Unit.millimeters.rawValue
            settingsController.setUnit(settingsController.unitSegmentedControl)

            XCTAssertEqual(controller.state.settings.unit, .millimeters)
            XCTAssertEqual(controller.rulerWindow.horizontalRule.unit, .millimeters)
            XCTAssertEqual(controller.rulerWindow.verticalRule.unit, .millimeters)
            XCTAssertEqual(settingsController.unitSegmentedControl.selectedSegment, Unit.millimeters.rawValue)
            XCTAssertEqual(prefs.unit, .pixels)

            let enteredWidthMillimeters: CGFloat = 100
            let enteredHeightMillimeters: CGFloat = 80
            let zeroPointBeforeDimensionChange = controller.rulerWindow.zeroPoint()
            settingsController.dimensionWidthField.stringValue = "\(enteredWidthMillimeters)"
            settingsController.dimensionHeightField.stringValue = "\(enteredHeightMillimeters)"
            let expectedHorizontalLength = settingsController.settingsControlsView.selectedHorizontalLength
            let expectedVerticalLength = settingsController.settingsControlsView.selectedVerticalLength
            settingsController.setDimensions(settingsController.dimensionWidthField)

            XCTAssertEqual(controller.state.layout.horizontalLength, expectedHorizontalLength, accuracy: 0.0001)
            XCTAssertEqual(controller.state.layout.verticalLength, expectedVerticalLength, accuracy: 0.0001)
            XCTAssertEqual(controller.rulerWindow.screenFrame(for: .horizontal).width, expectedHorizontalLength, accuracy: 0.0001)
            XCTAssertEqual(controller.rulerWindow.screenFrame(for: .vertical).height, expectedVerticalLength, accuracy: 0.0001)
            XCTAssertEqual(controller.rulerWindow.zeroPoint().x, zeroPointBeforeDimensionChange.x, accuracy: 0.0001)
            XCTAssertEqual(controller.rulerWindow.zeroPoint().y, zeroPointBeforeDimensionChange.y, accuracy: 0.0001)
            XCTAssertEqual(settingsController.dimensionWidthField.doubleValue, Double(enteredWidthMillimeters), accuracy: 0.15)
            XCTAssertEqual(settingsController.dimensionHeightField.doubleValue, Double(enteredHeightMillimeters), accuracy: 0.15)
            XCTAssertEqual(prefs.defaultHorizontalLength, 640)
            XCTAssertEqual(prefs.defaultVerticalLength, 280)

            settingsController.rulerColorWell.color = NSColor(
                deviceRed: 0.8,
                green: 0.2,
                blue: 0.4,
                alpha: 0.35
            )
            settingsController.setRulerColor(settingsController.rulerColorWell)

            let normalizedColor = NSColor(deviceRed: 0.8, green: 0.2, blue: 0.4, alpha: 1)
            assertColor(controller.state.settings.rulerColor, equals: normalizedColor)
            assertColor(controller.rulerWindow.horizontalRule.color.fill, equals: normalizedColor)
            assertColor(controller.rulerWindow.verticalRule.color.fill, equals: normalizedColor)
            assertColor(settingsController.rulerColorWell.color, equals: normalizedColor)
            assertColor(prefs.rulerColor, equals: defaultColor)
            XCTAssertFalse(settingsController.resetRulerColorButton.isHidden)

            settingsController.foregroundOpacitySlider.integerValue = 65
            settingsController.setForegroundOpacity(settingsController.foregroundOpacitySlider)

            XCTAssertEqual(controller.state.settings.foregroundOpacity, 65)
            XCTAssertEqual(controller.rulerWindow.alphaValue, 0.65, accuracy: 0.0001)
            XCTAssertEqual(settingsController.foregroundOpacityLabel.stringValue, "65%")
            XCTAssertEqual(prefs.foregroundOpacity, 90)

            settingsController.backgroundOpacitySlider.integerValue = 35
            settingsController.setBackgroundOpacity(settingsController.backgroundOpacitySlider)

            XCTAssertEqual(controller.state.settings.backgroundOpacity, 35)
            XCTAssertEqual(controller.rulerWindow.alphaValue, 0.35, accuracy: 0.0001)
            XCTAssertEqual(settingsController.backgroundOpacityLabel.stringValue, "35%")
            XCTAssertEqual(prefs.backgroundOpacity, 50)

            settingsController.floatRulersCheckbox.state = .on
            settingsController.setFloatRulers(settingsController.floatRulersCheckbox)

            XCTAssertTrue(controller.state.settings.floatRulers)
            XCTAssertTrue(controller.rulerWindow.isFloatingPanel)
            XCTAssertTrue(settingsController.floatRulersCheckbox.state == .on)
            XCTAssertTrue(prefs.floatRulers)

            settingsController.rulerShadowCheckbox.state = .on
            settingsController.setRulerShadow(settingsController.rulerShadowCheckbox)

            XCTAssertTrue(controller.state.settings.rulerShadow)
            XCTAssertTrue(controller.rulerWindow.hasShadow)
            XCTAssertTrue(settingsController.rulerShadowCheckbox.state == .on)
            XCTAssertFalse(prefs.rulerShadow)

            settingsController.resetRulerColor(settingsController.resetRulerColorButton)

            assertColor(controller.state.settings.rulerColor, equals: Prefs.defaultRulerFillColor)
            assertColor(controller.rulerWindow.horizontalRule.color.fill, equals: Prefs.defaultRulerFillColor)
            assertColor(prefs.rulerColor, equals: defaultColor)
            XCTAssertTrue(settingsController.resetRulerColorButton.isHidden)
        }
    }

    func testRulerSettingsControllerSetsDefaultsForNewRulers() {
        withRestoredRulerPreferences {
            prefs.unit = .pixels
            prefs.rulerColor = NSColor(deviceRed: 0.1, green: 0.2, blue: 0.3, alpha: 1)
            prefs.foregroundOpacity = 90
            prefs.backgroundOpacity = 50
            prefs.floatRulers = true
            prefs.rulerShadow = false
            prefs.zeroCorner = .topLeft
            prefs.defaultHorizontalLength = 500
            prefs.defaultVerticalLength = 400

            let rulerColor = NSColor(deviceRed: 0.72, green: 0.24, blue: 0.44, alpha: 1)
            let controller = RulerController(
                state: RulerInstanceState(
                    settings: RulerSettings(
                        unit: .inches,
                        rulerColor: rulerColor,
                        foregroundOpacity: 63,
                        backgroundOpacity: 37,
                        floatRulers: false,
                        rulerShadow: true,
                        zeroCorner: .bottomRight
                    ),
                    layout: RulerLayoutState(
                        zeroPoint: NSPoint(x: 240, y: 320),
                        horizontalLength: 260,
                        verticalLength: 180
                    )
                )
            )
            let settingsController = RulerSettingsController(rulerController: controller)
            defer {
                settingsController.close()
                controller.hide()
            }

            settingsController.setDefaultsForNewRulers(settingsController.setDefaultsButton as Any)

            XCTAssertEqual(prefs.unit, .inches)
            assertColor(prefs.rulerColor, equals: rulerColor)
            XCTAssertEqual(prefs.foregroundOpacity, 63)
            XCTAssertEqual(prefs.backgroundOpacity, 37)
            XCTAssertFalse(prefs.floatRulers)
            XCTAssertTrue(prefs.rulerShadow)
            XCTAssertEqual(prefs.zeroCorner, .bottomRight)
            XCTAssertEqual(prefs.defaultHorizontalLength, 260)
            XCTAssertEqual(prefs.defaultVerticalLength, 180)
        }
    }

    func testRulerSettingsControllerResetsRulerToDefaults() {
        withRestoredRulerPreferences {
            let defaultColor = NSColor(deviceRed: 0.15, green: 0.25, blue: 0.35, alpha: 1)
            prefs.unit = .millimeters
            prefs.rulerColor = defaultColor
            prefs.foregroundOpacity = 88
            prefs.backgroundOpacity = 44
            prefs.floatRulers = true
            prefs.rulerShadow = false
            prefs.zeroCorner = .topRight
            prefs.defaultHorizontalLength = 320
            prefs.defaultVerticalLength = 220

            let controller = RulerController(
                state: RulerInstanceState(
                    settings: RulerSettings(
                        unit: .inches,
                        rulerColor: NSColor(deviceRed: 0.8, green: 0.2, blue: 0.4, alpha: 1),
                        foregroundOpacity: 63,
                        backgroundOpacity: 37,
                        floatRulers: false,
                        rulerShadow: true,
                        zeroCorner: .bottomLeft
                    ),
                    layout: RulerLayoutState(
                        zeroPoint: NSPoint(x: 240, y: 320),
                        horizontalLength: 260,
                        verticalLength: 180
                    )
                )
            )
            let settingsController = RulerSettingsController(rulerController: controller)
            defer {
                settingsController.close()
                controller.hide()
            }

            settingsController.resetToDefault(settingsController.resetDefaultsButton as Any)

            XCTAssertEqual(controller.state.settings.unit, .millimeters)
            assertColor(controller.state.settings.rulerColor, equals: defaultColor)
            XCTAssertEqual(controller.state.settings.foregroundOpacity, 88)
            XCTAssertEqual(controller.state.settings.backgroundOpacity, 44)
            XCTAssertTrue(controller.state.settings.floatRulers)
            XCTAssertFalse(controller.state.settings.rulerShadow)
            XCTAssertEqual(controller.state.settings.zeroCorner, .topRight)
            XCTAssertEqual(controller.state.layout.horizontalLength, 320)
            XCTAssertEqual(controller.state.layout.verticalLength, 220)
            XCTAssertEqual(settingsController.settingsControlsView.selectedHorizontalLength, 320, accuracy: 0.1)
            XCTAssertEqual(settingsController.settingsControlsView.selectedVerticalLength, 220, accuracy: 0.1)
            XCTAssertEqual(settingsController.foregroundOpacityLabel.stringValue, "88%")
            XCTAssertEqual(settingsController.backgroundOpacityLabel.stringValue, "44%")
            XCTAssertEqual(controller.opacity, 88)
            XCTAssertEqual(controller.rulerWindow.alphaValue, windowAlphaValue(88), accuracy: 0.0001)
            XCTAssertEqual(prefs.foregroundOpacity, 88)
        }
    }

    func testRulerSettingsControllerAppliesColorPanelChangesToActiveRuler() {
        let controller = RulerController(
            state: RulerInstanceState(
                settings: RulerSettings(
                    rulerColor: NSColor(deviceRed: 0.2, green: 0.3, blue: 0.4, alpha: 1)
                ),
                layout: RulerLayoutState(
                    zeroPoint: NSPoint(x: 240, y: 320),
                    horizontalLength: 260,
                    verticalLength: 180
                )
            )
        )
        let settingsController = RulerSettingsController(rulerController: controller)
        defer {
            settingsController.close()
            controller.hide()
            closeRulerColorPanel()
        }

        let selectedColor = NSColor(deviceRed: 0.7, green: 0.1, blue: 0.5, alpha: 0.35)
        NSColorPanel.shared.color = selectedColor
        settingsController.rulerColorWell.takeColorFrom(NSColorPanel.shared)

        let normalizedColor = NSColor(deviceRed: 0.7, green: 0.1, blue: 0.5, alpha: 1)
        assertColor(controller.state.settings.rulerColor, equals: normalizedColor)
        assertColor(controller.rulerWindow.horizontalRule.color.fill, equals: normalizedColor)
        assertColor(settingsController.rulerColorWell.color, equals: normalizedColor)
    }

    func testRulerSettingsControllerCheckboxKeyEquivalentsToggleFloatAndShadow() {
        let controller = RulerController(
            state: RulerInstanceState(
                settings: RulerSettings(floatRulers: false, rulerShadow: false),
                layout: RulerLayoutState(
                    zeroPoint: NSPoint(x: 240, y: 320),
                    horizontalLength: 260,
                    verticalLength: 180
                )
            )
        )
        let settingsController = RulerSettingsController(rulerController: controller)
        defer {
            settingsController.close()
            controller.hide()
        }

        let floatEvent = keyDownEvent(characters: "f", keyCode: 3)
        let shadowEvent = keyDownEvent(characters: "s", keyCode: 1)
        guard let settingsWindow = settingsController.window else {
            XCTFail("Expected settings window")
            return
        }

        XCTAssertTrue(settingsWindow.performKeyEquivalent(with: floatEvent))
        XCTAssertTrue(controller.state.settings.floatRulers)
        XCTAssertTrue(settingsController.floatRulersCheckbox.state == .on)

        XCTAssertTrue(settingsWindow.performKeyEquivalent(with: shadowEvent))
        XCTAssertTrue(controller.state.settings.rulerShadow)
        XCTAssertTrue(settingsController.rulerShadowCheckbox.state == .on)
    }

    func testPreferencesControllerResetsDefaultsToFactoryDefaults() {
        withRestoredRulerPreferences {
            prefs.unit = .inches
            prefs.rulerColor = NSColor(deviceRed: 0.7, green: 0.3, blue: 0.2, alpha: 1)
            prefs.foregroundOpacity = 42
            prefs.backgroundOpacity = 21
            prefs.floatRulers = false
            prefs.groupRulers = true
            prefs.rulerShadow = true
            prefs.zeroCorner = .bottomRight
            prefs.defaultHorizontalLength = 333
            prefs.defaultVerticalLength = 222

            let preferencesController = PreferencesController()
            preferencesController.loadWindow()
            defer {
                preferencesController.close()
            }

            preferencesController.resetToFactoryDefaults(self)

            XCTAssertEqual(prefs.unit, Prefs.defaultUnit)
            assertColor(prefs.rulerColor, equals: Prefs.defaultRulerFillColor)
            XCTAssertEqual(prefs.foregroundOpacity, Prefs.defaultForegroundOpacity)
            XCTAssertEqual(prefs.backgroundOpacity, Prefs.defaultBackgroundOpacity)
            XCTAssertEqual(prefs.floatRulers, Prefs.defaultFloatRulers)
            XCTAssertEqual(prefs.groupRulers, Prefs.defaultGroupRulers)
            XCTAssertEqual(prefs.rulerShadow, Prefs.defaultRulerShadow)
            XCTAssertEqual(prefs.zeroCorner, Prefs.defaultZeroCorner)
            XCTAssertEqual(prefs.defaultHorizontalLength, Prefs.unsetDefaultRulerLength)
            XCTAssertEqual(prefs.defaultVerticalLength, Prefs.unsetDefaultRulerLength)
            XCTAssertEqual(preferencesController.foregroundOpacityLabel.stringValue, "\(Prefs.defaultForegroundOpacity)%")
            XCTAssertEqual(preferencesController.backgroundOpacityLabel.stringValue, "\(Prefs.defaultBackgroundOpacity)%")
            XCTAssertEqual(
                preferencesController.dimensionWidthField.integerValue,
                Int(RulerLayoutState.defaultLengths().horizontal.rounded())
            )
            XCTAssertEqual(
                preferencesController.dimensionHeightField.integerValue,
                Int(RulerLayoutState.defaultLengths().vertical.rounded())
            )
            XCTAssertEqual(preferencesController.floatRulersCheckbox.state, .on)
            XCTAssertEqual(preferencesController.rulerShadowCheckbox.state, .off)
        }
    }

    func testPreferencesControllerUpdatesDefaultUnitAndDimensions() {
        withRestoredRulerPreferences {
            prefs.unit = .pixels
            prefs.defaultHorizontalLength = 500
            prefs.defaultVerticalLength = 400

            let preferencesController = PreferencesController()
            preferencesController.loadWindow()
            defer {
                preferencesController.close()
            }

            preferencesController.unitSegmentedControl.selectedSegment = Unit.inches.rawValue
            preferencesController.setUnit(preferencesController.unitSegmentedControl)
            preferencesController.dimensionWidthField.stringValue = "6"
            preferencesController.dimensionHeightField.stringValue = "4"
            let expectedHorizontalLength = preferencesController.settingsControlsView.selectedHorizontalLength
            let expectedVerticalLength = preferencesController.settingsControlsView.selectedVerticalLength
            preferencesController.setDimensions(preferencesController.dimensionWidthField)

            XCTAssertEqual(prefs.unit, .inches)
            XCTAssertEqual(prefs.defaultHorizontalLength, Double(expectedHorizontalLength), accuracy: 0.0001)
            XCTAssertEqual(prefs.defaultVerticalLength, Double(expectedVerticalLength), accuracy: 0.0001)
        }
    }

    func testRulerSettingsControlsConvertDimensionsForSelectedUnit() {
        let controlsView = RulerSettingsControlsView(frame: NSRect(x: 0, y: 0, width: 315, height: 320))
        controlsView.configureForRulerSettings()

        controlsView.update(
            unit: .millimeters,
            horizontalLength: 100 * NSScreen.defaultDpmm,
            verticalLength: 80 * NSScreen.defaultDpmm,
            dimensionScreen: nil,
            rulerColor: Prefs.defaultRulerFillColor,
            foregroundOpacity: 90,
            backgroundOpacity: 50,
            floatRulers: true,
            rulerShadow: false
        )

        XCTAssertEqual(controlsView.dimensionWidthField.doubleValue, 100, accuracy: 0.0001)
        XCTAssertEqual(controlsView.dimensionHeightField.doubleValue, 80, accuracy: 0.0001)

        controlsView.dimensionWidthField.stringValue = "25.5"
        controlsView.dimensionHeightField.stringValue = "12.5"

        XCTAssertEqual(
            controlsView.selectedHorizontalLength,
            (25.5 * NSScreen.defaultDpmm).rounded(),
            accuracy: 0.0001
        )
        XCTAssertEqual(
            controlsView.selectedVerticalLength,
            (12.5 * NSScreen.defaultDpmm).rounded(),
            accuracy: 0.0001
        )

        controlsView.update(
            unit: .inches,
            horizontalLength: 6 * NSScreen.defaultDpi,
            verticalLength: 4.25 * NSScreen.defaultDpi,
            dimensionScreen: nil,
            rulerColor: Prefs.defaultRulerFillColor,
            foregroundOpacity: 90,
            backgroundOpacity: 50,
            floatRulers: true,
            rulerShadow: false
        )

        XCTAssertEqual(controlsView.dimensionWidthField.doubleValue, 6, accuracy: 0.0001)
        XCTAssertEqual(controlsView.dimensionHeightField.doubleValue, 4.25, accuracy: 0.0001)

        controlsView.dimensionWidthField.stringValue = "3.5"
        controlsView.dimensionHeightField.stringValue = "2.75"

        XCTAssertEqual(controlsView.selectedHorizontalLength, 3.5 * NSScreen.defaultDpi, accuracy: 0.0001)
        XCTAssertEqual(controlsView.selectedVerticalLength, 2.75 * NSScreen.defaultDpi, accuracy: 0.0001)
    }

    func testRulerSettingsControlsLayoutUsesSharedInsetsAndAlignedRows() {
        let controlsView = RulerSettingsControlsView(frame: NSRect(x: 0, y: 0, width: 315, height: 320))
        controlsView.configureForRulerSettings()

        controlsView.update(
            unit: .pixels,
            horizontalLength: 260,
            verticalLength: 180,
            rulerColor: Prefs.defaultRulerFillColor,
            foregroundOpacity: 90,
            backgroundOpacity: 50,
            floatRulers: true,
            rulerShadow: false
        )
        controlsView.layoutSubtreeIfNeeded()
        controlsView.contentView.layoutSubtreeIfNeeded()

        let leftAlignedControls: [NSView] = [
            controlsView.unitLabel,
            controlsView.dimensionsLabel,
            controlsView.rulerColorLabel,
            controlsView.foregroundOpacityTitleLabel,
            controlsView.foregroundOpacitySlider,
            controlsView.backgroundOpacityTitleLabel,
            controlsView.backgroundOpacitySlider,
            controlsView.floatRulersCheckbox,
            controlsView.rulerShadowCheckbox,
        ]
        let rightAlignedControls: [NSView] = [
            controlsView.unitSegmentedControl,
            controlsView.dimensionHeightField,
            controlsView.rulerColorWell,
            controlsView.foregroundOpacityLabel,
            controlsView.foregroundOpacitySlider,
            controlsView.backgroundOpacityLabel,
            controlsView.backgroundOpacitySlider,
        ]
        func alignmentRect(_ view: NSView) -> NSRect {
            return view.alignmentRect(forFrame: view.frame)
        }
        func firstBaselineY(_ view: NSView) -> CGFloat {
            return view.frame.maxY - view.firstBaselineOffsetFromTop
        }

        let expectedInset: CGFloat = 15
        let baselineAccuracy: CGFloat = 1
        let expectedLeftInset = controlsView.contentView.bounds.minX + expectedInset
        let expectedRightEdge = controlsView.contentView.bounds.maxX - expectedInset
        let unitTopInset = controlsView.contentView.bounds.maxY
            - alignmentRect(controlsView.unitSegmentedControl).maxY
        let unitToDimensionsSpacing = alignmentRect(controlsView.unitSegmentedControl).minY
            - alignmentRect(controlsView.dimensionHeightField).maxY

        XCTAssertEqual(unitTopInset, expectedInset, accuracy: 0.5)
        for control in leftAlignedControls {
            XCTAssertEqual(alignmentRect(control).minX, expectedLeftInset, accuracy: 0.5)
        }
        for control in rightAlignedControls {
            XCTAssertEqual(alignmentRect(control).maxX, expectedRightEdge, accuracy: 0.5)
        }
        XCTAssertEqual(unitToDimensionsSpacing, expectedInset, accuracy: 0.5)
        XCTAssertEqual(firstBaselineY(controlsView.unitLabel), firstBaselineY(controlsView.unitSegmentedControl), accuracy: baselineAccuracy)
        XCTAssertEqual(firstBaselineY(controlsView.dimensionsLabel), firstBaselineY(controlsView.dimensionWidthField), accuracy: baselineAccuracy)
        XCTAssertEqual(firstBaselineY(controlsView.dimensionWidthField), firstBaselineY(controlsView.dimensionsSeparatorLabel), accuracy: baselineAccuracy)
        XCTAssertEqual(firstBaselineY(controlsView.dimensionsSeparatorLabel), firstBaselineY(controlsView.dimensionHeightField), accuracy: baselineAccuracy)
        XCTAssertEqual(alignmentRect(controlsView.rulerColorLabel).midY, alignmentRect(controlsView.rulerColorWell).midY, accuracy: 0.5)
        XCTAssertEqual(firstBaselineY(controlsView.foregroundOpacityTitleLabel), firstBaselineY(controlsView.foregroundOpacityLabel), accuracy: baselineAccuracy)
        XCTAssertEqual(firstBaselineY(controlsView.backgroundOpacityTitleLabel), firstBaselineY(controlsView.backgroundOpacityLabel), accuracy: baselineAccuracy)
    }

    func testRulerSettingsControlsKeyViewLoopFollowsVisibleControls() {
        let controlsView = RulerSettingsControlsView(frame: NSRect(x: 0, y: 0, width: 315, height: 320))
        controlsView.configureForRulerSettings()

        controlsView.update(
            unit: .pixels,
            horizontalLength: 260,
            verticalLength: 180,
            rulerColor: Prefs.defaultRulerFillColor,
            foregroundOpacity: 90,
            backgroundOpacity: 50,
            floatRulers: true,
            rulerShadow: false
        )

        XCTAssertTrue(controlsView.unitSegmentedControl.nextKeyView === controlsView.dimensionWidthField)
        XCTAssertTrue(controlsView.dimensionWidthField.nextKeyView === controlsView.dimensionHeightField)
        XCTAssertTrue(controlsView.dimensionHeightField.nextKeyView === controlsView.rulerColorWell)
        XCTAssertTrue(controlsView.rulerColorWell.nextKeyView === controlsView.foregroundOpacitySlider)
        XCTAssertTrue(controlsView.foregroundOpacitySlider.nextKeyView === controlsView.backgroundOpacitySlider)
        XCTAssertTrue(controlsView.backgroundOpacitySlider.nextKeyView === controlsView.floatRulersCheckbox)
        XCTAssertTrue(controlsView.floatRulersCheckbox.nextKeyView === controlsView.rulerShadowCheckbox)
        XCTAssertTrue(controlsView.rulerShadowCheckbox.nextKeyView === controlsView.unitSegmentedControl)

        controlsView.update(
            unit: .pixels,
            horizontalLength: 260,
            verticalLength: 180,
            rulerColor: NSColor(deviceRed: 0.6, green: 0.3, blue: 0.2, alpha: 1),
            foregroundOpacity: 90,
            backgroundOpacity: 50,
            floatRulers: true,
            rulerShadow: false
        )

        XCTAssertTrue(controlsView.rulerColorWell.nextKeyView === controlsView.resetRulerColorButton)
        XCTAssertTrue(controlsView.resetRulerColorButton.nextKeyView === controlsView.foregroundOpacitySlider)
    }

    func testRulerSettingsControllerPresentsAsAttachedSheetOnRulerWindow() {
        let controller = RulerController(
            state: RulerInstanceState(
                settings: RulerSettings(),
                layout: RulerLayoutState(
                    zeroPoint: NSPoint(x: 240, y: 320),
                    horizontalLength: 260,
                    verticalLength: 180
                )
            )
        )
        let settingsController = RulerSettingsController(rulerController: controller)
        defer {
            settingsController.close()
            controller.hide()
        }

        controller.show()
        settingsController.show(attachedTo: controller, sender: self)

        guard let settingsWindow = settingsController.window else {
            XCTFail("Expected settings window")
            return
        }
        XCTAssertTrue(controller.rulerWindow.childWindows?.contains(settingsWindow) ?? false)
        XCTAssertNil(settingsWindow.sheetParent)
    }

    func testRulerSettingsControllerSuspendsOnlyAttachedRulerWhileVisible() {
        let first = RulerController(
            state: RulerInstanceState(
                settings: RulerSettings(floatRulers: true),
                layout: RulerLayoutState(
                    zeroPoint: NSPoint(x: 240, y: 320),
                    horizontalLength: 260,
                    verticalLength: 180
                )
            )
        )
        let second = RulerController(
            state: RulerInstanceState(
                settings: RulerSettings(floatRulers: true),
                layout: RulerLayoutState(
                    zeroPoint: NSPoint(x: 540, y: 320),
                    horizontalLength: 260,
                    verticalLength: 180
                )
            )
        )
        let settingsController = RulerSettingsController(rulerController: first)
        defer {
            settingsController.close()
            first.hide()
            second.hide()
        }

        first.show()
        second.show()

        settingsController.show(attachedTo: first, sender: self)

        XCTAssertTrue(first.isRulerInteractionSuspended)
        XCTAssertFalse(second.isRulerInteractionSuspended)
        XCTAssertFalse(first.rulerWindow.isFloatingPanel)
        XCTAssertTrue(second.rulerWindow.isFloatingPanel)

        settingsController.show(attachedTo: second, sender: self)

        XCTAssertFalse(first.isRulerInteractionSuspended)
        XCTAssertTrue(second.isRulerInteractionSuspended)
        XCTAssertTrue(first.rulerWindow.isFloatingPanel)
        XCTAssertFalse(second.rulerWindow.isFloatingPanel)

        settingsController.close()

        XCTAssertFalse(first.isRulerInteractionSuspended)
        XCTAssertFalse(second.isRulerInteractionSuspended)
        XCTAssertTrue(first.rulerWindow.isFloatingPanel)
        XCTAssertTrue(second.rulerWindow.isFloatingPanel)
    }

    func testRulerControllerPassesArrowKeysThroughWhileInteractionSuspended() {
        let controller = RulerController(
            state: RulerInstanceState(
                settings: RulerSettings(),
                layout: RulerLayoutState(
                    zeroPoint: NSPoint(x: 240, y: 320),
                    horizontalLength: 260,
                    verticalLength: 180
                )
            )
        )
        let owner = NSObject()
        defer {
            controller.resumeRulerInteraction(owner: owner)
            controller.hide()
        }

        let event = keyDownEvent(characters: "", keyCode: UInt16(kVK_RightArrow))
        let initialFrame = controller.rulerWindow.frame

        controller.suspendRulerInteraction(owner: owner)

        XCTAssertTrue(controller.isRulerInteractionSuspended)
        XCTAssertTrue(controller.onKeyDown(with: event) === event)
        XCTAssertEqual(controller.rulerWindow.frame, initialFrame)
    }

    func testRulerSettingsControllerAnchorsPanelCornerToRulerZeroPoint() {
        let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 900)
        let zeroPoint = NSPoint(x: visibleFrame.midX, y: visibleFrame.midY)

        for zeroCorner in [ZeroCorner.topLeft, .topRight, .bottomLeft, .bottomRight] {
            let controller = RulerController(
                state: RulerInstanceState(
                    settings: RulerSettings(zeroCorner: zeroCorner),
                    layout: RulerLayoutState(
                        zeroPoint: zeroPoint,
                        horizontalLength: 260,
                        verticalLength: 180
                    )
                )
            )
            let settingsController = RulerSettingsController(rulerController: controller)
            defer {
                settingsController.close()
                controller.hide()
            }

            controller.show()
            settingsController.show(attachedTo: controller, sender: self)

            guard let settingsWindow = settingsController.window else {
                XCTFail("Expected settings window")
                return
            }

            let rulerZeroPoint = controller.rulerWindow.zeroPoint()
            switch zeroCorner {
            case .topLeft:
                XCTAssertEqual(settingsWindow.frame.minX, rulerZeroPoint.x, accuracy: 1)
                XCTAssertEqual(settingsWindow.frame.maxY, rulerZeroPoint.y, accuracy: 1)
            case .topRight:
                XCTAssertEqual(settingsWindow.frame.maxX, rulerZeroPoint.x, accuracy: 1)
                XCTAssertEqual(settingsWindow.frame.maxY, rulerZeroPoint.y, accuracy: 1)
            case .bottomLeft:
                XCTAssertEqual(settingsWindow.frame.minX, rulerZeroPoint.x, accuracy: 1)
                XCTAssertEqual(settingsWindow.frame.minY, rulerZeroPoint.y, accuracy: 1)
            case .bottomRight:
                XCTAssertEqual(settingsWindow.frame.maxX, rulerZeroPoint.x, accuracy: 1)
                XCTAssertEqual(settingsWindow.frame.minY, rulerZeroPoint.y, accuracy: 1)
            }
        }
    }

    func testRulerSettingsControllerUsesFloatingUtilityPanelStyle() {
        let controller = RulerController(
            state: RulerInstanceState(
                settings: RulerSettings(),
                layout: RulerLayoutState(
                    zeroPoint: NSPoint(x: 240, y: 320),
                    horizontalLength: 260,
                    verticalLength: 180
                )
            )
        )
        let settingsController = RulerSettingsController(rulerController: controller)
        defer {
            settingsController.close()
            controller.hide()
        }

        guard let settingsWindow = settingsController.window else {
            XCTFail("Expected settings window")
            return
        }

        XCTAssertTrue(settingsWindow is NSPanel)
        XCTAssertTrue(settingsWindow.styleMask.contains(.utilityWindow))
        XCTAssertEqual(settingsWindow.animationBehavior, .utilityWindow)

        let settingsPanel = settingsWindow as? NSPanel
        XCTAssertTrue(settingsPanel?.isFloatingPanel ?? false)
        XCTAssertFalse(settingsPanel?.hidesOnDeactivate ?? true)
    }

    func testRulerSettingsColorPanelAttachesOnRightForLeftZeroCorner() {
        assertRulerSettingsColorPanelAttachesToSettingsPanel(zeroCorner: .topLeft) { settingsController, settingsWindow in
            settingsController.rulerColorWell.mouseDown(
                with: mouseDownEvent(windowNumber: settingsWindow.windowNumber)
            )
        }
    }

    func testRulerSettingsColorPanelActivatedByKeyboardUsesAnchoredPlacement() {
        assertRulerSettingsColorPanelAttachesToSettingsPanel(zeroCorner: .topLeft) { settingsController, _ in
            settingsController.rulerColorWell.keyDown(
                with: keyDownEvent(characters: " ", keyCode: UInt16(kVK_Space))
            )
        }
    }

    func testRulerSettingsColorPanelAttachesOnLeftForRightZeroCorners() {
        for zeroCorner in [ZeroCorner.topRight, .bottomRight] {
            assertRulerSettingsColorPanelAttachesToSettingsPanel(zeroCorner: zeroCorner) { settingsController, settingsWindow in
                settingsController.rulerColorWell.mouseDown(
                    with: mouseDownEvent(windowNumber: settingsWindow.windowNumber)
                )
            }
        }
    }

    func testRulerSettingsControllerRestoresForegroundOpacityWhenClosingSheet() {
        let controller = RulerController(
            state: RulerInstanceState(
                settings: RulerSettings(
                    foregroundOpacity: 80,
                    backgroundOpacity: 45
                ),
                layout: RulerLayoutState(
                    zeroPoint: NSPoint(x: 240, y: 320),
                    horizontalLength: 260,
                    verticalLength: 180
                )
            )
        )
        let settingsController = RulerSettingsController(rulerController: controller)
        defer {
            settingsController.close()
            controller.hide()
        }

        controller.show()
        settingsController.show(attachedTo: controller, sender: self)
        settingsController.backgroundOpacitySlider.integerValue = 35
        settingsController.setBackgroundOpacity(settingsController.backgroundOpacitySlider)

        XCTAssertEqual(controller.rulerWindow.alphaValue, 0.35, accuracy: 0.0001)

        settingsController.close()

        XCTAssertEqual(controller.rulerWindow.alphaValue, 0.8, accuracy: 0.0001)
    }

    func testRulerSettingsControllerTitlebarCloseClosesAttachedSheet() {
        let controller = RulerController(
            state: RulerInstanceState(
                settings: RulerSettings(),
                layout: RulerLayoutState(
                    zeroPoint: NSPoint(x: 240, y: 320),
                    horizontalLength: 260,
                    verticalLength: 180
                )
            )
        )
        let settingsController = RulerSettingsController(rulerController: controller)
        defer {
            settingsController.close()
            controller.hide()
        }

        controller.show()
        settingsController.show(attachedTo: controller, sender: self)
        guard let settingsWindow = settingsController.window else {
            XCTFail("Expected settings window")
            return
        }

        XCTAssertTrue(settingsWindow.styleMask.contains(.closable))

        settingsWindow.performClose(self)

        XCTAssertFalse(controller.rulerWindow.childWindows?.contains(settingsWindow) ?? false)
        XCTAssertFalse(settingsWindow.isVisible)
    }

    func testRulerSettingsControllerReanchorsWhenRulerZeroCornerChanges() {
        withRestoredRulerPreferences {
            withRestoredRulerSetState {
                let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 900)
                let zeroPoint = NSPoint(x: visibleFrame.midX, y: visibleFrame.midY)
                let appDelegate = AppDelegate()
                let controller = appDelegate.rulerManager.addRuler(
                    state: RulerInstanceState(
                        settings: RulerSettings(zeroCorner: .topLeft),
                        layout: RulerLayoutState(
                            zeroPoint: zeroPoint,
                            horizontalLength: 260,
                            verticalLength: 180
                        )
                    )
                )
                defer {
                    appDelegate.rulerSettingsController?.close()
                    controller.hide()
                }

                controller.show()
                appDelegate.openRulerSettings(self)

                guard let settingsWindow = appDelegate.rulerSettingsController?.window else {
                    XCTFail("Expected settings window")
                    return
                }

                let initialZeroPoint = controller.rulerWindow.zeroPoint()
                XCTAssertEqual(settingsWindow.frame.minX, initialZeroPoint.x, accuracy: 1)
                XCTAssertEqual(settingsWindow.frame.maxY, initialZeroPoint.y, accuracy: 1)

                appDelegate.flipRulers(along: .horizontal)

                let flippedZeroPoint = controller.rulerWindow.zeroPoint()
                XCTAssertEqual(controller.state.settings.zeroCorner, .topRight)
                XCTAssertEqual(settingsWindow.frame.maxX, flippedZeroPoint.x, accuracy: 1)
                XCTAssertEqual(settingsWindow.frame.maxY, flippedZeroPoint.y, accuracy: 1)
            }
        }
    }

    func testRulerManagerCopiesUpdatedDefaultsOnlyForNewRulers() {
        withRestoredRulerPreferences {
            prefs.unit = .pixels
            prefs.rulerColor = NSColor(deviceRed: 0.1, green: 0.2, blue: 0.3, alpha: 1)
            prefs.zeroCorner = .topLeft
            prefs.defaultHorizontalLength = 260
            prefs.defaultVerticalLength = 180
            let manager = RulerManager()
            defer {
                for controller in manager.controllers {
                    controller.hide()
                }
            }

            let existing = manager.createRuler(
                screenFrame: NSRect(x: 0, y: 0, width: 1000, height: 800)
            )

            prefs.unit = .millimeters
            prefs.rulerColor = NSColor(deviceRed: 0.8, green: 0.7, blue: 0.2, alpha: 1)
            prefs.zeroCorner = .topRight
            prefs.defaultHorizontalLength = 320
            prefs.defaultVerticalLength = 240
            let createdAfterDefaultsChange = manager.createRuler(
                screenFrame: NSRect(x: 0, y: 0, width: 1000, height: 800)
            )

            XCTAssertEqual(existing.state.settings.unit, .pixels)
            XCTAssertEqual(existing.state.layout.horizontalLength, 260)
            XCTAssertEqual(existing.state.layout.verticalLength, 180)
            XCTAssertEqual(existing.rulerWindow.horizontalRule.unit, .pixels)
            XCTAssertEqual(existing.rulerWindow.horizontalRule.zeroCorner, .topLeft)
            assertColor(
                existing.rulerWindow.horizontalRule.color.fill,
                equals: NSColor(deviceRed: 0.1, green: 0.2, blue: 0.3, alpha: 1)
            )
            XCTAssertEqual(createdAfterDefaultsChange.state.settings.unit, .millimeters)
            XCTAssertEqual(createdAfterDefaultsChange.state.layout.horizontalLength, 320)
            XCTAssertEqual(createdAfterDefaultsChange.state.layout.verticalLength, 240)
            XCTAssertEqual(createdAfterDefaultsChange.rulerWindow.horizontalRule.unit, .millimeters)
            XCTAssertEqual(createdAfterDefaultsChange.rulerWindow.horizontalRule.zeroCorner, .topRight)
            assertColor(
                createdAfterDefaultsChange.rulerWindow.horizontalRule.color.fill,
                equals: NSColor(deviceRed: 0.8, green: 0.7, blue: 0.2, alpha: 1)
            )
        }
    }

    func testSavedRulerSetStateRoundTripsThroughUserDefaults() {
        withRestoredRulerSetState {
            let firstID = UUID(uuidString: "8B425683-3E8E-4B2C-9F79-1B39FC70622D")!
            let secondID = UUID(uuidString: "6B688B39-FC3E-454C-94C8-E77B3131F600")!
            let states = [
                RulerInstanceState(
                    id: firstID,
                    settings: RulerSettings(unit: .pixels),
                    visibility: RulerWingVisibility(horizontal: true, vertical: false),
                    layout: RulerLayoutState(
                        zeroPoint: NSPoint(x: 200, y: 300),
                        horizontalLength: 320,
                        verticalLength: 180
                    )
                ),
                RulerInstanceState(
                    id: secondID,
                    settings: RulerSettings(unit: .inches),
                    visibility: RulerWingVisibility(horizontal: false, vertical: true),
                    layout: RulerLayoutState(
                        zeroPoint: NSPoint(x: 400, y: 500),
                        horizontalLength: 220,
                        verticalLength: 280
                    )
                ),
            ]

            prefs.saveRulerSetState(rulers: states, activeRulerID: secondID)
            let restoredState = prefs.loadRulerSetState()

            XCTAssertEqual(restoredState?.schemaVersion, StoredRulerSetState.currentSchemaVersion)
            XCTAssertEqual(restoredState?.rulers, states)
            XCTAssertEqual(restoredState?.activeRulerID, secondID)
        }
    }

    func testSavedRulerSetStateFallsBackForCorruptOrUnknownSchemaData() throws {
        try withRestoredRulerSetState {
            Prefs.userDefaults.set(Data("not-json".utf8), forKey: Prefs.rulerSetStateKey)

            XCTAssertNil(prefs.loadRulerSetState())

            let unknownSchemaState = StoredRulerSetState(
                schemaVersion: StoredRulerSetState.currentSchemaVersion + 1,
                rulers: [
                    RulerInstanceState.createFromDefaults()
                ],
                activeRulerID: nil
            )
            let data = try JSONEncoder().encode(unknownSchemaState)
            Prefs.userDefaults.set(data, forKey: Prefs.rulerSetStateKey)

            XCTAssertNil(prefs.loadRulerSetState())
        }
    }

    func testRulerManagerRestoresSavedActiveRulerID() {
        let firstID = UUID(uuidString: "CE2FB5D8-109F-4482-8F54-1381075EE8C8")!
        let secondID = UUID(uuidString: "3BF78AE6-446F-4C43-82B4-F7D0CFEDDE83")!
        let manager = RulerManager()
        defer {
            for controller in manager.controllers {
                controller.hide()
            }
        }

        manager.restore(
            [
                RulerInstanceState(
                    id: firstID,
                    settings: RulerSettings(unit: .pixels),
                    layout: RulerLayoutState(
                        zeroPoint: NSPoint(x: 200, y: 300),
                        horizontalLength: 320,
                        verticalLength: 180
                    )
                ),
                RulerInstanceState(
                    id: secondID,
                    settings: RulerSettings(unit: .millimeters),
                    layout: RulerLayoutState(
                        zeroPoint: NSPoint(x: 400, y: 500),
                        horizontalLength: 220,
                        verticalLength: 280
                    )
                ),
            ],
            activeRulerID: firstID
        )

        XCTAssertEqual(manager.activeController?.state.id, firstID)
    }

    func testAppDelegateRestoresSavedRulerSetBeforeShowingDefaults() {
        withRestoredRulerSetState {
            let id = UUID(uuidString: "2D1A252A-E2AA-4BB8-9142-80F87802CFA3")!
            let state = RulerInstanceState(
                id: id,
                settings: RulerSettings(unit: .inches, zeroCorner: .bottomRight),
                visibility: RulerWingVisibility(horizontal: false, vertical: true),
                layout: RulerLayoutState(
                    zeroPoint: NSPoint(x: 500, y: 600),
                    horizontalLength: 320,
                    verticalLength: 240
                )
            )
            prefs.saveRulerSetState(rulers: [state], activeRulerID: id)
            let appDelegate = AppDelegate()
            defer {
                for controller in appDelegate.rulerManager.controllers {
                    controller.hide()
                }
            }

            appDelegate.restoreSavedRulers()

            XCTAssertEqual(appDelegate.rulerManager.controllers.map(\.state.id), [id])
            XCTAssertEqual(appDelegate.rulerManager.activeController?.state.id, id)
            XCTAssertEqual(appDelegate.rulerManager.activeController?.state.settings.unit, .inches)
            XCTAssertFalse(appDelegate.rulerManager.activeController?.state.isWingVisible(.horizontal) ?? true)
            XCTAssertTrue(appDelegate.rulerManager.activeController?.state.isWingVisible(.vertical) ?? false)
        }
    }

    func testUITestResetClearsSavedRulerSetState() {
        withRestoredRulerPreferences {
            withRestoredRulerSetState {
                prefs.saveRulerSetState(
                    rulers: [RulerInstanceState.createFromDefaults()],
                    activeRulerID: nil
                )

                UITestSupport.prepareForLaunch().resetApplicationState()

                XCTAssertNil(Prefs.userDefaults.data(forKey: Prefs.rulerSetStateKey))
            }
        }
    }

    func testZeroCornerRawValuesPreservePersistedOrder() {
        XCTAssertEqual(ZeroCorner.topLeft.rawValue, 0)
        XCTAssertEqual(ZeroCorner.topRight.rawValue, 1)
        XCTAssertEqual(ZeroCorner.bottomLeft.rawValue, 2)
        XCTAssertEqual(ZeroCorner.bottomRight.rawValue, 3)
    }

    func testDefaultZeroCornerMatchesTopLeft() {
        XCTAssertEqual(Prefs.defaultZeroCorner, .topLeft)
    }

    func testZeroCornerLoadsFromRawValue() {
        XCTAssertEqual(Prefs.zeroCorner(fromRawValue: ZeroCorner.topLeft.rawValue), .topLeft)
        XCTAssertEqual(Prefs.zeroCorner(fromRawValue: ZeroCorner.topRight.rawValue), .topRight)
        XCTAssertEqual(Prefs.zeroCorner(fromRawValue: ZeroCorner.bottomLeft.rawValue), .bottomLeft)
        XCTAssertEqual(Prefs.zeroCorner(fromRawValue: ZeroCorner.bottomRight.rawValue), .bottomRight)
    }

    func testZeroCornerDefaultsToTopLeftForUnknownRawValue() {
        XCTAssertEqual(Prefs.zeroCorner(fromRawValue: -1), .topLeft)
        XCTAssertEqual(Prefs.zeroCorner(fromRawValue: 99), .topLeft)
    }

    func testZeroCornerPreferencePersistsToUserDefaults() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .bottomRight

            XCTAssertEqual(
                Prefs.userDefaults.integer(forKey: "zeroCorner"),
                ZeroCorner.bottomRight.rawValue
            )

            prefs.zeroCorner = .topRight

            XCTAssertEqual(
                Prefs.userDefaults.integer(forKey: "zeroCorner"),
                ZeroCorner.topRight.rawValue
            )
        }
    }

    func testGroupRulersDefaultsOffAndPersistsToUserDefaults() {
        withRestoredRulerPreferences {
            XCTAssertFalse(Prefs.defaultGroupRulers)

            prefs.groupRulers = true
            XCTAssertTrue(Prefs.userDefaults.bool(forKey: "groupRulers"))

            prefs.groupRulers = false
            XCTAssertFalse(Prefs.userDefaults.bool(forKey: "groupRulers"))
        }
    }

    func testZeroCornerGeometryDerivesOrientationTraits() {
        let cases: [
            (
                zeroCorner: ZeroCorner,
                horizontalGrowth: RulerGrowthDirection,
                verticalGrowth: RulerGrowthDirection,
                horizontalTickSide: RulerVerticalSide,
                verticalTickSide: RulerHorizontalSide,
                horizontalResizeSide: RulerHorizontalSide,
                verticalResizeSide: RulerVerticalSide
            )
        ] = [
            (.topLeft, .positive, .negative, .bottom, .right, .right, .bottom),
            (.topRight, .negative, .negative, .bottom, .left, .left, .bottom),
            (.bottomLeft, .positive, .positive, .top, .right, .right, .top),
            (.bottomRight, .negative, .positive, .top, .left, .left, .top),
        ]

        for testCase in cases {
            let geometry = ZeroCornerGeometry(zeroCorner: testCase.zeroCorner)

            XCTAssertEqual(
                geometry.growthDirection(for: .horizontal),
                testCase.horizontalGrowth,
                "\(testCase.zeroCorner) horizontal growth"
            )
            XCTAssertEqual(
                geometry.growthDirection(for: .vertical),
                testCase.verticalGrowth,
                "\(testCase.zeroCorner) vertical growth"
            )
            XCTAssertEqual(
                geometry.horizontalTickSide,
                testCase.horizontalTickSide,
                "\(testCase.zeroCorner) horizontal tick side"
            )
            XCTAssertEqual(
                geometry.verticalTickSide,
                testCase.verticalTickSide,
                "\(testCase.zeroCorner) vertical tick side"
            )
            XCTAssertEqual(
                geometry.horizontalResizeSide,
                testCase.horizontalResizeSide,
                "\(testCase.zeroCorner) horizontal resize side"
            )
            XCTAssertEqual(
                geometry.verticalResizeSide,
                testCase.verticalResizeSide,
                "\(testCase.zeroCorner) vertical resize side"
            )
        }
    }

    func testZeroCornerGeometryDerivesAxisSpecificCornerPlacements() {
        let cases: [
            (
                zeroCorner: ZeroCorner,
                unitLabelPlacement: RulerCornerPlacement,
                horizontalResizePlacement: RulerCornerPlacement,
                verticalResizePlacement: RulerCornerPlacement
            )
        ] = [
            (
                .topLeft,
                RulerCornerPlacement(xSide: .left, ySide: .top),
                RulerCornerPlacement(xSide: .right, ySide: .top),
                RulerCornerPlacement(xSide: .left, ySide: .bottom)
            ),
            (
                .topRight,
                RulerCornerPlacement(xSide: .right, ySide: .top),
                RulerCornerPlacement(xSide: .left, ySide: .top),
                RulerCornerPlacement(xSide: .right, ySide: .bottom)
            ),
            (
                .bottomLeft,
                RulerCornerPlacement(xSide: .left, ySide: .bottom),
                RulerCornerPlacement(xSide: .right, ySide: .bottom),
                RulerCornerPlacement(xSide: .left, ySide: .top)
            ),
            (
                .bottomRight,
                RulerCornerPlacement(xSide: .right, ySide: .bottom),
                RulerCornerPlacement(xSide: .left, ySide: .bottom),
                RulerCornerPlacement(xSide: .right, ySide: .top)
            ),
        ]

        for testCase in cases {
            let geometry = ZeroCornerGeometry(zeroCorner: testCase.zeroCorner)

            XCTAssertEqual(
                geometry.unitLabelPlacement(for: .horizontal),
                testCase.unitLabelPlacement,
                "\(testCase.zeroCorner) horizontal unit label placement"
            )
            XCTAssertEqual(
                geometry.unitLabelPlacement(for: .vertical),
                testCase.unitLabelPlacement,
                "\(testCase.zeroCorner) vertical unit label placement"
            )
            XCTAssertEqual(
                geometry.resizeHandlePlacement(for: .horizontal),
                testCase.horizontalResizePlacement,
                "\(testCase.zeroCorner) horizontal resize handle placement"
            )
            XCTAssertEqual(
                geometry.resizeHandlePlacement(for: .vertical),
                testCase.verticalResizePlacement,
                "\(testCase.zeroCorner) vertical resize handle placement"
            )
        }
    }

    func testZeroCornerFlipsAlongSelectedAxis() {
        XCTAssertEqual(ZeroCorner.topLeft.flipped(along: .horizontal), .topRight)
        XCTAssertEqual(ZeroCorner.topRight.flipped(along: .horizontal), .topLeft)
        XCTAssertEqual(ZeroCorner.bottomLeft.flipped(along: .horizontal), .bottomRight)
        XCTAssertEqual(ZeroCorner.bottomRight.flipped(along: .horizontal), .bottomLeft)

        XCTAssertEqual(ZeroCorner.topLeft.flipped(along: .vertical), .bottomLeft)
        XCTAssertEqual(ZeroCorner.topRight.flipped(along: .vertical), .bottomRight)
        XCTAssertEqual(ZeroCorner.bottomLeft.flipped(along: .vertical), .topLeft)
        XCTAssertEqual(ZeroCorner.bottomRight.flipped(along: .vertical), .topRight)
    }

    func testZeroCornerGeometryPlacesFramesAroundSharedZeroPoint() {
        let zeroPoint = NSPoint(x: 200, y: 300)
        let horizontalSize = NSSize(width: 120, height: Ruler.thickness)
        let verticalSize = NSSize(width: Ruler.thickness, height: 160)
        let cases: [
            (
                zeroCorner: ZeroCorner,
                horizontalFrame: NSRect,
                verticalFrame: NSRect
            )
        ] = [
            (
                .topLeft,
                NSRect(x: 200, y: 299, width: 120, height: Ruler.thickness),
                NSRect(x: 161, y: 140, width: Ruler.thickness, height: 160)
            ),
            (
                .topRight,
                NSRect(x: 80, y: 299, width: 120, height: Ruler.thickness),
                NSRect(x: 200, y: 140, width: Ruler.thickness, height: 160)
            ),
            (
                .bottomLeft,
                NSRect(x: 200, y: 261, width: 120, height: Ruler.thickness),
                NSRect(x: 161, y: 300, width: Ruler.thickness, height: 160)
            ),
            (
                .bottomRight,
                NSRect(x: 80, y: 261, width: 120, height: Ruler.thickness),
                NSRect(x: 200, y: 300, width: Ruler.thickness, height: 160)
            ),
        ]

        for testCase in cases {
            let geometry = ZeroCornerGeometry(zeroCorner: testCase.zeroCorner)
            let horizontalFrame = geometry.frame(
                for: .horizontal,
                zeroPoint: zeroPoint,
                size: horizontalSize
            )
            let verticalFrame = geometry.frame(
                for: .vertical,
                zeroPoint: zeroPoint,
                size: verticalSize
            )

            XCTAssertEqual(horizontalFrame, testCase.horizontalFrame, "\(testCase.zeroCorner) horizontal frame")
            XCTAssertEqual(verticalFrame, testCase.verticalFrame, "\(testCase.zeroCorner) vertical frame")
            XCTAssertEqual(
                geometry.zeroPoint(in: horizontalFrame, for: .horizontal),
                zeroPoint,
                "\(testCase.zeroCorner) horizontal zero point"
            )
            XCTAssertEqual(
                geometry.zeroPoint(in: verticalFrame, for: .vertical),
                zeroPoint,
                "\(testCase.zeroCorner) vertical zero point"
            )
        }
    }

    func testZeroCornerGeometryDefaultFramesShareAZeroPointForEachCorner() {
        let screenFrame = NSRect(x: 0, y: 0, width: 1000, height: 800)

        for zeroCorner in [ZeroCorner.topLeft, .topRight, .bottomLeft, .bottomRight] {
            let geometry = ZeroCornerGeometry(zeroCorner: zeroCorner)
            let horizontalFrame = geometry.defaultFrame(for: .horizontal, screenFrame: screenFrame)
            let verticalFrame = geometry.defaultFrame(for: .vertical, screenFrame: screenFrame)

            XCTAssertEqual(horizontalFrame.width, 500, "\(zeroCorner) horizontal width")
            XCTAssertEqual(horizontalFrame.height, Ruler.thickness, "\(zeroCorner) horizontal height")
            XCTAssertEqual(verticalFrame.width, Ruler.thickness, "\(zeroCorner) vertical width")
            XCTAssertEqual(verticalFrame.height, 400, "\(zeroCorner) vertical height")
            XCTAssertEqual(
                geometry.zeroPoint(in: horizontalFrame, for: .horizontal),
                geometry.zeroPoint(in: verticalFrame, for: .vertical),
                "\(zeroCorner) shared zero point"
            )
        }
    }

    func testRulerWindowLayoutJoinsSeparateRulersWithoutChangingRuleFrames() {
        let zeroPoint = NSPoint(x: 200, y: 300)
        let horizontalSize = NSSize(width: 120, height: Ruler.thickness)
        let verticalSize = NSSize(width: Ruler.thickness, height: 160)

        for zeroCorner in [ZeroCorner.topLeft, .topRight, .bottomLeft, .bottomRight] {
            let geometry = ZeroCornerGeometry(zeroCorner: zeroCorner)
            let horizontalFrame = geometry.frame(
                for: .horizontal,
                zeroPoint: zeroPoint,
                size: horizontalSize
            )
            let verticalFrame = geometry.frame(
                for: .vertical,
                zeroPoint: zeroPoint,
                size: verticalSize
            )

            let layout = RulerWindowLayout.joined(
                horizontalFrame: horizontalFrame,
                verticalFrame: verticalFrame,
                zeroCorner: zeroCorner
            )
            let roundTrippedLayout = RulerWindowLayout.layout(
                groupFrame: layout.groupFrame,
                zeroCorner: zeroCorner
            )

            XCTAssertEqual(layout.horizontalFrame, horizontalFrame, "\(zeroCorner) horizontal frame")
            XCTAssertEqual(layout.verticalFrame, verticalFrame, "\(zeroCorner) vertical frame")
            XCTAssertEqual(layout.groupFrame, horizontalFrame.union(verticalFrame), "\(zeroCorner) group frame")
            XCTAssertEqual(roundTrippedLayout, layout, "\(zeroCorner) round trip")
            XCTAssertEqual(
                layout.localFrame(for: Orientation.horizontal).size,
                horizontalSize,
                "\(zeroCorner) horizontal local size"
            )
            XCTAssertEqual(
                layout.localFrame(for: Orientation.vertical).size,
                verticalSize,
                "\(zeroCorner) vertical local size"
            )
        }
    }

    func testRulerContentViewLaysOutLegsAndHitTestsCorner() {
        let contentSize = NSSize(width: 260, height: 220)

        for zeroCorner in [ZeroCorner.topLeft, .topRight, .bottomLeft, .bottomRight] {
            let view = rulerContentView(size: contentSize, zeroCorner: zeroCorner)
            let layout = RulerWindowLayout.layout(groupFrame: view.bounds, zeroCorner: zeroCorner)
            let emptyCornerPoint = pointInsideEmptyRulerWindowCorner(
                horizontalFrame: layout.localFrame(for: Orientation.horizontal),
                verticalFrame: layout.localFrame(for: Orientation.vertical),
                bounds: view.bounds
            )

            XCTAssertEqual(
                view.localFrame(for: Orientation.horizontal),
                layout.localFrame(for: Orientation.horizontal),
                "\(zeroCorner) horizontal local frame"
            )
            XCTAssertEqual(
                view.localFrame(for: Orientation.vertical),
                layout.localFrame(for: Orientation.vertical),
                "\(zeroCorner) vertical local frame"
            )
            XCTAssertTrue(view.containsEmptyCorner(emptyCornerPoint), "\(zeroCorner) empty corner")
            XCTAssertTrue(view.hitTest(emptyCornerPoint) === view, "\(zeroCorner) empty corner hit test")

            view.showsVerticalRule = false
            view.layoutSubtreeIfNeeded()

            XCTAssertFalse(view.containsEmptyCorner(emptyCornerPoint), "\(zeroCorner) hidden vertical corner")
            XCTAssertFalse(view.hitTest(emptyCornerPoint) === view, "\(zeroCorner) hidden vertical hit test")
        }
    }

    func testRulerContentViewRestoresStandaloneLabelsWhenOnlyOneLegIsVisible() {
        let view = rulerContentView(size: NSSize(width: 260, height: 220), zeroCorner: .topLeft)

        XCTAssertFalse(view.horizontalRule.showsUnitLabel)
        XCTAssertFalse(view.verticalRule.showsUnitLabel)
        XCTAssertTrue(view.horizontalRule.showsZeroTick)
        XCTAssertTrue(view.verticalRule.showsZeroTick)

        view.showsVerticalRule = false
        view.layoutSubtreeIfNeeded()

        XCTAssertTrue(view.horizontalRule.showsUnitLabel)
        XCTAssertFalse(view.verticalRule.showsUnitLabel)
        XCTAssertTrue(view.horizontalRule.showsZeroTick)
        XCTAssertFalse(view.verticalRule.showsZeroTick)

        view.showsVerticalRule = true
        view.showsHorizontalRule = false
        view.layoutSubtreeIfNeeded()

        XCTAssertFalse(view.horizontalRule.showsUnitLabel)
        XCTAssertTrue(view.verticalRule.showsUnitLabel)
        XCTAssertFalse(view.horizontalRule.showsZeroTick)
        XCTAssertTrue(view.verticalRule.showsZeroTick)
    }

    func testRulerControllerEnablesMouseTicksOnlyForVisibleLegs() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topLeft
            let controller = RulerController(
                frame: NSRect(x: 100, y: 100, width: 260, height: 220)
            )

            controller.rulerWindow.setVisibleRules(horizontal: true, vertical: false)
            controller.setMouseTickDrawingEnabled(true)

            XCTAssertTrue(controller.rulerWindow.horizontalRule.showMouseTick)
            XCTAssertFalse(controller.rulerWindow.verticalRule.showMouseTick)

            controller.rulerWindow.setVisibleRules(horizontal: false, vertical: true)
            controller.setMouseTickDrawingEnabled(true)

            XCTAssertFalse(controller.rulerWindow.horizontalRule.showMouseTick)
            XCTAssertTrue(controller.rulerWindow.verticalRule.showMouseTick)

            controller.setMouseTickDrawingEnabled(false)

            XCTAssertFalse(controller.rulerWindow.horizontalRule.showMouseTick)
            XCTAssertFalse(controller.rulerWindow.verticalRule.showMouseTick)
        }
    }

    func testRulerControllerRestoresMouseTicksWhenHiddenLegReappears() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topLeft
            let horizontalFrame = NSRect(x: 200, y: 299, width: 320, height: Ruler.thickness)
            let verticalFrame = NSRect(x: 161, y: 120, width: Ruler.thickness, height: 180)
            let controller = RulerController(
                frame: RulerWindowLayout.joined(
                    horizontalFrame: horizontalFrame,
                    verticalFrame: verticalFrame,
                    zeroCorner: .topLeft
                ).groupFrame
            )

            controller.show(
                horizontalFrame: horizontalFrame,
                verticalFrame: verticalFrame,
                showsHorizontalRule: true,
                showsVerticalRule: false
            )
            controller.setMouseTickDrawingEnabled(false)
            controller.setMouseTickDrawingEnabled(true)

            XCTAssertTrue(controller.rulerWindow.horizontalRule.showMouseTick)
            XCTAssertFalse(controller.rulerWindow.verticalRule.showMouseTick)

            controller.show(
                horizontalFrame: horizontalFrame,
                verticalFrame: verticalFrame,
                showsHorizontalRule: true,
                showsVerticalRule: true
            )

            XCTAssertTrue(controller.rulerWindow.horizontalRule.showMouseTick)
            XCTAssertTrue(controller.rulerWindow.verticalRule.showMouseTick)
            controller.rulerWindow.orderOut(self)
        }
    }

    func testRulerControllerShrinksWindowToOnlyVisibleLeg() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topLeft
            let horizontalFrame = NSRect(x: 200, y: 299, width: 320, height: Ruler.thickness)
            let verticalFrame = NSRect(x: 161, y: 120, width: Ruler.thickness, height: 180)
            let controller = RulerController(
                frame: RulerWindowLayout.joined(
                    horizontalFrame: horizontalFrame,
                    verticalFrame: verticalFrame,
                    zeroCorner: .topLeft
                ).groupFrame
            )

            controller.show(
                horizontalFrame: horizontalFrame,
                verticalFrame: verticalFrame,
                showsHorizontalRule: true,
                showsVerticalRule: false
            )

            XCTAssertEqual(controller.rulerWindow.frame, horizontalFrame)
            XCTAssertEqual(
                controller.rulerWindow.screenFrame(for: .horizontal),
                horizontalFrame
            )
            XCTAssertFalse(controller.rulerWindow.isRuleVisible(.vertical))

            controller.show(
                horizontalFrame: horizontalFrame,
                verticalFrame: verticalFrame,
                showsHorizontalRule: false,
                showsVerticalRule: true
            )

            XCTAssertEqual(controller.rulerWindow.frame, verticalFrame)
            XCTAssertEqual(
                controller.rulerWindow.screenFrame(for: .vertical),
                verticalFrame
            )
            XCTAssertFalse(controller.rulerWindow.isRuleVisible(.horizontal))
            controller.rulerWindow.orderOut(self)
        }
    }

    func testRulerControllerAlignsOnlyVisibleLegWithoutExpandingWindow() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topLeft
            let horizontalFrame = NSRect(x: 200, y: 299, width: 320, height: Ruler.thickness)
            let verticalFrame = NSRect(x: 161, y: 120, width: Ruler.thickness, height: 180)
            let controller = RulerController(
                frame: RulerWindowLayout.joined(
                    horizontalFrame: horizontalFrame,
                    verticalFrame: verticalFrame,
                    zeroCorner: .topLeft
                ).groupFrame
            )
            let targetZeroPoint = NSPoint(x: 350, y: 500)

            controller.show(
                horizontalFrame: horizontalFrame,
                verticalFrame: verticalFrame,
                showsHorizontalRule: false,
                showsVerticalRule: true
            )

            controller.align(at: targetZeroPoint)

            let expectedFrame = RulerWindowLayout.layout(
                horizontalLength: 0,
                verticalLength: verticalFrame.height,
                zeroPoint: targetZeroPoint,
                zeroCorner: .topLeft
            ).visibleFrame(showsHorizontalRule: false, showsVerticalRule: true)
            XCTAssertEqual(controller.rulerWindow.frame, expectedFrame)
            XCTAssertEqual(controller.rulerWindow.frame.size, verticalFrame.size)
            XCTAssertEqual(
                ZeroCornerGeometry(zeroCorner: .topLeft).zeroPoint(
                    in: controller.rulerWindow.screenFrame(for: .vertical),
                    for: .vertical
                ),
                targetZeroPoint
            )
            controller.rulerWindow.orderOut(self)
        }
    }

    func testRulerControllerFlipsOnlyVisibleLegWithoutExpandingWindow() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topLeft
            let horizontalFrame = NSRect(x: 200, y: 299, width: 320, height: Ruler.thickness)
            let verticalFrame = NSRect(x: 161, y: 120, width: Ruler.thickness, height: 180)
            let controller = RulerController(
                frame: RulerWindowLayout.joined(
                    horizontalFrame: horizontalFrame,
                    verticalFrame: verticalFrame,
                    zeroCorner: .topLeft
                ).groupFrame
            )
            let oldZeroPoint = ZeroCornerGeometry(zeroCorner: .topLeft)
                .zeroPoint(in: verticalFrame, for: .vertical)

            controller.show(
                horizontalFrame: horizontalFrame,
                verticalFrame: verticalFrame,
                showsHorizontalRule: false,
                showsVerticalRule: true
            )

            controller.prepareForZeroCornerChange(to: .topRight)

            let expectedFrame = RulerWindowLayout.layout(
                horizontalLength: 0,
                verticalLength: verticalFrame.height,
                zeroPoint: oldZeroPoint,
                zeroCorner: .topRight
            ).visibleFrame(showsHorizontalRule: false, showsVerticalRule: true)
            XCTAssertEqual(controller.rulerWindow.frame, expectedFrame)
            XCTAssertEqual(controller.rulerWindow.frame.size, verticalFrame.size)
            XCTAssertEqual(
                ZeroCornerGeometry(zeroCorner: .topRight).zeroPoint(
                    in: controller.rulerWindow.frame,
                    for: .vertical
                ),
                oldZeroPoint
            )
            controller.rulerWindow.orderOut(self)
        }
    }

    func testMinAndMaxSizesMatchRulerOrientation() {
        let horizontal = Ruler(.horizontal, frame: NSRect(x: 0, y: 0, width: 300, height: 40))
        let vertical = Ruler(.vertical, frame: NSRect(x: 0, y: 0, width: 40, height: 300))

        XCTAssertEqual(getMinSize(ruler: horizontal), NSSize(width: 200, height: 40))
        XCTAssertEqual(getMaxSize(ruler: horizontal), NSSize(width: 4000, height: 40))
        XCTAssertEqual(getMinSize(ruler: vertical), NSSize(width: 40, height: 200))
        XCTAssertEqual(getMaxSize(ruler: vertical), NSSize(width: 40, height: 4000))
    }

    func testRulerTickLayoutMatchesUnitScales() {
        let pixels = RulerTickLayout(unit: .pixels, dpi: 144, dpmm: 4)
        XCTAssertEqual(pixels.tickScale, 1)
        XCTAssertEqual(pixels.textScale, 1)
        XCTAssertEqual(pixels.largeTicks, 50)
        XCTAssertEqual(pixels.mediumTicks, 10)
        XCTAssertEqual(pixels.smallTicks, 2)
        XCTAssertNil(pixels.tinyTicks)

        let millimeters = RulerTickLayout(unit: .millimeters, dpi: 144, dpmm: 4)
        XCTAssertEqual(millimeters.tickScale, 4)
        XCTAssertEqual(millimeters.textScale, 1)
        XCTAssertEqual(millimeters.largeTicks, 10)
        XCTAssertEqual(millimeters.mediumTicks, 5)
        XCTAssertEqual(millimeters.smallTicks, 1)
        XCTAssertNil(millimeters.tinyTicks)

        let inches = RulerTickLayout(unit: .inches, dpi: 144, dpmm: 4)
        XCTAssertEqual(inches.tickScale, 9)
        XCTAssertEqual(inches.textScale, 16)
        XCTAssertEqual(inches.largeTicks, 16)
        XCTAssertEqual(inches.mediumTicks, 8)
        XCTAssertEqual(inches.smallTicks, 4)
        XCTAssertEqual(inches.tinyTicks, 1)
    }

    func testHorizontalRuleDrawingHelpersFollowZeroCornerGeometry() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topLeft
            let rule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))

            XCTAssertEqual(rule.mouseNumber(forTickX: 51, rulerWidth: 300), 50)
            XCTAssertEqual(
                rule.tickX(forOffset: 50, rulerWidth: 300, growthDirection: .positive),
                50
            )
            XCTAssertEqual(
                rule.tickX(forOffset: 50, rulerWidth: 300, growthDirection: .negative),
                249
            )
            XCTAssertEqual(
                rule.mouseTickLineX(forTickX: 1, growthDirection: .positive),
                1
            )
            XCTAssertEqual(
                rule.mouseTickLineX(forTickX: 299, growthDirection: .negative),
                299
            )
            XCTAssertEqual(rule.mouseTickX(forLocalMouseX: 50.49), 50)
            XCTAssertEqual(rule.mouseTickX(forLocalMouseX: 50.5), 51)

            let bottomTick = rule.tickLine(forX: 50, length: 10, rulerHeight: 40, tickSide: .bottom)
            XCTAssertEqual(bottomTick.start, CGPoint(x: 50, y: 1))
            XCTAssertEqual(bottomTick.end, CGPoint(x: 50, y: 10))

            let topTick = rule.tickLine(forX: 250, length: 10, rulerHeight: 40, tickSide: .top)
            XCTAssertEqual(topTick.start, CGPoint(x: 250, y: 39))
            XCTAssertEqual(topTick.end, CGPoint(x: 250, y: 30))

            XCTAssertEqual(
                rule.tickLabelRect(
                    forX: 250,
                    labelSize: NSSize(width: 50, height: 20),
                    rulerHeight: 40,
                    tickSide: .top
                ),
                CGRect(x: 225.5, y: 19, width: 50, height: 20)
            )
        }
    }

    func testHorizontalRuleMouseAndUnitLabelsMirrorForRightZeroCorner() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .bottomRight
            let rule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))

            XCTAssertEqual(rule.mouseNumber(forTickX: 260, rulerWidth: 300), 40)
            XCTAssertEqual(
                rule.mouseNumber(
                    forTickX: rule.tickX(forOffset: 50, rulerWidth: 300, growthDirection: .negative) + 1,
                    rulerWidth: 300
                ),
                50
            )
            XCTAssertEqual(
                rule.unitLabelRect(labelSize: NSSize(width: 12, height: 10), rulerSize: NSSize(width: 300, height: 40)),
                CGRect(x: 280, y: 0, width: 20, height: 19)
            )
        }
    }

    func testVerticalRuleDrawingHelpersFollowZeroCornerGeometry() {
        let rule = VerticalRule(frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))

        XCTAssertEqual(
            rule.tickY(forOffset: 50, rulerHeight: 300, growthDirection: .negative),
            250
        )
        XCTAssertEqual(
            rule.tickY(forOffset: 50, rulerHeight: 300, growthDirection: .positive),
            51
        )
        XCTAssertEqual(
            rule.mouseTickLineY(forTickY: 299, growthDirection: .negative),
            299
        )
        XCTAssertEqual(
            rule.mouseTickLineY(forTickY: 1, growthDirection: .positive),
            1
        )
        XCTAssertEqual(rule.mouseTickY(forLocalMouseY: 50.49), 50)
        XCTAssertEqual(rule.mouseTickY(forLocalMouseY: 50.5), 51)

        let rightTick = rule.tickLine(forY: 250, length: 10, rulerWidth: 40, tickSide: .right)
        XCTAssertEqual(rightTick.start, CGPoint(x: 39, y: 250))
        XCTAssertEqual(rightTick.end, CGPoint(x: 30, y: 250))

        let leftTick = rule.tickLine(forY: 50, length: 10, rulerWidth: 40, tickSide: .left)
        XCTAssertEqual(leftTick.start, CGPoint(x: 1, y: 50))
        XCTAssertEqual(leftTick.end, CGPoint(x: 10, y: 50))

        XCTAssertEqual(
            rule.tickLabelRect(
                forY: 50,
                labelSize: NSSize(width: 50, height: 20),
                rulerWidth: 40,
                tickSide: .left
            ),
            CGRect(x: 13, y: 46, width: 50, height: 20)
        )
    }

    func testVerticalRuleMouseAndUnitLabelsMirrorForBottomZeroCorner() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topRight
            let topZeroRule = VerticalRule(frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))
            XCTAssertEqual(
                topZeroRule.mouseNumber(
                    forTickY: topZeroRule.tickY(forOffset: 50, rulerHeight: 300, growthDirection: .negative) - 1,
                    rulerHeight: 300
                ),
                50
            )

            prefs.zeroCorner = .bottomRight
            let rule = VerticalRule(frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))

            XCTAssertEqual(rule.mouseNumber(forTickY: 40, rulerHeight: 300), 40)
            XCTAssertEqual(
                rule.mouseNumber(
                    forTickY: rule.tickY(forOffset: 50, rulerHeight: 300, growthDirection: .positive) - 1,
                    rulerHeight: 300
                ),
                50
            )
            XCTAssertEqual(
                rule.unitLabelRect(labelSize: NSSize(width: 12, height: 10), rulerSize: NSSize(width: 40, height: 300)),
                CGRect(x: 20, y: 0, width: 20, height: 19)
            )
        }
    }

    func testVerticalMouseNumberLabelBackgroundCoversWideLabels() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topRight

            let rule = VerticalRule(frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))
            let wideLabelSize = NSSize(width: 32, height: 10)
            let labelRect = rule.mouseNumberLabelRect(
                tickY: 150,
                labelSize: wideLabelSize,
                rulerSize: rule.bounds.size
            )
            let backgroundRect = rule.mouseNumberLabelBackgroundRect(
                tickY: 150,
                labelSize: wideLabelSize,
                rulerSize: rule.bounds.size
            )

            XCTAssertTrue(backgroundRect.contains(labelRect))
            XCTAssertLessThan(labelRect.minX, 10)
            XCTAssertEqual(backgroundRect.minX, labelRect.minX, accuracy: 0.0001)
            XCTAssertEqual(backgroundRect.maxX, rule.bounds.maxX, accuracy: 0.0001)
        }
    }

    func testResizeHandlesAreVisuallyObscuredFromLeadingEdgeToRulerEnd() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topLeft
            let horizontalRule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))
            let verticalRule = VerticalRule(frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))
            guard let horizontalHandle = horizontalRule.subviews.first(where: { $0 is ResizeHandleView }) as? ResizeHandleView else {
                return XCTFail("Expected horizontal ruler to install a resize handle")
            }
            guard let verticalHandle = verticalRule.subviews.first(where: { $0 is ResizeHandleView }) as? ResizeHandleView else {
                return XCTFail("Expected vertical ruler to install a resize handle")
            }

            horizontalRule.mouseTickX = horizontalHandle.frame.midX
            XCTAssertFalse(horizontalHandle.isHidden)
            XCTAssertEqual(horizontalHandle.alphaValue, 0)

            horizontalRule.mouseTickX = horizontalHandle.frame.maxX
            XCTAssertEqual(horizontalHandle.alphaValue, 0)

            horizontalRule.mouseTickX = horizontalHandle.frame.minX - 1
            XCTAssertEqual(horizontalHandle.alphaValue, 1)

            verticalRule.mouseTickY = verticalHandle.frame.midY
            XCTAssertFalse(verticalHandle.isHidden)
            XCTAssertEqual(verticalHandle.alphaValue, 0)

            verticalRule.mouseTickY = verticalHandle.frame.minY
            XCTAssertEqual(verticalHandle.alphaValue, 0)

            verticalRule.mouseTickY = verticalHandle.frame.maxY + 1
            XCTAssertEqual(verticalHandle.alphaValue, 1)

            verticalRule.mouseTickY = verticalHandle.frame.midY
            verticalRule.showMouseTick = false
            XCTAssertEqual(verticalHandle.alphaValue, 1)

            prefs.zeroCorner = .topRight
            let leftEdgeRule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))
            guard let leftEdgeHandle = leftEdgeRule.subviews.first(where: { $0 is ResizeHandleView }) as? ResizeHandleView else {
                return XCTFail("Expected horizontal ruler to install a resize handle")
            }

            leftEdgeRule.mouseTickX = leftEdgeHandle.frame.maxX
            XCTAssertEqual(leftEdgeHandle.alphaValue, 0)

            leftEdgeRule.mouseTickX = leftEdgeHandle.frame.maxX + 1
            XCTAssertEqual(leftEdgeHandle.alphaValue, 1)

            leftEdgeRule.mouseTickX = leftEdgeHandle.frame.minX
            XCTAssertEqual(leftEdgeHandle.alphaValue, 0)

            prefs.zeroCorner = .bottomLeft
            let topEdgeRule = VerticalRule(frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))
            guard let topEdgeHandle = topEdgeRule.subviews.first(where: { $0 is ResizeHandleView }) as? ResizeHandleView else {
                return XCTFail("Expected vertical ruler to install a resize handle")
            }

            topEdgeRule.mouseTickY = topEdgeHandle.frame.maxY
            XCTAssertEqual(topEdgeHandle.alphaValue, 0)

            topEdgeRule.mouseTickY = topEdgeHandle.frame.minY - 1
            XCTAssertEqual(topEdgeHandle.alphaValue, 1)
        }
    }

    func testUnitLabelSubviewsFollowNearOppositeCornerAfterZeroCornerChange() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topLeft
            let horizontalRule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))
            let verticalRule = VerticalRule(frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))
            prefs.zeroCorner = .bottomRight

            horizontalRule.redrawForPreferenceChange()
            verticalRule.redrawForPreferenceChange()

            let horizontalLabelSize = unitLabelSize(for: horizontalRule)
            let verticalLabelSize = unitLabelSize(for: verticalRule)

            XCTAssertEqual(
                horizontalRule.unitLabelFrame,
                horizontalRule.unitLabelRect(labelSize: horizontalLabelSize, rulerSize: horizontalRule.bounds.size)
            )
            XCTAssertEqual(
                verticalRule.unitLabelFrame,
                verticalRule.unitLabelRect(labelSize: verticalLabelSize, rulerSize: verticalRule.bounds.size)
            )
        }
    }

    func testChildViewGeometryUsesRuleZeroCornerOverride() throws {
        try withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topLeft
            let rule = TestableZeroCornerHorizontalRule(
                frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness)
            )
            rule.testZeroCorner = .bottomRight

            rule.redrawForPreferenceChange()

            let unitLabel = try XCTUnwrap(rule.subviews.first { $0 is UnitLabelView } as? UnitLabelView)
            let resizeHandle = try XCTUnwrap(
                rule.subviews.first { $0 is ResizeHandleView } as? ResizeHandleView
            )
            let labelSize = unitLabelSize(for: rule)

            XCTAssertEqual(unitLabel.zeroCorner, .bottomRight)
            XCTAssertEqual(resizeHandle.zeroCorner, .bottomRight)
            XCTAssertEqual(
                rule.unitLabelFrame,
                UnitLabelView.labelFrame(
                    labelSize: labelSize,
                    rulerSize: rule.bounds.size,
                    orientation: .horizontal,
                    zeroCorner: .bottomRight
                )
            )
        }
    }

    func testUnitLabelsAreHiddenFromInnerEdgeToZero() throws {
        try withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topLeft
            let leftZeroRule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))
            let leftZeroLabel = try XCTUnwrap(leftZeroRule.subviews.first { $0 is UnitLabelView })
            let leftZeroFrame = try XCTUnwrap(leftZeroRule.unitLabelFrame)

            leftZeroRule.mouseTickX = leftZeroFrame.maxX
            XCTAssertTrue(leftZeroLabel.isHidden)
            leftZeroRule.mouseTickX = leftZeroFrame.maxX + 1
            XCTAssertFalse(leftZeroLabel.isHidden)
            leftZeroRule.mouseTickX = leftZeroRule.bounds.minX
            XCTAssertTrue(leftZeroLabel.isHidden)

            prefs.zeroCorner = .topRight
            let rightZeroRule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))
            let rightZeroLabel = try XCTUnwrap(rightZeroRule.subviews.first { $0 is UnitLabelView })
            let rightZeroFrame = try XCTUnwrap(rightZeroRule.unitLabelFrame)

            rightZeroRule.mouseTickX = rightZeroFrame.minX
            XCTAssertTrue(rightZeroLabel.isHidden)
            rightZeroRule.mouseTickX = rightZeroFrame.minX - 1
            XCTAssertFalse(rightZeroLabel.isHidden)
            rightZeroRule.mouseTickX = rightZeroRule.bounds.maxX
            XCTAssertTrue(rightZeroLabel.isHidden)

            prefs.zeroCorner = .topLeft
            let topZeroRule = VerticalRule(frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))
            let topZeroLabel = try XCTUnwrap(topZeroRule.subviews.first { $0 is UnitLabelView })
            let topZeroFrame = try XCTUnwrap(topZeroRule.unitLabelFrame)

            topZeroRule.mouseTickY = topZeroFrame.minY
            XCTAssertTrue(topZeroLabel.isHidden)
            topZeroRule.mouseTickY = topZeroFrame.minY - 1
            XCTAssertFalse(topZeroLabel.isHidden)
            topZeroRule.mouseTickY = topZeroRule.bounds.maxY
            XCTAssertTrue(topZeroLabel.isHidden)

            prefs.zeroCorner = .bottomLeft
            let bottomZeroRule = VerticalRule(frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))
            let bottomZeroLabel = try XCTUnwrap(bottomZeroRule.subviews.first { $0 is UnitLabelView })
            let bottomZeroFrame = try XCTUnwrap(bottomZeroRule.unitLabelFrame)

            bottomZeroRule.mouseTickY = bottomZeroFrame.maxY
            XCTAssertTrue(bottomZeroLabel.isHidden)
            bottomZeroRule.mouseTickY = bottomZeroFrame.maxY + 1
            XCTAssertFalse(bottomZeroLabel.isHidden)
            bottomZeroRule.mouseTickY = bottomZeroRule.bounds.minY
            XCTAssertTrue(bottomZeroLabel.isHidden)
        }
    }

    func testMouseNumberLabelsRespectUnitsAfterZeroCornerFlip() {
        withRestoredZeroCornerPreference {
            let previousUnit = prefs.unit
            defer { prefs.unit = previousUnit }

            prefs.zeroCorner = .bottomRight
            let horizontalRule = HorizontalRule(
                frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness)
            )
            let verticalRule = VerticalRule(
                frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300)
            )
            let horizontalNumber = horizontalRule.mouseNumber(forTickX: 260, rulerWidth: 300)
            let verticalNumber = verticalRule.mouseNumber(forTickY: 40, rulerHeight: 300)
            let horizontalDpmm = horizontalRule.screen?.dpmm.width ?? NSScreen.defaultDpmm
            let verticalDpmm = verticalRule.screen?.dpmm.width ?? NSScreen.defaultDpmm
            let horizontalDpi = horizontalRule.screen?.dpi.width ?? NSScreen.defaultDpi
            let verticalDpi = verticalRule.screen?.dpi.width ?? NSScreen.defaultDpi

            prefs.unit = .pixels
            XCTAssertEqual(horizontalRule.getMouseNumberLabel(horizontalNumber), "40")
            XCTAssertEqual(verticalRule.getMouseNumberLabel(verticalNumber), "40")

            prefs.unit = .millimeters
            XCTAssertEqual(
                horizontalRule.getMouseNumberLabel(horizontalNumber),
                String(format: "%.1f", horizontalNumber / horizontalDpmm)
            )
            XCTAssertEqual(
                verticalRule.getMouseNumberLabel(verticalNumber),
                String(format: "%.1f", verticalNumber / verticalDpmm)
            )

            prefs.unit = .inches
            XCTAssertEqual(
                horizontalRule.getMouseNumberLabel(horizontalNumber),
                String(format: "%.3f", horizontalNumber / horizontalDpi)
            )
            XCTAssertEqual(
                verticalRule.getMouseNumberLabel(verticalNumber),
                String(format: "%.3f", verticalNumber / verticalDpi)
            )
        }
    }

    func testRulerColorsDefaultToOriginalFillColor() {
        withRestoredRulerColorPreference {
            prefs.rulerColor = Prefs.defaultRulerFillColor

            assertColor(RulerColors().fill, equals: Prefs.defaultRulerFillColor)
        }
    }

    func testRulerColorsDeriveContrastingForegroundColors() {
        withRestoredRulerColorPreference {
            prefs.rulerColor = NSColor(calibratedWhite: 0.9, alpha: 1)
            let colorsOnLightFill = RulerColors()
            XCTAssertLessThan(relativeLuminance(colorsOnLightFill.ticks), relativeLuminance(colorsOnLightFill.fill))
            XCTAssertLessThan(relativeLuminance(colorsOnLightFill.numbers), relativeLuminance(colorsOnLightFill.fill))

            prefs.rulerColor = NSColor(calibratedWhite: 0.1, alpha: 1)
            let colorsOnDarkFill = RulerColors()
            XCTAssertGreaterThan(relativeLuminance(colorsOnDarkFill.ticks), relativeLuminance(colorsOnDarkFill.fill))
            XCTAssertGreaterThan(relativeLuminance(colorsOnDarkFill.numbers), relativeLuminance(colorsOnDarkFill.fill))
        }
    }

    func testRulerColorNormalizesUnconvertibleColorsInMemory() {
        withRestoredRulerColorPreference {
            prefs.rulerColor = NSColor(patternImage: NSImage(size: NSSize(width: 1, height: 1)))

            assertColor(prefs.rulerColor, equals: Prefs.defaultRulerFillColor)
        }
    }

    func testRulerColorNormalizesAlphaInMemory() {
        withRestoredRulerColorPreference {
            prefs.rulerColor = NSColor(deviceRed: 0.2, green: 0.4, blue: 0.6, alpha: 0.35)

            assertColor(prefs.rulerColor, equals: NSColor(deviceRed: 0.2, green: 0.4, blue: 0.6, alpha: 1))
        }
    }

    func testArchivedRulerColorNormalizesAlphaOnLoad() throws {
        let archivedColor = NSColor(deviceRed: 0.2, green: 0.4, blue: 0.6, alpha: 0.35)
        let data = try NSKeyedArchiver.archivedData(
            withRootObject: archivedColor,
            requiringSecureCoding: true
        )

        let loadedColor = Prefs.rulerFillColor(fromArchivedData: data)

        assertColor(loadedColor, equals: NSColor(deviceRed: 0.2, green: 0.4, blue: 0.6, alpha: 1))
    }

    func testDefaultRulerRectsUseExpectedShapeAndOffsets() {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1000, height: 800)
        let screenWidth = screenFrame.width
        let screenHeight = screenFrame.height
        let horizontalLength = screenWidth / 2
        let verticalLength = horizontalLength / (screenWidth / screenHeight)

        let horizontal = getDefaultContentRect(orientation: .horizontal)
        let vertical = getDefaultContentRect(orientation: .vertical)

        XCTAssertEqual(horizontal.height, Ruler.thickness)
        XCTAssertEqual(vertical.width, Ruler.thickness)
        XCTAssertEqual(horizontal.width, horizontalLength, accuracy: 0.0001)
        XCTAssertEqual(vertical.height, verticalLength, accuracy: 0.0001)
        XCTAssertEqual(horizontal.minX, screenFrame.minX + 69.0, accuracy: 0.0001)
        XCTAssertEqual(vertical.minX, screenFrame.minX + 30.0, accuracy: 0.0001)
        XCTAssertEqual(horizontal.minY, screenFrame.maxY - 90.0, accuracy: 0.0001)
        XCTAssertEqual(vertical.maxY, horizontal.minY + 1.0, accuracy: 0.0001)
    }

    func testRulerCursorControllerChoosesCursorForActiveRulerEvents() {
        var appliedCursors: [RulerCursorController.CursorStyle] = []
        let controller = RulerCursorController { appliedCursors.append($0) }

        controller.applicationDidBecomeActive()
        controller.mouseEnteredRuler()
        controller.mouseDownInRuler()
        controller.mouseUpInRuler(mouseIsInsideRuler: true)
        controller.mouseExitedRuler()

        XCTAssertEqual(appliedCursors, [
            .crosshair,
            .openHand,
            .closedHand,
            .openHand,
            .crosshair,
        ])
    }

    func testRulerCursorControllerReturnsToCrosshairWhenDragEndsOutsideRuler() {
        var appliedCursors: [RulerCursorController.CursorStyle] = []
        let controller = RulerCursorController { appliedCursors.append($0) }

        controller.applicationDidBecomeActive()
        controller.mouseEnteredRuler()
        controller.mouseDownInRuler()
        controller.mouseExitedRuler()
        controller.mouseUpInRuler(mouseIsInsideRuler: false)

        XCTAssertEqual(appliedCursors, [
            .crosshair,
            .openHand,
            .closedHand,
            .crosshair,
        ])
    }

    func testRulerCursorControllerResetsWhenAppResignsActive() {
        var appliedCursors: [RulerCursorController.CursorStyle] = []
        let controller = RulerCursorController { appliedCursors.append($0) }

        controller.applicationDidBecomeActive()
        controller.mouseEnteredRuler()
        controller.mouseDownInRuler()
        controller.applicationDidResignActive()
        controller.applicationDidBecomeActive()

        XCTAssertEqual(appliedCursors, [
            .crosshair,
            .openHand,
            .closedHand,
            .arrow,
            .crosshair,
        ])
    }

    func testRulerCursorControllerTracksMouseOverMouseDownAndMouseOutActions() {
        var appliedCursors: [RulerCursorController.CursorStyle] = []
        let controller = RulerCursorController { appliedCursors.append($0) }

        func assertCursor(
            after actionName: String,
            _ action: () -> Void,
            is expectedCursor: RulerCursorController.CursorStyle,
            file: StaticString = #filePath,
            line: UInt = #line
        ) {
            action()
            XCTAssertEqual(controller.currentCursor, expectedCursor, actionName, file: file, line: line)
            XCTAssertEqual(appliedCursors.last, expectedCursor, actionName, file: file, line: line)
        }

        controller.applicationDidBecomeActive()
        XCTAssertEqual(controller.currentCursor, .crosshair)

        assertCursor(after: "mouse over ruler", {
            controller.mouseEnteredRuler()
        }, is: .openHand)

        assertCursor(after: "mouse down inside ruler", {
            controller.mouseDownInRuler()
        }, is: .closedHand)

        let appliedCursorCountBeforeMouseOut = appliedCursors.count
        controller.mouseExitedRuler()
        XCTAssertEqual(controller.currentCursor, .closedHand, "mouse out while dragging")
        XCTAssertEqual(appliedCursors.count, appliedCursorCountBeforeMouseOut, "mouse out while dragging")

        assertCursor(after: "mouse up outside ruler", {
            controller.mouseUpInRuler(mouseIsInsideRuler: false)
        }, is: .crosshair)

        assertCursor(after: "mouse over ruler again", {
            controller.mouseEnteredRuler()
        }, is: .openHand)

        assertCursor(after: "mouse down inside ruler again", {
            controller.mouseDownInRuler()
        }, is: .closedHand)

        assertCursor(after: "mouse up inside ruler", {
            controller.mouseUpInRuler(mouseIsInsideRuler: true)
        }, is: .openHand)

        assertCursor(after: "mouse out after release", {
            controller.mouseExitedRuler()
        }, is: .crosshair)
    }

    func testRulerCrosshairCursorUsesAliasedBitmapImage() throws {
        let cursor = RulerCursorController.CursorStyle.crosshair.nsCursor

        XCTAssertEqual(cursor.image.size, NSSize(width: 17, height: 17))
        XCTAssertEqual(cursor.hotSpot, NSPoint(x: 8.5, y: 8.5))
        XCTAssertFalse(cursor.image.isTemplate)

        let bitmap = try XCTUnwrap(
            cursor.image.representations.compactMap { $0 as? NSBitmapImageRep }.first
        )
        XCTAssertEqual(bitmap.pixelsWide, 34)
        XCTAssertEqual(bitmap.pixelsHigh, 34)
        assertPixel(atX: 16, y: 16, in: bitmap, equals: .black)
        assertPixel(atX: 17, y: 17, in: bitmap, equals: .black)
        assertPixel(atX: 2, y: 14, in: bitmap, equals: .white)
        assertPixel(atX: 14, y: 14, in: bitmap, equals: .white)
        assertPixel(atX: 0, y: 0, in: bitmap, equals: .clear)

        for y in 0..<bitmap.pixelsHigh {
            for x in 0..<bitmap.pixelsWide {
                let color = try XCTUnwrap(bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB))
                guard color.alphaComponent > 0 else { continue }

                XCTAssertEqual(color.alphaComponent, 1, accuracy: 0.0001)
                XCTAssertEqual(color.redComponent, color.redComponent.rounded(), accuracy: 0.0001)
                XCTAssertEqual(color.greenComponent, color.greenComponent.rounded(), accuracy: 0.0001)
                XCTAssertEqual(color.blueComponent, color.blueComponent.rounded(), accuracy: 0.0001)
            }
        }
    }

    func testMouseTickTimerPolicyRunsOnlyWhenRulersAreVisible() {
        let policy = MouseTickTimerPolicy(foregroundInterval: 1 / 60, backgroundInterval: 1 / 30)

        policy.applicationDidBecomeActive()
        XCTAssertNil(policy.desiredInterval)

        policy.updateVisibleRulers(true)
        XCTAssertEqual(policy.desiredInterval, 1 / 60)

        policy.applicationDidResignActive()
        XCTAssertEqual(policy.desiredInterval, 1 / 30)

        policy.updateVisibleRulers(false)
        XCTAssertNil(policy.desiredInterval)
    }

    func testMouseTickTimerPolicySuspendsUntilAllOwnersResume() {
        let policy = MouseTickTimerPolicy(foregroundInterval: 1 / 60, backgroundInterval: 1 / 30)
        let firstOwner = NSObject()
        let secondOwner = NSObject()

        policy.applicationDidBecomeActive()
        policy.updateVisibleRulers(true)

        policy.suspend(owner: firstOwner)
        policy.suspend(owner: secondOwner)
        XCTAssertNil(policy.desiredInterval)

        policy.resume(owner: firstOwner)
        XCTAssertNil(policy.desiredInterval)

        policy.resume(owner: secondOwner)
        XCTAssertEqual(policy.desiredInterval, 1 / 60)
    }

    func testMouseTickTimerPolicyKeepsSuspensionAcrossVisibilityChanges() {
        let policy = MouseTickTimerPolicy(foregroundInterval: 1 / 60, backgroundInterval: 1 / 30)
        let owner = NSObject()

        policy.applicationDidBecomeActive()
        policy.updateVisibleRulers(true)
        policy.suspend(owner: owner)

        policy.updateVisibleRulers(false)
        XCTAssertNil(policy.desiredInterval)

        policy.updateVisibleRulers(true)
        XCTAssertNil(policy.desiredInterval)

        policy.resume(owner: owner)
        XCTAssertEqual(policy.desiredInterval, 1 / 60)
    }

    func testMouseTickTimerPolicyClearsSuspensionWhenOwnerDeallocates() {
        let policy = MouseTickTimerPolicy(foregroundInterval: 1 / 60, backgroundInterval: 1 / 30)

        policy.applicationDidBecomeActive()
        policy.updateVisibleRulers(true)

        autoreleasepool {
            let owner = NSObject()
            policy.suspend(owner: owner)
            XCTAssertNil(policy.desiredInterval)
        }

        XCTAssertEqual(policy.desiredInterval, 1 / 60)
    }

    func testHorizontalResizeHandleFrameMathResizesOnlyWidthFromRightEdge() {
        let initialFrame = NSRect(x: 10, y: 20, width: 300, height: Ruler.thickness)
        let frame = resizedRulerFrame(
            orientation: .horizontal,
            initialFrame: initialFrame,
            delta: NSSize(width: 50, height: 25),
            minSize: NSSize(width: 200, height: Ruler.thickness),
            maxSize: NSSize(width: 4000, height: Ruler.thickness)
        )

        XCTAssertEqual(frame, NSRect(x: 10, y: 20, width: 350, height: Ruler.thickness))
    }

    func testHorizontalResizeHandleFrameMathClampsWidth() {
        let initialFrame = NSRect(x: 10, y: 20, width: 300, height: Ruler.thickness)
        let frame = resizedRulerFrame(
            orientation: .horizontal,
            initialFrame: initialFrame,
            delta: NSSize(width: -250, height: 0),
            minSize: NSSize(width: 200, height: Ruler.thickness),
            maxSize: NSSize(width: 4000, height: Ruler.thickness)
        )

        XCTAssertEqual(frame, NSRect(x: 10, y: 20, width: 200, height: Ruler.thickness))
    }

    func testVerticalResizeHandleFrameMathResizesOnlyHeightFromBottomEdge() {
        let initialFrame = NSRect(x: 10, y: 20, width: Ruler.thickness, height: 300)
        let frame = resizedRulerFrame(
            orientation: .vertical,
            initialFrame: initialFrame,
            delta: NSSize(width: 25, height: -50),
            minSize: NSSize(width: Ruler.thickness, height: 200),
            maxSize: NSSize(width: Ruler.thickness, height: 4000)
        )

        XCTAssertEqual(frame, NSRect(x: 10, y: -30, width: Ruler.thickness, height: 350))
        XCTAssertEqual(frame.maxY, initialFrame.maxY)
    }

    func testVerticalResizeHandleFrameMathClampsHeightWhileKeepingTopEdgeFixed() {
        let initialFrame = NSRect(x: 10, y: 20, width: Ruler.thickness, height: 300)
        let frame = resizedRulerFrame(
            orientation: .vertical,
            initialFrame: initialFrame,
            delta: NSSize(width: 0, height: 250),
            minSize: NSSize(width: Ruler.thickness, height: 200),
            maxSize: NSSize(width: Ruler.thickness, height: 4000)
        )

        XCTAssertEqual(frame, NSRect(x: 10, y: 120, width: Ruler.thickness, height: 200))
        XCTAssertEqual(frame.maxY, initialFrame.maxY)
    }

    func testHorizontalResizeHandleFrameMathCanResizeFromLeftEdge() {
        let initialFrame = NSRect(x: 10, y: 20, width: 300, height: Ruler.thickness)
        let frame = resizedRulerFrame(
            orientation: .horizontal,
            zeroCorner: .topRight,
            initialFrame: initialFrame,
            delta: NSSize(width: 50, height: 25),
            minSize: NSSize(width: 200, height: Ruler.thickness),
            maxSize: NSSize(width: 4000, height: Ruler.thickness)
        )

        XCTAssertEqual(frame, NSRect(x: 60, y: 20, width: 250, height: Ruler.thickness))
        XCTAssertEqual(frame.maxX, initialFrame.maxX)
    }

    func testVerticalResizeHandleFrameMathCanResizeFromTopEdge() {
        let initialFrame = NSRect(x: 10, y: 20, width: Ruler.thickness, height: 300)
        let frame = resizedRulerFrame(
            orientation: .vertical,
            zeroCorner: .bottomLeft,
            initialFrame: initialFrame,
            delta: NSSize(width: 25, height: 50),
            minSize: NSSize(width: Ruler.thickness, height: 200),
            maxSize: NSSize(width: Ruler.thickness, height: 4000)
        )

        XCTAssertEqual(frame, NSRect(x: 10, y: 20, width: Ruler.thickness, height: 350))
        XCTAssertEqual(frame.minY, initialFrame.minY)
    }

    func testHorizontalResizeHandleFrameMathClampsLeftEdgeResizesAroundRightEdge() {
        let initialFrame = NSRect(x: 10, y: 20, width: 300, height: Ruler.thickness)

        let minFrame = resizedRulerFrame(
            orientation: .horizontal,
            zeroCorner: .topRight,
            initialFrame: initialFrame,
            delta: NSSize(width: 250, height: 0),
            minSize: NSSize(width: 200, height: Ruler.thickness),
            maxSize: NSSize(width: 400, height: Ruler.thickness)
        )
        let maxFrame = resizedRulerFrame(
            orientation: .horizontal,
            zeroCorner: .topRight,
            initialFrame: initialFrame,
            delta: NSSize(width: -250, height: 0),
            minSize: NSSize(width: 200, height: Ruler.thickness),
            maxSize: NSSize(width: 400, height: Ruler.thickness)
        )

        XCTAssertEqual(minFrame, NSRect(x: 110, y: 20, width: 200, height: Ruler.thickness))
        XCTAssertEqual(maxFrame, NSRect(x: -90, y: 20, width: 400, height: Ruler.thickness))
        XCTAssertEqual(minFrame.maxX, initialFrame.maxX)
        XCTAssertEqual(maxFrame.maxX, initialFrame.maxX)
    }

    func testVerticalResizeHandleFrameMathClampsTopEdgeResizesAroundBottomEdge() {
        let initialFrame = NSRect(x: 10, y: 20, width: Ruler.thickness, height: 300)

        let minFrame = resizedRulerFrame(
            orientation: .vertical,
            zeroCorner: .bottomLeft,
            initialFrame: initialFrame,
            delta: NSSize(width: 0, height: -250),
            minSize: NSSize(width: Ruler.thickness, height: 200),
            maxSize: NSSize(width: Ruler.thickness, height: 400)
        )
        let maxFrame = resizedRulerFrame(
            orientation: .vertical,
            zeroCorner: .bottomLeft,
            initialFrame: initialFrame,
            delta: NSSize(width: 0, height: 250),
            minSize: NSSize(width: Ruler.thickness, height: 200),
            maxSize: NSSize(width: Ruler.thickness, height: 400)
        )

        XCTAssertEqual(minFrame, NSRect(x: 10, y: 20, width: Ruler.thickness, height: 200))
        XCTAssertEqual(maxFrame, NSRect(x: 10, y: 20, width: Ruler.thickness, height: 400))
        XCTAssertEqual(minFrame.minY, initialFrame.minY)
        XCTAssertEqual(maxFrame.minY, initialFrame.minY)
    }

    func testResizeHandlePositionsFollowFarOppositeCornerFromZeroCorner() {
        withRestoredZeroCornerPreference {
            let cases: [
                (
                    zeroCorner: ZeroCorner,
                    expectedHorizontalXSide: RulerHorizontalSide,
                    expectedVerticalYSide: RulerVerticalSide
                )
            ] = [
                (.topLeft, .right, .bottom),
                (.topRight, .left, .bottom),
                (.bottomLeft, .right, .top),
                (.bottomRight, .left, .top),
            ]

            for testCase in cases {
                prefs.zeroCorner = testCase.zeroCorner
                let horizontalRule = HorizontalRule(
                    frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness)
                )
                let verticalRule = VerticalRule(
                    frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300)
                )

                guard let horizontalFrame = horizontalRule.resizeHandleExclusionFrame,
                      let verticalFrame = verticalRule.resizeHandleExclusionFrame else {
                    XCTFail("Expected both rulers to install resize handles for \(testCase.zeroCorner)")
                    continue
                }

                switch testCase.expectedHorizontalXSide {
                case .left:
                    XCTAssertLessThan(horizontalFrame.midX, horizontalRule.bounds.midX, "\(testCase.zeroCorner)")
                case .right:
                    XCTAssertGreaterThan(horizontalFrame.midX, horizontalRule.bounds.midX, "\(testCase.zeroCorner)")
                }

                XCTAssertEqual(horizontalFrame.minY, horizontalRule.bounds.minY, "\(testCase.zeroCorner)")
                XCTAssertEqual(horizontalFrame.maxY, horizontalRule.bounds.maxY, "\(testCase.zeroCorner)")
                XCTAssertEqual(verticalFrame.minX, verticalRule.bounds.minX, "\(testCase.zeroCorner)")
                XCTAssertEqual(verticalFrame.maxX, verticalRule.bounds.maxX, "\(testCase.zeroCorner)")

                switch testCase.expectedVerticalYSide {
                case .top:
                    XCTAssertGreaterThan(verticalFrame.midY, verticalRule.bounds.midY, "\(testCase.zeroCorner)")
                case .bottom:
                    XCTAssertLessThan(verticalFrame.midY, verticalRule.bounds.midY, "\(testCase.zeroCorner)")
                }
            }
        }
    }

    func testPreferenceRedrawUpdatesResizeHandleFrameForZeroCornerChanges() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topLeft
            let rule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))
            guard let initialFrame = rule.resizeHandleExclusionFrame else {
                return XCTFail("Expected horizontal ruler to install a resize handle")
            }

            prefs.zeroCorner = .topRight
            rule.redrawForPreferenceChange()
            guard let flippedFrame = rule.resizeHandleExclusionFrame else {
                return XCTFail("Expected horizontal ruler to keep its resize handle")
            }

            XCTAssertGreaterThan(initialFrame.midX, rule.bounds.midX)
            XCTAssertLessThan(flippedFrame.midX, rule.bounds.midX)
        }
    }

    func testResizeHandleCursorsUseCustomCenteredImages() {
        let horizontalCursor = windowResizeCursor(for: .horizontal)
        let verticalCursor = windowResizeCursor(for: .vertical)

        XCTAssertEqual(horizontalCursor.image.size, NSSize(width: 21, height: 15))
        XCTAssertEqual(verticalCursor.image.size, NSSize(width: 15, height: 21))
        XCTAssertEqual(horizontalCursor.hotSpot, NSPoint(x: 10, y: 7))
        XCTAssertEqual(verticalCursor.hotSpot, NSPoint(x: 7, y: 10))
        XCTAssertFalse(horizontalCursor.image.isTemplate)
        XCTAssertFalse(verticalCursor.image.isTemplate)
    }

    func testHorizontalResizeHandleFramePinsToLeftEdgeSlot() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topRight

            let resizeHandle = ResizeHandleView(orientation: .horizontal, color: RulerColors())
            let frame = resizeHandle.frame(in: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))

            XCTAssertEqual(frame.minX, 0)
        }
    }

    func testHorizontalMouseTickLabelFlipsBeforeResizeHandleWithoutPinning() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topLeft

            let rule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))
            let labelSize = CGSize(width: 30, height: 10)
            let rulerSize = rule.bounds.size
            guard let resizeHandleFrame = rule.resizeHandleExclusionFrame else {
                return XCTFail("Expected horizontal ruler to install a resize handle")
            }
            let tickLabelSpacing: CGFloat = 5
            let mouseTickJustPastRightHandleFit = resizeHandleFrame.minX - labelSize.width - tickLabelSpacing + 1
            let mouseTickNearRightEdge: CGFloat = 290

            let labelJustPastRightHandleFit = rule.mouseNumberLabelRect(
                tickX: mouseTickJustPastRightHandleFit,
                labelSize: labelSize,
                rulerSize: rulerSize
            )
            let labelRect = rule.mouseNumberLabelRect(
                tickX: mouseTickNearRightEdge,
                labelSize: labelSize,
                rulerSize: rulerSize
            )

            XCTAssertLessThan(labelJustPastRightHandleFit.maxX, mouseTickJustPastRightHandleFit)
            XCTAssertLessThanOrEqual(labelJustPastRightHandleFit.maxX, resizeHandleFrame.minX)
            XCTAssertEqual(
                mouseTickJustPastRightHandleFit - labelJustPastRightHandleFit.maxX,
                tickLabelSpacing,
                accuracy: 0.0001
            )
            XCTAssertLessThan(labelRect.maxX, mouseTickNearRightEdge)
            XCTAssertEqual(
                mouseTickNearRightEdge - labelRect.maxX,
                tickLabelSpacing,
                accuracy: 0.0001
            )
        }
    }

    func testHorizontalMouseTickLabelFlipsBeforeRightUnitLabel() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topRight

            let rule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))
            let labelSize = CGSize(width: 30, height: 10)
            let tickLabelSpacing: CGFloat = 5
            let unitLabelFlipPadding: CGFloat = 3
            guard let unitLabelFrame = rule.unitLabelFrame else {
                return XCTFail("Expected horizontal ruler to install a unit label")
            }
            let mouseTickAtRightUnitFit = unitLabelFrame.minX - unitLabelFlipPadding - labelSize.width - tickLabelSpacing
            let mouseTickJustPastRightUnitFit = mouseTickAtRightUnitFit + 1

            let fittingLabelRect = rule.mouseNumberLabelRect(
                tickX: mouseTickAtRightUnitFit,
                labelSize: labelSize,
                rulerSize: rule.bounds.size
            )
            let flippedLabelRect = rule.mouseNumberLabelRect(
                tickX: mouseTickJustPastRightUnitFit,
                labelSize: labelSize,
                rulerSize: rule.bounds.size
            )

            XCTAssertGreaterThan(fittingLabelRect.minX, mouseTickAtRightUnitFit)
            XCTAssertEqual(
                fittingLabelRect.maxX,
                unitLabelFrame.minX - unitLabelFlipPadding,
                accuracy: 0.0001
            )
            XCTAssertLessThan(flippedLabelRect.maxX, mouseTickJustPastRightUnitFit)
            XCTAssertEqual(
                mouseTickJustPastRightUnitFit - flippedLabelRect.maxX,
                tickLabelSpacing,
                accuracy: 0.0001
            )
        }
    }

    func testHorizontalMouseTickLabelStaysOnPreferredSideNearLeftResizeEnd() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .bottomRight

            let rule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 600, height: Ruler.thickness))
            let labelSize = CGSize(width: 30, height: 10)
            let tickLabelSpacing: CGFloat = 5
            guard let resizeHandleFrame = rule.resizeHandleExclusionFrame else {
                return XCTFail("Expected horizontal ruler to install a resize handle")
            }
            let mouseTickInsideLeftResizeEnd = resizeHandleFrame.maxX - tickLabelSpacing - 1

            let labelRect = rule.mouseNumberLabelRect(
                tickX: mouseTickInsideLeftResizeEnd,
                labelSize: labelSize,
                rulerSize: rule.bounds.size
            )

            XCTAssertGreaterThan(labelRect.minX, mouseTickInsideLeftResizeEnd)
            XCTAssertEqual(
                labelRect.minX - mouseTickInsideLeftResizeEnd,
                tickLabelSpacing,
                accuracy: 0.0001
            )
        }
    }

    func testHorizontalMouseTickLabelClampsToRulerStart() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topLeft

            let rule = HorizontalRule(frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness))
            let labelSize = CGSize(width: 30, height: 10)
            let rulerSize = rule.bounds.size
            let mouseTickNearLeftEdge: CGFloat = -10

            let labelRect = rule.mouseNumberLabelRect(
                tickX: mouseTickNearLeftEdge,
                labelSize: labelSize,
                rulerSize: rulerSize
            )

            XCTAssertEqual(
                labelRect.minX,
                0,
                accuracy: 0.0001
            )
        }
    }

    func testVerticalMouseTickLabelStaysOnPreferredSideNearTopResizeEnd() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .bottomLeft

            let rule = VerticalRule(frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))
            let labelSize = CGSize(width: 20, height: 10)
            let tickLabelSpacing: CGFloat = 4
            guard let resizeHandleFrame = rule.resizeHandleExclusionFrame else {
                return XCTFail("Expected vertical ruler to install a resize handle")
            }
            let mouseTickInsideTopResizeEnd = resizeHandleFrame.minY + tickLabelSpacing + 1

            let labelRect = rule.mouseNumberLabelRect(
                tickY: mouseTickInsideTopResizeEnd,
                labelSize: labelSize,
                rulerSize: rule.bounds.size
            )

            XCTAssertLessThan(labelRect.maxY, mouseTickInsideTopResizeEnd)
            XCTAssertEqual(
                mouseTickInsideTopResizeEnd - labelRect.maxY,
                tickLabelSpacing,
                accuracy: 0.0001
            )
        }
    }

    func testVerticalMouseTickLabelFlipsBeforeBottomUnitLabel() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .bottomLeft

            let rule = VerticalRule(frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))
            let labelSize = CGSize(width: 20, height: 10)
            let tickLabelSpacing: CGFloat = 4
            let unitLabelFlipPadding: CGFloat = 3
            guard let unitLabelFrame = rule.unitLabelFrame else {
                return XCTFail("Expected vertical ruler to install a unit label")
            }
            let mouseTickAtBottomUnitFit = unitLabelFrame.maxY
                + unitLabelFlipPadding
                + tickLabelSpacing
                + labelSize.height
            let mouseTickJustPastBottomUnitFit = mouseTickAtBottomUnitFit - 1

            let fittingLabelRect = rule.mouseNumberLabelRect(
                tickY: mouseTickAtBottomUnitFit,
                labelSize: labelSize,
                rulerSize: rule.bounds.size
            )
            let flippedLabelRect = rule.mouseNumberLabelRect(
                tickY: mouseTickJustPastBottomUnitFit,
                labelSize: labelSize,
                rulerSize: rule.bounds.size
            )

            XCTAssertLessThan(fittingLabelRect.maxY, mouseTickAtBottomUnitFit)
            XCTAssertEqual(
                fittingLabelRect.minY,
                unitLabelFrame.maxY + unitLabelFlipPadding,
                accuracy: 0.0001
            )
            XCTAssertGreaterThan(flippedLabelRect.minY, mouseTickJustPastBottomUnitFit)
            XCTAssertEqual(
                flippedLabelRect.minY - mouseTickJustPastBottomUnitFit,
                tickLabelSpacing,
                accuracy: 0.0001
            )
        }
    }

    func testVerticalMouseTickLabelStaysWithinRulerEnds() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topLeft

            let rule = VerticalRule(frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300))
            let labelSize = CGSize(width: 20, height: 10)
            let rulerSize = rule.bounds.size

            let labelNearBottom = rule.mouseNumberLabelRect(
                tickY: 1,
                labelSize: labelSize,
                rulerSize: rulerSize
            )
            XCTAssertEqual(
                labelNearBottom.minY,
                5,
                accuracy: 0.0001
            )

            let labelNearTop = rule.mouseNumberLabelRect(
                tickY: 299,
                labelSize: labelSize,
                rulerSize: rulerSize
            )
            XCTAssertEqual(
                labelNearTop.minY,
                285,
                accuracy: 0.0001
            )
        }
    }

    func testResizeHandleDisablesWindowBackgroundDraggingDuringResizeDrag() {
        let window = oneWingRulerWindow(
            orientation: .horizontal,
            frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness)
        )
        guard let resizeHandle = resizeHandle(in: window.horizontalRule) else {
            return XCTFail("Expected horizontal ruler to install a resize handle")
        }

        XCTAssertTrue(window.isMovableByWindowBackground)

        let mouseDownEvent = NSEvent.mouseEvent(
            with: .leftMouseDown,
            location: resizeHandle.convert(NSPoint(x: 1, y: 1), to: nil),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: window.windowNumber,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 1
        )!
        let mouseUpEvent = NSEvent.mouseEvent(
            with: .leftMouseUp,
            location: resizeHandle.convert(NSPoint(x: 1, y: 1), to: nil),
            modifierFlags: [],
            timestamp: 0.1,
            windowNumber: window.windowNumber,
            context: nil,
            eventNumber: 1,
            clickCount: 1,
            pressure: 0
        )!

        resizeHandle.mouseDown(with: mouseDownEvent)
        XCTAssertFalse(window.isMovableByWindowBackground)

        resizeHandle.mouseUp(with: mouseUpEvent)
        XCTAssertTrue(window.isMovableByWindowBackground)
    }

    func testResizeHandleDetachesChildWindowsDuringResizeDrag() {
        let childWindow = oneWingRulerWindow(
            orientation: .vertical,
            frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 300)
        )
        let window = oneWingRulerWindow(
            orientation: .horizontal,
            frame: NSRect(x: 0, y: 0, width: 300, height: Ruler.thickness)
        )
        window.addChildWindow(childWindow, ordered: .below)
        guard let resizeHandle = resizeHandle(in: window.horizontalRule) else {
            return XCTFail("Expected horizontal ruler to install a resize handle")
        }
        let location = resizeHandle.convert(NSPoint(x: 1, y: 1), to: nil)

        resizeHandle.mouseDown(with: mouseEvent(
            type: .leftMouseDown,
            location: location,
            windowNumber: window.windowNumber,
            timestamp: 0
        ))

        XCTAssertFalse(window.childWindows?.contains(childWindow) ?? false)

        resizeHandle.mouseUp(with: mouseEvent(
            type: .leftMouseUp,
            location: location,
            windowNumber: window.windowNumber,
            timestamp: 0.1
        ))

        XCTAssertTrue(window.childWindows?.contains(childWindow) ?? false)
    }

    func testHorizontalResizeHandleDragKeepsLeftAndTopEdgesFixed() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topLeft

            let initialFrame = NSRect(x: 100, y: 200, width: 300, height: Ruler.thickness)
            let window = oneWingRulerWindow(orientation: .horizontal, frame: initialFrame)
            guard let resizeHandle = resizeHandle(in: window.horizontalRule) else {
                return XCTFail("Expected horizontal ruler to install a resize handle")
            }

            let startLocation = resizeHandle.convert(
                NSPoint(x: resizeHandle.bounds.minX + 1, y: resizeHandle.bounds.midY),
                to: nil
            )
            let mouseDownEvent = mouseEvent(
                type: .leftMouseDown,
                location: startLocation,
                windowNumber: window.windowNumber,
                timestamp: 0
            )

            resizeHandle.mouseDown(with: mouseDownEvent)

            let dragOffsets = [
                NSSize(width: -40, height: 0),
                NSSize(width: 80, height: 0),
                NSSize(width: 0, height: 30),
                NSSize(width: 0, height: -30),
            ]

            for (index, offset) in dragOffsets.enumerated() {
                let dragEvent = mouseEvent(
                    type: .leftMouseDragged,
                    location: NSPoint(x: startLocation.x + offset.width, y: startLocation.y + offset.height),
                    windowNumber: window.windowNumber,
                    timestamp: TimeInterval(index + 1) * 0.1
                )

                resizeHandle.mouseDragged(with: dragEvent)

                XCTAssertEqual(window.frame.minX, initialFrame.minX, "left edge moved for drag offset \(offset)")
                XCTAssertEqual(window.frame.maxY, initialFrame.maxY, "top edge moved for drag offset \(offset)")
            }

            let mouseUpEvent = mouseEvent(
                type: .leftMouseUp,
                location: startLocation,
                windowNumber: window.windowNumber,
                timestamp: 1
            )
            resizeHandle.mouseUp(with: mouseUpEvent)
        }
    }

    func testResizeHandleDragUsesRuleZeroCornerOverride() {
        withRestoredZeroCornerPreference {
            prefs.zeroCorner = .topLeft

            let horizontalInitialFrame = NSRect(x: 100, y: 200, width: 300, height: Ruler.thickness)
            let horizontalWindow = oneWingRulerWindow(
                orientation: .horizontal,
                frame: horizontalInitialFrame,
                settings: RulerSettings(zeroCorner: .topRight)
            )
            defer { horizontalWindow.close() }
            guard let horizontalResizeHandle = resizeHandle(in: horizontalWindow.horizontalRule) else {
                return XCTFail("Expected horizontal ruler to install a resize handle")
            }

            let horizontalStartLocation = horizontalResizeHandle.convert(
                NSPoint(x: horizontalResizeHandle.bounds.minX + 1, y: horizontalResizeHandle.bounds.midY),
                to: nil
            )
            horizontalResizeHandle.mouseDown(with: mouseEvent(
                type: .leftMouseDown,
                location: horizontalStartLocation,
                windowNumber: horizontalWindow.windowNumber,
                timestamp: 0
            ))
            horizontalResizeHandle.mouseDragged(with: mouseEvent(
                type: .leftMouseDragged,
                location: NSPoint(x: horizontalStartLocation.x + 50, y: horizontalStartLocation.y),
                windowNumber: horizontalWindow.windowNumber,
                timestamp: 0.1
            ))

            XCTAssertEqual(horizontalWindow.frame.maxX, horizontalInitialFrame.maxX)
            XCTAssertEqual(horizontalWindow.frame.minX, horizontalInitialFrame.minX + 50)
            XCTAssertEqual(horizontalWindow.frame.width, horizontalInitialFrame.width - 50)

            horizontalResizeHandle.mouseUp(with: mouseEvent(
                type: .leftMouseUp,
                location: horizontalStartLocation,
                windowNumber: horizontalWindow.windowNumber,
                timestamp: 0.2
            ))

            let verticalInitialFrame = NSRect(x: 300, y: 200, width: Ruler.thickness, height: 300)
            let verticalWindow = oneWingRulerWindow(
                orientation: .vertical,
                frame: verticalInitialFrame,
                settings: RulerSettings(zeroCorner: .bottomLeft)
            )
            defer { verticalWindow.close() }
            guard let verticalResizeHandle = resizeHandle(in: verticalWindow.verticalRule) else {
                return XCTFail("Expected vertical ruler to install a resize handle")
            }

            let verticalStartLocation = verticalResizeHandle.convert(
                NSPoint(x: verticalResizeHandle.bounds.midX, y: verticalResizeHandle.bounds.midY),
                to: nil
            )
            verticalResizeHandle.mouseDown(with: mouseEvent(
                type: .leftMouseDown,
                location: verticalStartLocation,
                windowNumber: verticalWindow.windowNumber,
                timestamp: 0.3
            ))
            verticalResizeHandle.mouseDragged(with: mouseEvent(
                type: .leftMouseDragged,
                location: NSPoint(x: verticalStartLocation.x, y: verticalStartLocation.y - 50),
                windowNumber: verticalWindow.windowNumber,
                timestamp: 0.4
            ))

            XCTAssertEqual(verticalWindow.frame.minY, verticalInitialFrame.minY)
            XCTAssertEqual(verticalWindow.frame.maxY, verticalInitialFrame.maxY - 50)
            XCTAssertEqual(verticalWindow.frame.height, verticalInitialFrame.height - 50)

            verticalResizeHandle.mouseUp(with: mouseEvent(
                type: .leftMouseUp,
                location: verticalStartLocation,
                windowNumber: verticalWindow.windowNumber,
                timestamp: 0.5
            ))
        }
    }

    func testPrimaryRulerHotkeysToggleWingVisibilityWithoutLegacyWindows() {
        withRestoredZeroCornerPreference {
            let previousGroupRulers = prefs.groupRulers
            defer { prefs.groupRulers = previousGroupRulers }

            prefs.zeroCorner = .topLeft
            prefs.groupRulers = true
            let appDelegate = AppDelegate()

            XCTAssertTrue(
                appDelegate.performRulerHotkey(
                    keyCode: kVK_ANSI_H,
                    modifierFlags: [],
                    sender: appDelegate
                )
            )

            let rulerWindow = appDelegate.rulerManager.activeController?.rulerWindow
            XCTAssertTrue(prefs.groupRulers)
            XCTAssertFalse(rulerWindow?.isRuleVisible(.horizontal) ?? true)
            XCTAssertTrue(rulerWindow?.isRuleVisible(.vertical) ?? false)
            rulerWindow?.orderOut(self)
        }
    }

    func testManagedGroupHotkeyTogglesGroupedDraggingMode() {
        withRestoredRulerPreferences {
            prefs.groupRulers = false
            let appDelegate = AppDelegate()
            let controller = appDelegate.rulerManager.createRuler()
            defer {
                controller.hide()
            }

            XCTAssertTrue(
                appDelegate.performRulerHotkey(
                    keyCode: kVK_ANSI_G,
                    modifierFlags: [],
                    sender: controller
                )
            )
            XCTAssertTrue(prefs.groupRulers)

            XCTAssertTrue(
                appDelegate.performRulerHotkey(
                    keyCode: kVK_ANSI_G,
                    modifierFlags: [],
                    sender: controller
                )
            )
            XCTAssertFalse(prefs.groupRulers)
        }
    }

    func testCommandGraveCyclesManagedRulers() {
        let appDelegate = AppDelegate()
        let first = appDelegate.rulerManager.createRuler()
        let second = appDelegate.rulerManager.createRuler()
        defer {
            first.hide()
            second.hide()
        }
        first.show()
        second.show()
        appDelegate.rulerManager.markActive(first)

        XCTAssertTrue(
            appDelegate.performRulerHotkey(
                keyCode: kVK_ANSI_Grave,
                modifierFlags: .command,
                sender: first
            )
        )

        XCTAssertTrue(appDelegate.rulerManager.activeController === second)
    }

    func testManagedWingHotkeysAffectOnlyActiveRuler() {
        let appDelegate = AppDelegate()
        let first = appDelegate.rulerManager.createRuler()
        let second = appDelegate.rulerManager.createRuler()
        defer {
            first.hide()
            second.hide()
        }

        appDelegate.rulerManager.markActive(first)

        XCTAssertTrue(
            appDelegate.performRulerHotkey(
                keyCode: kVK_ANSI_H,
                modifierFlags: [],
                sender: first
            )
        )

        XCTAssertFalse(first.rulerWindow.isRuleVisible(.horizontal))
        XCTAssertTrue(first.rulerWindow.isRuleVisible(.vertical))
        XCTAssertTrue(second.rulerWindow.isRuleVisible(.horizontal))
        XCTAssertTrue(second.rulerWindow.isRuleVisible(.vertical))
    }

    func testManagedCommandsApplySettingsToActiveRulerOnly() {
        withRestoredRulerPreferences {
            prefs.unit = .pixels
            prefs.floatRulers = true
            prefs.rulerShadow = false
            let appDelegate = AppDelegate()
            let first = appDelegate.rulerManager.createRuler(
                defaults: RulerSettings(unit: .pixels, floatRulers: true, rulerShadow: false)
            )
            let second = appDelegate.rulerManager.createRuler(
                defaults: RulerSettings(unit: .millimeters, floatRulers: true, rulerShadow: false)
            )
            defer {
                first.hide()
                second.hide()
            }

            appDelegate.rulerManager.markActive(first)
            appDelegate.setUnitInches(self)
            appDelegate.toggleFloatRulers(self)
            appDelegate.toggleRulerShadow(self)

            XCTAssertEqual(first.state.settings.unit, .inches)
            XCTAssertFalse(first.state.settings.floatRulers)
            XCTAssertTrue(first.state.settings.rulerShadow)
            XCTAssertEqual(first.rulerWindow.horizontalRule.unit, .inches)
            XCTAssertFalse(first.rulerWindow.isFloatingPanel)
            XCTAssertTrue(first.rulerWindow.hasShadow)
            XCTAssertEqual(second.state.settings.unit, .millimeters)
            XCTAssertTrue(second.state.settings.floatRulers)
            XCTAssertFalse(second.state.settings.rulerShadow)
            XCTAssertEqual(prefs.unit, .pixels)
            XCTAssertTrue(prefs.floatRulers)
            XCTAssertFalse(prefs.rulerShadow)
        }
    }

    func testManagedFlipAndResetUseActiveRulerWithoutChangingDefaults() {
        withRestoredRulerPreferences {
            withRestoredRulerSetState {
                prefs.zeroCorner = .topRight
                let appDelegate = AppDelegate()
                let first = appDelegate.rulerManager.createRuler(
                    defaults: RulerSettings(zeroCorner: .bottomLeft)
                )
                let second = appDelegate.rulerManager.createRuler(
                    defaults: RulerSettings(zeroCorner: .topLeft)
                )
                defer {
                    first.hide()
                    second.hide()
                }

                second.setWing(.vertical, isVisible: false)
                appDelegate.rulerManager.markActive(second)
                appDelegate.flipRulers(along: .horizontal)

                XCTAssertEqual(second.state.settings.zeroCorner, .topRight)
                XCTAssertEqual(second.rulerWindow.horizontalRule.zeroCorner, .topRight)
                XCTAssertEqual(first.state.settings.zeroCorner, .bottomLeft)
                XCTAssertEqual(prefs.zeroCorner, .topRight)

                appDelegate.resetRulerPositions(self)

                XCTAssertEqual(second.state.settings.zeroCorner, Prefs.defaultZeroCorner)
                XCTAssertTrue(second.state.isWingVisible(.horizontal))
                XCTAssertTrue(second.state.isWingVisible(.vertical))
                XCTAssertEqual(first.state.settings.zeroCorner, .bottomLeft)
                XCTAssertEqual(prefs.zeroCorner, .topRight)

                let restoredState = prefs.loadRulerSetState()
                let savedSecond = restoredState?.rulers.first { $0.id == second.state.id }
                XCTAssertEqual(restoredState?.activeRulerID, second.state.id)
                XCTAssertEqual(savedSecond?.settings.zeroCorner, Prefs.defaultZeroCorner)
                XCTAssertTrue(savedSecond?.visibility.showsHorizontal ?? false)
                XCTAssertTrue(savedSecond?.visibility.showsVertical ?? false)
            }
        }
    }

    func testManagedWingCommandsDoNotHideLastVisibleWing() {
        let appDelegate = AppDelegate()
        let controller = appDelegate.rulerManager.createRuler()
        defer {
            controller.hide()
        }

        appDelegate.rulerManager.markActive(controller)
        controller.setWing(.vertical, isVisible: false)
        appDelegate.toggleHorizontalRuler(self)

        XCTAssertTrue(controller.state.isWingVisible(.horizontal))
        XCTAssertFalse(controller.state.isWingVisible(.vertical))
    }

    func testManagedMenuValidationReflectsActiveRulerState() {
        let appDelegate = AppDelegate()
        let controller = appDelegate.rulerManager.createRuler()
        defer {
            controller.hide()
        }
        appDelegate.rulerManager.markActive(controller)
        controller.setWing(.vertical, isVisible: false)

        let closeItem = NSMenuItem(
            title: "",
            action: #selector(AppDelegate.closeKeyWindow(_:)),
            keyEquivalent: ""
        )
        let horizontalItem = NSMenuItem(
            title: "",
            action: #selector(AppDelegate.toggleHorizontalRuler(_:)),
            keyEquivalent: ""
        )
        let verticalItem = NSMenuItem(
            title: "",
            action: #selector(AppDelegate.toggleVerticalRuler(_:)),
            keyEquivalent: ""
        )
        let groupItem = NSMenuItem(
            title: "",
            action: #selector(AppDelegate.toggleGroupRulers(_:)),
            keyEquivalent: ""
        )

        XCTAssertTrue(appDelegate.validateMenuItem(closeItem))
        XCTAssertFalse(appDelegate.validateMenuItem(horizontalItem))
        XCTAssertTrue(appDelegate.validateMenuItem(verticalItem))
        XCTAssertTrue(appDelegate.validateMenuItem(groupItem))
    }

    func testManagedMenuValidationDisablesWingCommandsWithoutActiveRuler() {
        let appDelegate = AppDelegate()
        let horizontalItem = NSMenuItem(
            title: "",
            action: #selector(AppDelegate.toggleHorizontalRuler(_:)),
            keyEquivalent: ""
        )
        let verticalItem = NSMenuItem(
            title: "",
            action: #selector(AppDelegate.toggleVerticalRuler(_:)),
            keyEquivalent: ""
        )

        XCTAssertFalse(appDelegate.validateMenuItem(horizontalItem))
        XCTAssertEqual(horizontalItem.title, "Show Horizontal Ruler")
        XCTAssertFalse(appDelegate.validateMenuItem(verticalItem))
        XCTAssertEqual(verticalItem.title, "Show Vertical Ruler")
    }

    func testShiftHotkeysFlipActiveRulerOrigin() {
        let appDelegate = AppDelegate()
        let controller = appDelegate.rulerManager.createRuler(
            defaults: RulerSettings(zeroCorner: .topLeft)
        )
        defer {
            controller.hide()
        }

        XCTAssertTrue(
            appDelegate.performRulerHotkey(
                keyCode: kVK_ANSI_H,
                modifierFlags: .shift,
                sender: controller
            )
        )
        XCTAssertEqual(controller.state.settings.zeroCorner, .topRight)

        XCTAssertTrue(
            appDelegate.performRulerHotkey(
                keyCode: kVK_ANSI_V,
                modifierFlags: .shift,
                sender: controller
            )
        )
        XCTAssertEqual(controller.state.settings.zeroCorner, .bottomRight)
    }

    func testShiftHotkeysIgnoreCapsLock() {
        let appDelegate = AppDelegate()
        let controller = appDelegate.rulerManager.createRuler(
            defaults: RulerSettings(zeroCorner: .topLeft)
        )
        defer {
            controller.hide()
        }

        XCTAssertTrue(
            appDelegate.performRulerHotkey(
                keyCode: kVK_ANSI_H,
                modifierFlags: [.shift, .capsLock],
                sender: controller
            )
        )
        XCTAssertEqual(controller.state.settings.zeroCorner, .topRight)
    }

    func testNonShiftModifiedRulerHotkeysAreIgnored() {
        let appDelegate = AppDelegate()

        XCTAssertFalse(
            appDelegate.performRulerHotkey(
                keyCode: kVK_ANSI_H,
                modifierFlags: .option,
                sender: self
            )
        )
    }

    private func mouseEvent(
        type: NSEvent.EventType,
        location: NSPoint,
        windowNumber: Int,
        timestamp: TimeInterval
    ) -> NSEvent {
        return NSEvent.mouseEvent(
            with: type,
            location: location,
            modifierFlags: [],
            timestamp: timestamp,
            windowNumber: windowNumber,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: type == .leftMouseUp ? 0 : 1
        )!
    }

    private func withRestoredRulerColorPreference(_ test: () throws -> Void) rethrows {
        let previousColor = prefs.rulerColor
        let previousDomainValue = persistentPreferenceValue(forKey: "rulerColor")

        defer {
            prefs.rulerColor = previousColor
            restorePersistentPreferenceValue(previousDomainValue, forKey: "rulerColor")
        }

        try test()
    }

    private func withRestoredZeroCornerPreference(_ test: () throws -> Void) rethrows {
        let previousZeroCorner = prefs.zeroCorner
        let previousDomainValue = persistentPreferenceValue(forKey: "zeroCorner")

        defer {
            prefs.zeroCorner = previousZeroCorner
            restorePersistentPreferenceValue(previousDomainValue, forKey: "zeroCorner")
        }

        try test()
    }

    private func withRestoredRulerPreferences(_ test: () throws -> Void) rethrows {
        let previousUnit = prefs.unit
        let previousColor = prefs.rulerColor
        let previousForegroundOpacity = prefs.foregroundOpacity
        let previousBackgroundOpacity = prefs.backgroundOpacity
        let previousFloatRulers = prefs.floatRulers
        let previousGroupRulers = prefs.groupRulers
        let previousRulerShadow = prefs.rulerShadow
        let previousZeroCorner = prefs.zeroCorner
        let previousDefaultHorizontalLength = prefs.defaultHorizontalLength
        let previousDefaultVerticalLength = prefs.defaultVerticalLength

        defer {
            prefs.unit = previousUnit
            prefs.rulerColor = previousColor
            prefs.foregroundOpacity = previousForegroundOpacity
            prefs.backgroundOpacity = previousBackgroundOpacity
            prefs.floatRulers = previousFloatRulers
            prefs.groupRulers = previousGroupRulers
            prefs.rulerShadow = previousRulerShadow
            prefs.zeroCorner = previousZeroCorner
            prefs.defaultHorizontalLength = previousDefaultHorizontalLength
            prefs.defaultVerticalLength = previousDefaultVerticalLength
        }

        try test()
    }

    private func keyDownEvent(characters: String, keyCode: UInt16) -> NSEvent {
        return NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: characters,
            charactersIgnoringModifiers: characters,
            isARepeat: false,
            keyCode: keyCode
        )!
    }

    private func assertRulerSettingsColorPanelAttachesToSettingsPanel(
        zeroCorner: ZeroCorner,
        openingColorPanel: (RulerSettingsController, NSWindow) -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let controller = RulerController(
            state: RulerInstanceState(
                settings: RulerSettings(zeroCorner: zeroCorner),
                layout: RulerLayoutState(
                    zeroPoint: NSPoint(x: 240, y: 320),
                    horizontalLength: 260,
                    verticalLength: 180
                )
            )
        )
        let settingsController = RulerSettingsController(rulerController: controller)
        let colorPanel = NSColorPanel.shared
        closeRulerColorPanel()
        let originalColorPanelFrame = colorPanel.frame
        defer {
            settingsController.close()
            controller.hide()
            closeRulerColorPanel()
            colorPanel.setFrame(originalColorPanelFrame, display: false)
        }

        guard let settingsWindow = settingsController.window else {
            XCTFail("Expected settings window", file: file, line: line)
            return
        }

        let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 900)
        settingsWindow.setFrame(
            NSRect(
                x: visibleFrame.minX + 60,
                y: visibleFrame.maxY - 340,
                width: 320,
                height: 300
            ),
            display: false
        )
        settingsWindow.orderFront(self)

        let colorPanelSize = colorPanel.frame.size
        let expectedFrame = settingsWindow.screen?.visibleFrame ?? colorPanel.screen?.visibleFrame
        let expectedX: CGFloat
        let expectedMaxY: CGFloat
        if let expectedFrame = expectedFrame {
            var expectedTopLeft = expectedColorPanelTopLeftPoint(
                colorPanelSize: colorPanelSize,
                settingsFrame: settingsWindow.frame,
                zeroCorner: zeroCorner
            )
            if expectedTopLeft.x < expectedFrame.minX {
                expectedTopLeft.x = min(settingsWindow.frame.maxX + 8, expectedFrame.maxX - colorPanelSize.width)
            } else if expectedTopLeft.x + colorPanelSize.width > expectedFrame.maxX {
                expectedTopLeft.x = max(settingsWindow.frame.minX - colorPanelSize.width - 8, expectedFrame.minX)
            }
            if colorPanelSize.height <= expectedFrame.height {
                expectedTopLeft.y = min(
                    max(expectedTopLeft.y, expectedFrame.minY + colorPanelSize.height),
                    expectedFrame.maxY
                )
            } else {
                expectedTopLeft.y = expectedFrame.maxY
            }
            expectedX = expectedTopLeft.x
            expectedMaxY = expectedTopLeft.y
        } else {
            let expectedTopLeft = expectedColorPanelTopLeftPoint(
                colorPanelSize: colorPanelSize,
                settingsFrame: settingsWindow.frame,
                zeroCorner: zeroCorner
            )
            expectedX = expectedTopLeft.x
            expectedMaxY = expectedTopLeft.y
        }

        openingColorPanel(settingsController, settingsWindow)

        XCTAssertTrue(colorPanel.parent === settingsWindow, file: file, line: line)
        XCTAssertTrue(settingsWindow.childWindows?.contains(colorPanel) ?? false, file: file, line: line)
        XCTAssertEqual(colorPanel.frame.minX, expectedX, accuracy: 1, file: file, line: line)
        XCTAssertEqual(colorPanel.frame.maxY, expectedMaxY, accuracy: 1, file: file, line: line)
    }

    private func expectedColorPanelTopLeftPoint(
        colorPanelSize: NSSize,
        settingsFrame: NSRect,
        zeroCorner: ZeroCorner
    ) -> NSPoint {
        let x: CGFloat
        let y: CGFloat

        switch zeroCorner {
        case .topLeft, .bottomLeft:
            x = settingsFrame.maxX + 8
        case .topRight, .bottomRight:
            x = settingsFrame.minX - colorPanelSize.width - 8
        }

        switch zeroCorner {
        case .topLeft, .topRight:
            y = settingsFrame.maxY
        case .bottomLeft, .bottomRight:
            y = settingsFrame.minY + colorPanelSize.height
        }

        return NSPoint(x: x, y: y)
    }

    private func mouseDownEvent(windowNumber: Int) -> NSEvent {
        return NSEvent.mouseEvent(
            with: .leftMouseDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: windowNumber,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 1
        )!
    }

    private func withRestoredRulerSetState(_ test: () throws -> Void) rethrows {
        let previousState = persistentPreferenceValue(forKey: Prefs.rulerSetStateKey)

        defer {
            restorePersistentPreferenceValue(previousState, forKey: Prefs.rulerSetStateKey)
        }

        try test()
    }

    private func persistentPreferenceValue(forKey key: String) -> Any? {
        let defaults = Prefs.userDefaults
        guard let domainName = Prefs.userDefaultsPersistentDomainName else {
            return defaults.object(forKey: key)
        }

        return defaults.persistentDomain(forName: domainName)?[key]
    }

    private func restorePersistentPreferenceValue(_ value: Any?, forKey key: String) {
        let defaults = Prefs.userDefaults
        guard let domainName = Prefs.userDefaultsPersistentDomainName else {
            if let value = value {
                defaults.set(value, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
            return
        }

        var domain = defaults.persistentDomain(forName: domainName) ?? [:]
        if let value = value {
            domain[key] = value
        } else {
            domain.removeValue(forKey: key)
        }
        defaults.setPersistentDomain(domain, forName: domainName)
    }
}

private final class TestableZeroCornerHorizontalRule: HorizontalRule {
    var testZeroCorner: ZeroCorner = .topLeft

    override var zeroCorner: ZeroCorner {
        return testZeroCorner
    }
}

private func rulerContentView(size: NSSize, zeroCorner: ZeroCorner) -> RulerContentView {
    let horizontalRule = HorizontalRule(
        frame: NSRect(x: 0, y: 0, width: 120, height: Ruler.thickness)
    )
    let verticalRule = VerticalRule(
        frame: NSRect(x: 0, y: 0, width: Ruler.thickness, height: 160)
    )
    let view = RulerContentView(
        frame: NSRect(origin: .zero, size: size),
        horizontalRule: horizontalRule,
        verticalRule: verticalRule
    )

    view.zeroCorner = zeroCorner
    view.layoutSubtreeIfNeeded()
    return view
}

private func oneWingRulerWindow(
    orientation: Orientation,
    frame: NSRect,
    settings: RulerSettings = RulerSettings()
) -> RulerWindow {
    let window = RulerWindow(frame: frame, settings: settings)
    window.setVisibleRules(
        horizontal: orientation == .horizontal,
        vertical: orientation == .vertical
    )
    window.setFrame(frame, display: false)
    window.updateLayoutForCurrentZeroCorner()
    return window
}

private func resizeHandle(in rule: RuleView) -> ResizeHandleView? {
    return rule.subviews.first { $0 is ResizeHandleView } as? ResizeHandleView
}

private func pointInsideEmptyRulerWindowCorner(
    horizontalFrame: NSRect,
    verticalFrame: NSRect,
    bounds: NSRect
) -> NSPoint {
    let x: CGFloat
    if horizontalFrame.minX > bounds.minX {
        x = (bounds.minX + horizontalFrame.minX) / 2
    } else {
        x = (horizontalFrame.maxX + bounds.maxX) / 2
    }

    let y: CGFloat
    if verticalFrame.maxY < bounds.maxY {
        y = (verticalFrame.maxY + bounds.maxY) / 2
    } else {
        y = (bounds.minY + verticalFrame.minY) / 2
    }

    return NSPoint(x: x, y: y)
}

private func withInstalledAppDelegate(_ test: (AppDelegate) throws -> Void) rethrows {
    let previousDelegate = NSApp.delegate
    let appDelegate = AppDelegate()
    NSApp.delegate = appDelegate

    defer {
        NSApp.delegate = previousDelegate
    }

    try test(appDelegate)
}

private func unitLabelSize(for rule: RuleView) -> NSSize {
    let label = NSAttributedString(
        string: rule.getUnitLabel(),
        attributes: rule.labelAttributes(alignment: .left, foregroundColor: rule.color.ticks)
    )

    return UnitLabelView.labelSize(for: label)
}

private func assertColor(
    _ actualColor: NSColor,
    equals expectedColor: NSColor,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let actual = actualColor.usingColorSpace(.deviceRGB) else {
        XCTFail("Could not convert actual color to device RGB", file: file, line: line)
        return
    }

    guard let expected = expectedColor.usingColorSpace(.deviceRGB) else {
        XCTFail("Could not convert expected color to device RGB", file: file, line: line)
        return
    }

    XCTAssertEqual(actual.redComponent, expected.redComponent, accuracy: 0.0001, file: file, line: line)
    XCTAssertEqual(actual.greenComponent, expected.greenComponent, accuracy: 0.0001, file: file, line: line)
    XCTAssertEqual(actual.blueComponent, expected.blueComponent, accuracy: 0.0001, file: file, line: line)
    XCTAssertEqual(actual.alphaComponent, expected.alphaComponent, accuracy: 0.0001, file: file, line: line)
}

private func assertPixel(
    atX x: Int,
    y: Int,
    in bitmap: NSBitmapImageRep,
    equals expectedColor: NSColor,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let actualColor = bitmap.colorAt(x: x, y: y) else {
        XCTFail("Missing pixel at \(x), \(y)", file: file, line: line)
        return
    }

    assertColor(actualColor, equals: expectedColor, file: file, line: line)
}

private func relativeLuminance(
    _ color: NSColor,
    file: StaticString = #filePath,
    line: UInt = #line
) -> CGFloat {
    guard let color = color.usingColorSpace(.deviceRGB) else {
        XCTFail("Could not convert color to device RGB", file: file, line: line)
        return .nan
    }

    return (0.299 * color.redComponent)
        + (0.587 * color.greenComponent)
        + (0.114 * color.blueComponent)
}
