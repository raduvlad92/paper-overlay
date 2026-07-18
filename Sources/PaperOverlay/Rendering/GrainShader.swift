/// Metal shader source, compiled at runtime with `MTLDevice.makeLibrary(source:)`.
///
/// The offline Metal compiler (`xcrun metal`) ships only with full Xcode, not
/// the Command Line Tools, so this project cannot pre-compile a .metallib.
/// Runtime compilation is a fully supported path with identical GPU
/// performance; the one-time compile cost at launch is a few milliseconds.
enum GrainShader {
    static let source = """
    #include <metal_stdlib>
    using namespace metal;

    constant float TAU = 6.28318530718;

    struct VertexOut {
        float4 position [[position]];
    };

    // Fullscreen triangle, no vertex buffer needed.
    vertex VertexOut grain_vertex(uint vid [[vertex_id]]) {
        float2 positions[3] = { float2(-1.0, -1.0), float2(3.0, -1.0), float2(-1.0, 3.0) };
        VertexOut out;
        out.position = float4(positions[vid], 0.0, 1.0);
        return out;
    }

    // All scalar floats so the Swift-side layout matches trivially.
    struct GrainUniforms {
        float red;        // per-channel tint intensity, 0..1
        float green;
        float blue;
        float gamma;      // applied to the noise value, 0.2..3
        float opacity;    // overall overlay opacity, 0..0.8
        float grainCell;  // noise cell size in *pixels* (grain size)
        float tileSize;   // seamless tile period in *pixels*
        float octaveMix;  // weight of the second, finer noise octave
        float style;      // TextureStyle raw value
    };

    float hash21(float2 p) {
        // Cheap 2D -> 1D hash, stable across GPUs (no trig, no large floats).
        uint2 q = uint2(int2(p));
        uint n = q.x * 1597334673u ^ q.y * 3812015801u;
        n = (n ^ (n >> 16)) * 2246822519u;
        n = (n ^ (n >> 13)) * 3266489917u;
        n ^= n >> 16;
        return float(n) * (1.0 / 4294967295.0);
    }

    // Value noise on a lattice of `cells` x `cells` cells spanning one tile,
    // with lattice indices wrapped so the tile repeats seamlessly.
    float tileableValueNoise(float2 tilePos, float cells, float tileSize, float seed) {
        float cellPx = tileSize / cells;
        float2 uv = tilePos / cellPx;
        float2 i = floor(uv);
        float2 f = uv - i;
        float2 s = f * f * (3.0 - 2.0 * f);

        float2 i00 = fmod(i + float2(0.0, 0.0), cells);
        float2 i10 = fmod(i + float2(1.0, 0.0), cells);
        float2 i01 = fmod(i + float2(0.0, 1.0), cells);
        float2 i11 = fmod(i + float2(1.0, 1.0), cells);

        float2 seedOff = float2(seed * 97.0, seed * 57.0);
        float v00 = hash21(i00 + seedOff);
        float v10 = hash21(i10 + seedOff);
        float v01 = hash21(i01 + seedOff);
        float v11 = hash21(i11 + seedOff);

        return mix(mix(v00, v10, s.x), mix(v01, v11, s.x), s.y);
    }

    // Largest period <= `desired` that divides tileSize exactly, so periodic
    // (sin-based) patterns stay seamless at the tile boundary.
    float wrappedPeriod(float tileSize, float desired) {
        float k = max(1.0, round(tileSize / max(desired, 2.0)));
        return tileSize / k;
    }

    fragment float4 grain_fragment(VertexOut in [[stage_in]],
                                   constant GrainUniforms &u [[buffer(0)]]) {
        float tileSize = max(u.tileSize, 8.0);
        float2 tilePos = fmod(in.position.xy, tileSize);

        // Integer cell count per tile keeps the wrap seamless.
        float cells = max(2.0, round(tileSize / max(u.grainCell, 1.0)));

        float base = tileableValueNoise(tilePos, cells, tileSize, 1.0);
        float fine = tileableValueNoise(tilePos, min(cells * 2.0, tileSize), tileSize, 2.0);
        // Per-pixel speckle from *absolute* screen coordinates, deliberately
        // not wrapped at the tile edge: it breaks up the tile periodicity so
        // no repeating pattern is visible even at small tile sizes.
        float speckle = hash21(floor(in.position.xy));

        int style = int(u.style + 0.5);
        float n;

        if (style == 1) {
            // Canvas: perpendicular thread weave + fiber noise.
            float period = wrappedPeriod(tileSize, u.grainCell * 7.0);
            float wx = 0.5 + 0.5 * sin(TAU * tilePos.x / period);
            float wy = 0.5 + 0.5 * sin(TAU * tilePos.y / period);
            float weave = 0.5 + 0.20 * (wx - 0.5) + 0.20 * (wy - 0.5);
            n = weave * 0.72 + fine * 0.28;
            n = mix(n, speckle, 0.12);
        } else if (style == 2) {
            // Parchment: large-cell mottling, several octaves, few speckles.
            float cellsL = max(2.0, round(tileSize / max(u.grainCell * 18.0, 8.0)));
            float m1 = tileableValueNoise(tilePos, cellsL, tileSize, 5.0);
            float m2 = tileableValueNoise(tilePos, min(cellsL * 2.0, tileSize), tileSize, 6.0);
            float m3 = tileableValueNoise(tilePos, min(cellsL * 4.0, tileSize), tileSize, 7.0);
            n = 0.5 * m1 + 0.3 * m2 + 0.2 * m3;
            n = mix(n, speckle, 0.08);
        } else if (style == 3) {
            // Newsprint: dense pulp speckle + faint horizontal banding.
            float band = 0.5 + 0.5 * sin(TAU * tilePos.y / wrappedPeriod(tileSize, u.grainCell * 3.0));
            n = speckle * 0.50 + base * 0.32 + band * 0.18;
        } else if (style == 4) {
            // Linen: diagonal weave, finer threads than canvas.
            float period = wrappedPeriod(tileSize, u.grainCell * 4.0);
            float d1 = 0.5 + 0.5 * sin(TAU * (tilePos.x + tilePos.y) / period);
            float d2 = 0.5 + 0.5 * sin(TAU * (tilePos.x - tilePos.y) / period);
            float weave = 0.5 + 0.17 * (d1 - 0.5) + 0.17 * (d2 - 0.5);
            n = weave * 0.68 + fine * 0.32;
            n = mix(n, speckle, 0.14);
        } else {
            // Paper grain (default): value noise + fine octave + speckle.
            n = base * (1.0 - u.octaveMix) + fine * u.octaveMix;
            n = mix(n, speckle, 0.3);
        }

        n = pow(clamp(n, 0.0, 1.0), max(u.gamma, 0.05));

        float3 tint = float3(u.red, u.green, u.blue);
        // Never fully opaque: 0.8 ceiling so the screen can't be covered.
        float alpha = clamp(u.opacity, 0.0, 0.8);
        // Premultiplied alpha for compositing over the transparent window.
        return float4(tint * n * alpha, alpha);
    }
    """
}
