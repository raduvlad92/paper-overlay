import SwiftUI

struct ControlsView: View {
    @EnvironmentObject private var settings: OverlaySettings

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
