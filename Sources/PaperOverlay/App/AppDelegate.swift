import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // LSUIElement only applies to the bundled .app; this keeps the Dock
        // icon hidden when launched as a bare executable via `swift run`.
        NSApp.setActivationPolicy(.accessory)
        NSLog("PaperOverlay: launched, activation policy set to .accessory")
        NSLog("PaperOverlay: resources at %@", Bundle.appModule.bundlePath)
        AppState.shared.overlayManager.start()

        // Debug-only hook so persistence can be exercised without UI
        // interaction (e.g. PO_DEBUG_SET_OPACITY=0.42 swift run).
        if let raw = ProcessInfo.processInfo.environment["PO_DEBUG_SET_OPACITY"],
           let value = Double(raw) {
            AppState.shared.settings.opacity = value
            NSLog("PaperOverlay: debug hook set opacity=%.2f", value)
        }
    }
}
