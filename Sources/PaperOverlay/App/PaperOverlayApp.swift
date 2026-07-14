import SwiftUI

@main
struct PaperOverlayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            VStack(alignment: .leading, spacing: 8) {
                Text("Paper Overlay", bundle: .module)
                    .font(.headline)
                Divider()
                Button {
                    NSApp.terminate(nil)
                } label: {
                    Text("Quit Paper Overlay", bundle: .module)
                }
            }
            .padding(12)
            .frame(width: 260)
        } label: {
            Image(systemName: "doc.plaintext")
        }
        .menuBarExtraStyle(.window)
    }
}
