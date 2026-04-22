import SwiftUI
import StoreKit
import KatafractStyle

struct AccountView: View {
    @StateObject private var store = SafeOpenStore.shared
    @EnvironmentObject var appState: AppState
    @State private var showBuyCredits = false
    @State private var showClearConfirm = false

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }

    private var nextRefillRelative: String {
        guard store.nextRefillAt < .distantFuture else { return "—" }
        let now = Date()
        let delta = store.nextRefillAt.timeIntervalSince(now)
        if delta <= 0 { return "any moment" }
        let days  = Int(delta / 86400)
        let hours = Int((delta.truncatingRemainder(dividingBy: 86400)) / 3600)
        if days >= 2        { return "in \(days)d" }
        else if days == 1  { return "in 1d \(hours)h" }
        else if hours >= 1 { return "in \(hours)h" }
        else               { return "in \(max(1, Int(delta / 60)))m" }
    }

    var body: some View {
        NavigationStack {
            List {

                // ── Credits sealed ledger (Opus hero move #3) ─────────────
                Section {
                    Button { showBuyCredits = true } label: {
                        CreditsLedgerView(
                            balance: store.balance,
                            freeBalance: store.freeBalance,
                            freeBalanceCap: store.freeBalanceCap,
                            isStale: store.balanceIsStale
                        )
                    }
                    .buttonStyle(.plain)
                }

                Section {
                    Button { showBuyCredits = true } label: {
                        Label("Buy Credits", systemImage: "plus.circle.fill")
                    }
                }

                Section("Support") {
                    Link(destination: URL(string: "https://katafract.com/privacy/safeopen")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    Link(destination: URL(string: "https://katafract.com/terms/safeopen")!) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                    Link(destination: URL(string: "https://katafract.com/support/safeopen")!) {
                        Label("Help & Support", systemImage: "questionmark.circle")
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
                    KataProgressRing(size: 44)
                }
            }
        }
    }
}

// MARK: - Credits Sealed Ledger View

private struct CreditsLedgerView: View {
    let balance: Int
    let freeBalance: Int
    let freeBalanceCap: Int
    let isStale: Bool

    @State private var hairlineOpacity: Double = 0.4
    @State private var previousBalance: Int = 0

    private var ratio: Double {
        let cap = Double(max(1, freeBalanceCap))
        return min(1.0, Double(freeBalance) / cap)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Big kataIce balance number
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("\(balance)")
                    .font(.kataDisplay(48))
                    .foregroundStyle(Color.kataIce)
                    .contentTransition(.numericText())

                if isStale {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .padding(.leading, 8)
                }
            }

            // Subtext
            Text("credits sealed")
                .font(.kataMono(12))
                .foregroundStyle(Color.kataGold.opacity(0.7))

            // Gold hairline — full width, animates on purchase, width tracks free ratio
            GeometryReader { proxy in
                Rectangle()
                    .fill(Color.kataGold)
                    .frame(width: proxy.size.width * ratio, height: 0.5)
                    .opacity(hairlineOpacity)
                    .animation(.easeInOut(duration: 0.4), value: ratio)
            }
            .frame(height: 0.5)
            .padding(.top, 2)

            // Secondary line: free vs cap
            Text("Free credits: \(freeBalance) / \(freeBalanceCap)")
                .font(.kataCaption(11))
                .foregroundStyle(Color.kataIce.opacity(0.4))
        }
        .padding(.vertical, 12)
        .onChange(of: balance) { oldValue, newValue in
            if newValue > oldValue {
                // Purchase — flash hairline bright
                withAnimation(.easeInOut(duration: 0.6)) { hairlineOpacity = 1.0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeInOut(duration: 0.6)) { hairlineOpacity = 0.4 }
                }
                Task { @MainActor in KataHaptic.unlocked.fire() }
            }
        }
        .onAppear { previousBalance = balance }
    }
}
