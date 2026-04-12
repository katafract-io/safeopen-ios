import SwiftUI
import StoreKit

struct AccountView: View {
    @StateObject private var store = SafeOpenStore.shared
    @EnvironmentObject var appState: AppState
    @State private var showUpgrade = false
    @State private var showClearConfirm = false

    private var isPro: Bool { store.isPro }
    private let cyan = Color(red: 0, green: 0.83, blue: 1)

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            List {

                // ── Subscription status ───────────────────────────────────
                Section {
                    if isPro {
                        HStack(spacing: 12) {
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.title2)
                                .foregroundStyle(cyan)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("SafeOpen Pro")
                                    .font(.subheadline.weight(.semibold))
                                Text("AI analysis · Disposable IPv6 · Open Safely")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("Active")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(cyan)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(cyan.opacity(0.12), in: Capsule())
                        }
                        .padding(.vertical, 4)
                    } else {
                        Button { showUpgrade = true } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "shield.lefthalf.filled")
                                    .font(.title2)
                                    .foregroundStyle(cyan)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Upgrade to Pro")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text("AI analysis · Disposable IPv6 · Open Safely")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                // ── Subscription management ───────────────────────────────
                Section {
                    if isPro {
                        Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                            Label("Manage Subscription", systemImage: "arrow.up.right.square")
                        }
                    } else {
                        Button {
                            Task { await store.restorePurchases() }
                        } label: {
                            Label("Restore Purchases", systemImage: "arrow.clockwise")
                        }
                        .disabled(store.isPurchasing)
                    }
                }

                // ── Support ───────────────────────────────────────────────
                Section("Support") {
                    Link(destination: URL(string: "https://katafract.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    Link(destination: URL(string: "mailto:support@katafract.com")!) {
                        Label("Contact Support", systemImage: "envelope")
                    }
                }

                // ── Data ─────────────────────────────────────────────────
                Section("Data") {
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label("Clear History", systemImage: "trash")
                    }
                }

                // ── About ────────────────────────────────────────────────
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Account")
            .sheet(isPresented: $showUpgrade) {
                ProUpgradeView()
            }
            .confirmationDialog("Clear all scan history?", isPresented: $showClearConfirm, titleVisibility: .visible) {
                Button("Clear History", role: .destructive) { appState.clearHistory() }
                Button("Cancel", role: .cancel) { }
            }
            .overlay {
                if store.isPurchasing {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView().tint(cyan).scaleEffect(1.5)
                }
            }
        }
    }
}
