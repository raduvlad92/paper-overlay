import Foundation

/// Composition root shared by the AppDelegate (overlay lifecycle) and the
/// SwiftUI MenuBarExtra scene (dashboard UI).
@MainActor
final class AppState {
    static let shared = AppState()

    let settings: OverlaySettings
    let presetStore: PresetStore
    let overlayManager: OverlayManager

    private init() {
        let settings = OverlaySettings()
        self.settings = settings
        self.presetStore = PresetStore()
        self.overlayManager = OverlayManager(settings: settings)
    }
}
