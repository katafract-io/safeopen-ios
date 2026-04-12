import SwiftUI
import StoreKit

struct ProUpgradeView: View {
    @StateObject private var store = SafeOpenStore.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // ── Hero ─────────────────────────────────────────────
                    VStack(spacing: 12) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 52, weight: .semibold))
                            .foregroundStyle(Color(red: 0, green: 0.83, blue: 1))
                            .padding(.top, 36)

                        Text("SafeOpen Pro")
                            .font(.title.bold())

                        Text("AI-powered link analysis and a disposable IPv6 identity — your device never touches the destination.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 24)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 0, green: 0.83, blue: 1).opacity(0.08))

                    // ── Feature list ─────────────────────────────────────
                    VStack(alignment: .leading, spacing: 14) {
                        FeatureRow(icon: "sparkles",
                                   title: "AI link analysis",
                                   detail: "Know what a link does before you touch it — in plain English.")
                        FeatureRow(icon: "globe.badge.chevron.backward",
                                   title: "Disposable IPv6 identity",
                                   detail: "A fresh address per session — burned after 10 minutes.")
                        FeatureRow(icon: "eye.slash.fill",
                                   title: "Zero device IP exposure",
                                   detail: "The destination sees a unique datacenter IPv6, never your IP.")
                        FeatureRow(icon: "trash.fill",
                                   title: "No cookies, no cache",
                                   detail: "Isolated browser session wiped on close.")
                    }
                    .padding(24)

                    // ── Pricing ──────────────────────────────────────────
                    VStack(spacing: 12) {
                        if store.products.isEmpty {
                            ProgressView()
                                .padding()
                        } else {
                            if let annual = store.annual {
                                PriceButton(product: annual, badge: "Best Value") {
                                    Task { await store.purchase(annual) }
                                }
                            }
                            if let monthly = store.monthly {
                                PriceButton(product: monthly, badge: nil) {
                                    Task { await store.purchase(monthly) }
                                }
                            }
                        }

                        Button("Restore Purchases") {
                            Task { await store.restorePurchases() }
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)

                        if let err = store.error {
                            Text(err)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        Text("Payment charged to your Apple ID. Subscription auto-renews unless cancelled at least 24 hours before the end of the current period.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not Now") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .overlay {
                if store.isPurchasing {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView()
                        .tint(Color(red: 0, green: 0.83, blue: 1))
                        .scaleEffect(1.5)
                }
            }
            .onChange(of: store.isPro) { _, isPro in
                if isPro { dismiss() }
            }
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color(red: 0, green: 0.83, blue: 1))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Price Button

private struct PriceButton: View {
    let product: Product
    let badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(.subheadline.weight(.semibold))
                    if let badge {
                        Text(badge)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color(red: 0, green: 0.83, blue: 1))
                    }
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.subheadline.weight(.bold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .foregroundStyle(.primary)
    }
}
