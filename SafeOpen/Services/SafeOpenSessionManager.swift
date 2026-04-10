import Foundation
import Combine

@MainActor
final class SafeOpenSessionManager: ObservableObject {

    static let shared = SafeOpenSessionManager()

    @Published var session: SafeOpenSession?
    @Published var prefetch: PrefetchResult?
    @Published var isLoading = false
    @Published var error: String?
    @Published var needsUpgrade = false

    private let api = InspectionAPIClient()
    private var expiryTask: Task<Void, Never>?
    private var activeSessionId: String?

    // MARK: - Prefetch (Phase C)

    func loadPreview(url: URL) async {
        guard InspectionAPIClient.isProUser else {
            needsUpgrade = true
            return
        }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let result = try await api.prefetchURL(url)
            self.prefetch = result
            // Also store session so the browser can use it
            session = SafeOpenSession(
                sessionId:    result.sessionId,
                sessionToken: "",         // prefetch doesn't return a proxy token
                proxyHost:    "",
                proxyPort:    8444,
                assignedIpv6: result.assignedIpv6,
                ephemeral:    result.ephemeral,
                expiresAt:    result.expiresAt
            )
            scheduleExpiry(at: result.expiresAt)
        } catch {
            if case InspectionAPIError.planRequired = error {
                self.needsUpgrade = true
            } else {
                self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    // MARK: - Full proxy session (Phase D)

    func openSession(url: URL) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        // Revoke any prior session
        await revokeCurrentSession()

        do {
            let s = try await api.createSession(for: url)
            session = s
            activeSessionId = s.sessionId
            scheduleExpiry(at: s.expiresAt)
        } catch {
            if case InspectionAPIError.planRequired = error {
                self.needsUpgrade = true
            } else {
                self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    func revokeCurrentSession() async {
        guard let id = activeSessionId else { return }
        activeSessionId = nil
        session = nil
        prefetch = nil
        expiryTask?.cancel()
        await api.revokeSession(id)
    }

    func clear() {
        session = nil
        prefetch = nil
        error = nil
        expiryTask?.cancel()
    }

    // MARK: - Private

    private func scheduleExpiry(at date: Date) {
        expiryTask?.cancel()
        let delay = date.timeIntervalSinceNow
        guard delay > 0 else { return }
        expiryTask = Task {
            try? await Task.sleep(for: .seconds(delay))
            session = nil
            prefetch = nil
        }
    }
}
