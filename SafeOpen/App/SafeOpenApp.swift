import SwiftUI

@main
struct SafeOpenApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var store    = SafeOpenStore.shared
    @StateObject private var dtm      = DeviceTokenManager.shared

    var body: some Scene {
        WindowGroup {
            AppCoordinator()
                .environmentObject(appState)
                .environmentObject(store)
                .task { await dtm.registerIfNeeded() }
        }
    }
}
