import AppKit

/// Owns the overlay windows. Milestone 3: a single window on the main screen
/// rendering the procedural Metal grain with default parameters.
@MainActor
final class OverlayManager {
    private var window: OverlayWindow?
    private var grainView: GrainOverlayView?

    func start() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            NSLog("PaperOverlay: no screens available, overlay not created")
            return
        }
        guard let pipeline = GrainPipeline.shared else {
            NSLog("PaperOverlay: Metal unavailable, overlay not created")
            return
        }

        let window = OverlayWindow(screen: screen)
        let grainView = GrainOverlayView(
            frame: CGRect(origin: .zero, size: screen.frame.size),
            pipeline: pipeline,
            parameters: GrainParameters()
        )
        window.contentView = grainView
        window.orderFrontRegardless()
        grainView.needsDisplay = true
        self.window = window
        self.grainView = grainView

        NSLog(
            "PaperOverlay: overlay window created frame=%@ level=%ld clickThrough=%d scale=%.1f",
            NSStringFromRect(window.frame), window.level.rawValue,
            window.ignoresMouseEvents ? 1 : 0, screen.backingScaleFactor
        )
    }
}
