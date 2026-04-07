import Foundation
import Combine

@MainActor
class QRScannerViewModel: ObservableObject {
    @Published var result: InspectionResult?
    @Published var isScanning = false

    private let service = SafeOpenService()

    func didScan(raw: String) {
        result = service.inspect(raw: raw, source: .camera)
    }
}
