import AVFoundation
import Foundation
import UIKit

@MainActor
final class QRScannerViewModel: ObservableObject {

    @Published var result: InspectionResult?
    @Published var cameraStatus: AVAuthorizationStatus = .notDetermined
    @Published var cameraAuthorized = false
    @Published var torchOn = false
    /// Incremented each time the camera restarts so CameraPreviewView re-attaches the layer.
    @Published private(set) var attachGeneration: Int = 0

    @Published private(set) var previewLayer: AVCaptureVideoPreviewLayer?

    private let scanner = CameraScannerService()
    private let service = SafeOpenService()
    private var scanCooldown = false
    private var lastScannedValue: String?

    // MARK: - Lifecycle

    func requestPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        cameraStatus = status

        switch status {
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            cameraStatus = granted ? .authorized : .denied
            cameraAuthorized = granted
            if granted { startScanning() }
        case .authorized:
            cameraAuthorized = true
            startScanning()
        default:
            cameraAuthorized = false
        }
    }

    func stopScanning() {
        scanner.stop()
    }

    func resumeScanning() {
        guard cameraAuthorized else { return }
        scanner.resume()
        attachGeneration += 1   // forces CameraPreviewView.updateUIView to re-attach the layer
    }

    func toggleTorch() {
        torchOn.toggle()
        scanner.setTorch(torchOn)
    }

    func attachPreview(to view: UIView) {
        guard let layer = previewLayer else { return }
        layer.frame = view.bounds
        // Always re-attach if the layer is on a stale superlayer (e.g. after navigation pop/push)
        if layer.superlayer !== view.layer {
            layer.removeFromSuperlayer()
            view.layer.insertSublayer(layer, at: 0)
        }
    }

    // MARK: - Private

    private func startScanning() {
        scanner.onDecode = { [weak self] raw in
            Task { @MainActor [weak self] in self?.handleScan(raw: raw) }
        }

        scanner.start { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if case .success(let layer) = result {
                    self.previewLayer = layer
                }
            }
        }
    }

    private func handleScan(raw: String) {
        guard !scanCooldown, raw != lastScannedValue else { return }
        lastScannedValue = raw
        scanCooldown = true

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        result = service.inspect(raw: raw, source: .camera)

        Task {
            try? await Task.sleep(for: .seconds(2.5))
            scanCooldown = false
            lastScannedValue = nil
        }
    }
}
