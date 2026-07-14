# Paper Overlay for macOS

A native menu-bar utility that overlays a subtle, GPU-rendered paper-grain
texture across your whole screen to reduce digital eye strain. macOS port of
the Windows app of the same name.

- **Menu-bar only** — no Dock icon, no windows; everything lives in a
  dropdown from the status bar icon.
- **Procedural Metal shader** — the grain is generated on the GPU (no static
  bitmaps) and parameterized by grain size (five levels, finest → medium),
  pattern size, per-channel R/G/B intensity, gamma, and opacity (capped at
  0.8 so the screen can never be fully covered). Rendering is fully static
  between changes, so idle GPU usage is ~zero.
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

**Works with True Tone and Night Shift** — both shift your display's white
point *on top of* the overlay, so they combine with Paper Overlay's tint
rather than conflict. If you keep True Tone on, the color-neutral
**Neutral** preset gives you paper texture while True Tone handles warmth;
if you prefer manual control, the Warm/Sepia/Night presets replicate that
warmth with texture included. (There's no macOS API for apps to read or
switch True Tone, and Paper Overlay deliberately doesn't touch private
system frameworks.)

Requires macOS 13 Ventura or newer. Current version: **0.0.9** (early —
not feature-complete yet).

## Install

**Download:** grab `PaperOverlay-<version>-Installer.pkg` from the
[latest release](https://github.com/raduvlad92/paper-overlay/releases/latest).

Paper Overlay is distributed without an Apple Developer signature, so macOS
Gatekeeper blocks the download once. The `.pkg` installer is the recommended
route because you only face that dialog for the installer itself — the
installed app is quarantine-free and never shows a warning.

### Recommended: guided installer (.pkg)

1. Double-click `PaperOverlay-<version>-Installer.pkg`. macOS will say it
   was blocked — click **Done** (not "Move to Bin").
2. Open **System Settings → Privacy & Security**, scroll down, click
   **Open Anyway**, and confirm. (One time only.)
3. The installer wizard opens: click through **Continue → Install**. It
   explains each step, installs the app into Applications, and launches it.
4. Look for the page icon in your menu bar. No further security prompts —
   apps installed by macOS Installer are not quarantined.

### Alternative: .dmg

Drag **PaperOverlay** into **Applications**, then the *app itself* needs the
same Done → System Settings → **Open Anyway** dance on first launch (steps
are in the "If the app won't open" file inside the dmg). On macOS 15 and
newer, right-click → Open is no longer enough for unsigned apps.

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

## Package for distribution

```sh
./build_pkg.sh    # recommended: guided .pkg installer wizard
./build_dmg.sh    # alternative: classic drag-to-Applications dmg
```

Both build a universal (Apple Silicon + Intel) release binary and assemble
`dist/PaperOverlay.app` (with `LSUIElement` so it stays out of the Dock),
ad-hoc codesigned (`codesign --sign -`). `build_pkg.sh` wraps it in a
`pkgbuild`/`productbuild` installer with welcome/conclusion pages
(`Packaging/pkg/`) that auto-launches the app after install; `build_dmg.sh`
produces `dist/PaperOverlay-<version>.dmg` via `hdiutil`.

The only way to remove the remaining one-time Gatekeeper dialog entirely is
Developer ID signing + notarization, which requires the paid Apple Developer
Program.

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
Packaging/
  Info.plist                     bundle plist used by both build scripts
  assemble_app.sh                shared universal-build + .app assembly step
  pkg/                           installer wizard pages + postinstall script
  make_icon.swift                procedural generator for AppIcon.icns
build_pkg.sh                     guided .pkg installer (recommended artifact)
build_dmg.sh                     classic drag-to-Applications .dmg
```

## Monetization status

Everything is currently free and unlocked. `LicenseManager` is a stub — it
anchors a first-run timestamp in the Keychain and exposes trial/license
properties, but nothing is enforced and there is no payment or network code.
An Upgrade tab exists in the code but is hidden until purchasing is real.
Future work is marked with `TODO(licensing)` comments.

## License

Source-available: you're welcome to read the code and build/run it from
source for personal use, but redistribution and reuse in other projects
require permission — see [LICENSE](LICENSE).
