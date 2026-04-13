import SwiftUI
import WebKit
import MapKit
import Contacts
import EventKit

struct InspectionResultView: View {
    let result: InspectionResult
    @State private var copied = false
    @State private var copiedClean = false
    @State private var showHighRiskAlert = false

    private var parsedContent: ParsedContent {
        PayloadParser().parse(raw: result.payload.rawValue, type: result.payload.type)
    }

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

                    // Parsed content card
                    ParsedContentCard(content: parsedContent)

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
                        // ── Type-specific primary actions ──────────────────
                        TypeActions(result: result)

                        // ── URL actions ────────────────────────────────────
                        if result.finalURL != nil && (result.payload.type == .url || result.payload.type == .shortURL) {
                            Button {
                                if result.riskLevel == .high {
                                    showHighRiskAlert = true
                                } else {
                                    UIApplication.shared.open(result.finalURL!)
                                }
                            } label: {
                                Label("Open in Browser", systemImage: "safari")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(riskColor)
                            .controlSize(.large)
                            .alert("High Risk — Open Anyway?", isPresented: $showHighRiskAlert) {
                                Button("Open in Browser", role: .destructive) {
                                    UIApplication.shared.open(result.finalURL!)
                                }
                                Button("Cancel", role: .cancel) {}
                            } message: {
                                Text("This link shows signs of being dangerous. Opening it may expose you to phishing, malware, or other threats.")
                            }

                            OpenSafelyButton(result: result)
                        }

                        // ── Copy actions ───────────────────────────────────
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
        case .dataURL:   return "Data URL"
        case .deepLink:  return "Deep Link"
        case .wifi:      return "Wi-Fi"
        case .sms:       return "SMS"
        case .email:     return "Email"
        case .phone:     return "Phone"
        case .contact:   return "Contact"
        case .meCard:    return "MECARD"
        case .calendar:  return "Calendar"
        case .otp:       return "OTP"
        case .crypto:    return "Crypto"
        case .geo:       return "Location"
        case .script:    return "Script"
        case .json:      return "JSON"
        case .plainText: return "Plain Text"
        case .unknown:   return "Unknown"
        }
    }

    private var color: Color {
        switch type {
        case .url, .shortURL:    return Color(red: 0, green: 0.83, blue: 1)
        case .deepLink:          return Color(red: 0, green: 0.83, blue: 1).opacity(0.8)
        case .dataURL:           return .orange
        case .wifi:              return .blue
        case .sms, .phone:       return .green
        case .email:             return .orange
        case .contact, .meCard:  return .purple
        case .calendar:          return .red
        case .otp:               return Color(red: 0.9, green: 0.6, blue: 0)
        case .crypto:            return Color(red: 1, green: 0.6, blue: 0)
        case .geo:               return .teal
        case .script:            return .red
        case .json:              return .indigo
        default:                 return .secondary
        }
    }
}

// MARK: - Open Safely Button

struct OpenSafelyButton: View {
    let result: InspectionResult

    @StateObject private var manager = SafeOpenSessionManager.shared
    @StateObject private var store   = SafeOpenStore.shared
    @State private var showBrowser = false
    @State private var showPrefetchSheet = false
    @State private var showUpgrade = false
    @State private var checkingPro = true   // spinner until first StoreKit check completes
    @State private var diagnostic: SafeOpenStore.StoreKitDiagnostic?
    @State private var diagRunning = false
    @State private var debugTapCount = 0
    @State private var showDebugPanel = false

    private var isPro: Bool { store.isPro }
    private let cyan = Color(red: 0, green: 0.83, blue: 1)

