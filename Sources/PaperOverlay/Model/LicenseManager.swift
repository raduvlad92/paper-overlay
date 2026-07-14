import Foundation
import Security

/// Licensing stub. The full feature set is unlocked: `isLicensed` is always
/// true and nothing in the app gates on trial state. The first-run timestamp
/// is anchored in the Keychain so future trial tracking survives app
/// reinstalls and UserDefaults resets.
///
/// TODO(licensing): plug in the real checks here later:
///   - SaaS (subscription): validate a server-issued token and its expiry.
///   - Lifetime (one-time): validate an offline-verifiable license key.
/// No network calls, Stripe, or key-entry logic exist anywhere yet.
@MainActor
final class LicenseManager: ObservableObject {
    static let trialLengthDays = 14

    private static let keychainService = "com.raduvlad.PaperOverlay"
    private static let keychainAccount = "firstRunTimestamp"

    /// The date the app first ran on this machine, anchored in the Keychain.
    let firstRunDate: Date

    init() {
        firstRunDate = Self.loadOrCreateFirstRunDate()
        NSLog("PaperOverlay: license stub ready (firstRun=%@, daysRemaining=%ld, licensed=%d)",
              firstRunDate as NSDate, daysRemainingInTrial, isLicensed ? 1 : 0)
    }

    /// TODO(licensing): return the real entitlement state once SaaS/Lifetime
    /// license validation exists. Until then everything is unlocked.
    var isLicensed: Bool { true }

    var daysRemainingInTrial: Int {
        let elapsed = Calendar.current.dateComponents(
            [.day], from: firstRunDate, to: Date()
        ).day ?? 0
        return max(0, Self.trialLengthDays - elapsed)
    }

    /// Informational only — nothing is enforced when the trial "ends".
    /// TODO(licensing): gate features on `isTrialActive || isLicensed`.
    var isTrialActive: Bool { daysRemainingInTrial > 0 }

    // MARK: - Keychain anchor

    private static func loadOrCreateFirstRunDate() -> Date {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
        ]
        var result: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
           let data = result as? Data,
           let string = String(data: data, encoding: .utf8),
           let interval = TimeInterval(string) {
            return Date(timeIntervalSince1970: interval)
        }

        let now = Date()
        let payload = String(now.timeIntervalSince1970).data(using: .utf8)!
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: payload,
        ]
        let status = SecItemAdd(attributes as CFDictionary, nil)
        if status != errSecSuccess {
            NSLog("PaperOverlay: keychain first-run anchor failed (%d), using in-memory date",
                  status)
        }
        return now
    }
}
