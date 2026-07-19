import AppKit
import Carbon.HIToolbox

/// System-wide shortcut that toggles the overlay. Uses Carbon's
/// RegisterEventHotKey, which works for background (LSUIElement) apps and —
/// unlike NSEvent global monitors for key events — requires no Accessibility
/// permission.
@MainActor
final class HotkeyManager: ObservableObject {
    struct Shortcut: Codable, Equatable {
        var keyCode: UInt32
        var carbonModifiers: UInt32
        var display: String
    }

    static let defaultsKey = "toggleShortcut"

    @Published private(set) var shortcut: Shortcut?
    @Published private(set) var isRecording = false

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var recordMonitor: Any?
    private let defaults: UserDefaults
    private let onTrigger: () -> Void

    init(defaults: UserDefaults = .standard, onTrigger: @escaping () -> Void) {
        self.defaults = defaults
        self.onTrigger = onTrigger

        if let data = defaults.data(forKey: Self.defaultsKey),
           let saved = try? JSONDecoder().decode(Shortcut.self, from: data) {
            shortcut = saved
        }
        installCarbonHandler()
        registerCurrentShortcut()
    }

    // MARK: - Recording

    func beginRecording() {
        guard recordMonitor == nil else { return }
        isRecording = true
        recordMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            MainActor.assumeIsolated {
                self.handleRecorded(event: event)
            }
            return nil // swallow the keystroke while recording
        }
    }

    func cancelRecording() {
        if let monitor = recordMonitor {
            NSEvent.removeMonitor(monitor)
            recordMonitor = nil
        }
        isRecording = false
    }

    func clearShortcut() {
        cancelRecording()
        shortcut = nil
        defaults.removeObject(forKey: Self.defaultsKey)
        unregister()
    }

    private func handleRecorded(event: NSEvent) {
        if event.keyCode == UInt16(kVK_Escape) {
            cancelRecording()
            return
        }

        let flags = event.modifierFlags.intersection([.command, .control, .option, .shift])
        // Require a real chord so typing plain letters can't become a hotkey.
        guard flags.contains(.command) || flags.contains(.control) || flags.contains(.option) else {
            NSSound.beep()
            return
        }

        var carbonMods: UInt32 = 0
        var symbols = ""
        if flags.contains(.control) { carbonMods |= UInt32(controlKey); symbols += "⌃" }
        if flags.contains(.option) { carbonMods |= UInt32(optionKey); symbols += "⌥" }
        if flags.contains(.shift) { carbonMods |= UInt32(shiftKey); symbols += "⇧" }
        if flags.contains(.command) { carbonMods |= UInt32(cmdKey); symbols += "⌘" }

        let keyLabel = (event.charactersIgnoringModifiers ?? "?").uppercased()
        let new = Shortcut(keyCode: UInt32(event.keyCode),
                           carbonModifiers: carbonMods,
                           display: symbols + keyLabel)

        cancelRecording()
        shortcut = new
        if let data = try? JSONEncoder().encode(new) {
            defaults.set(data, forKey: Self.defaultsKey)
        }
        registerCurrentShortcut()
        NSLog("PaperOverlay: hotkey set to %@", new.display)
    }

    // MARK: - Carbon registration

    private func installCarbonHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            guard let userData else { return noErr }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async {
                manager.onTrigger()
                NSLog("PaperOverlay: hotkey triggered")
            }
            return noErr
        }, 1, &eventType, selfPtr, &eventHandlerRef)
    }

    private func registerCurrentShortcut() {
        unregister()
        guard let shortcut else { return }
        let hotKeyID = EventHotKeyID(signature: OSType(0x504F_766C) /* 'POvl' */, id: 1)
        let status = RegisterEventHotKey(shortcut.keyCode, shortcut.carbonModifiers,
                                         hotKeyID, GetApplicationEventTarget(),
                                         0, &hotKeyRef)
        if status != noErr {
            NSLog("PaperOverlay: hotkey registration failed (%d)", status)
        } else {
            NSLog("PaperOverlay: hotkey registered (%@)", shortcut.display)
        }
    }

    private func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }
}
