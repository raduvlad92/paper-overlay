import SwiftUI

struct MonitorsView: View {
    @EnvironmentObject private var settings: OverlaySettings
    @State private var displays: [(id: CGDirectDisplayID, name: String)] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Overlay per monitor", bundle: .appModule)
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(displays, id: \.id) { display in
                Toggle(isOn: binding(for: display.id)) {
                    Text(display.name)
                        .lineLimit(1)
                }
                .toggleStyle(.switch)
                .controlSize(.small)
            }

            if !settings.masterEnabled {
                Text("The overlay is switched off globally.", bundle: .appModule)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            displays = AppState.shared.overlayManager.connectedDisplays
        }
    }

    private func binding(for id: CGDirectDisplayID) -> Binding<Bool> {
        Binding(
            get: { !settings.disabledDisplays.contains(id) },
            set: { enabled in
                if enabled {
                    settings.disabledDisplays.remove(id)
                } else {
                    settings.disabledDisplays.insert(id)
                }
            }
        )
    }
}
