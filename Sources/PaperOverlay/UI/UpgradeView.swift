import SwiftUI

/// Visual placeholder for the future paid tiers. Entirely inert: no payment
/// logic, no network calls, no license key entry.
struct UpgradeView: View {
    @EnvironmentObject private var license: LicenseManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Support Paper Overlay and unlock everything, forever.", bundle: .appModule)
                .font(.caption)
                .foregroundStyle(.secondary)

            PricingCard(
                titleKey: "Lifetime",
                priceKey: "$19 one-time",
                detailKey: "Pay once, keep every feature and update."
            )
            PricingCard(
                titleKey: "Subscription",
                priceKey: "$1.49 / month",
                detailKey: "All features while your subscription is active."
            )

            Text("Purchasing isn't available yet — every feature is currently free.",
                 bundle: .appModule)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}

private struct PricingCard: View {
    let titleKey: LocalizedStringKey
    let priceKey: LocalizedStringKey
    let detailKey: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(titleKey, bundle: .appModule)
                    .font(.subheadline.bold())
                Spacer()
                Text(priceKey, bundle: .appModule)
                    .font(.subheadline.monospacedDigit())
            }
            Text(detailKey, bundle: .appModule)
                .font(.caption)
                .foregroundStyle(.secondary)

            // TODO(licensing): wire this to the real checkout flow —
            // Lifetime: one-time purchase + offline license key validation;
            // Subscription: SaaS entitlement check. Inert by design for now.
            Button {
                // Intentionally does nothing.
            } label: {
                Text("Coming soon", bundle: .appModule)
                    .frame(maxWidth: .infinity)
            }
            .disabled(true)
            .controlSize(.small)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary.opacity(0.5)))
    }
}
