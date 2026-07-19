import MetalKit

/// Procedural texture families rendered by the shader.
enum TextureStyle: Int, CaseIterable, Codable {
    case paperGrain = 0
    case canvas = 1
    case parchment = 2
    case newsprint = 3
    case linen = 4

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(Int.self)
        self = TextureStyle(rawValue: raw) ?? .paperGrain
    }
}

/// Grain size levels exposed in the UI, finest to medium.
/// Raw values are stable persistence identifiers: 3 was "coarse" (removed),
/// and the two finer-than-ultra-fine levels were added later as 4 and 5.
enum GrainSize: Int, CaseIterable, Codable {
    case ultraFine = 0
    case fine = 1
    case medium = 2
    case finest = 4
    case extraFine = 5

    /// UI/display order, finest grain first.
    static var allCases: [GrainSize] { [.finest, .extraFine, .ultraFine, .fine, .medium] }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(Int.self)
        // Raw value 3 ("coarse") no longer exists; map old saved settings
        // and presets to the closest remaining size.
        self = GrainSize(rawValue: raw) ?? .medium
    }

    /// Noise cell size in points (scaled to pixels per display).
    var cellPoints: Float {
        switch self {
        case .finest: return 0.5
        case .extraFine: return 0.75
        case .ultraFine: return 1.0
        case .fine: return 2.0
        case .medium: return 3.5
        }
    }

    var octaveMix: Float {
        switch self {
        case .finest: return 0.65
        case .extraFine: return 0.60
        case .ultraFine: return 0.55
        case .fine: return 0.45
        case .medium: return 0.35
        }
    }
}

/// The full set of shader parameters. Milestone 3 uses the defaults;
/// the dashboard drives them later.
struct GrainParameters: Equatable {
    var red: Float = 0.85
    var green: Float = 0.78
    var blue: Float = 0.62
    var gamma: Float = 1.0
    var opacity: Float = 0.14 // capped at 0.8 so the screen is never fully covered
    var grainSize: GrainSize = .ultraFine
    var tileSizePoints: Float = 256 // 160...512
    var textureStyle: TextureStyle = .paperGrain
    var vignette: Float = 0 // lamp-light edge darkening, 0..1
}

/// Must mirror the Metal-side GrainUniforms struct (all scalar floats,
/// so layout matches without alignment concerns).
private struct GrainUniforms {
    var red: Float
    var green: Float
    var blue: Float
    var gamma: Float
    var opacity: Float
    var grainCell: Float
    var tileSize: Float
    var octaveMix: Float
    var style: Float
    var vignette: Float
    var viewportW: Float
    var viewportH: Float
}

enum GrainRendererError: Error {
    case noDevice
    case pipelineCreationFailed(String)
}

/// Shared Metal state: one device, library, and pipeline for all overlay views.
final class GrainPipeline {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let pipelineState: MTLRenderPipelineState

    static let shared: GrainPipeline? = {
        do {
            let pipeline = try GrainPipeline()
            NSLog("PaperOverlay: Metal shader compiled at runtime, pipeline ready (device=%@)",
                  pipeline.device.name)
            return pipeline
        } catch {
            NSLog("PaperOverlay: FATAL Metal setup failed: %@", String(describing: error))
            return nil
        }
    }()

    private init() throws {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue() else {
            throw GrainRendererError.noDevice
        }
        self.device = device
        self.commandQueue = queue

        // Runtime compile: the offline `metal` compiler isn't in the CLT.
        let library = try device.makeLibrary(source: GrainShader.source, options: nil)
        guard let vertexFn = library.makeFunction(name: "grain_vertex"),
              let fragmentFn = library.makeFunction(name: "grain_fragment") else {
            throw GrainRendererError.pipelineCreationFailed("shader functions not found")
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFn
        descriptor.fragmentFunction = fragmentFn
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        self.pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
    }
}

/// An MTKView that renders the procedural grain. It is paused and only
/// redraws when `parameters` change or the system invalidates it, so GPU
/// usage is effectively zero while the overlay is static.
final class GrainOverlayView: MTKView, MTKViewDelegate {
    private let pipeline: GrainPipeline

    var parameters: GrainParameters {
        didSet {
            if parameters != oldValue { needsDisplay = true }
        }
    }

    init(frame: CGRect, pipeline: GrainPipeline, parameters: GrainParameters) {
        self.pipeline = pipeline
        self.parameters = parameters
        super.init(frame: frame, device: pipeline.device)

        colorPixelFormat = .bgra8Unorm
        clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        isPaused = true
        enableSetNeedsDisplay = true
        framebufferOnly = true
        layer?.isOpaque = false
        delegate = self
    }

    @available(*, unavailable)
    required init(coder: NSCoder) { fatalError("not supported") }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        needsDisplay = true
    }

    func draw(in view: MTKView) {
        guard let descriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let commandBuffer = pipeline.commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

        let scale = Float(window?.backingScaleFactor ?? 2.0)
        var uniforms = GrainUniforms(
            red: parameters.red,
            green: parameters.green,
            blue: parameters.blue,
            gamma: parameters.gamma,
            opacity: parameters.opacity,
            grainCell: parameters.grainSize.cellPoints * scale,
            tileSize: parameters.tileSizePoints * scale,
            octaveMix: parameters.grainSize.octaveMix,
            style: Float(parameters.textureStyle.rawValue),
            vignette: parameters.vignette,
            viewportW: Float(view.drawableSize.width),
            viewportH: Float(view.drawableSize.height)
        )

        encoder.setRenderPipelineState(pipeline.pipelineState)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<GrainUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
