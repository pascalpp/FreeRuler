# AGENTS.md

Guidance for Codex and other coding agents working on Free Ruler.

## Project Overview

Free Ruler is a native macOS ruler app written in Swift with AppKit. It shows
horizontal and vertical ruler windows, supports pixels/millimeters/inches,
grouped movement, floating windows, ruler shadows, mouse alignment, and
preferences persisted with `UserDefaults`.

The main app target lives in `Free Ruler/` and the Xcode project is
`Free Ruler.xcodeproj`. The module name used by tests is `Free_Ruler`.

## Repository Layout

- `AppDelegate.swift`: app lifecycle, menu actions, ruler creation,
  hotkey behavior, timer policy wiring, and UI test state reset.
- `Ruler.swift`: ruler model plus default placement and min/max size
  helpers.
- `RulerController.swift`, `RulerWindow.swift`, `RuleView.swift`,
  `HorizontalRule.swift`, `VerticalRule.swift`: ruler window/view behavior and
  drawing.
- `Prefs.swift`: persisted app preferences.
- `Base.lproj/*.xib`: AppKit interface files for menus/preferences.
- `*.lproj/*.strings` and `Localizable.xcstrings`:
  localized resources.
- `FreeRulerTests/`: unit tests for core non-UI behavior.
- `FreeRulerUITests/`: UI tests.
- `scripts/release/` and `HOW-TO-RELEASE.md`: GitHub release automation.

Generated build outputs belong in `build/` or `dist/`; do not commit release
zips or other generated artifacts.

## Working Conventions

- Use a separate git worktree for agent changes when practical, keeping the
  primary checkout on `main`.
- Prefer branches named `<agent>/<issue-number>-<description>`.
- Before editing, check `git status --short --branch` and do not overwrite
  user changes.
- Keep changes scoped. This is a small AppKit app, so avoid broad refactors
  unless the requested task really needs them.
- Follow the existing Swift style in nearby files. The codebase uses UIKit-era
  AppKit patterns, explicit `NS*` types, and straightforward helpers rather than
  heavy abstraction.

## Build And Test

Use Xcode's command-line tools from the repository root:

```sh
xcodebuild -project "Free Ruler.xcodeproj" -scheme "Free Ruler" build
xcodebuild -project "Free Ruler.xcodeproj" -scheme "Free Ruler" test
```

For focused test work, prefer the smallest relevant Xcode test invocation first,
then run the full scheme if the change affects shared behavior.

The `package.json` scripts are for versioning and release automation, not the
normal test suite. `npm test` is intentionally not wired to the Xcode tests.

## App Behavior Notes

- `prefs` drives units, grouping, floating windows, shadows, and opacity. When
  preference values change, make sure menus and ruler redraws stay in sync.
- The app has two ruler orientations: `horizontal` and `vertical`. Many helpers
  intentionally switch over `Orientation`; update both branches when changing
  geometry or drawing behavior.
- Ruler thickness is currently 40 pt. Min/max sizes and default positions are
  tested in `FreeRulerTests/RulerCoreTests.swift`.
- Mouse tick updates are managed through `MouseTickTimerPolicy`; avoid starting
  timers independently unless the policy is updated too.
- UI tests can launch with `FREE_RULER_UI_TESTS` set. `AppDelegate` resets
  defaults in that mode for deterministic tests.
- `scripts/generate-app-icon.sh` regenerates the app icon PNGs from the
  AppKit icon renderer.

## Localization And Resources

- User-facing strings should be localized. Check both `Localizable.xcstrings`
  and the existing `.lproj/*.strings` files before adding new keys.
- Menu and preferences UI still come from XIB files. Be careful when editing
  `Base.lproj/*.xib` and keep localized `.strings` files consistent with UI
  text changes.
- The project file has paths containing spaces, especially ``and`Free Ruler.xcodeproj`; quote paths in shell commands.

## Release Notes

GitHub releases are signed and notarized zips produced by the scripts documented
in `HOW-TO-RELEASE.md`. Agents should not run the release commands unless
instructed to do so.
