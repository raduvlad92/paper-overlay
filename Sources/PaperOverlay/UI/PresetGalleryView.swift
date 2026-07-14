import SwiftUI

struct PresetGalleryView: View {
    @EnvironmentObject private var settings: OverlaySettings
    @EnvironmentObject private var presetStore: PresetStore
    @State private var newPresetName: String = ""

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Built-in", bundle: .appModule)
                .font(.caption)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Preset.builtIns) { preset in
                    PresetButton(preset: preset)
                }
            }

            if !presetStore.customPresets.isEmpty {
                Text("Custom", bundle: .appModule)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(presetStore.customPresets) { preset in
                        PresetButton(preset: preset)
                            .contextMenu {
                                Button(role: .destructive) {
                                    presetStore.delete(preset)
                                } label: {
                                    Text("Delete", bundle: .appModule)
                                }
                            }
                    }
                }
                Text("Right-click a custom preset to delete it.", bundle: .appModule)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Divider()

            HStack(spacing: 6) {
                TextField(text: $newPresetName) {
                    Text("Preset name", bundle: .appModule)
                }
                .textFieldStyle(.roundedBorder)
                .controlSize(.small)
                .onSubmit(saveCurrent)

                Button(action: saveCurrent) {
                    Text("Save", bundle: .appModule)
                }
                .controlSize(.small)
                .disabled(newPresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .help(Text("Save the current settings as a custom preset", bundle: .appModule))
        }
    }

    private func saveCurrent() {
        presetStore.saveCurrent(named: newPresetName, from: settings)
        newPresetName = ""
    }
}

struct PresetButton: View {
    @EnvironmentObject private var settings: OverlaySettings
    let preset: Preset

    private var isActive: Bool { settings.matches(preset) }

    var body: some View {
        Button {
            settings.apply(preset)
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(red: preset.red, green: preset.green, blue: preset.blue))
                    .frame(width: 10, height: 10)
                    .overlay(Circle().strokeBorder(.quaternary))
                Text(preset.name)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if isActive {
                    Image(systemName: "checkmark")
                        .font(.caption2.bold())
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.bordered)
    }
}
