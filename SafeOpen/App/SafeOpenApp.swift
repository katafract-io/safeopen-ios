import SwiftUI
import KatafractStyle

@main
struct SafeOpenApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var store    = SafeOpenStore.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        guard !ScreenshotMode.isEnabled else { return }
        Task.detached(priority: .background) {
            soLog("attest bootstrap start", category: "attest")
            await AppAttestClient.shared.bootstrapIfNeeded()
            soLog("attest bootstrap done", category: "attest")
            await DeviceCheckClient.claimWelcomeOnce()
        }
    }

    var body: some Scene {
        WindowGroup {
            AppCoordinator()
                .environmentObject(appState)
                .environmentObject(store)
                .tint(KataAccent.gold)
                .onChange(of: scenePhase) { _, newPhase in
                    soLog("scenePhase → \(newPhase)", category: "scene")
                    if newPhase == .active, !ScreenshotMode.isEnabled {
                        Task { await SafeOpenStore.shared.retryPendingRedemptions() }
                    }
                }
        }
    }
}
