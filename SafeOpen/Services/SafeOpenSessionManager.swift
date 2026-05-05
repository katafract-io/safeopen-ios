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
        loadTask?.cancel()
        isLoading = true
        error = nil
        isRateLimited = false
        isOffline = false

        loadTask = Task {
            defer { isLoading = false }
            do {
                let result = try await api.prefetchURL(url)
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
            } catch InspectionAPIError.creditsRequired {
                if !PlatformEntitlement.isPlatformUnlocked {
                    needsCredits = true
                }
            } catch InspectionAPIError.rateLimited {
                isRateLimited = true
                self.error = "Too many requests. Please wait a moment and try again."
            } catch let error as URLError where error.code == .notConnectedToInternet {
                isOffline = true
                self.error = "No internet connection."
            } catch InspectionAPIError.serverError(let code, _) where code >= 500 {
                self.error = "SafeOpen servers are temporarily unavailable."
            } catch {
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
            } catch InspectionAPIError.creditsRequired {
                if !PlatformEntitlement.isPlatformUnlocked {
                    needsCredits = true
                }
            } catch InspectionAPIError.rateLimited {
                isRateLimited = true
                self.error = "Too many requests. Please wait a moment and try again."
            } catch let error as URLError where error.code == .notConnectedToInternet {
                isOffline = true
                self.error = "No internet connection."
            } catch InspectionAPIError.serverError(let code, _) where code >= 500 {
                self.error = "SafeOpen servers are temporarily unavailable."
            } catch {
                self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
        await loadTask?.value
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
