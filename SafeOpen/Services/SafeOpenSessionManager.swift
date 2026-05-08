import Foundation
import Combine

@MainActor
final class SafeOpenSessionManager: ObservableObject {

    static let shared = SafeOpenSessionManager()

    @Published var session: SafeOpenSession?
    @Published var prefetch: PrefetchResult?
    @Published var isLoading = false
    @Published var error: String?
    @Published var needsCredits = false
    @Published var isRateLimited = false
    @Published var isOffline = false

    private let api = InspectionAPIClient()
    private var expiryTask: Task<Void, Never>?
    private var loadTask: Task<Void, Never>?
    private var activeSessionId: String?

    // MARK: - Prefetch

    func loadPreview(url: URL) async {
        soLog("loadPreview → \(url.absoluteString.prefix(80))", category: "session")
        loadTask?.cancel()
        isLoading = true
        error = nil
        isRateLimited = false
        isOffline = false

        loadTask = Task {
            defer { isLoading = false }
            do {
                let result = try await api.prefetchURL(url)
                soLog("prefetch OK: status=\(result.statusCode) snapshot=\(result.hasSnapshot) ephemeral=\(result.ephemeral)", category: "session")
                self.prefetch = result
                session = SafeOpenSession(
                    sessionId:    result.sessionId,
                    sessionToken: "",
                    proxyHost:    "",
                    proxyPort:    8444,
                    assignedIpv6: result.assignedIpv6,
                    ephemeral:    result.ephemeral,
                    expiresAt:    result.expiresAt
                )
                scheduleExpiry(at: result.expiresAt)
            } catch InspectionAPIError.unauthorized {
                soLog("prefetch: 401/403 unauthorized — token rejected by backend", category: "session")
                self.error = "Service error. Please update the app."
            } catch InspectionAPIError.creditsRequired {
                soLog("prefetch: credits required", category: "session")
                if !PlatformEntitlement.isPlatformUnlocked {
                    needsCredits = true
                }
            } catch InspectionAPIError.rateLimited {
                soLog("prefetch: rate limited", category: "session")
                isRateLimited = true
                self.error = "Too many requests. Please wait a moment and try again."
            } catch let error as URLError where error.code == .notConnectedToInternet {
                soLog("prefetch: offline (\(error.localizedDescription))", category: "session")
                isOffline = true
                self.error = "No internet connection."
            } catch InspectionAPIError.serverError(let code, _) where code == 400 {
                soLog("prefetch: blocked 400", category: "session")
                self.error = "This URL can't be scanned for security reasons."
            } catch InspectionAPIError.serverError(let code, _) where code >= 500 {
                soLog("prefetch: server error \(code)", category: "session")
                self.error = "SafeOpen servers are temporarily unavailable."
            } catch {
                soLog("prefetch: error — \(error.localizedDescription)", category: "session")
                self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            if needsCredits == false {
                await SafeOpenStore.shared.refreshBalance()
            }
        }
        await loadTask?.value
    }

    // MARK: - Full proxy session

    func openSession(url: URL) async {
        soLog("openSession → \(url.absoluteString.prefix(80))", category: "session")
        loadTask?.cancel()
        isLoading = true
        error = nil
        isRateLimited = false
        isOffline = false

        await revokeCurrentSession()

        loadTask = Task {
            defer { isLoading = false }
            do {
                let s = try await api.createSession(for: url)
                session = s
                activeSessionId = s.sessionId
                scheduleExpiry(at: s.expiresAt)
                await SafeOpenStore.shared.refreshBalance()
            } catch InspectionAPIError.unauthorized {
                soLog("openSession: 401/403 unauthorized — token rejected by backend", category: "session")
                self.error = "Service error. Please update the app."
            } catch InspectionAPIError.creditsRequired {
                soLog("openSession: credits required", category: "session")
                if !PlatformEntitlement.isPlatformUnlocked {
                    needsCredits = true
                }
            } catch InspectionAPIError.rateLimited {
                soLog("openSession: rate limited", category: "session")
                isRateLimited = true
                self.error = "Too many requests. Please wait a moment and try again."
            } catch let error as URLError where error.code == .notConnectedToInternet {
                soLog("openSession: offline (\(error.localizedDescription))", category: "session")
                isOffline = true
                self.error = "No internet connection."
            } catch InspectionAPIError.serverError(let code, _) where code == 400 {
                soLog("openSession: blocked 400", category: "session")
                self.error = "This URL can't be scanned for security reasons."
            } catch InspectionAPIError.serverError(let code, _) where code >= 500 {
                soLog("openSession: server error \(code)", category: "session")
                self.error = "SafeOpen servers are temporarily unavailable."
            } catch {
                soLog("openSession: error — \(error.localizedDescription)", category: "session")
                self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
        await loadTask?.value
    }

    func revokeCurrentSession() async {
        guard let id = activeSessionId else { return }
        soLog("revoking session \(id.prefix(8))", category: "session")
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
        loadTask?.cancel()
    }

    func cancelLoadTask() {
        loadTask?.cancel()
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
