import AppKit

/// Owns one overlay window per connected display, keeping the set in sync as
/// displays are connected, disconnected, or change resolution/scale.
@MainActor
final class OverlayManager {
    private struct Entry {
        let window: OverlayWindow
        let grainView: GrainOverlayView
    }

    private var entries: [CGDirectDisplayID: Entry] = [:]
    private var observer: NSObjectProtocol?

    /// Shader parameters applied to every display's overlay.
    var parameters = GrainParameters() {
        didSet {
            for entry in entries.values {
                entry.grainView.parameters = parameters
            }
        }
    }

    /// Displays on which the user has switched the overlay off.
    private(set) var disabledDisplays: Set<CGDirectDisplayID> = []

    func start() {
        syncScreens()
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.syncScreens()
            }
        }
    }

    // MARK: - Per-monitor enable/disable

    func isEnabled(display: CGDirectDisplayID) -> Bool {
        !disabledDisplays.contains(display)
    }

    func setEnabled(_ enabled: Bool, display: CGDirectDisplayID) {
        if enabled {
            disabledDisplays.remove(display)
        } else {
            disabledDisplays.insert(display)
        }
        syncScreens()
    }

    /// Currently connected displays as (id, localized name) pairs, for the UI.
    var connectedDisplays: [(id: CGDirectDisplayID, name: String)] {
        NSScreen.screens.compactMap { screen in
            guard let id = screen.displayID else { return nil }
            return (id, screen.localizedName)
        }
    }

    // MARK: - Screen syncing

    private func syncScreens() {
        guard let pipeline = GrainPipeline.shared else {
            NSLog("PaperOverlay: Metal unavailable, overlays not created")
            return
        }

        var seen: Set<CGDirectDisplayID> = []
        for screen in NSScreen.screens {
            guard let displayID = screen.displayID else { continue }
            seen.insert(displayID)

            if disabledDisplays.contains(displayID) {
                removeOverlay(for: displayID, reason: "disabled")
                continue
            }

            if let entry = entries[displayID] {
                // Same display: track resolution/origin/scale changes.
                if entry.window.frame != screen.frame {
                    entry.window.setFrame(screen.frame, display: true)
                    NSLog("PaperOverlay: display %u reframed to %@",
                          displayID, NSStringFromRect(screen.frame))
                }
                entry.grainView.needsDisplay = true
            } else {
                let window = OverlayWindow(screen: screen)
                let grainView = GrainOverlayView(
                    frame: CGRect(origin: .zero, size: screen.frame.size),
                    pipeline: pipeline,
                    parameters: parameters
                )
                window.contentView = grainView
                window.orderFrontRegardless()
                grainView.needsDisplay = true
                entries[displayID] = Entry(window: window, grainView: grainView)
                NSLog("PaperOverlay: overlay added on display %u (%@) frame=%@ scale=%.1f",
                      displayID, screen.localizedName,
                      NSStringFromRect(screen.frame), screen.backingScaleFactor)
            }
        }

        for displayID in entries.keys where !seen.contains(displayID) {
            removeOverlay(for: displayID, reason: "disconnected")
        }

        NSLog("PaperOverlay: sync complete, %ld screen(s), %ld overlay(s) active",
              NSScreen.screens.count, entries.count)
    }

    private func removeOverlay(for displayID: CGDirectDisplayID, reason: String) {
        guard let entry = entries.removeValue(forKey: displayID) else { return }
        entry.window.orderOut(nil)
        entry.window.contentView = nil
        NSLog("PaperOverlay: overlay removed on display %u (%@)", displayID, reason)
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }
}
