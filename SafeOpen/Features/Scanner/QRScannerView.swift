import AVFoundation
import SwiftUI

struct QRScannerView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = QRScannerViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if viewModel.cameraAuthorized {
                    CameraPreviewView(viewModel: viewModel)
                        .ignoresSafeArea()

                    ScannerOverlay(torchOn: viewModel.torchOn) {
                        viewModel.toggleTorch()
                    }
                } else {
                    CameraPermissionView(status: viewModel.cameraStatus)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(item: $viewModel.result) { result in
                InspectionResultView(result: result)
            }
        }
        .task { await viewModel.requestPermission() }
        .onDisappear { viewModel.stopScanning() }
        .onAppear { viewModel.resumeScanning() }
        .onReceive(viewModel.$result.compactMap { $0 }) { appState.record($0) }
    }
}

// MARK: - Camera preview

struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var viewModel: QRScannerViewModel

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // attachGeneration is read here so SwiftUI calls updateUIView whenever it changes.
        _ = viewModel.attachGeneration
        viewModel.attachPreview(to: uiView)
        viewModel.previewLayer?.frame = uiView.bounds
        // Restrict metadata detection (and autofocus hint) to the centered finder box.
        viewModel.applyFinderInterestRect(in: uiView.bounds)
    }
}

// MARK: - Scanner overlay

private struct FinderFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}

struct ScannerOverlay: View {
    let torchOn: Bool
    let onTorchToggle: () -> Void

    @State private var finderRect: CGRect = .zero

    private let finderSize: CGFloat = 270

    var body: some View {
        ZStack {
            // Dimmed surround — cutout tracks actual finder position
            DimmedSurround(finderRect: finderRect)

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Text("SafeOpen")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()

                    Button(action: onTorchToggle) {
                        Image(systemName: torchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(torchOn ? Color.yellow : .white)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()

                // Invisible spacer that anchors the finder region for DimmedSurround alignment
                Color.clear
                    .frame(width: finderSize, height: finderSize)
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(key: FinderFrameKey.self, value: geo.frame(in: .global))
                        }
                    )

                Spacer()

                // Hint label
                Text("Point at any QR code or barcode")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 48)
            }
        }
        .onPreferenceChange(FinderFrameKey.self) { finderRect = $0 }
    }
}

// MARK: - Dimmed surround

struct DimmedSurround: View {
    let finderRect: CGRect

    var body: some View {
        GeometryReader { geo in
            // Determine this view's origin in global (screen) coordinates.
            // finderRect is also in global coords, so subtracting the origin
            // converts it into this view's local drawing space.
            let viewOrigin = geo.frame(in: .global).origin
            let localRect: CGRect = {
                if finderRect != .zero {
                    return CGRect(
                        x: finderRect.minX - viewOrigin.x,
                        y: finderRect.minY - viewOrigin.y,
                        width: finderRect.width,
                        height: finderRect.height
                    )
                } else {
                    // Centered fallback before layout settles
                    let cx = geo.size.width / 2, cy = geo.size.height / 2
                    let halfW: CGFloat = 135
                    return CGRect(x: cx - halfW, y: cy - halfW, width: halfW * 2, height: halfW * 2)
                }
            }()
            Path { path in
                path.addRect(CGRect(origin: .zero, size: geo.size))
                path.addRoundedRect(in: localRect, cornerSize: CGSize(width: 20, height: 20))
            }
            .fill(Color.black.opacity(0.5), style: FillStyle(eoFill: true))
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Permission denied

struct CameraPermissionView: View {
    let status: AVAuthorizationStatus

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text(status == .notDetermined ? "Requesting Camera Access…" : "Camera Access Required")
                    .font(.title3.bold())

                Text("SafeOpen needs camera access to scan QR codes.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if status == .denied || status == .restricted {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0, green: 0.83, blue: 1))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
