import AppKit
import CryptoKit
import Foundation

/// Checks GitHub Releases for a newer version and installs it in place.
///
/// The install is quarantine-free by construction: files this app downloads
/// itself via URLSession never receive the com.apple.quarantine attribute
/// that browsers attach (that flag is what triggers Gatekeeper's "Not
/// Opened" block). So unlike re-downloading the .pkg from a browser, an
/// in-app update never shows a security prompt.
@MainActor
final class UpdateManager: ObservableObject {
    enum State: Equatable {
        case idle
        case checking
        case updateAvailable(version: String)
        case installing
        case error(String)
    }

    struct ReleaseInfo: Equatable {
        let version: String
        let zipURL: URL
        let shaURL: URL
    }

    enum UpdateError: LocalizedError {
        case badResponse
        case missingAssets
        case downloadFailed
        case checksumMismatch
        case extractionFailed
        case payloadMismatch
        case notInstalledLocation
        case permissionDenied

        var errorDescription: String? {
            switch self {
            case .badResponse: return "Couldn't reach GitHub."
            case .missingAssets: return "This release is missing update files."
            case .downloadFailed: return "Download failed."
            case .checksumMismatch: return "Downloaded file didn't verify. Try again later."
            case .extractionFailed: return "Couldn't unpack the update."
            case .payloadMismatch: return "Downloaded app didn't match the expected version."
            case .notInstalledLocation: return "App isn't running from /Applications."
            case .permissionDenied:
                return "Couldn't replace the app in Applications. Download the latest installer from GitHub and reinstall once — after that, updates install automatically."
            }
        }
    }

    static let repo = "raduvlad92/paper-overlay"
    private static let autoCheckKey = "updateAutoCheckEnabled"
    private static let promptedVersionKey = "updatePromptedVersion"
    private static let lastCheckedKey = "updateLastCheckedAt"
    private static let hourlyInterval: TimeInterval = 3600

    @Published private(set) var state: State = .idle
    @Published var autoCheckEnabled: Bool {
        didSet {
            defaults.set(autoCheckEnabled, forKey: Self.autoCheckKey)
            if autoCheckEnabled { checkNow() }
        }
    }
    @Published private(set) var lastCheckedAt: Date?

    /// Drives the menu bar badge: true while there's something to install or
    /// an install is in progress.
    var isUpdateAvailable: Bool {
        switch state {
        case .updateAvailable, .installing: return true
        default: return false
        }
    }

    /// SMAppService-style guard: updating an unbundled `swift run` checkout
    /// makes no sense, and Bundle.main.bundleURL wouldn't be /Applications.
    let isAvailable: Bool
    private let currentVersion: String
    private let defaults: UserDefaults
    private var pendingRelease: ReleaseInfo?
    private var timer: Timer?
    private var wakeObserver: NSObjectProtocol?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isAvailable = Bundle.main.bundlePath.hasSuffix(".app")
        self.currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        self.autoCheckEnabled = defaults.object(forKey: Self.autoCheckKey) as? Bool ?? true
        if let interval = defaults.object(forKey: Self.lastCheckedKey) as? Double {
            lastCheckedAt = Date(timeIntervalSince1970: interval)
        }

        guard isAvailable else {
            NSLog("PaperOverlay: updater disabled (unbundled)")
            return
        }

