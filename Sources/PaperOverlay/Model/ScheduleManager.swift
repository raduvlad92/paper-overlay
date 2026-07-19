import AppKit
import Combine

/// Time-based automatic preset switching (e.g. warmer/dimmer at night).
/// Applies a preset only when crossing a boundary (or when the schedule
/// config itself changes), so manual slider tweaks always win until the
/// next boundary — the app never fights the user.
@MainActor
final class ScheduleManager: ObservableObject {
    struct Config: Codable, Equatable {
        var enabled: Bool = false
        var nightStartMinutes: Int = 20 * 60 // 20:00
        var nightEndMinutes: Int = 7 * 60    // 07:00
        var dayPresetID: UUID?
        var nightPresetID: UUID?

        init() {}

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? false
            nightStartMinutes = try c.decodeIfPresent(Int.self, forKey: .nightStartMinutes) ?? 20 * 60
            nightEndMinutes = try c.decodeIfPresent(Int.self, forKey: .nightEndMinutes) ?? 7 * 60
            dayPresetID = try c.decodeIfPresent(UUID.self, forKey: .dayPresetID)
            nightPresetID = try c.decodeIfPresent(UUID.self, forKey: .nightPresetID)
        }
    }

    static let defaultsKey = "schedule"

    @Published var config: Config {
        didSet {
            guard config != oldValue else { return }
            persist()
            evaluate(force: true)
        }
    }

    private var timer: Timer?
    private var wakeObserver: NSObjectProtocol?
    private var lastIsNight: Bool?
    private let settings: OverlaySettings
    private let presetStore: PresetStore
    private let defaults: UserDefaults

    init(settings: OverlaySettings, presetStore: PresetStore,
         defaults: UserDefaults = .standard) {
        self.settings = settings
        self.presetStore = presetStore
        self.defaults = defaults

        if let data = defaults.data(forKey: Self.defaultsKey),
           let saved = try? JSONDecoder().decode(Config.self, from: data) {
            config = saved
        } else {
            config = Config()
        }

        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.evaluate()
            }
        }
        timer.map { RunLoop.main.add($0, forMode: .common) }

        // A sleep can skip right over a boundary; re-evaluate on wake.
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.evaluate()
            }
        }

        evaluate(force: true)
    }

    var isNightNow: Bool {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let now = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        let start = config.nightStartMinutes
        let end = config.nightEndMinutes
        if start == end { return false }
        if start < end { return now >= start && now < end }
        return now >= start || now < end // window wraps past midnight
    }

    private func evaluate(force: Bool = false) {
        guard config.enabled else {
            lastIsNight = nil
            return
        }
        let night = isNightNow
        guard force || lastIsNight != night else { return }
        lastIsNight = night

        let presetID = night ? config.nightPresetID : config.dayPresetID
        guard let presetID,
              let preset = Preset.find(id: presetID, customPresets: presetStore.customPresets) else {
            return
        }
        settings.apply(preset)
        NSLog("PaperOverlay: schedule applied %@ preset '%@'",
              night ? "night" : "day", preset.name)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        defaults.set(data, forKey: Self.defaultsKey)
    }
}
