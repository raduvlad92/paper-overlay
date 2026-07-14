import Foundation

/// A saved combination of all shader parameters.
struct Preset: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var red: Double
    var green: Double
    var blue: Double
    var gamma: Double
    var opacity: Double
    var grainSize: GrainSize
    var tileSize: Double
    var isBuiltIn: Bool = false

    static let builtIns: [Preset] = [
        Preset(name: "Neutral", red: 0.75, green: 0.75, blue: 0.75,
               gamma: 1.0, opacity: 0.12, grainSize: .fine, tileSize: 256, isBuiltIn: true),
        Preset(name: "Warm", red: 0.90, green: 0.78, blue: 0.55,
               gamma: 1.0, opacity: 0.15, grainSize: .fine, tileSize: 256, isBuiltIn: true),
        Preset(name: "Sepia", red: 0.82, green: 0.66, blue: 0.45,
               gamma: 1.15, opacity: 0.20, grainSize: .medium, tileSize: 256, isBuiltIn: true),
        Preset(name: "Night", red: 0.60, green: 0.45, blue: 0.25,
               gamma: 1.30, opacity: 0.25, grainSize: .ultraFine, tileSize: 192, isBuiltIn: true),
        Preset(name: "Reading", red: 0.95, green: 0.88, blue: 0.72,
               gamma: 0.90, opacity: 0.18, grainSize: .coarse, tileSize: 320, isBuiltIn: true),
    ]
}