        // First check shortly after launch (let startup settle), then hourly.
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            self?.checkIfEnabled()
        }
        timer = Timer.scheduledTimer(withTimeInterval: Self.hourlyInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkIfEnabled() }
        }
        timer.map { RunLoop.main.add($0, forMode: .common) }

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkIfEnabled() }
        }
    }

    private func checkIfEnabled() {
        guard autoCheckEnabled else { return }
        checkNow()
    }

    // MARK: - Check

    func checkNow(force: Bool = false) {
        guard isAvailable else { return }
        if !force, state == .checking { return }
        state = .checking

        let effectiveCurrent = ProcessInfo.processInfo.environment["PO_DEBUG_FAKE_VERSION"] ?? currentVersion

        Task {
            do {
                let info = try await fetchLatestRelease()
                lastCheckedAt = Date()
                defaults.set(Date().timeIntervalSince1970, forKey: Self.lastCheckedKey)

                if Self.isNewer(info.version, than: effectiveCurrent) {
                    pendingRelease = info
                    state = .updateAvailable(version: info.version)
                    NSLog("PaperOverlay: update available (%@ -> %@)", effectiveCurrent, info.version)
                    maybePrompt(info: info)
                } else {
                    pendingRelease = nil
                    state = .idle
                }
            } catch {
                NSLog("PaperOverlay: update check failed: %@", String(describing: error))
                // Fail quietly: a background check failing (offline, GitHub
                // hiccup) shouldn't surface as a persistent error banner.
                state = .idle
            }
        }
    }

    private func maybePrompt(info: ReleaseInfo) {
        guard defaults.string(forKey: Self.promptedVersionKey) != info.version else { return }
        defaults.set(info.version, forKey: Self.promptedVersionKey)

        if ProcessInfo.processInfo.environment["PO_DEBUG_AUTOINSTALL"] == "1" {
            install()
            return
        }

        let alert = NSAlert()
        alert.messageText = "Paper Overlay \(info.version) is available"
        alert.informativeText = "It installs automatically and relaunches the app — no security prompts."
        alert.addButton(withTitle: "Install Now")
        alert.addButton(withTitle: "Later")
        alert.alertStyle = .informational
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            install()
        }
    }

    // MARK: - Install

    func install() {
        guard let info = pendingRelease else { return }
        state = .installing

        Task {
            do {
                let zipData = try await download(info.zipURL)
                let shaText = try await downloadText(info.shaURL)
                let actual = SHA256.hash(data: zipData).map { String(format: "%02x", $0) }.joined()
                let expected = shaText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                guard actual == expected else { throw UpdateError.checksumMismatch }

                try performInstall(zipData: zipData, expectedVersion: info.version)
                // performInstall relaunches and terminates on success, so
                // reaching here means it threw before that point.
            } catch {
                NSLog("PaperOverlay: update install failed: %@", String(describing: error))
                state = .error((error as? LocalizedError)?.errorDescription ?? "Update failed.")
            }
        }
    }

    private func performInstall(zipData: Data, expectedVersion: String) throws {
        let fm = FileManager.default
        let workDir = try fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("PaperOverlay-update", isDirectory: true)
        try? fm.removeItem(at: workDir)
        try fm.createDirectory(at: workDir, withIntermediateDirectories: true)

        let zipPath = workDir.appendingPathComponent("update.zip")
        try zipData.write(to: zipPath)

        // ditto is the standard macOS archive tool and ships without Xcode.
        let unzip = Process()
        unzip.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        unzip.arguments = ["-x", "-k", zipPath.path, workDir.path]
        try unzip.run()
        unzip.waitUntilExit()
        guard unzip.terminationStatus == 0 else { throw UpdateError.extractionFailed }

        let newAppURL = workDir.appendingPathComponent("PaperOverlay.app")
        guard let bundle = Bundle(url: newAppURL),
              bundle.bundleIdentifier == "com.raduvlad.PaperOverlay",
              let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String,
              version == expectedVersion else {
            throw UpdateError.payloadMismatch
        }

        let installedURL = Bundle.main.bundleURL
        guard installedURL.path == "/Applications/PaperOverlay.app" else {
            throw UpdateError.notInstalledLocation
        }

        // The installed bundle must be owned by the current user for this
        // to work — the pkg installer's postinstall script chowns it away
        // from the root:wheel ownership pkgbuild uses by default. Installs
        // from before that fix (or a manually copied bundle) are still
        // root-owned; surface a clear one-time fix instead of a cryptic
        // POSIX error.
        do {
            try fm.trashItem(at: installedURL, resultingItemURL: nil)
        } catch {
            throw UpdateError.permissionDenied
        }
        try fm.moveItem(at: newAppURL, to: installedURL)
        try? fm.removeItem(at: workDir)

        NSLog("PaperOverlay: update installed (%@), relaunching", expectedVersion)
        relaunchAndQuit(at: installedURL)
    }

    private func relaunchAndQuit(at url: URL) {
        let reopen = Process()
        reopen.executableURL = URL(fileURLWithPath: "/bin/sh")
        reopen.arguments = ["-c", "sleep 0.5; open \"\(url.path)\""]
        try? reopen.run()
        NSApp.terminate(nil)
    }

    // MARK: - Networking

    private func fetchLatestRelease() async throws -> ReleaseInfo {
        let url = URL(string: "https://api.github.com/repos/\(Self.repo)/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw UpdateError.badResponse
        }

        let release = try JSONDecoder().decode(GHRelease.self, from: data)
        let version = release.tag_name.hasPrefix("v") ? String(release.tag_name.dropFirst()) : release.tag_name
        guard let zipAsset = release.assets.first(where: { $0.name.hasSuffix(".zip") }),
              let shaAsset = release.assets.first(where: { $0.name.hasSuffix(".zip.sha256") }),
              let zipURL = URL(string: zipAsset.browser_download_url),
              let shaURL = URL(string: shaAsset.browser_download_url) else {
            throw UpdateError.missingAssets
        }
        return ReleaseInfo(version: version, zipURL: zipURL, shaURL: shaURL)
    }

    private func download(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw UpdateError.downloadFailed
        }
        return data
    }

    private func downloadText(_ url: URL) async throws -> String {
        let data = try await download(url)
        guard let text = String(data: data, encoding: .utf8) else { throw UpdateError.downloadFailed }
        return text
    }

    // MARK: - Version comparison

    static func isNewer(_ a: String, than b: String) -> Bool {
        func components(_ s: String) -> [Int] { s.split(separator: ".").map { Int($0) ?? 0 } }
        let ca = components(a), cb = components(b)
        for i in 0..<max(ca.count, cb.count) {
            let x = i < ca.count ? ca[i] : 0
            let y = i < cb.count ? cb[i] : 0
            if x != y { return x > y }
        }
        return false
    }
}

private struct GHRelease: Decodable {
    let tag_name: String
    let assets: [GHAsset]
}

private struct GHAsset: Decodable {
    let name: String
    let browser_download_url: String
}