    var body: some View {
        Group {
            if checkingPro {
                HStack(spacing: 10) {
                    ProgressView().tint(cyan)
                    Text("Checking subscription…")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color(UIColor.secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 14))

            } else if isPro {
                VStack(spacing: 8) {
                    Button { Task { await openSafely() } } label: {
                        HStack {
                            if manager.isLoading {
                                ProgressView().tint(.black).scaleEffect(0.8)
                            } else {
                                Label("Inspect & Open Safely", systemImage: "shield.lefthalf.filled")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(cyan)
                    .controlSize(.large)
                    .disabled(manager.isLoading || result.finalURL == nil)

                    Label("Servers inspect it · Isolated session · No cookies", systemImage: "sparkles")
                        .font(.caption2)
                        .foregroundStyle(cyan.opacity(0.85))
                }

            } else {
                // Upsell — already subscribed? Restore button is prominent.
                VStack(spacing: 10) {
                    Button { showUpgrade = true } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.title2).foregroundStyle(cyan)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.payload.type == .shortURL
                                     ? "Reveal destination & Open Safely"
                                     : "Inspect & Open Safely")
                                    .font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                                Text("SafeOpen Pro — our servers fetch it for you")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("Pro")
                                .font(.caption.weight(.bold)).foregroundStyle(cyan)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(cyan.opacity(0.12), in: Capsule())
                        }
                        .padding(14)
                        .background(Color(UIColor.secondarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    // Restore — tap 5× to reveal diagnostic panel
                    Button {
                        Task {
                            checkingPro = true
                            defer { checkingPro = false }
                            try? await AppStore.sync()
                            await store.refreshProStatus()
                        }
                    } label: {
                        Text("Already subscribed? Restore")
                            .font(.footnote).foregroundStyle(cyan)
                    }
                    .simultaneousGesture(TapGesture(count: 1).onEnded {
                        debugTapCount += 1
                        if debugTapCount >= 5 { showDebugPanel = true }
                    })

                    // ── Debug panel (hidden; unlocked by 5-tapping Restore) ─
                    if showDebugPanel {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("StoreKit Diagnostic")
                                    .font(.caption.monospaced().weight(.semibold))
                                    .foregroundStyle(.orange)
                                Spacer()
                                Button { showDebugPanel = false; debugTapCount = 0 } label: {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                                }
                            }

                            Button {
                                Task {
                                    diagRunning = true
                                    diagnostic = await store.diagnose()
                                    diagRunning = false
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    if diagRunning { ProgressView().scaleEffect(0.7) }
                                    Text(diagRunning ? "Running…" : "Run Diagnostic")
                                        .font(.caption.monospaced())
                                }
                                .foregroundStyle(.orange)
                            }
                            .disabled(diagRunning)

                            if let d = diagnostic {
                                let text = diagText(d)
                                Group {
                                    debugRow("inMemory isPro", "\(d.inMemoryIsPro)")
                                    debugRow("UserDefaults isPro", "\(d.userDefaultsIsPro)")
                                    debugRow("syncError", d.syncError ?? "nil")
                                    debugRow("monthlyID", d.monthlyID)
                                    debugRow("annualID", d.annualID)
                                    debugRow("currentEntitlements(\(d.currentEntitlements.count))",
                                             d.currentEntitlements.isEmpty ? "none" :
                                             d.currentEntitlements.map { "\($0.id)\n  rev=\($0.revoked) exp=\($0.expires)" }.joined(separator: "\n"))
                                    debugRow("allTransactions(\(d.allTransactions.count))",
                                             d.allTransactions.isEmpty ? "none" :
                                             d.allTransactions.map { "\($0.id)\n  rev=\($0.revoked) exp=\($0.expires)" }.joined(separator: "\n"))
                                    debugRow("session.isLoading", "\(manager.isLoading)")
                                    debugRow("session.error", manager.error ?? "nil")
                                    debugRow("prefetch.sessionId", manager.prefetch?.sessionId ?? "nil")
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Button {
                                    UIPasteboard.general.string = text
                                } label: {
                                    Label("Copy All", systemImage: "doc.on.doc")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                        .padding(10)
                        .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    }
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
        // On appear: verify subscription then reveal correct state (spinner → button or upsell).
        // checkingPro starts true so upsell never flashes before the check completes.
        .task {
            defer { checkingPro = false }
            guard !store.isPro else { return }  // cached UserDefaults = pro, skip
            await store.refreshProStatus()
        }
    }

    private func openSafely() async {
        guard let url = result.finalURL else { return }
        if let existing = manager.prefetch, existing.expiresAt.timeIntervalSinceNow > 30 {
            showPrefetchSheet = true
            return
        }
        await manager.loadPreview(url: url)
        if manager.prefetch != nil && manager.error == nil {
            showPrefetchSheet = true
        }
    }

    @ViewBuilder
    private func debugRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.monospaced().weight(.semibold))
                .foregroundStyle(.orange)
            Text(value)
                .font(.caption2.monospaced())
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        }
        Divider()
    }

    private func diagText(_ d: SafeOpenStore.StoreKitDiagnostic) -> String {
        var lines = [
            "=== SafeOpen StoreKit Diagnostic ===",
            "inMemory isPro: \(d.inMemoryIsPro)",
            "UserDefaults isPro: \(d.userDefaultsIsPro)",
            "syncError: \(d.syncError ?? "nil")",
            "monthlyID: \(d.monthlyID)",
            "annualID:  \(d.annualID)",
            "",
            "=== Session Manager ===",
            "isLoading: \(manager.isLoading)",
            "error: \(manager.error ?? "nil")",
            "session: \(manager.session?.sessionId ?? "nil")",
            "prefetch: \(manager.prefetch?.sessionId ?? "nil")",
            "",
            "=== currentEntitlements (\(d.currentEntitlements.count)) ===",
        ]
        if d.currentEntitlements.isEmpty { lines.append("  (none)") }
        for e in d.currentEntitlements {
            lines.append("  \(e.id) | revoked=\(e.revoked) | exp=\(e.expires)")
        }
        lines.append("")
        lines.append("=== allTransactions (\(d.allTransactions.count)) ===")
        if d.allTransactions.isEmpty { lines.append("  (none)") }
        for t in d.allTransactions {
            lines.append("  \(t.id) | revoked=\(t.revoked) | exp=\(t.expires)")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Prefetch preview sheet

struct PrefetchPreviewSheet: View {
    let prefetch: PrefetchResult
    let onOpen: () -> Void
    let onCancel: () -> Void

    @State private var selectedTab: PreviewTab = .snapshot
    private let cyan  = Color(red: 0, green: 0.83, blue: 1)
    private let token = InspectionAPIClient.serviceToken

    enum PreviewTab: String, CaseIterable {
        case snapshot = "Preview"
        case details  = "Details"
    }

    private var loadFailed: Bool {
        prefetch.statusCode == 0 && prefetch.finalUrl == prefetch.originalUrl
    }

    private var trackerCount: Int { prefetch.trackers.count }
    private var havenBlockable: Int {
        prefetch.trackers.filter { $0.category == "advertising" || $0.category == "analytics" }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if loadFailed {
                    // ── Unreachable ───────────────────────────────────────
                    unreachableView
                } else {
                    // ── Tab picker ────────────────────────────────────────
                    Picker("Tab", selection: $selectedTab) {
                        ForEach(PreviewTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(UIColor.systemGroupedBackground))

                    if selectedTab == .snapshot {
                        snapshotTab
                    } else {
                        detailsTab
                    }
                }

                // ── Open Safely footer ────────────────────────────────────
                if !loadFailed {
                    openFooter
                }
            }
            .navigationTitle(prefetch.title ?? "Safe Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }

    // MARK: - Snapshot tab

    private var snapshotTab: some View {
        ScrollView {
            VStack(spacing: 0) {
                // AI summary header
                if let summary = prefetch.summary {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(cyan)
                            .font(.subheadline)
                        Text(summary)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cyan.opacity(0.08))
                }

                // Snapshot WebView
                if prefetch.hasSnapshot {
                    SnapshotWebView(
                        url: URL(string: "\(InspectionAPIClient.baseURL)/v1/safe-open/snapshot/\(prefetch.sessionId)")!,
                        token: token
                    )
                    .frame(minHeight: 420)
                } else {
                    // No snapshot — show destination info
                    VStack(spacing: 8) {
                        Image(systemName: "photo.slash")
                            .font(.largeTitle)
                            .foregroundStyle(.tertiary)
                        Text("Page preview unavailable")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let title = prefetch.title {
                            Text(title).font(.headline).padding(.top, 4)
                        }
                        Text(prefetch.finalUrl)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                    .frame(maxWidth: .infinity)
                }

                // Tracker + upsell section
                if trackerCount > 0 {
                    trackerSection
                }
            }
        }
    }

    // MARK: - Tracker section

    private var trackerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "eye.trianglebadge.exclamationmark.fill")
                    .foregroundStyle(.orange)
                Text("\(trackerCount) tracker\(trackerCount == 1 ? "" : "s") detected")
                    .font(.subheadline.weight(.semibold))
            }

            // Tracker chips
            FlowLayout(spacing: 6) {
                ForEach(prefetch.trackers) { tracker in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(tracker.categoryColor)
                            .frame(width: 6, height: 6)
                        Text(tracker.domain)
                            .font(.caption.monospaced())
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(tracker.categoryColor.opacity(0.12), in: Capsule())
                }
            }

            // Legend
            HStack(spacing: 12) {
                ForEach(Array(Set(prefetch.trackers.map(\.category))).sorted(), id: \.self) { cat in
                    let color = TrackerEntry(domain: "", category: cat).categoryColor
                    Label(TrackerEntry(domain: "", category: cat).displayCategory, systemImage: "circle.fill")
                        .font(.caption2)
                        .foregroundStyle(color)
                }
            }

            // Haven upsell
            if havenBlockable > 0 {
                havenUpsell
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }

    private var havenUpsell: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "shield.fill")
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Haven DNS would block \(havenBlockable) of these")
                        .font(.subheadline.weight(.semibold))
                    Text("DNS-level ad and tracker blocking on all your devices.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Link(destination: URL(string: "https://katafract.com/enclave")!) {
                Text("Learn about Enclave →")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            }
        }
        .padding(12)
        .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Details tab

    private var detailsTab: some View {
        List {
            Section("Verified Destination") {
                VStack(alignment: .leading, spacing: 6) {
                    if let title = prefetch.title {
                        Text(title).font(.headline)
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

            Section("Privacy") {
                LabeledContent("Inspected via") {
                    Text(prefetch.ephemeral ? "Disposable IPv6" : "Shared node")
                        .foregroundStyle(prefetch.ephemeral ? cyan : .secondary)
                }
                LabeledContent("Your IP during inspect") {
                    Text("Not exposed").foregroundStyle(.green)
                }
                LabeledContent("Your IP while browsing") {
                    Text("Your device connection").foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Unreachable

    private var unreachableView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle).foregroundStyle(.orange)
            Text("Destination unreachable")
                .font(.headline)
            Text("Our proxy nodes couldn't connect. The address may be private, invalid, or no longer active.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text(prefetch.originalUrl)
                .font(.caption.monospaced()).foregroundStyle(.secondary)
                .lineLimit(3).multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Open footer

    private var openFooter: some View {
        VStack(spacing: 6) {
            Button {
                onOpen()
            } label: {
                Label("Open in Isolated Browser", systemImage: "arrow.up.right.square")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(cyan)
            .controlSize(.large)
            .padding(.horizontal, 16)

            Text("Opens in a cookie-free session. Your IP will be used for browsing.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.vertical, 12)
        .background(Color(UIColor.systemGroupedBackground))
    }
}

// MARK: - Snapshot WebView

struct SnapshotWebView: UIViewRepresentable {
    let url: URL
    let token: String

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = context.coordinator  // blocks link taps
        wv.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
        wv.scrollView.backgroundColor = .clear
        wv.scrollView.isScrollEnabled = true
        load(wv)
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    private func load(_ wv: WKWebView) {
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        wv.load(req)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView,
                     decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Only allow the initial snapshot load; cancel all link taps
            decisionHandler(action.navigationType == .other ? .allow : .cancel)
        }
    }
}

// MARK: - Flow layout (wrapping chip row)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                y += rowH + spacing; x = 0; rowH = 0
            }
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
        return CGSize(width: width, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowH + spacing; x = bounds.minX; rowH = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
    }
}

// MARK: - Type-specific actions

struct TypeActions: View {
    let result: InspectionResult

    var body: some View {
        switch result.payload.type {
        case .phone:
            if let url = URL(string: result.payload.rawValue.hasPrefix("tel:") ? result.payload.rawValue : "tel:\(result.payload.rawValue)") {
                PrimaryActionButton(label: "Call", icon: "phone.fill", tint: .green) {
                    UIApplication.shared.open(url)
                }
            }

        case .sms:
            if let url = smsURL(from: result.payload.rawValue) {
                PrimaryActionButton(label: "Send Message", icon: "message.fill", tint: .green) {
                    UIApplication.shared.open(url)
                }
            }

        case .email:
            if let url = URL(string: result.payload.rawValue) {
                PrimaryActionButton(label: "Compose Email", icon: "envelope.fill", tint: .orange) {
                    UIApplication.shared.open(url)
                }
            }

        case .wifi:
            WiFiActionCard(raw: result.payload.rawValue)

        case .geo:
            GeoActionButtons(raw: result.payload.rawValue)

        case .deepLink:
            if let url = URL(string: result.payload.rawValue) {
                PrimaryActionButton(label: "Open App", icon: "arrow.up.right.square", tint: Color(red: 0, green: 0.83, blue: 1)) {
                    UIApplication.shared.open(url)
                }
            }

        case .otp:
            OTPActionButtons(raw: result.payload.rawValue)

        case .crypto:
            CryptoActionButtons(content: PayloadParser().parse(raw: result.payload.rawValue, type: .crypto))

        case .contact, .meCard:
            ContactActionButtons(content: PayloadParser().parse(raw: result.payload.rawValue, type: result.payload.type))

        case .calendar:
            CalendarActionButton(raw: result.payload.rawValue)

        default:
            EmptyView()
        }
    }

    private func smsURL(from raw: String) -> URL? {
        // SMSTO:+1234:body or SMS:+1234
        let stripped = raw
            .replacingOccurrences(of: "SMSTO:", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "SMS:", with: "", options: .caseInsensitive)
        let parts = stripped.split(separator: ":", maxSplits: 1)
        let number = parts.first.map(String.init) ?? stripped
        let body = parts.count > 1 ? String(parts[1]) : ""
        var comps = URLComponents()
        comps.scheme = "sms"
        comps.path = number
        if !body.isEmpty { comps.queryItems = [URLQueryItem(name: "body", value: body)] }
        return comps.url
    }
}

private struct GeoActionButtons: View {
    let raw: String

    var body: some View {
        let body = raw.replacingOccurrences(of: "geo:", with: "", options: .caseInsensitive)
        let coords = body.components(separatedBy: "?")[0].components(separatedBy: ",")
        if coords.count >= 2, let lat = Double(coords[0]), let lon = Double(coords[1]) {
            PrimaryActionButton(label: "Open in Maps", icon: "map.fill", tint: .teal) {
                let url = URL(string: "maps://?ll=\(lat),\(lon)")!
                UIApplication.shared.open(url)
            }
        }
    }
}

private struct OTPActionButtons: View {
    let raw: String
    @State private var copied = false

    var body: some View {
        VStack(spacing: 10) {
            PrimaryActionButton(label: copied ? "Copied!" : "Copy OTP URL", icon: copied ? "checkmark" : "doc.on.doc", tint: Color(red: 0.9, green: 0.6, blue: 0)) {
                UIPasteboard.general.string = raw
                withAnimation { copied = true }
                Task { try? await Task.sleep(for: .seconds(2)); withAnimation { copied = false } }
            }
            Text("Open your authenticator app and scan this code, or paste the URL directly.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

private struct CryptoActionButtons: View {
    let content: ParsedContent
    @State private var copied = false

    var body: some View {
        if case .crypto(let c) = content {
            PrimaryActionButton(label: copied ? "Address Copied!" : "Copy \(c.currency) Address", icon: copied ? "checkmark" : "doc.on.doc", tint: Color(red: 1, green: 0.6, blue: 0)) {
                UIPasteboard.general.string = c.address
                withAnimation { copied = true }
                Task { try? await Task.sleep(for: .seconds(2)); withAnimation { copied = false } }
            }
        }
    }
}

private struct ContactActionButtons: View {
    let content: ParsedContent

    var body: some View {
        if case .contact(let c) = content {
            PrimaryActionButton(label: "Save to Contacts", icon: "person.crop.circle.badge.plus", tint: .purple) {
                saveContact(c)
            }
        }
    }

    private func saveContact(_ c: ContactContent) {
        let contact = CNMutableContact()
        if let fn = c.fullName { contact.givenName = fn }
        else { contact.givenName = c.firstName ?? ""; contact.familyName = c.lastName ?? "" }
        if let org = c.org { contact.organizationName = org }
        contact.phoneNumbers = c.phones.map {
            CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: $0))
        }
        contact.emailAddresses = c.emails.map {
            CNLabeledValue(label: CNLabelWork, value: $0 as NSString)
        }
        let vc = CNContactViewController(forNewContact: contact)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            let nav = UINavigationController(rootViewController: vc)
            root.present(nav, animated: true)
        }
    }
}

private struct CalendarActionButton: View {
    let raw: String

    var body: some View {
        PrimaryActionButton(label: "Add to Calendar", icon: "calendar.badge.plus", tint: .red) {
            addEvent()
        }
    }

    private func addEvent() {
        let store = EKEventStore()
        store.requestFullAccessToEvents { granted, _ in
            guard granted else { return }
            let parser = PayloadParser()
            guard case .event(let e) = parser.parse(raw: raw, type: .calendar) else { return }
            let event = EKEvent(eventStore: store)
            event.title = e.summary ?? "Event"
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm"
            if let s = e.startDate { event.startDate = df.date(from: s) ?? Date() }
            if let end = e.endDate { event.endDate = df.date(from: end) ?? Date().addingTimeInterval(3600) }
            if let loc = e.location { event.location = loc }
            event.notes = e.description
            event.calendar = store.defaultCalendarForNewEvents
            try? store.save(event, span: .thisEvent)
            DispatchQueue.main.async {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let root = scene.windows.first?.rootViewController {
                    let alert = UIAlertController(title: "Added", message: "\"\(event.title ?? "Event")\" added to your calendar.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    root.present(alert, animated: true)
                }
            }
        }
    }
}

private struct PrimaryActionButton: View {
    let label: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
        .controlSize(.large)
    }
}

// MARK: - Parsed content card

struct ParsedContentCard: View {
    let content: ParsedContent

    var body: some View {
        switch content {
        case .contact(let c):  ContactCard(c: c)
        case .event(let e):    EventCard(e: e)
        case .otp(let o):      OTPCard(o: o)
        case .geo(let g):      GeoCard(g: g)
        case .crypto(let c):   CryptoCard(c: c)
        case .script(let s):   ScriptCard(s: s)
        case .json(let j):     JSONCard(j: j)
        case .dataURL(let d):  DataURLCard(d: d)
        case .deepLink(let l): DeepLinkCard(l: l)
        case .wifi:            EmptyView()   // WiFiActionCard handles this
        case .none:            EmptyView()
        }
    }

    // MARK: Contact
    private struct ContactCard: View {
        let c: ContactContent
        var body: some View {
            InfoCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Contact — \(c.format)", systemImage: "person.crop.circle")
                        .font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                    Divider()
                    if let name = c.fullName ?? [c.firstName, c.lastName].compactMap({ $0 }).joined(separator: " ").nonEmpty {
                        row("Name", name)
                    }
                    if let org = c.org   { row("Org",   org) }
                    if let title = c.title { row("Title", title) }
                    ForEach(c.phones, id: \.self) { row("Phone", $0) }
                    ForEach(c.emails, id: \.self) { row("Email", $0) }
                    if let addr = c.address { row("Address", addr) }
                    if let url  = c.url  { row("URL", url) }
                    if let note = c.note { row("Note", note) }
                }
            }
        }
        private func row(_ label: String, _ value: String) -> some View {
            HStack(alignment: .top) {
                Text(label).font(.caption).foregroundStyle(.secondary).frame(width: 60, alignment: .leading)
                Text(value).font(.subheadline).foregroundStyle(.primary)
                Spacer()
            }
        }
    }

    // MARK: Event
    private struct EventCard: View {
        let e: EventContent
        var body: some View {
            InfoCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Calendar Event", systemImage: "calendar").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                    Divider()
                    if let s = e.summary  { row("Title",    s) }
                    if let s = e.startDate { row("Starts",  s) }
                    if let s = e.endDate   { row("Ends",    s) }
                    if let l = e.location  { row("Location", l) }
                    if let d = e.description { row("Notes",  d) }
                    if let o = e.organizer { row("Organizer", o) }
                }
            }
        }
        private func row(_ label: String, _ value: String) -> some View {
            HStack(alignment: .top) {
                Text(label).font(.caption).foregroundStyle(.secondary).frame(width: 70, alignment: .leading)
                Text(value).font(.subheadline).foregroundStyle(.primary)
                Spacer()
            }
        }
    }

    // MARK: OTP
    private struct OTPCard: View {
        let o: OTPContent
        var body: some View {
            InfoCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("One-Time Password (\(o.type.uppercased()))", systemImage: "lock.rotation").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                    Divider()
                    if let issuer  = o.issuer  { row("Issuer",  issuer) }
                    if let account = o.account { row("Account", account) }
                    HStack(spacing: 16) {
                        if let d = o.digits { chip("\(d) digits") }
                        if let p = o.period { chip("every \(p)s") }
                    }
                }
            }
        }
        private func row(_ label: String, _ value: String) -> some View {
            HStack(alignment: .top) {
                Text(label).font(.caption).foregroundStyle(.secondary).frame(width: 60, alignment: .leading)
                Text(value).font(.subheadline).foregroundStyle(.primary)
                Spacer()
            }
        }
        private func chip(_ s: String) -> some View {
            Text(s).font(.caption2.weight(.semibold)).padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color(UIColor.tertiarySystemGroupedBackground), in: Capsule())
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Geo
    private struct GeoCard: View {
        let g: GeoContent
        var body: some View {
            InfoCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Location", systemImage: "location.fill").font(.footnote.weight(.semibold)).foregroundStyle(.teal)
                    Divider()
                    if let q = g.query { Text(q).font(.subheadline.weight(.semibold)) }
                    Text(String(format: "%.6f, %.6f", g.latitude, g.longitude))
                        .font(.caption.monospaced()).foregroundStyle(.secondary)
                    if let alt = g.altitude { Text(String(format: "Altitude: %.0f m", alt)).font(.caption).foregroundStyle(.secondary) }
                }
            }
        }
    }

    // MARK: Crypto
    private struct CryptoCard: View {
        let c: CryptoContent
        @State private var copied = false
        var body: some View {
            InfoCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("\(c.currency) Payment", systemImage: "bitcoinsign.circle").font(.footnote.weight(.semibold)).foregroundStyle(Color(red: 1, green: 0.6, blue: 0))
                    Divider()
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Address").font(.caption).foregroundStyle(.secondary)
                            Text(c.address).font(.caption.monospaced()).lineLimit(3)
                        }
                        Spacer()
                        Button {
                            UIPasteboard.general.string = c.address
                            withAnimation { copied = true }
                            Task { try? await Task.sleep(for: .seconds(2)); withAnimation { copied = false } }
                        } label: {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc").font(.caption)
                        }.buttonStyle(.bordered).tint(.secondary)
                    }
                    if let amt = c.amount  { row("Amount",  amt) }
                    if let lbl = c.label   { row("To",      lbl) }
                    if let msg = c.message { row("Message", msg) }
                }
            }
        }
        private func row(_ label: String, _ value: String) -> some View {
            HStack { Text(label).font(.caption).foregroundStyle(.secondary).frame(width: 60, alignment: .leading); Text(value).font(.subheadline); Spacer() }
        }
    }

    // MARK: Script
    private struct ScriptCard: View {
        let s: ScriptContent
        var body: some View {
            InfoCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Executable Script", systemImage: "exclamationmark.triangle.fill").font(.footnote.weight(.semibold)).foregroundStyle(.red)
                        Spacer()
                        Text(s.language).font(.caption2.weight(.bold))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.red.opacity(0.15), in: Capsule()).foregroundStyle(.red)
                    }
                    Divider()
                    Text(s.snippet).font(.caption.monospaced()).foregroundStyle(.secondary).lineLimit(10)
                    Text("Do not execute unless you fully trust the source.")
                        .font(.caption2).foregroundStyle(.red.opacity(0.8))
                }
            }
        }
    }

    // MARK: JSON
    private struct JSONCard: View {
        let j: String
        var body: some View {
            InfoCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("JSON Data", systemImage: "curlybraces").font(.footnote.weight(.semibold)).foregroundStyle(.indigo)
                    Divider()
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(j).font(.caption.monospaced()).foregroundStyle(.primary)
                    }
                    .frame(maxHeight: 200)
                }
            }
        }
    }

    // MARK: Data URL
    private struct DataURLCard: View {
        let d: DataURLContent
        var body: some View {
            InfoCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Embedded Data", systemImage: "doc.zipper").font(.footnote.weight(.semibold)).foregroundStyle(.orange)
                    Divider()
                    HStack(spacing: 16) {
                        chip(d.mimeType)
                        if let enc = d.encoding { chip(enc) }
                        chip(formatBytes(d.dataSize))
                    }
                }
            }
        }
        private func chip(_ s: String) -> some View {
            Text(s).font(.caption2.weight(.semibold)).padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color(UIColor.tertiarySystemGroupedBackground), in: Capsule()).foregroundStyle(.secondary)
        }
        private func formatBytes(_ n: Int) -> String {
            n < 1024 ? "\(n) B" : n < 1_048_576 ? String(format: "%.1f KB", Double(n) / 1024) : String(format: "%.1f MB", Double(n) / 1_048_576)
        }
    }

    // MARK: Deep Link
    private struct DeepLinkCard: View {
        let l: DeepLinkContent
        var body: some View {
            InfoCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("App Deep Link", systemImage: "arrow.up.right.square").font(.footnote.weight(.semibold)).foregroundStyle(Color(red: 0, green: 0.83, blue: 1))
                    Divider()
                    HStack {
                        Text("Scheme").font(.caption).foregroundStyle(.secondary).frame(width: 60, alignment: .leading)
                        Text(l.scheme + "://").font(.subheadline.monospaced()); Spacer()
                    }
                    if let host = l.host {
                        HStack { Text("App/Host").font(.caption).foregroundStyle(.secondary).frame(width: 60, alignment: .leading); Text(host).font(.subheadline); Spacer() }
                    }
                    if let path = l.path {
                        HStack { Text("Path").font(.caption).foregroundStyle(.secondary).frame(width: 60, alignment: .leading); Text(path).font(.subheadline.monospaced()).lineLimit(2); Spacer() }
                    }
                }
            }
        }
    }
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}

