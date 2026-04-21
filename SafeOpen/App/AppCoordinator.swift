import SwiftUI

struct AppCoordinator: View {
    @EnvironmentObject var appState: AppState

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
        .tint(Color.kataSapphire)
    }
}
