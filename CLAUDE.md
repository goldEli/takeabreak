# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TakeABreak is a macOS menu bar app (AppKit + SwiftUI) that reminds you to take breaks using a work/rest timer cycle. It shows a fullscreen overlay during breaks and detects Lark/Feishu meetings to postpone breaks automatically.

## Build Commands

```bash
# Build via Swift Package Manager
swift build

# Build a distributable .app bundle (includes icon generation)
./scripts/build_app.sh
open .build/app/TakeABreak.app
```

There are no tests or linting configured.

## Architecture

**Swift 6.2 / macOS 13+** — pure Swift Package Manager project with a single executable target. No third-party dependencies.

### Core Components

- **`TakeABreakApp.swift`** — App entry point. Sets up both a `WindowGroup` (settings window) and a `MenuBarExtra` (menu bar popover), both rendering `MenuBarContentView`. Contains `AppDelegate` which handles notification permissions and app icon.
- **`BreakTimerStore.swift`** — Central state machine (`@MainActor ObservableObject`). Manages work/rest phase transitions, countdown timer, `UserDefaults` persistence for settings, and `UNUserNotification` delivery. When a work cycle ends, it checks `MeetingDetector` before transitioning to rest — if a meeting is detected, it postpones the break by 60 seconds.
- **`BreakOverlayController.swift`** — Observes `BreakTimerStore.phase` via Combine. During rest phase, creates borderless `NSWindow`s at `.screenSaver` level on every screen, hiding Dock and menu bar. Tears them down when rest ends.
- **`BreakOverlayView.swift`** — SwiftUI view shown in the fullscreen overlay with countdown and "End Break" button.
- **`MenuBarContentView.swift`** — SwiftUI settings UI for work minutes and break seconds, plus start/pause/quit controls.
- **`MeetingDetector.swift`** — Shells out to `ps -ax -o comm=` and scans process names for Lark/Feishu meeting keywords.

### Key Design Decisions

- `LSUIElement` is set in `Info.plist` so the app hides from the Dock when run as a `.app` bundle, but `AppDelegate` sets `.regular` activation policy so it can show a window during development via `swift build`.
- The overlay uses `NSWindow` (not SwiftUI `Window`) for precise control over window level, collection behavior, and presentation options.
- Settings persist via `UserDefaults` with keys `workMinutes` and `breakSeconds`.

### Scripts

- `scripts/build_app.sh` — Compiles with `swiftc`, generates the app icon, and assembles the `.app` bundle structure.
- `scripts/generate_icon.swift` — Programmatically draws the app icon (orange gradient with cup-and-saucer) at all required sizes using CoreGraphics.
- `scripts/set_bundle_icon.swift` — Applies the icon to the `.app` bundle via `NSWorkspace.setIcon`.
