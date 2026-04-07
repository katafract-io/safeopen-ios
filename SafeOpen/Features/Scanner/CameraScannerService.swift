import AVFoundation
import Foundation

/// Stub — Codex Task 2: wrap AVCaptureSession for QR detection.
/// Emit decoded strings via the `onDecode` callback.
class CameraScannerService: NSObject {
    var onDecode: ((String) -> Void)?

    // TODO: AVCaptureSession setup, AVCaptureMetadataOutput, delegate
}
