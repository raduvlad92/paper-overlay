import SwiftUI

enum DashboardTab: Hashable {
    case presets, adjust, monitors, upgrade
}

struct DashboardView: View {
    @EnvironmentObject private var settings: OverlaySettings
    @EnvironmentObject private var loginItems: LoginItemManager
    @State private var tab: DashboardTab = .presets

    // TODO(licensing): flip to true when purchasing goes live.
    private let showUpgradeTab = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Paper Overlay", bundle: .appModule)
                    .font(.headline)
                Spacer()
                Toggle(isOn: $settings.masterEnabled) {
                    EmptyView()
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                .help(Text("Enable or disable the overlay everywhere", bundle: .appModule))
            }

            Picker("", selection: $tab) {
                Text("Presets", bundle: .appModule).tag(DashboardTab.presets)
                Text("Adjust", bundle: .appModule).tag(DashboardTab.adjust)
                Text("Monitors", bundle: .appModule).tag(DashboardTab.monitors)
                if showUpgradeTab {
                    Text("Upgrade", bundle: .appModule).tag(DashboardTab.upgrade)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            // Fixed-height, top-aligned content area: the MenuBarExtra window
            // keeps one size across tabs, so shorter tabs don't float in a
            // half-empty panel.
            ScrollView(.vertical, showsIndicators: false) {
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
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Toggle(isOn: Binding(
                    get: { loginItems.isEnabled },
                    set: { loginItems.setEnabled($0) }
                )) {
                    Text("Start at Login", bundle: .appModule)
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                .disabled(!loginItems.isAvailable)

                if !loginItems.isAvailable {
                    Text("Start at Login is available in the packaged app.", bundle: .appModule)
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
                    Text("Quit Paper Overlay", bundle: .appModule)
                }
            }
        }
        .padding(14)
        .frame(width: 320, height: 460)
    }
}
