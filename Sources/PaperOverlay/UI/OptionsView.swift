import SwiftUI

struct OptionsView: View {
    @EnvironmentObject private var settings: OverlaySettings

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $settings.hiddenFromCapture) {
                Text("Hide from screenshots & screen sharing", bundle: .appModule)
            }
            .toggleStyle(.switch)
            .controlSize(.small)

            Text("You see the overlay, but screenshots, recordings, and video-call screen shares stay clean.",
                 bundle: .appModule)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
