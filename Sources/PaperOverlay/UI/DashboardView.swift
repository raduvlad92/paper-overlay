import SwiftUI

enum DashboardTab: Hashable {
    case presets, adjust, monitors, upgrade
}

struct DashboardView: View {
    @EnvironmentObject private var settings: OverlaySettings
    @EnvironmentObject private var loginItems: LoginItemManager
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
                Text("Upgrade", bundle: .module).tag(DashboardTab.upgrade)
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
                case .upgrade:
                    UpgradeView()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Toggle(isOn: Binding(
                    get: { loginItems.isEnabled },
                    set: { loginItems.setEnabled($0) }
                )) {
                    Text("Start at Login", bundle: .module)
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                .disabled(!loginItems.isAvailable)

                if !loginItems.isAvailable {
                    Text("Start at Login is available in the packaged app.", bundle: .module)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else if let error = loginItems.lastError {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }

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
