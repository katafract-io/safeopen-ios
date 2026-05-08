import SwiftUI

/// Diagnostic panel for founder-level users during development.
/// Triggered by triple-tapping the "KATAFRACT" label in PasteLinkView.
/// Only visible when PlatformEntitlement.isPlatformUnlocked is true.
struct FounderDebugPanel: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = SafeOpenStore.shared

    private let cyan = Color(red: 0, green: 0.83, blue: 1)

    var body: some View {
        NavigationStack {
            List {
                Section("Entitlement") {
                    row("Status", PlatformEntitlement.isPlatformUnlocked ? "✓ Unlocked" : "✗ Locked")
                    if let token = enclaveToken {
                        row("Enclave token", "\(token.prefix(6))…\(token.suffix(4))")
                    } else {
                        row("Enclave token", "— not found")
                    }
                    row("App Group", PlatformEntitlement.sharedGroup)
                }

                Section("Device") {
                    let did = InspectionAPIClient.deviceID
                    row("Device ID", "…\(did.suffix(12))")
                    row("API base", InspectionAPIClient.baseURL)
                }

                Section("Credits") {
                    row("Balance", "\(store.balance)")
                    row("Balance stale", store.balanceIsStale ? "yes" : "no")
                }

                Section("Actions") {
                    Button("Refresh credit balance") {
                        Task { await SafeOpenStore.shared.refreshBalance() }
                    }
                    .foregroundStyle(cyan)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Founder Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: { dismiss() })
                }
            }
        }
    }

    private var enclaveToken: String? {
        UserDefaults(suiteName: PlatformEntitlement.sharedGroup)?
            .string(forKey: PlatformEntitlement.tokenKey)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.monospaced())
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
        }
    }
}
