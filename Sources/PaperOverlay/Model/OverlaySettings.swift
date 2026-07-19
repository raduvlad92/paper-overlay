import AppKit
import Combine

/// Single source of truth for everything the dashboard controls.
/// The overlay manager observes this object and re-renders live.
@MainActor
final class OverlaySettings: ObservableObject {
    @Published var red: Double = 0.85
    @Published var green: Double = 0.78
    @Published var blue: Double = 0.62
    @Published var gamma: Double = 1.0
    @Published var opacity: Double = 0.14
    @Published var grainSize: GrainSize = .ultraFine
    @Published var tileSize: Double = 256 // points, 160...512
    @Published var textureStyle: TextureStyle = .paperGrain
    @Published var vignette: Double = 0 // lamp-light edge darkening, 0...1

    /// Never 1.0: a fully opaque overlay would cover the whole screen.
    static let maxOpacity: Double = 0.8
    static let tileSizeRange: ClosedRange<Double> = 160...512
    @Published var masterEnabled: Bool = true
    @Published var disabledDisplays: Set<CGDirectDisplayID> = []
    /// Overlay excluded from screenshots, recordings, and screen sharing.
    @Published var hiddenFromCapture: Bool = true

    private struct Snapshot: Codable {
        var red, green, blue, gamma, opacity, tileSize, vignette: Double
        var grainSize: GrainSize
        var textureStyle: TextureStyle
        var masterEnabled: Bool
        var disabledDisplays: [CGDirectDisplayID]
        var hiddenFromCapture: Bool

        init(red: Double, green: Double, blue: Double, gamma: Double,
             opacity: Double, tileSize: Double, vignette: Double,
             grainSize: GrainSize, textureStyle: TextureStyle,
             masterEnabled: Bool, disabledDisplays: [CGDirectDisplayID],
             hiddenFromCapture: Bool) {
            self.red = red
            self.green = green
            self.blue = blue
            self.gamma = gamma
            self.opacity = opacity
            self.tileSize = tileSize
            self.vignette = vignette
            self.grainSize = grainSize
            self.textureStyle = textureStyle
            self.masterEnabled = masterEnabled
            self.disabledDisplays = disabledDisplays
            self.hiddenFromCapture = hiddenFromCapture
        }

        /// Tolerant decoding: fields added in later versions fall back to
        /// defaults instead of failing the decode and losing all settings.
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            red = try c.decodeIfPresent(Double.self, forKey: .red) ?? 0.85
            green = try c.decodeIfPresent(Double.self, forKey: .green) ?? 0.78
            blue = try c.decodeIfPresent(Double.self, forKey: .blue) ?? 0.62
            gamma = try c.decodeIfPresent(Double.self, forKey: .gamma) ?? 1.0
            opacity = try c.decodeIfPresent(Double.self, forKey: .opacity) ?? 0.14
            tileSize = try c.decodeIfPresent(Double.self, forKey: .tileSize) ?? 256
            vignette = try c.decodeIfPresent(Double.self, forKey: .vignette) ?? 0
            grainSize = try c.decodeIfPresent(GrainSize.self, forKey: .grainSize) ?? .ultraFine
            textureStyle = try c.decodeIfPresent(TextureStyle.self, forKey: .textureStyle) ?? .paperGrain
            masterEnabled = try c.decodeIfPresent(Bool.self, forKey: .masterEnabled) ?? true
            disabledDisplays = try c.decodeIfPresent([CGDirectDisplayID].self, forKey: .disabledDisplays) ?? []
            hiddenFromCapture = try c.decodeIfPresent(Bool.self, forKey: .hiddenFromCapture) ?? true
        }
    }

    static let defaultsKey = "overlaySettings"
    private let defaults: UserDefaults
    private var saveCancellable: AnyCancellable?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let data = defaults.data(forKey: Self.defaultsKey),
           let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) {
            red = snapshot.red
            green = snapshot.green
            blue = snapshot.blue
            gamma = snapshot.gamma
            // Clamp values saved before the current limits existed.
            opacity = min(snapshot.opacity, Self.maxOpacity)
            tileSize = snapshot.tileSize.clamped(to: Self.tileSizeRange)
            vignette = snapshot.vignette.clamped(to: 0...1)
            grainSize = snapshot.grainSize
            textureStyle = snapshot.textureStyle
            masterEnabled = snapshot.masterEnabled
            disabledDisplays = Set(snapshot.disabledDisplays)
            hiddenFromCapture = snapshot.hiddenFromCapture
            NSLog("PaperOverlay: restored settings (opacity=%.2f, tile=%.0f)",
                  opacity, tileSize)
        }

        // Debounced autosave: by the time the sink runs, the @Published
        // values that triggered objectWillChange are already updated.
        saveCancellable = objectWillChange
            .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.save()
            }
    }

    private func save() {
        let snapshot = Snapshot(
            red: red, green: green, blue: blue, gamma: gamma,
            opacity: opacity, tileSize: tileSize, vignette: vignette,
            grainSize: grainSize, textureStyle: textureStyle,
            masterEnabled: masterEnabled,
            disabledDisplays: Array(disabledDisplays),
            hiddenFromCapture: hiddenFromCapture
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: Self.defaultsKey)
        NSLog("PaperOverlay: settings saved")
    }

    var grainParameters: GrainParameters {
        GrainParameters(
            red: Float(red),
            green: Float(green),
            blue: Float(blue),
            gamma: Float(gamma),
            opacity: Float(opacity),
            grainSize: grainSize,
            tileSizePoints: Float(tileSize),
            textureStyle: textureStyle,
            vignette: Float(vignette)
        )
    }

    func apply(_ preset: Preset) {
        red = preset.red
        green = preset.green
        blue = preset.blue
        gamma = preset.gamma
        opacity = min(preset.opacity, Self.maxOpacity)
        grainSize = preset.grainSize
        tileSize = preset.tileSize.clamped(to: Self.tileSizeRange)
        textureStyle = preset.textureStyle
        vignette = preset.vignette.clamped(to: 0...1)
    }

    /// True when the current slider values exactly match the given preset.
    func matches(_ preset: Preset) -> Bool {
        red == preset.red && green == preset.green && blue == preset.blue
            && gamma == preset.gamma && opacity == preset.opacity
            && grainSize == preset.grainSize && tileSize == preset.tileSize
            && textureStyle == preset.textureStyle && vignette == preset.vignette
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
