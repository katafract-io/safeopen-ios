import UIKit
import SwiftUI
import Social

class ShareViewController: UIViewController {
    private var urlToInspect: URL?
    private var resultState: ResultState = .idle

    private enum ResultState {
        case idle
        case loading
        case result(InspectionResult)
        case error(String)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure view
        view.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
        preferredContentSize = CGSize(width: 400, height: 500)

        // Extract URL from share items
        extractURL { [weak self] url in
            guard let self = self, let url = url else {
                self?.resultState = .error("No URL found in shared content")
                self?.updateUI()
                return
            }
            self.urlToInspect = url
            self.inspectURL(url)
        }
    }

    private func extractURL(completion: @escaping (URL?) -> Void) {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            completion(nil)
            return
        }

        for item in items {
            // Try URL
            if let attachments = item.attachments as? [NSItemProvider] {
                for provider in attachments {
                    if provider.hasItemConformingToTypeIdentifier("public.url") {
                        provider.loadItem(forTypeIdentifier: "public.url", options: nil) { item, _ in
                            if let url = item as? URL {
                                completion(url)
                                return
                            }
                        }
                    }
                }
            }

            // Try plain text
            if let attachments = item.attachments as? [NSItemProvider] {
                for provider in attachments {
                    if provider.hasItemConformingToTypeIdentifier("public.plain-text") {
                        provider.loadItem(forTypeIdentifier: "public.plain-text", options: nil) { item, _ in
                            if let text = item as? String, let url = self.extractURLFromText(text) {
                                completion(url)
                                return
                            }
                        }
                    }
                }
            }
        }

        completion(nil)
    }

    private func extractURLFromText(_ text: String) -> URL? {
        // Simple URL extraction from plain text
        let patterns = [
            "https?://[\\S]+",
            "www\\.[\\S]+"
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, range: range) {
                    if let range = Range(match.range, in: text) {
                        var urlString = String(text[range])
                        if !urlString.hasPrefix("http") {
                            urlString = "https://" + urlString
                        }
                        return URL(string: urlString)
                    }
                }
            }
        }
        return nil
    }

    private func inspectURL(_ url: URL) {
        resultState = .loading
        updateUI()

        Task {
            let result = await ShareExtensionInspector.shared.inspect(url: url)
            await MainActor.run {
                self.resultState = .result(result)
                self.updateUI()
            }
        }
    }

    private func updateUI() {
        // Remove previous SwiftUI view if any
        children.forEach { $0.view.removeFromSuperview() }

        let inspectView = ShareInspectView(
            url: urlToInspect ?? URL(fileURLWithPath: "/"),
            result: {
                switch resultState {
                case .result(let r): return r
                default: return nil
                }
            }(),
            isLoading: {
                if case .loading = resultState { return true }
                return false
            }(),
            error: {
                if case .error(let e) = resultState { return e }
                return nil
            }(),
            onOpenInApp: handleOpenInApp
        )

        let hostingController = UIHostingController(rootView: inspectView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.didMove(toParent: self)
    }

    private func handleOpenInApp() {
        guard let url = urlToInspect else {
            extensionContext?.completeRequest(returningItems: nil)
            return
        }

        // Deep link into main app: safeopen://inspect?url=...
        let encodedURL = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let deepLink = URL(string: "safeopen://inspect?url=\(encodedURL)")!

        extensionContext?.open(deepLink) { success in
            self.extensionContext?.completeRequest(returningItems: nil)
        }
    }
}
