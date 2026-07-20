import SwiftUI

struct OptionsView: View {
    @EnvironmentObject private var settings: OverlaySettings
    @EnvironmentObject private var hotkeys: HotkeyManager
    @EnvironmentObject private var schedule: ScheduleManager
    @EnvironmentObject private var presetStore: PresetStore
    @EnvironmentObject private var updates: UpdateManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $settings.hiddenFromCapture) {
                Text("Hide from screenshots & screen sharing", bundle: .appModule)
            }
            .toggleStyle(.switch)
            .controlSize(.small)

            Text("You see the overlay, but screenshots, recordings, and video-call screen shares stay clean.",
                 bundle: .appModule)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            HStack {
                Text("Toggle overlay shortcut", bundle: .appModule)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    hotkeys.isRecording ? hotkeys.cancelRecording() : hotkeys.beginRecording()
                } label: {
                    if hotkeys.isRecording {
                        Text("Press keys…", bundle: .appModule)
                    } else if let shortcut = hotkeys.shortcut {
                        Text(shortcut.display)
                    } else {
                        Text("Record", bundle: .appModule)
                    }
                }
                .controlSize(.small)

                if hotkeys.shortcut != nil && !hotkeys.isRecording {
                    Button {
                        hotkeys.clearShortcut()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .help(Text("Remove shortcut", bundle: .appModule))
                }
            }

            Text("Works system-wide. Include ⌘, ⌃, or ⌥; press Esc to cancel recording.",
                 bundle: .appModule)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            Toggle(isOn: $schedule.config.enabled) {
                Text("Switch presets on a schedule", bundle: .appModule)
            }
            .toggleStyle(.switch)
            .controlSize(.small)

            if schedule.config.enabled {
                HStack {
                    Text("Night from", bundle: .appModule)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    DatePicker("", selection: minutesBinding(\.nightStartMinutes),
                               displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .controlSize(.small)
                    Text("to", bundle: .appModule)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    DatePicker("", selection: minutesBinding(\.nightEndMinutes),
                               displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .controlSize(.small)
                }

                presetPicker(titleKey: "Day preset", selection: $schedule.config.dayPresetID)
                presetPicker(titleKey: "Night preset", selection: $schedule.config.nightPresetID)

                Text("Manual changes stay until the next switch.", bundle: .appModule)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Divider()

            Toggle(isOn: $updates.autoCheckEnabled) {
                Text("Check for updates automatically", bundle: .appModule)
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .disabled(!updates.isAvailable)

            HStack {
                Button {
                    updates.checkNow(force: true)
                } label: {
                    Text("Check Now", bundle: .appModule)
                }
                .controlSize(.small)
                .disabled(!updates.isAvailable || updates.state == .checking)

                Spacer()

                if let lastCheckedAt = updates.lastCheckedAt {
                    HStack(spacing: 4) {
                        Text("Last checked", bundle: .appModule)
                        Text(Self.relativeTime(lastCheckedAt))
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                }
            }

            Text(updates.isAvailable
                 ? "Checks github.com once per hour. Nothing else is sent."
                 : "Available in the packaged app.",
                 bundle: .appModule)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private static func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func presetPicker(titleKey: LocalizedStringKey, selection: Binding<UUID?>) -> some View {
        HStack {
            Text(titleKey, bundle: .appModule)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Picker("", selection: selection) {
                Text("None", bundle: .appModule).tag(UUID?.none)
                ForEach(Preset.builtIns + presetStore.customPresets) { preset in
                    Text(preset.name).tag(Optional(preset.id))
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .controlSize(.small)
            .fixedSize()
        }
    }

    private func minutesBinding(_ keyPath: WritableKeyPath<ScheduleManager.Config, Int>) -> Binding<Date> {
        Binding(
            get: {
                let minutes = schedule.config[keyPath: keyPath]
                return Calendar.current.date(bySettingHour: minutes / 60,
                                             minute: minutes % 60,
                                             second: 0, of: Date()) ?? Date()
            },
            set: { date in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                schedule.config[keyPath: keyPath] = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
            }
        )
    }
}
