import SwiftUI
import KatafractStyle
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
                    GeometryReader { proxy in
                        Rectangle()
                            .fill(Color.kataGold)
                            .frame(width: proxy.size.width * vm.progress, height: 0.5)
                    }
                    .frame(height: 0.5, alignment: .top)
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

    func makeCoordinator() -> Coordinator { Coordinator(vm: vm, session: session) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Ephemeral store — zero persistence
        config.websiteDataStore = .nonPersistent()
        config.preferences.javaScriptCanOpenWindowsAutomatically = false

        // Proxy routing via WKURLSchemeHandler for safeopen:// scheme.
        // All http/https requests are intercepted and converted to safeopen://proxy?url=...
        // The SafeOpenSchemeHandler then proxies the request through the SafeOpen API,
        // ensuring the destination only sees the SafeOpen server IP.
        let schemeHandler = SafeOpenSchemeHandler()
        schemeHandler.sessionManager = SafeOpenSessionManager.shared
        config.setURLSchemeHandler(schemeHandler, forURLScheme: "safeopen")

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

        // Convert the initial URL to safeopen:// scheme for proxying
        let proxyURL = context.coordinator.convertToProxyScheme(url)
        wv.load(URLRequest(url: proxyURL))
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        let vm: BrowserViewModel
        let session: SafeOpenSession
        var progressObs: NSKeyValueObservation?
        var titleObs: NSKeyValueObservation?

        init(vm: BrowserViewModel, session: SafeOpenSession) {
            self.vm = vm
            self.session = session
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                // Extract the real destination URL from the proxy URL
                self.vm.currentURL = webView.url?.extractDestinationURL() ?? webView.url
                self.vm.isLoading = false
                self.vm.progress = 1.0
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async { self.vm.isLoading = false }
        }

        // Intercept navigation to convert http/https to safeopen:// scheme
        func webView(_ webView: WKWebView,
                     decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = action.request.url else {
                decisionHandler(.cancel)
                return
            }

            let scheme = url.scheme?.lowercased() ?? ""

            // Allow about: and already-converted safeopen: schemes
            if scheme == "about" || scheme == "safeopen" {
                decisionHandler(.allow)
                return
            }

            // Convert http/https to safeopen:// for proxy routing
            if scheme == "http" || scheme == "https" {
                if let proxyURL = convertToProxyScheme(url) {
                    var modifiedRequest = action.request
                    modifiedRequest.url = proxyURL
                    webView.load(modifiedRequest)
                }
                decisionHandler(.cancel)
                return
            }

            // Block all other schemes
            decisionHandler(.cancel)
        }

        // MARK: - Private

        func convertToProxyScheme(_ url: URL) -> URL? {
            var components = URLComponents()
            components.scheme = "safeopen"
            components.host = "proxy"
            components.queryItems = [
                URLQueryItem(name: "url", value: url.absoluteString)
            ]
            return components.url
        }
    }
}

extension URL {
    /// Extract destination URL from safeopen://proxy?url=... format
    fileprivate func extractDestinationURL() -> URL? {
        guard scheme == "safeopen" else { return self }
        if let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
           let queryItems = components.queryItems,
           let urlParam = queryItems.first(where: { $0.name == "url" })?.value {
            return URL(string: urlParam)
        }
        return nil
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
                    LabeledContent("Analysis IP") {
                        Text(session.assignedIpv6)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Analysis mode") {
                        Text(session.ephemeral ? "Disposable IPv6" : "Shared node IP")
                            .foregroundStyle(session.ephemeral ? Color(red: 0, green: 0.83, blue: 1) : .secondary)
                    }
                    LabeledContent("Your actual IP") {
                        Text("Hidden — routed via SafeOpen")
                            .foregroundStyle(.green)
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
                         ? "Our servers analyzed this link using a disposable IPv6 address, and all your browsing traffic routes through that same address. The destination only sees our server's IP, not your device's IP. This browser session is isolated with no cookies or cache."
                         : "Our servers analyzed this link through a shared Katafract node, and all your browsing traffic routes through that node. The destination only sees our shared node IP, not your device's IP. This browser session is isolated with no cookies or cache.")
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
