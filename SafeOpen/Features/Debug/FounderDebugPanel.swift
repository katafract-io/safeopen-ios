import SwiftUI

/// Diagnostic panel for founder-level users during development.
/// Triggered by triple-tapping the "KATAFRACT" label in PasteLinkView.
/// Only visible when PlatformEntitlement.isPlatformUnlocked is true.
struct FounderDebugPanel: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store  = SafeOpenStore.shared
    @StateObject private var logger = SOLogger.shared
    @State private var copied       = false
    @State private var selectedTab  = Tab.log

    private let cyan = Color(red: 0, green: 0.83, blue: 1)

    enum Tab { case log, info }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Tab", selection: $selectedTab) {
                    Text("Live Log").tag(Tab.log)
                    Text("Info").tag(Tab.info)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                if selectedTab == .log {
                    logTab
                } else {
                    infoTab
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Founder Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            UIPasteboard.general.string = logger.allText
                            copied = true
                            Task { try? await Task.sleep(for: .seconds(2)); copied = false }
                        } label: {
                            Label(copied ? "Copied!" : "Copy log", systemImage: "doc.on.doc")
                        }
                        Button(role: .destructive) {
                            logger.clear()
                        } label: {
                            Label("Clear log", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    // MARK: - Log tab

    private var logTab: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(logger.entries) { entry in
                        Text(entry.formatted)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(color(for: entry.category))
                            .textSelection(.enabled)
                            .padding(.horizontal, 12)
                            .id(entry.id)
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.vertical, 8)
            }
            .onChange(of: logger.entries.count) { _, _ in
                withAnimation(.linear(duration: 0.1)) {
                    proxy.scrollTo("bottom")
                }
            }
            .onAppear {
                proxy.scrollTo("bottom")
            }
        }
    }

    private func color(for category: String) -> Color {
        switch category {
        case "scene":   return .secondary
        case "session": return cyan
        case "api":     return .green
        case "attest":  return .purple
        default:        return .primary
        }
    }

    // MARK: - Info tab

    private var infoTab: some View {
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
            Section("Session") {
                let mgr = SafeOpenSessionManager.shared
                row("Loading", mgr.isLoading ? "yes" : "no")
                row("Has prefetch", mgr.prefetch != nil ? "yes" : "no")
                row("Error", mgr.error ?? "—")
                row("Offline", mgr.isOffline ? "yes" : "no")
            }
            Section("Actions") {
                Button("Refresh credit balance") {
                    Task { await SafeOpenStore.shared.refreshBalance() }
                }
                .foregroundStyle(cyan)
            }
        }
        .listStyle(.insetGrouped)
    }

    private var enclaveToken: String? {
        UserDefaults(suiteName: PlatformEntitlement.sharedGroup)?
            .string(forKey: PlatformEntitlement.tokenKey)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.monospaced())
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
        }
    }
}
