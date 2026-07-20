import Foundation

/// Composition root shared by the AppDelegate (overlay lifecycle) and the
/// SwiftUI MenuBarExtra scene (dashboard UI).
@MainActor
final class AppState {
    static let shared = AppState()

    let settings: OverlaySettings
    let presetStore: PresetStore
    let overlayManager: OverlayManager
    let loginItems: LoginItemManager
    let license: LicenseManager
    let hotkeys: HotkeyManager
    let schedule: ScheduleManager
    let updates: UpdateManager

    private init() {
        let settings = OverlaySettings()
        let presetStore = PresetStore()
        self.settings = settings
        self.presetStore = presetStore
        self.overlayManager = OverlayManager(settings: settings)
        self.loginItems = LoginItemManager()
        self.license = LicenseManager()
        self.hotkeys = HotkeyManager { settings.masterEnabled.toggle() }
        self.schedule = ScheduleManager(settings: settings, presetStore: presetStore)
        self.updates = UpdateManager()
    }
}
