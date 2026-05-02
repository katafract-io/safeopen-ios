import SwiftUI
import KatafractStyle

// MARK: - InspectionResultView + ProUpgradeView forward imports
// These are imported here for screenshot mode sheet presentations.
// In normal flow they're reached via NavigationStack, but in screenshot mode
// we present them directly as sheets from AppCoordinator.onAppear.

struct AppCoordinator: View {
    @EnvironmentObject var appState: AppState
    @State private var screenshotResult: InspectionResult?
    @State private var showScreenshotUpgrade = false

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            QRScannerView()
                .tag(0)
                .tabItem {
                    Label("Scan", systemImage: "qrcode.viewfinder")
                }

            PasteLinkView(pendingURL: $appState.pendingURLToInspect)
                .tag(1)
                .tabItem {
                    Label("Inspect", systemImage: "link.badge.plus")
                }

            HistoryView()
                .tag(2)
                .tabItem {
                    Label("History", systemImage: "clock")
                }

            AccountView()
                .tag(3)
                .tabItem {
                    Label("Account", systemImage: "person.circle")
                }
        }
        .preferredColorScheme(.dark)
        .tint(KataAccent.gold)
        .sheet(item: $screenshotResult) { result in
            NavigationStack {
                InspectionResultView(result: result)
            }
        }
        .sheet(isPresented: $showScreenshotUpgrade) {
            ProUpgradeView()
        }
        .onAppear {
            // Inject screenshot mode presentations
            if ScreenshotMode.isEnabled && ScreenshotMode.seedData {
                if let result = ScreenshotMode.presentResult {
                    screenshotResult = result
                }
                if ScreenshotMode.presentUpgradeSheet {
                    showScreenshotUpgrade = true
                }
            }
        }
    }
}
