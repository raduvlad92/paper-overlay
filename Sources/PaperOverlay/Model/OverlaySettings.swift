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
    @Published var grainSize: GrainSize = .fine
    @Published var tileSize: Double = 256 // points, 64...512
    @Published var masterEnabled: Bool = true
    @Published var disabledDisplays: Set<CGDirectDisplayID> = []

    var grainParameters: GrainParameters {
        GrainParameters(
            red: Float(red),
            green: Float(green),
            blue: Float(blue),
            gamma: Float(gamma),
            opacity: Float(opacity),
            grainSize: grainSize,
            tileSizePoints: Float(tileSize)
        )
    }

    func apply(_ preset: Preset) {
        red = preset.red
        green = preset.green
        blue = preset.blue
        gamma = preset.gamma
        opacity = preset.opacity
        grainSize = preset.grainSize
        tileSize = preset.tileSize
    }

    /// True when the current slider values exactly match the given preset.
    func matches(_ preset: Preset) -> Bool {
        red == preset.red && green == preset.green && blue == preset.blue
            && gamma == preset.gamma && opacity == preset.opacity
            && grainSize == preset.grainSize && tileSize == preset.tileSize
    }
}
