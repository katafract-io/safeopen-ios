import SwiftUI
import KatafractStyle

// MARK: - InspectionResultView + ProUpgradeView forward imports
// These are imported here for screenshot mode sheet presentations.
// In normal flow they're reached via NavigationStack, but in screenshot mode
// we present them directly as sheets from AppCoordinator.onAppear.

struct AppCoordinator: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var store: SafeOpenStore
    @State private var screenshotResult: InspectionResult?
    @State private var showScreenshotUpgrade = false
    @State private var screenshotPrefetch: PrefetchResult?
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            QRScannerView()
                .tag(0)
                .tabItem {
                    Label("Scan", systemImage: "qrcode.viewfinder")
                }
                .accessibilityIdentifier("scan-tab")

            PasteLinkView(pendingURL: $appState.pendingURLToInspect)
                .tag(1)
                .tabItem {
                    Label("Inspect", systemImage: "link.badge.plus")
                }
                .accessibilityIdentifier("inspect-tab")

            HistoryView()
                .tag(2)
                .tabItem {
                    Label("History", systemImage: "clock")
                }
                .accessibilityIdentifier("history-tab")

            AccountView()
                .tag(3)
                .tabItem {
                    Label("Account", systemImage: "person.circle")
                }
                .accessibilityIdentifier("account-tab")
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
        .sheet(item: $screenshotPrefetch) { prefetch in
            PrefetchPreviewSheet(
                prefetch: prefetch,
                onOpen: { screenshotPrefetch = nil },
                onCancel: { screenshotPrefetch = nil }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: Binding(
            get: { !hasSeenOnboarding && !ScreenshotMode.isEnabled },
            set: { if !$0 { hasSeenOnboarding = true } }
        )) {
            OnboardingView(onDismiss: {
                hasSeenOnboarding = true
                // Ensure store loads products and balance after onboarding
                Task {
                    await store.loadProducts()
                    await store.refreshBalance()
                }
            })
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
                screenshotPrefetch = ScreenshotMode.presentPrefetch
            }
        }
    }
}
