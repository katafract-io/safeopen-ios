import SwiftUI
import StoreKit

struct AccountView: View {
    @StateObject private var store = SafeOpenStore.shared
    @EnvironmentObject var appState: AppState
    @State private var showBuyCredits = false
    @State private var showClearConfirm = false

    private let cyan = Color(red: 0, green: 0.83, blue: 1)

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }

    private var nextRefillRelative: String {
        guard store.nextRefillAt < .distantFuture else { return "—" }
        let now = Date()
        let delta = store.nextRefillAt.timeIntervalSince(now)
        if delta <= 0 {
            return "any moment"
        }
        let days  = Int(delta / 86400)
        let hours = Int((delta.truncatingRemainder(dividingBy: 86400)) / 3600)
        if days >= 2 {
            return "in \(days)d"
        } else if days == 1 {
            return "in 1d \(hours)h"
        } else if hours >= 1 {
            return "in \(hours)h"
        } else {
            let minutes = max(1, Int(delta / 60))
            return "in \(minutes)m"
        }
    }

    var body: some View {
        NavigationStack {
            List {

                Section {
                    Button { showBuyCredits = true } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "bolt.shield.fill")
                                .font(.title2)
                                .foregroundStyle(cyan)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Credits")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text("AI features cost 1 credit each. Basic inspection is free.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 0) {
                                HStack(spacing: 4) {
                                    if store.balanceIsStale {
                                        Image(systemName: "wifi.exclamationmark")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                    }
                                    Text("\(store.balance)")
                                        .font(.title2.bold())
                                        .foregroundStyle(cyan)
                                        .contentTransition(.numericText())
                                }
                                Text(store.balanceIsStale ? "offline · stale" : "balance")
                                    .font(.caption2)
                                    .foregroundStyle(store.balanceIsStale ? .orange : .secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    Button { showBuyCredits = true } label: {
                        Label("Buy Credits", systemImage: "plus.circle.fill")
                    }
                    // No "Restore Purchases" affordance — Apple rule 3.1.1 prohibits it for
                    // consumable-only apps. Pending-redemption recovery runs silently on launch.
                }

                Section("Support") {
                    Link(destination: URL(string: "https://katafract.com/privacy/safeopen")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    Link(destination: URL(string: "https://katafract.com/terms/safeopen")!) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                    Link(destination: URL(string: "https://katafract.com/support/safeopen")!) {
                        Label("Help &amp; Support", systemImage: "questionmark.circle")
                    }
                    Link(destination: URL(string: "mailto:support@katafract.com")!) {
                        Label("Contact Support", systemImage: "envelope")
                    }
                }

                Section("Data") {
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label("Clear History", systemImage: "trash")
                    }
                }

                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Next free top-up")
                            Text(store.freeBalance >= store.freeBalanceCap
                                 ? "Cap reached — top-up skipped until you use credits"
                                 : "+\(min(10, store.freeBalanceCap - store.freeBalance)) credits")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(nextRefillRelative)
                            .foregroundStyle(.secondary)
                            .font(.subheadline.monospacedDigit())
                    }
                    HStack {
                        Text("Free credits")
                        Spacer()
                        Text("\(store.freeBalance) / \(store.freeBalanceCap)")
                            .foregroundStyle(.secondary)
                            .font(.subheadline.monospacedDigit())
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion).foregroundStyle(.secondary)
                    }
                    if store.totalConsumed > 0 {
                        HStack {
                            Text("Credits used")
                            Spacer()
                            Text("\(store.totalConsumed)").foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Account")
            .sheet(isPresented: $showBuyCredits) {
                ProUpgradeView()
            }
            .confirmationDialog("Clear all scan history?", isPresented: $showClearConfirm, titleVisibility: .visible) {
                Button("Clear History", role: .destructive) { appState.clearHistory() }
                Button("Cancel", role: .cancel) { }
            }
            .task { await store.refreshBalance() }
            .overlay {
                if store.isPurchasing {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView().tint(cyan).scaleEffect(1.5)
                }
            }
        }
    }
}
