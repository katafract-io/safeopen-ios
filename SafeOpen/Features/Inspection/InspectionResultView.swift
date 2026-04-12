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
    @StateObject private var store  = SafeOpenStore.shared
    @State private var showBrowser = false
    @State private var showPrefetchSheet = false
    @State private var showUpgrade = false

    private var isPro: Bool { store.isPro }
    private let cyan = Color(red: 0, green: 0.83, blue: 1)

    var body: some View {
        Group {
            if isPro {
                // Pro: full Open Safely button
                VStack(spacing: 8) {
                    Button {
                        Task { await openSafely() }
                    } label: {
                        HStack {
                            if manager.isLoading {
                                ProgressView().tint(.black).scaleEffect(0.8)
                            } else {
                                Label("Open Safely", systemImage: "shield.lefthalf.filled")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(cyan)
                    .controlSize(.large)
                    .disabled(manager.isLoading || result.finalURL == nil)

                    Label("Disposable IPv6 · Session isolated", systemImage: "sparkles")
                        .font(.caption2)
                        .foregroundStyle(cyan.opacity(0.85))
                }
            } else {
                // Free: Pro upsell card
                Button { showUpgrade = true } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.title2)
                            .foregroundStyle(cyan)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Analyze & Open Safely")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("AI summary · Disposable IPv6 · Isolated browser")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("Pro")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(cyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(cyan.opacity(0.12), in: Capsule())
                    }
                    .padding(14)
                    .background(Color(UIColor.secondarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
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
            if let prefetch = manager.prefetch {
                PrefetchPreviewSheet(
                    prefetch: prefetch,
                    onOpen: { showPrefetchSheet = false; showBrowser = true },
                    onCancel: { showPrefetchSheet = false; manager.clear() }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showUpgrade) {
            ProUpgradeView()
        }
        .onChange(of: manager.needsUpgrade) { _, needs in
            if needs {
                showUpgrade = true
                manager.needsUpgrade = false
            }
        }
    }

    private func openSafely() async {
        guard let url = result.finalURL else { return }
        // Reuse prefetch if still fresh (> 30s remaining), else re-fetch
        if let existing = manager.prefetch, existing.expiresAt.timeIntervalSinceNow > 30 {
            showPrefetchSheet = true
            return
        }
        await manager.loadPreview(url: url)
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

    private let cyan = Color(red: 0, green: 0.83, blue: 1)

    /// True when the backend couldn't actually reach the destination
    private var loadFailed: Bool {
        prefetch.statusCode == 0 && prefetch.finalUrl == prefetch.originalUrl
    }

    var body: some View {
        NavigationStack {
            List {
                if loadFailed {
                    // ── Unreachable destination ──────────────────────────
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("Destination unreachable")
                                    .font(.headline)
                            }
                            Text("Our proxy nodes couldn't connect to this address. It may be a private/local network address (e.g. 192.168.x.x), an invalid URL, or a link that no longer exists.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(prefetch.originalUrl)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                        .padding(.vertical, 6)
                    }
                } else {
                    // ── AI Summary ───────────────────────────────────────
                    if let summary = prefetch.summary {
                        Section("Summary") {
                            Text(summary)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .padding(.vertical, 4)
                        }
                    }

                    // ── Destination ──────────────────────────────────────
                    Section("Verified Destination") {
                        VStack(alignment: .leading, spacing: 6) {
                            if let title = prefetch.title {
                                Text(title)
                                    .font(.headline)
                            }
                            Text(prefetch.finalUrl)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(4)
                            if prefetch.statusCode > 0 {
                                Text("HTTP \(prefetch.statusCode)")
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(prefetch.statusCode < 400 ? .green : .orange)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // ── Redirect chain ───────────────────────────────────
                    if !prefetch.redirectChain.isEmpty {
                        Section("Redirect Chain (\(prefetch.redirectChain.count))") {
                            ForEach(Array(prefetch.redirectChain.enumerated()), id: \.offset) { _, hop in
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
                }

                // ── Privacy ──────────────────────────────────────────────
                Section("Privacy") {
                    LabeledContent("Inspected via") {
                        Text(prefetch.ephemeral ? "Disposable IPv6" : "Shared node")
                            .foregroundStyle(prefetch.ephemeral ? cyan : .secondary)
                    }
                    LabeledContent("Your IP during inspect") {
                        Text("Not exposed")
                            .foregroundStyle(.green)
                    }
                    LabeledContent("Your IP if opened") {
                        Text("Your device")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Safe Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                if !loadFailed {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Open Safely") { onOpen() }
                            .bold()
                            .tint(cyan)
                    }
                }
            }
        }
    }
}
