import AVFoundation
import Foundation

final class CameraScannerService: NSObject {

    var onDecode: ((String) -> Void)?

    private var captureSession: AVCaptureSession?
    private(set) var previewLayer: AVCaptureVideoPreviewLayer?
    private var isRunning = false

    // MARK: - Start

    func start(completion: @escaping (Result<AVCaptureVideoPreviewLayer, Error>) -> Void) {
        guard !isRunning else { return }

        let session = AVCaptureSession()
        session.beginConfiguration()

        guard let device = AVCaptureDevice.default(for: .video) else {
            completion(.failure(CameraError.noCameraAvailable))
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                completion(.failure(CameraError.noCameraAvailable))
                return
            }
            session.addInput(input)

            let output = AVCaptureMetadataOutput()
            guard session.canAddOutput(output) else {
                completion(.failure(CameraError.noCameraAvailable))
                return
            }
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [
                .qr, .ean8, .ean13, .pdf417, .aztec,
                .dataMatrix, .code39, .code93, .code128, .upce
            ]
        } catch {
            completion(.failure(error))
            return
        }

        session.commitConfiguration()

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill

        captureSession = session
        previewLayer = layer

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            session.startRunning()
            DispatchQueue.main.async {
                self?.isRunning = true
                completion(.success(layer))
            }
        }
    }

    func stop() {
        captureSession?.stopRunning()
        isRunning = false
    }

    func resume() {
        guard let session = captureSession, !isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            session.startRunning()
            DispatchQueue.main.async { self?.isRunning = true }
        }
    }

    func setTorch(_ on: Bool) {
        guard
            let device = AVCaptureDevice.default(for: .video),
            device.hasTorch,
            (try? device.lockForConfiguration()) != nil
        else { return }
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension CameraScannerService: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard
            let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            let value = obj.stringValue,
            !value.isEmpty
        else { return }
        onDecode?(value)
    }
}

// MARK: - Errors

enum CameraError: LocalizedError {
    case noCameraAvailable
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .noCameraAvailable: return "No camera available on this device."
        case .permissionDenied:  return "Camera access was denied. Enable it in Settings."
        }
    }
}
