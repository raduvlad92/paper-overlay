import SwiftUI

struct ControlsView: View {
    @EnvironmentObject private var settings: OverlaySettings

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Texture", bundle: .appModule)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: $settings.textureStyle) {
                    Text("Paper grain", bundle: .appModule).tag(TextureStyle.paperGrain)
                    Text("Canvas", bundle: .appModule).tag(TextureStyle.canvas)
                    Text("Parchment", bundle: .appModule).tag(TextureStyle.parchment)
                    Text("Newsprint", bundle: .appModule).tag(TextureStyle.newsprint)
                    Text("Linen", bundle: .appModule).tag(TextureStyle.linen)
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .controlSize(.small)
                .fixedSize()
            }

            ParameterSlider(titleKey: "Red", value: $settings.red, range: 0...1)
            ParameterSlider(titleKey: "Green", value: $settings.green, range: 0...1)
            ParameterSlider(titleKey: "Blue", value: $settings.blue, range: 0...1)
            ParameterSlider(titleKey: "Gamma", value: $settings.gamma, range: 0.2...3.0)
            ParameterSlider(titleKey: "Opacity", value: $settings.opacity,
                            range: 0...OverlaySettings.maxOpacity)

            HStack {
                Text("Grain size", bundle: .appModule)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: $settings.grainSize) {
                    Text("Finest", bundle: .appModule).tag(GrainSize.finest)
                    Text("Extra-fine", bundle: .appModule).tag(GrainSize.extraFine)
                    Text("Ultra-fine", bundle: .appModule).tag(GrainSize.ultraFine)
                    Text("Fine", bundle: .appModule).tag(GrainSize.fine)
                    Text("Medium", bundle: .appModule).tag(GrainSize.medium)
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .controlSize(.small)
                .fixedSize()
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("Pattern size", bundle: .appModule)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Text("Small", bundle: .appModule)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Slider(value: $settings.tileSize, in: OverlaySettings.tileSizeRange)
                        .controlSize(.small)
                    Text("Big", bundle: .appModule)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            ParameterSlider(titleKey: "Lamp light", value: $settings.vignette, range: 0...1)

            Text("Tip: True Tone and Night Shift add their own warmth on top of the overlay. If you use them, try the Neutral preset or lower Red.",
                 bundle: .appModule)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct ParameterSlider: View {
    let titleKey: LocalizedStringKey
    @Binding var value: Double
    let range: ClosedRange<Double>
    var format: String = "%.2f"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(titleKey, bundle: .appModule)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: format, value))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range)
                .controlSize(.small)
        }
    }
}
