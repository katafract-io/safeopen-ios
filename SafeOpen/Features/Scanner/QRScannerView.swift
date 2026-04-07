import SwiftUI

/// Stub — Codex Task 2: implement native AVFoundation camera scanning.
struct QRScannerView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = QRScannerViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                Text("Camera scanner goes here")
                    .foregroundStyle(.secondary)
                // TODO: CameraScannerView (AVFoundation wrapper)
            }
            .navigationTitle("Scan QR")
            .navigationDestination(item: $viewModel.result) { result in
                InspectionResultView(result: result)
            }
        }
        .onReceive(viewModel.$result.compactMap { $0 }) { result in
            appState.record(result)
        }
    }
}
