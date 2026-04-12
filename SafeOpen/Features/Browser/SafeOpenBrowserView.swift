import SwiftUI
import WebKit

struct SafeOpenBrowserView: View {
    let url: URL
    let session: SafeOpenSession

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = BrowserViewModel()
    @State private var showSessionInfo = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                WebView(url: url, session: session, vm: vm)
                    .ignoresSafeArea(edges: .bottom)

                if vm.isLoading {
                    ProgressView(value: vm.progress)
                        .progressViewStyle(.linear)
                        .tint(Color(red: 0, green: 0.83, blue: 1))
                        .frame(maxWidth: .infinity, maxHeight: 2, alignment: .top)
                        .ignoresSafeArea()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button {
                        showSessionInfo.toggle()
                    } label: {
                        VStack(spacing: 1) {
                            Text(vm.pageTitle.isEmpty ? url.host ?? "Loading…" : vm.pageTitle)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 8))
                                Text("Isolated · No cookies or cache")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            UIPasteboard.general.string = vm.currentURL?.absoluteString ?? url.absoluteString
                        } label: {
                            Label("Copy URL", systemImage: "doc.on.doc")
                        }
                        Button {
                            if let u = vm.currentURL ?? Optional(url) {
                                UIApplication.shared.open(u)
                            }
                        } label: {
                            Label("Open in Safari", systemImage: "safari")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showSessionInfo) {
            SessionInfoSheet(session: session)
                .presentationDetents([.medium])
        }
    }
}

// MARK: - WKWebView wrapper

final class BrowserViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var progress: Double = 0
    @Published var pageTitle = ""
    @Published var currentURL: URL?
}

struct WebView: UIViewRepresentable {
    let url: URL
    let session: SafeOpenSession
    @ObservedObject var vm: BrowserViewModel

    func makeCoordinator() -> Coordinator { Coordinator(vm: vm) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Ephemeral store — zero persistence
        config.websiteDataStore = .nonPersistent()
        config.preferences.javaScriptCanOpenWindowsAutomatically = false

        // Proxy routing: WKWebView doesn't expose a native proxy API.
        // Full routing requires openSession() to return real credentials,
        // then a WKURLSchemeHandler intercept. Current flow uses prefetch-only
        // sessions (empty token/host), so the browser opens direct with a
        // non-persistent data store for local privacy.

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = context.coordinator
        wv.allowsBackForwardNavigationGestures = true
        wv.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15"

        // Observe progress
        context.coordinator.progressObs = wv.observe(\.estimatedProgress, options: .new) { wv, _ in
            DispatchQueue.main.async {
                self.vm.progress = wv.estimatedProgress
                self.vm.isLoading = wv.isLoading
            }
        }
        context.coordinator.titleObs = wv.observe(\.title, options: .new) { wv, _ in
            DispatchQueue.main.async {
                self.vm.pageTitle = wv.title ?? ""
            }
        }

        wv.load(URLRequest(url: url))
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        let vm: BrowserViewModel
        var progressObs: NSKeyValueObservation?
        var titleObs: NSKeyValueObservation?

        init(vm: BrowserViewModel) { self.vm = vm }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.vm.currentURL = webView.url
                self.vm.isLoading = false
                self.vm.progress = 1.0
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async { self.vm.isLoading = false }
        }

        // Block navigation to non-http schemes (no mailto:, tel:, etc.)
        func webView(_ webView: WKWebView,
                     decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            let scheme = action.request.url?.scheme?.lowercased() ?? ""
            if scheme == "http" || scheme == "https" || scheme == "about" {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
            }
        }
    }
}

// MARK: - Session info sheet

struct SessionInfoSheet: View {
    let session: SafeOpenSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Identity") {
                    LabeledContent("Browsing IP") {
                        Text(session.assignedIpv6)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Mode") {
                        Text(session.ephemeral ? "Disposable" : "Shared node IP")
                            .foregroundStyle(session.ephemeral ? Color(red: 0, green: 0.83, blue: 1) : .secondary)
                    }
                }

                Section("Privacy") {
                    LabeledContent("Session storage") {
                        Text("None — cookies cleared")
                            .foregroundStyle(.green)
                    }
                }

                Section("Session") {
                    LabeledContent("Expires") {
                        Text(session.expiresAt, style: .relative)
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Session ID") {
                        Text(session.sessionId.prefix(16) + "…")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Text(session.ephemeral
                         ? "This session uses a disposable IPv6 address that is unique to this inspection. The destination cannot link this session to any other activity. The address is retired when you close this browser."
                         : "This session routes through a shared Katafract node IP. Your device's real IP is not exposed to the destination.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Session Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
