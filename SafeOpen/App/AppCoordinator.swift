import SwiftUI

struct AppCoordinator: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            QRScannerView()
                .tabItem {
                    Label("Scan", systemImage: "qrcode.viewfinder")
                }

            PasteLinkView()
                .tabItem {
                    Label("Inspect", systemImage: "link.badge.plus")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }
        }
        .preferredColorScheme(.dark)
        .tint(Color(red: 0, green: 0.83, blue: 1))
    }
}
