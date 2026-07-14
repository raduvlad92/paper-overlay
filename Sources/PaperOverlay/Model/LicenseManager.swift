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
        // Never show the keychain authorization dialog: reading an item that
        // was created by a differently-signed build of this app would
        // otherwise block launch behind a modal prompt. With interaction
        // disabled the read fails fast instead, and we recreate the anchor.
        //
        // TODO(licensing): once builds are signed with a stable Developer ID
        // identity, every build shares the item's ACL and the recreate path
        // stops resetting the anchor between updates.
        SecKeychainSetUserInteractionAllowed(false)
        defer { SecKeychainSetUserInteractionAllowed(true) }

        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
        ]

        var result: AnyObject?
        var query = baseQuery
        query[kSecReturnData as String] = true
        let readStatus = SecItemCopyMatching(query as CFDictionary, &result)
        if readStatus == errSecSuccess,
           let data = result as? Data,
           let string = String(data: data, encoding: .utf8),
           let interval = TimeInterval(string) {
            return Date(timeIntervalSince1970: interval)
        }

        if readStatus != errSecItemNotFound {
            // Item exists but this build can't read it (created by a
            // previous ad-hoc build). Replace it so this build owns it.
            NSLog("PaperOverlay: keychain anchor unreadable (%d), recreating", readStatus)
            SecItemDelete(baseQuery as CFDictionary)
        }

        let now = Date()
        var attributes = baseQuery
        attributes[kSecValueData as String] = String(now.timeIntervalSince1970).data(using: .utf8)!
        let addStatus = SecItemAdd(attributes as CFDictionary, nil)
        if addStatus != errSecSuccess {
            NSLog("PaperOverlay: keychain first-run anchor failed (%d), using in-memory date",
                  addStatus)
        }
        return now
    }
}
