import SwiftUI

struct InspectionResultView: View {
    let result: InspectionResult
    @State private var copied = false
    @State private var copiedClean = false

    private var cleanURL: URL? {
        guard let url = result.finalURL else { return nil }
        return URLNormalizationService.stripTrackingParams(from: url)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // ── Risk banner ──────────────────────────────────────────────
                RiskBanner(result: result)

                // ── Body ─────────────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 16) {

                    // Payload type + destination
                    InfoCard {
                        LabeledRow(label: "Type") {
                            PayloadTypeBadge(type: result.payload.type)
                        }

                        if let url = result.finalURL {
                            Divider().padding(.vertical, 4)
                            LabeledRow(label: "Destination") {
                                Text(url.absoluteString)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.primary)
                                    .lineLimit(4)
                                    .multilineTextAlignment(.trailing)
                            }
                            if let clean = cleanURL {
                                Divider().padding(.vertical, 4)
                                LabeledRow(label: "Clean URL") {
                                    Text(clean.absoluteString)
                                        .font(.caption.monospaced())
                                        .foregroundStyle(Color(red: 0, green: 0.83, blue: 1))
                                        .lineLimit(4)
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                        }
                    }

                    // Risk factors
                    if !result.riskFactors.isEmpty {
                        InfoCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Risk Factors")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                ForEach(result.riskFactors, id: \.self) { factor in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.caption)
                                            .foregroundStyle(riskColor.opacity(0.9))
                                            .frame(width: 16)
                                        Text(factor.explanation)
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                    }
                                }
                            }
                        }
                    }

                    // Raw payload
                    InfoCard {
                        LabeledRow(label: "Raw Payload") {
                            Text(result.payload.rawValue)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(6)
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    // Actions
                    VStack(spacing: 12) {
                        if let url = result.finalURL {
                            Button {
                                UIApplication.shared.open(url)
                            } label: {
                                Label("Open in Browser", systemImage: "safari")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(riskColor)
                            .controlSize(.large)
                        }

                        // Open Safely button — wired to session manager
                        OpenSafelyButton(result: result)

                        if let clean = cleanURL {
                            Button {
                                UIPasteboard.general.string = clean.absoluteString
                                withAnimation { copiedClean = true }
                                Task {
                                    try? await Task.sleep(for: .seconds(2))
                                    withAnimation { copiedClean = false }
                                }
                            } label: {
                                Label(copiedClean ? "Copied!" : "Copy Clean URL",
                                      systemImage: copiedClean ? "checkmark" : "scissors")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(Color(red: 0, green: 0.83, blue: 1))
                            .controlSize(.large)
                        }

                        Button {
                            let text = result.payload.normalizedValue ?? result.payload.rawValue
                            UIPasteboard.general.string = text
                            withAnimation { copied = true }
                            Task {
                                try? await Task.sleep(for: .seconds(2))
                                withAnimation { copied = false }
                            }
                        } label: {
                            Label(copied ? "Copied!" : "Copy to Clipboard",
                                  systemImage: copied ? "checkmark" : "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.secondary)
                        .controlSize(.large)
                    }
                }
                .padding(20)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Inspection")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var riskColor: Color {
        switch result.riskLevel {
        case .low:     return .green
        case .caution: return .orange
        case .high:    return .red
        case .unknown: return .secondary
        }
    }
}

// MARK: - Risk Banner

struct RiskBanner: View {
    let result: InspectionResult

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: riskIcon)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(riskColor)
                .padding(.top, 28)

            Text(result.riskLevel.displayTitle)
                .font(.title2.bold())
                .foregroundStyle(.primary)

            Text(result.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(riskColor.opacity(0.08))
    }

    private var riskIcon: String {
        switch result.riskLevel {
        case .low:     return "checkmark.shield.fill"
        case .caution: return "exclamationmark.shield.fill"
        case .high:    return "xmark.shield.fill"
        case .unknown: return "questionmark.app.fill"
        }
    }

    private var riskColor: Color {
        switch result.riskLevel {
        case .low:     return .green
        case .caution: return .orange
        case .high:    return .red
        case .unknown: return .secondary
        }
    }
}

// MARK: - Info Card

struct InfoCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Labeled Row

struct LabeledRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            Spacer()
            content
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Payload type badge

struct PayloadTypeBadge: View {
    let type: PayloadType

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }

    private var label: String {
        switch type {
        case .url:       return "Website"
        case .shortURL:  return "Short Link"
        case .wifi:      return "Wi-Fi"
        case .sms:       return "SMS"
        case .email:     return "Email"
        case .phone:     return "Phone"
        case .contact:   return "Contact"
        case .calendar:  return "Calendar"
        case .plainText: return "Plain Text"
        case .unknown:   return "Unknown"
        }
    }

    private var color: Color {
        switch type {
        case .url, .shortURL: return Color(red: 0, green: 0.83, blue: 1)
        case .wifi:           return .blue
        case .sms, .phone:    return .green
        case .email:          return .orange
        case .contact:        return .purple
        case .calendar:       return .red
        default:              return .secondary
        }
    }
}

// MARK: - Open Safely Button

struct OpenSafelyButton: View {
    let result: InspectionResult

    @StateObject private var manager = SafeOpenSessionManager.shared
    @State private var showBrowser = false
    @State private var showPrefetchSheet = false
    @State private var showUpgrade = false

    private var isPro: Bool { InspectionAPIClient.isProUser }

    var body: some View {
        Group {
            VStack(spacing: 8) {
                Button {
                    Task { await openSafely() }
                } label: {
                    HStack {
                        if manager.isLoading {
                            ProgressView()
                                .tint(.black)
                                .scaleEffect(0.8)
                        } else {
                            Label("Open Safely", systemImage: "shield.lefthalf.filled")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0, green: 0.83, blue: 1))
                .controlSize(.large)
                .disabled(manager.isLoading || result.finalURL == nil)

                // Pro badge / upsell
                if isPro {
                    Label("Disposable IPv6 · Session isolated", systemImage: "sparkles")
                        .font(.caption2)
                        .foregroundStyle(Color(red: 0, green: 0.83, blue: 1).opacity(0.85))
                } else {
                    Button {
                        showUpgrade = true
                    } label: {
                        Label("Upgrade for disposable IPv6 identity", systemImage: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .alert("Error", isPresented: .constant(manager.error != nil), actions: {
            Button("OK") { manager.error = nil }
        }, message: {
            Text(manager.error ?? "")
        })
        .sheet(isPresented: $showBrowser, onDismiss: {
            Task { await manager.revokeCurrentSession() }
        }) {
            if let session = manager.session, let url = result.finalURL {
                SafeOpenBrowserView(url: url, session: session)
            }
        }
        .sheet(isPresented: $showPrefetchSheet) {
            if let prefetch = manager.prefetch, result.finalURL != nil {
                PrefetchPreviewSheet(
                    prefetch: prefetch,
                    onOpen: { showPrefetchSheet = false; showBrowser = true },
                    onCancel: { showPrefetchSheet = false; manager.clear() }
                )
                .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showUpgrade) {
            ProUpgradeView()
        }
    }

    private func openSafely() async {
        guard let url = result.finalURL else { return }
        // Phase C: prefetch first, show preview
        await manager.prefetch(url: url)
        if manager.prefetch != nil && manager.error == nil {
            showPrefetchSheet = true
        }
    }
}

// MARK: - Prefetch preview sheet

struct PrefetchPreviewSheet: View {
    let prefetch: PrefetchResult
    let onOpen: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Verified Destination") {
                    if let url = prefetch.resolvedURL {
                        VStack(alignment: .leading, spacing: 6) {
                            if let title = prefetch.title {
                                Text(title)
                                    .font(.headline)
                            }
                            Text(url.absoluteString)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                        .padding(.vertical, 4)
                    }
                }

                if !prefetch.redirectChain.isEmpty {
                    Section("Redirect Chain (\(prefetch.redirectChain.count))") {
                        ForEach(Array(prefetch.redirectChain.enumerated()), id: \.offset) { i, hop in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(hop.statusCode)")
                                    .font(.caption.monospaced().weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 36)
                                Text(hop.url)
                                    .font(.caption.monospaced())
                                    .lineLimit(2)
                            }
                        }
                    }
                }

                Section("Privacy") {
                    LabeledContent("Inspected via") {
                        Text(prefetch.ephemeral ? "Disposable IPv6" : "Shared node")
                            .foregroundStyle(prefetch.ephemeral ? Color(red: 0, green: 0.83, blue: 1) : .secondary)
                    }
                    LabeledContent("Your IP exposed") {
                        Text("No — never touched destination")
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("Safe Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Open Safely") { onOpen() }
                        .bold()
                        .tint(Color(red: 0, green: 0.83, blue: 1))
                }
            }
        }
    }
}
