import SwiftUI
import StoreKit
import KatafractStyle

/// Buy Credits sheet. Replaces the old subscription paywall.
/// Three consumable IAPs grant scan credits.
struct ProUpgradeView: View {
    @StateObject private var store = SafeOpenStore.shared
    @Environment(\.dismiss) private var dismiss

    private let cyan = Color(red: 0, green: 0.83, blue: 1)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    VStack(spacing: 14) {
                        Image(systemName: "bolt.shield.fill")
                            .font(.system(size: 52, weight: .semibold))
                            .foregroundStyle(cyan)
                            .padding(.top, 32)

                        Text("Credits")
                            .font(.title.bold())

                        Text("AI summaries and link preview screenshots cost 1 credit each. URL inspection, risk scoring, and tracking-parameter stripping are always free.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                            .padding(.bottom, 8)
                    }
                    .frame(maxWidth: .infinity)

                    BalanceCard(balance: store.balance, nextRefill: store.nextRefillAt)
                        .padding(.horizontal, 16)
                        .padding(.top, 18)

                    VStack(spacing: 12) {
                        if store.products.isEmpty {
                            KataProgressRing(size: 28).padding(28)
                        } else {
                            ForEach(store.products, id: \.id) { product in
                                let offer = store.offers.first { $0.productId == product.id }
                                CreditPackRow(
                                    product: product,
                                    baseCredits: offer?.baseCredits ?? credits(for: product.id),
                                    bonusCredits: offer?.bonusCredits ?? 0,
                                    bonusType: offer?.bonusType ?? "",
                                    highlight: product.id == SafeOpenStore.standardID
                                ) {
                                    Task { await store.purchase(product) }
                                }
                                .disabled(store.isPurchasing)
                            }
                        }
                    }
                    .padding(16)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Credits never expire", systemImage: "infinity")
                        Label("No subscription, no auto-renewal", systemImage: "checkmark.circle")
                        Label("10 free credits added monthly (cap: \(store.freeBalanceCap))", systemImage: "gift")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    // NOTE: Apple rule 3.1.1 prohibits a user-facing "Restore Purchases" affordance
                    // for consumable-only apps. Pending-redemption recovery happens silently on app
                    // launch via SafeOpenStore.retryPendingRedemptions().

                    if let err = store.error {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                    }

                    Spacer(minLength: 30)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Buy Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                guard !ScreenshotMode.isEnabled else { return }
                await store.refreshBalance()
                await store.refreshOffers()
            }
            .overlay {
                if store.isPurchasing {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    KataProgressRing(size: 44)
                }
            }
        }
    }

    private func credits(for productID: String) -> Int {
        switch productID {
        case SafeOpenStore.standardID: return 500
        // Legacy grandfather mappings (if old user restores purchase)
        case SafeOpenStore.starterID:  return 100
        case SafeOpenStore.powerID:    return 2000
        default: return 0
        }
    }
}

private struct BalanceCard: View {
    let balance: Int
    let nextRefill: Date
    private let cyan = Color(red: 0, green: 0.83, blue: 1)

    var body: some View {
        VStack(spacing: 6) {
            Text("Current Balance")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1)
            Text("\(balance)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(cyan)
                .contentTransition(.numericText())
            Text("scan credits")
                .font(.caption)
                .foregroundStyle(.secondary)
            if nextRefill < .distantFuture {
                Text("Next free refill: \(nextRefill.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct CreditPackRow: View {
    let product: Product
    let baseCredits: Int
    let bonusCredits: Int
    let bonusType: String
    let highlight: Bool
    let action: () -> Void

    private let cyan   = Color(red: 0, green: 0.83, blue: 1)
    private let gold   = Color(red: 1.0, green: 0.78, blue: 0.24)

    private var totalCredits: Int { baseCredits + bonusCredits }
    private var hasBonus: Bool { bonusCredits > 0 }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("\(totalCredits)")
                            .font(.title2.bold())
                        Text("credits")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if highlight && !hasBonus {
                            Text("BEST VALUE")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(cyan.opacity(0.15), in: Capsule())
                                .foregroundStyle(cyan)
                        }
                        if hasBonus {
                            Text(bonusBadgeText)
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(gold.opacity(0.18), in: Capsule())
                                .foregroundStyle(gold)
                        }
                    }
                    if hasBonus {
                        Text("\(baseCredits) + \(bonusCredits) bonus")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(perCreditLabel)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                hasBonus ? gold.opacity(0.5) :
                                (highlight ? cyan.opacity(0.4) : Color.clear),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var bonusBadgeText: String {
        let pct = Int((Double(bonusCredits) / Double(baseCredits) * 100).rounded())
        switch bonusType {
        case "upgrade":    return "UPGRADE +\(pct)%"
        case "repurchase": return "LOYALTY +\(pct)%"
        default:           return "+\(pct)%"
        }
    }

    private var perCreditLabel: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceFormatStyle.locale
        formatter.maximumFractionDigits = 4
        let perCredit = NSDecimalNumber(decimal: product.price / Decimal(max(1, totalCredits)))
        return "\(formatter.string(from: perCredit) ?? "") per credit"
    }
}
