import Foundation
import ServiceManagement

/// Wraps SMAppService.mainApp for the "Start at Login" toggle.
/// This is a self-service Login Items registration, not a permission prompt.
@MainActor
final class LoginItemManager: ObservableObject {
    @Published private(set) var isEnabled: Bool = false
    @Published private(set) var lastError: String?

    /// SMAppService can only register a real .app bundle; when running as a
    /// bare executable (`swift run`) the toggle is shown disabled instead.
    let isAvailable: Bool = Bundle.main.bundlePath.hasSuffix(".app")

    init() {
        refresh()
    }

    func refresh() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        guard isAvailable else { return }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            lastError = nil
            NSLog("PaperOverlay: login item %@", enabled ? "registered" : "unregistered")
        } catch {
            lastError = error.localizedDescription
            NSLog("PaperOverlay: login item change failed: %@", String(describing: error))
        }
        refresh()
    }
}
