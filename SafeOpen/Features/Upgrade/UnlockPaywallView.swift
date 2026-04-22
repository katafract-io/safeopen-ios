import SwiftUI
import StoreKit
import KatafractStyle

struct UnlockPaywallView: View {
    @StateObject private var entitlements = EntitlementService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isPurchasing = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 14) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 52, weight: .semibold))
                            .foregroundStyle(.kataSapphire)
                            .padding(.top, 32)

                        Text("Daily Limit Reached")
                            .font(.title.bold())

                        Text("You've used all 3 free scans today. Unlock unlimited scanning with a one-time purchase or subscribe to Enclave.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                            .padding(.bottom, 8)
                    }
                    .frame(maxWidth: .infinity)

                    // Two-option cards
                    VStack(spacing: 12) {
                        // 99¢ Unlock card
                        UnlockOptionCard(
                            title: "99¢ Unlock",
                            subtitle: "One-time purchase",
                            description: "Unlimited scans on this device forever. URL safety checks always free.",
                            price: "$0.99",
                            ctaText: "Unlock SafeOpen",
                            isPrimary: false,
                            isLoading: isPurchasing
                        ) {
                            Task { await performUnlockPurchase() }
                        }
                        .disabled(isPurchasing)

                        // Enclave card
                        EnclaveOptionCard(
                            isPrimary: true,
                            isLoading: isPurchasing
                        )
                    }
                    .padding(16)

                    // Features list
                    VStack(alignment: .leading, spacing: 10) {
                        FeatureRow(
                            icon: "infinity",
                            text: "99¢ unlock is yours forever"
                        )
                        FeatureRow(
                            icon: "checkmark.circle",
                            text: "Enclave tier adds VPN, DNS, and 7 other apps"
                        )
                        FeatureRow(
                            icon: "eye.slash",
                            text: "Enclave unlocks AI page preview (see what you're opening safely)"
                        )
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    // Error display
                    if let error = error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                    }

                    // Restore purchases link
                    Button(action: { Task { await entitlements.restorePurchases() } }) {
                        Text("Restore Purchases")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    .padding(.top, 16)

                    Spacer(minLength: 30)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Unlock SafeOpen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .overlay {
                if isPurchasing {
                    Color.black.opacity(0.35).ignoresSafeArea()
                }
            }
        }
    }

    // MARK: - Actions

    private func performUnlockPurchase() async {
        isPurchasing = true
        error = nil
        defer { isPurchasing = false }

        do {
            try await entitlements.purchaseUnlock()
            dismiss()
        } catch let entitlementError as EntitlementError {
            error = entitlementError.localizedDescription
        } catch {
            error = error.localizedDescription
        }
    }
}

// MARK: - Sub-views

struct UnlockOptionCard: View {
    let title: String
    let subtitle: String
    let description: String
    let price: String
    let ctaText: String
    let isPrimary: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline.bold())
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(description)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            HStack {
                VStack(alignment: .leading) {
                    Text(price)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                }

                Spacer()

                Button(action: action) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(ctaText)
                            .font(.footnote.bold())
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: 120)
                .frame(height: 36)
                .background(isPrimary ? Color.kataSapphire : Color.gray.opacity(0.3))
                .cornerRadius(8)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 100)
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct EnclaveOptionCard: View {
    let isPrimary: Bool
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Enclave")
                    .font(.headline.bold())
                    .foregroundStyle(.primary)

                Text("Platform subscription")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Unlimited scans + AI page preview + VPN + DNS protection + all utility apps")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text("$8/mo")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)

                    Text("or $64/yr")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: {}) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Subscribe")
                            .font(.footnote.bold())
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: 120)
                .frame(height: 36)
                .background(Color.kataSapphire)
                .cornerRadius(8)
                .disabled(true) // Placeholder — wire to actual Stripe subscription flow
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 100)
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        Label(text, systemImage: icon)
    }
}

#Preview {
    UnlockPaywallView()
}
