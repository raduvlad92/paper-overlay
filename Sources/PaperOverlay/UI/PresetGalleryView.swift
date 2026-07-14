import SwiftUI

struct PresetGalleryView: View {
    @EnvironmentObject private var settings: OverlaySettings

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Built-in", bundle: .module)
                .font(.caption)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Preset.builtIns) { preset in
                    PresetButton(preset: preset)
                }
            }
        }
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
