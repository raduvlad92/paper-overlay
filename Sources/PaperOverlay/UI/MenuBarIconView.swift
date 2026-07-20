import SwiftUI

/// The status bar icon, with a small badge overlaid when an update is
/// ready to install.
struct MenuBarIconView: View {
    @ObservedObject private var updates = AppState.shared.updates

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "doc.plaintext")
            if updates.isUpdateAvailable {
                Image(systemName: "arrow.up.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .blue)
                    .font(.system(size: 9, weight: .bold))
                    .offset(x: 7, y: -6)
            }
        }
    }
}
