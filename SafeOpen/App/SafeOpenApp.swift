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
            await AppAttestClient.shared.bootstrapIfNeeded()
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
                    if newPhase == .active, !ScreenshotMode.isEnabled {
                        Task { await SafeOpenStore.shared.retryPendingRedemptions() }
                    }
                }
        }
    }
}
