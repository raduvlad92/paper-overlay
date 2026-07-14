import SwiftUI

@main
struct PaperOverlayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            DashboardView()
                .environmentObject(AppState.shared.settings)
        } label: {
            Image(systemName: "doc.plaintext")
        }
        .menuBarExtraStyle(.window)
    }
}
