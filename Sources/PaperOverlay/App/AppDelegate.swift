import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let overlayManager = OverlayManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // LSUIElement only applies to the bundled .app; this keeps the Dock
        // icon hidden when launched as a bare executable via `swift run`.
        NSApp.setActivationPolicy(.accessory)
        NSLog("PaperOverlay: launched, activation policy set to .accessory")
        overlayManager.start()
    }
}
