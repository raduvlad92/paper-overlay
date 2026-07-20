import AppKit
import SwiftUI

/// Shown at the top of the dashboard whenever there's something to report
/// about the in-app updater: an update ready to install, one installing, or
/// an install that failed.
struct UpdateBannerView: View {
    @EnvironmentObject private var updates: UpdateManager

    var body: some View {
        switch updates.state {
        case .updateAvailable(let version):
            container {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Version \(version) is ready", bundle: .appModule)
                        .font(.caption.bold())
                    Text("Installs automatically — no security prompts.", bundle: .appModule)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    updates.install()
                } label: {
                    Text("Install", bundle: .appModule)
                }
                .controlSize(.small)
            }
        case .installing:
            container {
                ProgressView()
                    .controlSize(.small)
                Text("Installing update…", bundle: .appModule)
                    .font(.caption)
                Spacer()
            }
        case .error(let message):
            container(tint: .orange) {
                Text(message)
                    .font(.caption2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button {
                    openReleasesPage()
                } label: {
                    Text("Open GitHub", bundle: .appModule)
                }
                .controlSize(.small)
            }
        case .idle, .checking:
            EmptyView()
        }
    }

    private func openReleasesPage() {
        guard let url = URL(string: "https://github.com/\(UpdateManager.repo)/releases/latest") else { return }
        NSWorkspace.shared.open(url)
    }

    @ViewBuilder
    private func container<Content: View>(tint: Color = .blue, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top, spacing: 8) {
            content()
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 6).fill(tint.opacity(0.15)))
    }
}
