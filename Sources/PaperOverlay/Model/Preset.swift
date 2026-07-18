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
    var textureStyle: TextureStyle = .paperGrain
    var isBuiltIn: Bool = false

    init(id: UUID = UUID(), name: String, red: Double, green: Double, blue: Double,
         gamma: Double, opacity: Double, grainSize: GrainSize, tileSize: Double,
         textureStyle: TextureStyle = .paperGrain,
         isBuiltIn: Bool = false) {
        self.id = id
        self.name = name
        self.red = red
        self.green = green
        self.blue = blue
        self.gamma = gamma
        self.opacity = opacity
        self.grainSize = grainSize
        self.tileSize = tileSize
        self.textureStyle = textureStyle
        self.isBuiltIn = isBuiltIn
    }

    /// Tolerant decoding: fields added in later app versions fall back to
    /// defaults instead of failing the whole decode (which would silently
    /// discard the user's saved presets on upgrade).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Preset"
        red = try c.decodeIfPresent(Double.self, forKey: .red) ?? 0.85
        green = try c.decodeIfPresent(Double.self, forKey: .green) ?? 0.78
        blue = try c.decodeIfPresent(Double.self, forKey: .blue) ?? 0.62
        gamma = try c.decodeIfPresent(Double.self, forKey: .gamma) ?? 1.0
        opacity = try c.decodeIfPresent(Double.self, forKey: .opacity) ?? 0.14
        grainSize = try c.decodeIfPresent(GrainSize.self, forKey: .grainSize) ?? .ultraFine
        tileSize = try c.decodeIfPresent(Double.self, forKey: .tileSize) ?? 256
        textureStyle = try c.decodeIfPresent(TextureStyle.self, forKey: .textureStyle) ?? .paperGrain
        isBuiltIn = try c.decodeIfPresent(Bool.self, forKey: .isBuiltIn) ?? false
    }

    /// Stable IDs so schedules and UI selection can reference built-ins
    /// across launches and app versions.
    static let builtIns: [Preset] = [
        Preset(id: UUID(uuidString: "B0000000-0000-4000-8000-000000000001")!,
               name: "Neutral", red: 0.75, green: 0.75, blue: 0.75,
               gamma: 1.0, opacity: 0.12, grainSize: .ultraFine, tileSize: 256, isBuiltIn: true),
        Preset(id: UUID(uuidString: "B0000000-0000-4000-8000-000000000002")!,
               name: "Warm", red: 0.90, green: 0.78, blue: 0.55,
               gamma: 1.0, opacity: 0.15, grainSize: .ultraFine, tileSize: 256, isBuiltIn: true),
        Preset(id: UUID(uuidString: "B0000000-0000-4000-8000-000000000003")!,
               name: "Sepia", red: 0.82, green: 0.66, blue: 0.45,
               gamma: 1.15, opacity: 0.20, grainSize: .ultraFine, tileSize: 256, isBuiltIn: true),
        Preset(id: UUID(uuidString: "B0000000-0000-4000-8000-000000000004")!,
               name: "Night", red: 0.60, green: 0.45, blue: 0.25,
               gamma: 1.30, opacity: 0.25, grainSize: .ultraFine, tileSize: 192, isBuiltIn: true),
        Preset(id: UUID(uuidString: "B0000000-0000-4000-8000-000000000005")!,
               name: "Reading", red: 0.95, green: 0.88, blue: 0.72,
               gamma: 0.90, opacity: 0.18, grainSize: .ultraFine, tileSize: 320, isBuiltIn: true),
    ]

    static func find(id: UUID, customPresets: [Preset]) -> Preset? {
        builtIns.first { $0.id == id } ?? customPresets.first { $0.id == id }
    }
}
