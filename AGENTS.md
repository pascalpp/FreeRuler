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
- `RulerWindow.swift`, `RuleView.swift`, `HorizontalRule.swift`,
  `VerticalRule.swift`: ruler window/controller/view behavior and drawing.
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

## GitHub CLI In Codex

`gh` is authenticated for the `pascalpp` account through the macOS keyring.
Sandboxed agent commands may not be able to read that keyring entry and can
report the token in `~/.config/gh/hosts.yml` as invalid even when
`gh auth status` works in the user's terminal.

Before concluding that GitHub CLI auth is missing, retry authenticated `gh`
commands outside the sandbox with approval/escalation. Do not run `gh auth
login`, `gh auth logout`, or edit `~/.config/gh/hosts.yml` unless the escalated
`gh auth status` check also fails or the user explicitly asks for reauth.

## PR Review Comment Resolution

When asked to address PR review comments, inspect the pull request associated
with the current branch and find any unresolved review comments or threads.
Address actionable comments with code changes, keeping each change scoped to
the feedback. After making fixes, run the relevant core/unit tests, commit the
changes, and push them to the remote PR branch.

After pushing fixes, resolve the addressed review comments. Leave replies only
when clarification or context is needed, and prefix agent replies with the agent
name in brackets, for example `[codex]`.

Once all currently actionable comments are resolved, set a poller to check the
PR for new unresolved comments after 8 minutes. If new comments are found,
repeat the full comment-resolution loop: inspect, fix, test, commit, push,
resolve, and start a new poller. If the poller finds no new comments, check
again up to 3 total no-comment tries; after the third no-comment poll, stop
polling and consider the review-comment resolution process complete.

## Build And Test

Use Xcode's command-line tools from the repository root:

```sh
xcodebuild -project "Free Ruler.xcodeproj" -scheme "Free Ruler" build
xcodebuild -project "Free Ruler.xcodeproj" -scheme "Free Ruler" test -only-testing:FreeRulerTests
yarn test
yarn test:unit
yarn test:ui
```

For focused test work, prefer the smallest relevant Xcode test invocation first,
then run the core/unit tests if the change affects shared behavior. Do not run
the UI tests unless the user explicitly asks for them.

The `package.json` test scripts are aliases for the Xcode test commands:
`yarn test:unit` runs `FreeRulerTests`; `yarn test:ui` runs
`FreeRulerUITests`; `yarn test` runs both.

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
