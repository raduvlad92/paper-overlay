import Foundation

/// Persists user-created presets in UserDefaults as a JSON-encoded array.
@MainActor
final class PresetStore: ObservableObject {
    static let defaultsKey = "customPresets"

    @Published private(set) var customPresets: [Preset] = []
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.defaultsKey),
           let presets = try? JSONDecoder().decode([Preset].self, from: data) {
            customPresets = presets
            NSLog("PaperOverlay: restored %ld custom preset(s)", presets.count)
        }
    }

    func saveCurrent(named name: String, from settings: OverlaySettings) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let preset = Preset(
            name: trimmed,
            red: settings.red,
            green: settings.green,
            blue: settings.blue,
            gamma: settings.gamma,
            opacity: settings.opacity,
            grainSize: settings.grainSize,
            tileSize: settings.tileSize
        )
        customPresets.append(preset)
        persist()
    }

    func delete(_ preset: Preset) {
        customPresets.removeAll { $0.id == preset.id }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(customPresets) else { return }
        defaults.set(data, forKey: Self.defaultsKey)
        NSLog("PaperOverlay: saved %ld custom preset(s)", customPresets.count)
    }
}
