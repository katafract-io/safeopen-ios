import WebKit
import Foundation

/// WKURLSchemeHandler that intercepts safeopen:// URLs and routes them through
/// the SafeOpen API proxy, ensuring the destination only sees the SafeOpen server IP.
final class SafeOpenSchemeHandler: NSObject, WKURLSchemeHandler {
    weak var sessionManager: SafeOpenSessionManager?
    private var activeTasks: [String: Task<Void, Never>] = [:]

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let requestURL = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }

        // Extract destination URL from the safeopen:// request
        // Format: safeopen://proxy?url=<percent-encoded-destination-url>
        let destinationURL = extractDestinationURL(from: requestURL)
        let taskKey = self.taskKey(for: urlSchemeTask)

        let task = Task {
            await self.handleProxyRequest(requestURL, destinationURL: destinationURL, schemeTask: urlSchemeTask)
        }

        // Store the task so we can cancel it if needed
        activeTasks[taskKey] = task
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // Cancel any in-flight requests for this task
        let taskKey = taskKey(for: urlSchemeTask)
        if let task = activeTasks.removeValue(forKey: taskKey) {
            task.cancel()
        }
    }

    // MARK: - Private

    private func extractDestinationURL(from safeOpenURL: URL) -> URL? {
        if let components = URLComponents(url: safeOpenURL, resolvingAgainstBaseURL: true),
           let queryItems = components.queryItems,
           let urlParam = queryItems.first(where: { $0.name == "url" })?.value {
            return URL(string: urlParam)
        }
        return nil
    }

    private func taskKey(for task: WKURLSchemeTask) -> String {
        ObjectIdentifier(task).debugDescription
    }

    @MainActor
    private func handleProxyRequest(_ originalRequest: URL, destinationURL: URL?, schemeTask: WKURLSchemeTask) async {
        guard let destination = destinationURL else {
            schemeTask.didFailWithError(URLError(.badURL))
            return
        }

        do {
            // Create a session via SafeOpenSessionManager if available
            // The SafeOpen backend will proxy the request and return the response
            let response = try await fetchThroughProxy(destination, using: schemeTask.request)

            // Return the proxied response
            schemeTask.didReceive(response.response)
            schemeTask.didReceive(response.data)
            schemeTask.didFinish()
        } catch {
            schemeTask.didFailWithError(error)
        }
    }

    @MainActor
    private func fetchThroughProxy(_ destinationURL: URL, using originalRequest: URLRequest) async throws -> (response: HTTPURLResponse, data: Data) {
        // Ensure the SafeOpen session is active and has valid proxy credentials
        guard let session = sessionManager?.session else {
            throw SafeOpenProxyError.noActiveSession
        }

        let session_id = session.sessionId
        let sessionToken = session.sessionToken

        // Create a request to the SafeOpen proxy endpoint
        // This endpoint takes a destination URL and returns the proxied content
        // Format: /v1/safe-open/proxy
        let proxyEndpoint = URL(string: "https://api.katafract.com/v1/safe-open/proxy")!
        var proxyRequest = URLRequest(url: proxyEndpoint)
        proxyRequest.httpMethod = "POST"
        proxyRequest.setValue("Bearer \(InspectionAPIClient.serviceToken)", forHTTPHeaderField: "Authorization")
        proxyRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        proxyRequest.setValue(session_id, forHTTPHeaderField: "X-Session-ID")
        if !sessionToken.isEmpty {
            proxyRequest.setValue(sessionToken, forHTTPHeaderField: "X-Session-Token")
        }

        // Body: destination URL and the original request details
        let body: [String: Any] = [
            "destination_url": destinationURL.absoluteString,
            "method": originalRequest.httpMethod ?? "GET",
            "headers": originalRequest.allHTTPHeaderFields ?? [:],
        ]
        proxyRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: proxyRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SafeOpenProxyError.invalidResponse
        }

        // The proxy endpoint returns the proxied response as raw data
        // We need to wrap it in an HTTPURLResponse with the appropriate metadata
        guard (200...299).contains(httpResponse.statusCode) else {
            throw SafeOpenProxyError.proxyRequestFailed(httpResponse.statusCode)
        }

        // Create a new response that looks like it came from the destination
        // but actually came through our proxy
        let finalResponse = HTTPURLResponse(
            url: destinationURL,
            statusCode: httpResponse.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: httpResponse.allHeaderFields as? [String: String]
        ) ?? httpResponse

        return (finalResponse, data)
    }
}

enum SafeOpenProxyError: LocalizedError {
    case noActiveSession
    case invalidResponse
    case proxyRequestFailed(Int)

    var errorDescription: String? {
        switch self {
        case .noActiveSession:
            return "No active SafeOpen session. Please start a new inspection."
        case .invalidResponse:
            return "Invalid response from proxy server."
        case .proxyRequestFailed(let code):
            return "Proxy request failed with status \(code)."
        }
    }
}
