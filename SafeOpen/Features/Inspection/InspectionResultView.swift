import SwiftUI

struct InspectionResultView: View {
    let result: InspectionResult
    @State private var copied = false
    @State private var copiedClean = false
    @State private var showHighRiskAlert = false

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
                            if manager.isLoading || store.isUpgrading {
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
                    .disabled(manager.isLoading || store.isUpgrading || result.finalURL == nil)

                    Label("Servers inspect it · Isolated browser · No cookies", systemImage: "sparkles")
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
                            Text(result.payload.type == .shortURL ? "Reveal destination & Open Safely" : "Inspect & Open Safely")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(result.payload.type == .shortURL
                                 ? "Our servers resolve the real URL — you see it before your device connects"
                                 : "Our servers fetch it · You see what's there · Isolated browser")
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
                    LabeledContent("Your IP while browsing") {
                        Text("Your device connection")
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
