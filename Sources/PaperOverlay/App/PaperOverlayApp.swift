import SwiftUI

@main
struct PaperOverlayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            DashboardView()
                .environmentObject(AppState.shared.settings)
                .environmentObject(AppState.shared.presetStore)
                .environmentObject(AppState.shared.loginItems)
                .environmentObject(AppState.shared.license)
        } label: {
            Image(systemName: "doc.plaintext")
        }
        .menuBarExtraStyle(.window)
    }
}
