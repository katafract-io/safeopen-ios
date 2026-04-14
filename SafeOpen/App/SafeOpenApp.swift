import SwiftUI

@main
struct SafeOpenApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var store    = SafeOpenStore.shared

    init() {
        Task.detached(priority: .background) {
            // One-time App Attest bootstrap (no-op if already attested or unsupported).
            await AppAttestClient.shared.bootstrapIfNeeded()
            // DeviceCheck welcome claim (idempotent — Apple stores the bit per device).
            await DeviceCheckClient.claimWelcomeOnce()
        }
    }

    var body: some Scene {
        WindowGroup {
            AppCoordinator()
                .environmentObject(appState)
                .environmentObject(store)
        }
    }
}
