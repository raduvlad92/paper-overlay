import SwiftUI

struct OptionsView: View {
    @EnvironmentObject private var settings: OverlaySettings
    @EnvironmentObject private var hotkeys: HotkeyManager

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

            Divider()

            HStack {
                Text("Toggle overlay shortcut", bundle: .appModule)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    hotkeys.isRecording ? hotkeys.cancelRecording() : hotkeys.beginRecording()
                } label: {
                    if hotkeys.isRecording {
                        Text("Press keys…", bundle: .appModule)
                    } else if let shortcut = hotkeys.shortcut {
                        Text(shortcut.display)
                    } else {
                        Text("Record", bundle: .appModule)
                    }
                }
                .controlSize(.small)

                if hotkeys.shortcut != nil && !hotkeys.isRecording {
                    Button {
                        hotkeys.clearShortcut()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .help(Text("Remove shortcut", bundle: .appModule))
                }
            }

            Text("Works system-wide. Include ⌘, ⌃, or ⌥; press Esc to cancel recording.",
                 bundle: .appModule)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
