import AppKit
import Combine

/// Owns one overlay window per connected display, keeping the set in sync as
/// displays are connected, disconnected, or change resolution/scale, and as
/// the user changes settings in the dashboard.
@MainActor
final class OverlayManager {
    private struct Entry {
        let window: OverlayWindow
        let grainView: GrainOverlayView
    }

    private let settings: OverlaySettings
    private var entries: [CGDirectDisplayID: Entry] = [:]
    private var screenObserver: NSObjectProtocol?
    private var settingsCancellable: AnyCancellable?

    init(settings: OverlaySettings) {
        self.settings = settings
    }

    func start() {
        syncScreens()

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.syncScreens()
            }
        }

        // Live-update all overlays whenever any dashboard control changes.
        // receive(on:) defers to the next runloop tick so @Published values
        // are already updated when we read them.
        settingsCancellable = settings.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applySettings()
            }
    }

    /// Currently connected displays as (id, localized name) pairs, for the UI.
    var connectedDisplays: [(id: CGDirectDisplayID, name: String)] {
        NSScreen.screens.compactMap { screen in
            guard let id = screen.displayID else { return nil }
            return (id, screen.localizedName)
        }
    }

    private func applySettings() {
        let parameters = settings.grainParameters
        for entry in entries.values {
            entry.grainView.parameters = parameters
        }
        // Cheap when nothing changed; handles master/per-display toggles.
        syncScreens()
    }

    // MARK: - Screen syncing

    private func syncScreens() {
        guard let pipeline = GrainPipeline.shared else {
            NSLog("PaperOverlay: Metal unavailable, overlays not created")
            return
        }

        var changed = false
        var seen: Set<CGDirectDisplayID> = []

        for screen in NSScreen.screens {
            guard let displayID = screen.displayID else { continue }
            seen.insert(displayID)

            let enabled = settings.masterEnabled && !settings.disabledDisplays.contains(displayID)
            guard enabled else {
                if removeOverlay(for: displayID, reason: "disabled") { changed = true }
                continue
            }

            if let entry = entries[displayID] {
                // Same display: track resolution/origin/scale changes.
                if entry.window.frame != screen.frame {
                    entry.window.setFrame(screen.frame, display: true)
                    entry.grainView.needsDisplay = true
                    changed = true
                    NSLog("PaperOverlay: display %u reframed to %@",
                          displayID, NSStringFromRect(screen.frame))
                }
            } else {
                let window = OverlayWindow(screen: screen)
                let grainView = GrainOverlayView(
                    frame: CGRect(origin: .zero, size: screen.frame.size),
                    pipeline: pipeline,
                    parameters: settings.grainParameters
                )
                window.contentView = grainView
                window.orderFrontRegardless()
                grainView.needsDisplay = true
                entries[displayID] = Entry(window: window, grainView: grainView)
                changed = true
                NSLog("PaperOverlay: overlay added on display %u (%@) frame=%@ scale=%.1f",
                      displayID, screen.localizedName,
                      NSStringFromRect(screen.frame), screen.backingScaleFactor)
            }
        }

        for displayID in entries.keys where !seen.contains(displayID) {
            if removeOverlay(for: displayID, reason: "disconnected") { changed = true }
        }

        if changed {
            NSLog("PaperOverlay: sync complete, %ld screen(s), %ld overlay(s) active",
                  NSScreen.screens.count, entries.count)
        }
    }

    @discardableResult
    private func removeOverlay(for displayID: CGDirectDisplayID, reason: String) -> Bool {
        guard let entry = entries.removeValue(forKey: displayID) else { return false }
        entry.window.orderOut(nil)
        entry.window.contentView = nil
        NSLog("PaperOverlay: overlay removed on display %u (%@)", displayID, reason)
        return true
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }
}
