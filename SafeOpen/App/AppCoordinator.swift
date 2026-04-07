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
                    Label("Paste", systemImage: "doc.on.clipboard")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }
        }
    }
}
