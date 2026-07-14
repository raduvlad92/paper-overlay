# Paper Overlay for macOS

A native menu-bar utility that overlays a subtle, GPU-rendered paper-grain
texture across your whole screen to reduce digital eye strain. macOS port of
the Windows app of the same name.

- **Menu-bar only** — no Dock icon, no windows; everything lives in a
  dropdown from the status bar icon.
- **Procedural Metal shader** — the grain is generated on the GPU (no static
  bitmaps), tileable, and parameterized by grain size (ultra-fine → coarse),
  tile size (64–512 px), per-channel R/G/B intensity, gamma, and opacity.
  Rendering is fully static between changes, so idle GPU usage is ~zero.
- **100% click-through** — the overlay never intercepts clicks, drags,
  games, or any other input, and follows you across Spaces and fullscreen apps.
- **Multi-monitor with hot-plug** — one overlay per display, added/removed
  live as monitors connect, disconnect, or change resolution; mixed Retina
  scale factors handled.
- **Presets** — five built-ins (Neutral, Warm, Sepia, Night, Reading) plus
  unlimited named custom presets.
- **Start at Login** — self-service Login Items toggle via `SMAppService`.
- **Private by design** — no network access, no Accessibility, Screen
  Recording, camera, microphone, contacts, or file permissions. Settings are
  stored in `UserDefaults`.

Requires macOS 13 Ventura or newer.

## Install (prebuilt .dmg)

1. Open the `.dmg` and drag **PaperOverlay** into **Applications**.
2. **First launch:** right-click (or Control-click) the app and choose
   **Open**, then confirm. This is the standard Gatekeeper step for unsigned
   apps — Paper Overlay is currently distributed without an Apple Developer
   signature. You only need to do this once.
3. Look for the page icon in your menu bar.

## Build from source

Only the Xcode **Command Line Tools** are required — no Xcode.app, no
`.xcodeproj`. This is a plain Swift Package Manager executable.

```sh
git clone https://github.com/raduvlad92/paper-overlay.git
cd paper-overlay
swift build          # debug build
swift run            # build + run (menu bar icon appears)
```

Notes when running unbundled via `swift run`:

- "Start at Login" is disabled — `SMAppService` requires a real `.app` bundle.
- The Metal shader is compiled at runtime from embedded source
  (`MTLDevice.makeLibrary(source:)`), because the offline `metal` compiler
  ships only with full Xcode. This is a one-time, few-millisecond cost at
  launch with identical GPU performance afterward.

## Package a distributable .dmg

```sh
./build_dmg.sh
```

This builds a universal (Apple Silicon + Intel) release binary, assembles
`dist/PaperOverlay.app` (with `LSUIElement` so it stays out of the Dock),
ad-hoc codesigns it (`codesign --sign -`), and produces
`dist/PaperOverlay-<version>.dmg` via `hdiutil`.

## Project layout

```
Package.swift                    SwiftPM manifest (executable target, macOS 13+)
Sources/PaperOverlay/
  App/                           entry point, app delegate, composition root
  Overlay/                       per-display click-through windows + hot-plug sync
  Rendering/                     Metal shader source + MTKView grain renderer
  Model/                         settings, presets, login item, licensing stub
  UI/                            MenuBarExtra dashboard (SwiftUI)
  Resources/en.lproj/            localized strings (classic .strings format —
                                 string catalogs need Xcode tooling; more
                                 languages can be dropped in as <lang>.lproj/)
Packaging/Info.plist             bundle plist used by build_dmg.sh
build_dmg.sh                     release build + .app assembly + .dmg
```

## Licensing status

All features are currently free and unlocked. `LicenseManager` is a stub —
it anchors a first-run timestamp in the Keychain and exposes trial/license
properties, but nothing is enforced and there is no payment or network code.
The Upgrade tab in the dashboard is a visual placeholder. Future work is
marked with `TODO(licensing)` comments.
