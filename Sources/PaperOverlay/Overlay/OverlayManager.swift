import AppKit

/// Owns the overlay windows. Milestone 2: a single window on the main screen
/// filled with a flat semi-transparent color to prove out click-through.
@MainActor
final class OverlayManager {
    private var window: OverlayWindow?

    func start() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            NSLog("PaperOverlay: no screens available, overlay not created")
            return
        }

        let window = OverlayWindow(screen: screen)
        let contentView = NSView(frame: screen.frame)
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor(
            calibratedRed: 0.85, green: 0.75, blue: 0.55, alpha: 0.15
        ).cgColor
        window.contentView = contentView
        window.orderFrontRegardless()
        self.window = window

        NSLog(
            "PaperOverlay: overlay window created frame=%@ level=%ld clickThrough=%d",
            NSStringFromRect(window.frame), window.level.rawValue, window.ignoresMouseEvents ? 1 : 0
        )
    }
}
