import SwiftUI

@main
struct SafeOpenApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var store    = SafeOpenStore.shared

    var body: some Scene {
        WindowGroup {
            AppCoordinator()
                .environmentObject(appState)
                .environmentObject(store)
        }
    }
}
