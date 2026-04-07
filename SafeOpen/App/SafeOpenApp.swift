import SwiftUI

@main
struct SafeOpenApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            AppCoordinator()
                .environmentObject(appState)
        }
    }
}
