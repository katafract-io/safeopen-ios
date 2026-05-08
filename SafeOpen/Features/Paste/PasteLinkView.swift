import SwiftUI
import KatafractStyle

struct PasteLinkView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = PasteLinkViewModel()
    @FocusState private var inputFocused: Bool
    @Binding var pendingURL: URL?
    @State private var showDebug = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {

                    // ── App identity lockup ───────────────────────────────
                    VStack(spacing: 4) {
                        Text("SafeOpen")
                            .font(.kataDisplay(28))
                            .foregroundStyle(Color.kataMidnight)
                        Text("KATAFRACT")
                            .font(.kataMono(10))
                            .foregroundStyle(Color.kataSapphire.opacity(0.6))
                            .kerning(2)
                            .onTapGesture(count: 3) {
                                if PlatformEntitlement.isPlatformUnlocked {
                                    showDebug = true
                                }
                            }
                    }
                    .padding(.top, 8)

                    // ── URL input card ────────────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        Text("URL or Text")
                            .font(.kataCaption(12, weight: .semibold))
                            .foregroundStyle(Color.kataMidnight.opacity(0.55))
                            .padding(.horizontal, 4)

                        ZStack(alignment: .topLeading) {
                            if viewModel.input.isEmpty {
                                Text("Paste a link, QR content, or any text…")
                                    .font(.kataBody(15))
                                    .foregroundStyle(Color.kataMidnight.opacity(0.3))
                                    .padding(.top, 10)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }

                            TextEditor(text: $viewModel.input)
                                .font(.kataMono(15))
                                .foregroundStyle(Color.kataMidnight)
                                .scrollContentBackground(.hidden)
                                .focused($inputFocused)
                                .frame(minHeight: 110, alignment: .top)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.kataIce.opacity(0.45))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.kataSapphire.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }

                    // ── Secondary controls ────────────────────────────────
                    HStack {
                        Button {
                            if let str = UIPasteboard.general.string, !str.isEmpty {
                                viewModel.input = str
                                KataHaptic.tap.fire()
                            }
                        } label: {
                            Label("Paste", systemImage: "doc.on.clipboard")
                                .font(.kataBody(15, weight: .medium))
                                .foregroundStyle(Color.kataSapphire)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        if !viewModel.input.isEmpty {
                            Button(role: .destructive) {
                                viewModel.input = ""
                                KataHaptic.tap.fire()
                            } label: {
                                Label("Clear", systemImage: "xmark.circle")
                                    .font(.kataCaption(13))
                                    .foregroundStyle(Color.kataMidnight.opacity(0.45))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // ── Primary CTA ───────────────────────────────────────
                    Button {
                        inputFocused = false
                        viewModel.inspect()
                        KataHaptic.tap.fire()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "shield.lefthalf.filled")
                            Text("Check Safety")
                                .font(.kataHeadline(17, weight: .medium))
                        }
                        .foregroundStyle(Color.kataIce)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule().fill(Color.kataSapphire)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(viewModel.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarHidden(true)
            .navigationDestination(item: $viewModel.result) { result in
                InspectionResultView(result: result)
            }
        }
        .fullScreenCover(isPresented: $viewModel.isInspecting) {
            InspectingSealView()
        }
        .sheet(isPresented: $showDebug) {
            FounderDebugPanel()
        }
        .onReceive(viewModel.$result.compactMap { $0 }) { appState.record($0) }
        .onAppear {
            if let url = pendingURL {
                viewModel.input = url.absoluteString
                pendingURL = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.inspect()
                }
            }
        }
    }
}
