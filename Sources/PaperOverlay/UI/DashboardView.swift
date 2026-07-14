import SwiftUI

enum DashboardTab: Hashable {
    case presets, adjust, monitors
}

struct DashboardView: View {
    @EnvironmentObject private var settings: OverlaySettings
    @State private var tab: DashboardTab = .presets

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Paper Overlay", bundle: .module)
                    .font(.headline)
                Spacer()
                Toggle(isOn: $settings.masterEnabled) {
                    EmptyView()
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                .help(Text("Enable or disable the overlay everywhere", bundle: .module))
            }

            Picker("", selection: $tab) {
                Text("Presets", bundle: .module).tag(DashboardTab.presets)
                Text("Adjust", bundle: .module).tag(DashboardTab.adjust)
                Text("Monitors", bundle: .module).tag(DashboardTab.monitors)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Group {
                switch tab {
                case .presets:
                    PresetGalleryView()
                case .adjust:
                    ControlsView()
                case .monitors:
                    MonitorsView()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            HStack {
                Spacer()
                Button {
                    NSApp.terminate(nil)
                } label: {
                    Text("Quit Paper Overlay", bundle: .module)
                }
            }
        }
        .padding(14)
        .frame(width: 320)
    }
}
