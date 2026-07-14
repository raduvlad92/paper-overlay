import SwiftUI

struct ControlsView: View {
    @EnvironmentObject private var settings: OverlaySettings

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ParameterSlider(titleKey: "Red", value: $settings.red, range: 0...1)
            ParameterSlider(titleKey: "Green", value: $settings.green, range: 0...1)
            ParameterSlider(titleKey: "Blue", value: $settings.blue, range: 0...1)
            ParameterSlider(titleKey: "Gamma", value: $settings.gamma, range: 0.2...3.0)
            ParameterSlider(titleKey: "Opacity", value: $settings.opacity, range: 0...1)

            VStack(alignment: .leading, spacing: 2) {
                Text("Grain size", bundle: .module)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("", selection: $settings.grainSize) {
                    Text("Ultra-fine", bundle: .module).tag(GrainSize.ultraFine)
                    Text("Fine", bundle: .module).tag(GrainSize.fine)
                    Text("Medium", bundle: .module).tag(GrainSize.medium)
                    Text("Coarse", bundle: .module).tag(GrainSize.coarse)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            ParameterSlider(titleKey: "Tile size", value: $settings.tileSize,
                            range: 64...512, format: "%.0f px")
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
                Text(titleKey, bundle: .module)
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