private struct WiFiActionCard: View {
    let raw: String
    @State private var copiedSSID = false
    @State private var copiedPass = false

    private var parsed: (ssid: String, password: String, security: String) {
        // WIFI:T:WPA;S:NetworkName;P:Password;H:false;;
        var ssid = "", password = "", security = "Unknown"
        let fields = raw
            .replacingOccurrences(of: "WIFI:", with: "", options: .caseInsensitive)
            .components(separatedBy: ";")
        for field in fields {
            let kv = field.split(separator: ":", maxSplits: 1).map(String.init)
            guard kv.count == 2 else { continue }
            switch kv[0].uppercased() {
            case "S": ssid     = kv[1]
            case "P": password = kv[1]
            case "T": security = kv[1].uppercased() == "nopass" ? "Open" : kv[1].uppercased()
            default: break
            }
        }
        return (ssid, password, security)
    }

    var body: some View {
        let info = parsed
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "wifi")
                    .foregroundStyle(.blue)
                Text("Wi-Fi Network")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(info.security)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(UIColor.tertiarySystemGroupedBackground), in: Capsule())
            }

            if !info.ssid.isEmpty {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Network").font(.caption).foregroundStyle(.secondary)
                        Text(info.ssid).font(.subheadline.monospaced())
                    }
                    Spacer()
                    Button {
                        UIPasteboard.general.string = info.ssid
                        withAnimation { copiedSSID = true }
                        Task { try? await Task.sleep(for: .seconds(2)); withAnimation { copiedSSID = false } }
                    } label: {
                        Image(systemName: copiedSSID ? "checkmark" : "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(.secondary)
                }
            }

            if !info.password.isEmpty {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Password").font(.caption).foregroundStyle(.secondary)
                        Text(String(repeating: "•", count: min(info.password.count, 12)))
                            .font(.subheadline.monospaced())
                    }
                    Spacer()
                    Button {
                        UIPasteboard.general.string = info.password
                        withAnimation { copiedPass = true }
                        Task { try? await Task.sleep(for: .seconds(2)); withAnimation { copiedPass = false } }
                    } label: {
                        Label(copiedPass ? "Copied" : "Copy Password",
                              systemImage: copiedPass ? "checkmark" : "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .controlSize(.small)
                }
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}
