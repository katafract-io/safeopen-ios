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

    @State private var pulse = false
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

                // Finder frame with animated corners
                ZStack {
                    FinderFrame(size: finderSize, pulse: pulse)
                }
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
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Dimmed surround

struct DimmedSurround: View {
    let finderRect: CGRect

    var body: some View {
        GeometryReader { geo in
            Path { path in
                // Full screen coverage
                path.addRect(CGRect(origin: .zero, size: geo.size))
                // Cut out the finder box (even-odd fill) — use screen coords
                // Convert finderRect from global to this view's local space
                let localRect: CGRect
                if finderRect != .zero {
                    localRect = finderRect
                } else {
                    // Before layout settles, use a centered estimate so the whole screen isn't dimmed
                    let cx = geo.size.width / 2, cy = geo.size.height / 2
                    let halfW: CGFloat = 135
                    localRect = CGRect(x: cx - halfW, y: cy - halfW, width: halfW * 2, height: halfW * 2)
                }
                path.addRoundedRect(in: localRect, cornerSize: CGSize(width: 20, height: 20))
            }
            .fill(Color.black.opacity(0.5), style: FillStyle(eoFill: true))
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Finder frame corners

struct FinderFrame: View {
    let size: CGFloat
    let pulse: Bool

    private let arm: CGFloat = 32
    private let thick: CGFloat = 4
    private let corner: CGFloat = 8
    private let accentColor = Color(red: 0, green: 0.83, blue: 1)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner)
                .stroke(accentColor.opacity(0.15), lineWidth: 1)
                .frame(width: size, height: size)

            ForEach(0..<4, id: \.self) { i in
                CornerBracket(arm: arm, thick: thick, radius: corner, color: accentColor)
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(Double(i) * 90))
            }
        }
        .opacity(pulse ? 1.0 : 0.65)
        .scaleEffect(pulse ? 1.0 : 0.985)
        .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulse)
    }
}

struct CornerBracket: View {
    let arm: CGFloat
    let thick: CGFloat
    let radius: CGFloat
    let color: Color

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height

            // Top-left bracket (this view is rotated for other corners)
            var path = Path()
            path.move(to: CGPoint(x: 0, y: arm))
            path.addLine(to: CGPoint(x: 0, y: radius))
            path.addQuadCurve(to: CGPoint(x: radius, y: 0),
                              control: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: arm, y: 0))

            ctx.stroke(path, with: .color(color),
                       style: StrokeStyle(lineWidth: thick, lineCap: .round))
            _ = (w, h)
        }
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
