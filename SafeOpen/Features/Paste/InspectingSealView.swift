// SafeOpen/Features/Paste/InspectingSealView.swift
// Hero scan-in-progress screen. Presented as a fullscreenCover while
// the local inspect() call runs (and optionally backend enrichment later).

import SwiftUI
import KatafractStyle

struct InspectingSealView: View {

    // MARK: - Stage cycling

    private let stages = [
        "Loading page in isolated sandbox…",
        "Capturing render…",
        "Analyzing redirects…",
    ]

    @State private var stageIndex: Int = 0
    @State private var progressFill: Double = 0.0

    // MARK: - Timer

    private let timer = Timer.publish(every: 1.2, on: .main, in: .common).autoconnect()

    // MARK: - Body

    var body: some View {
        ZStack {
            // ── Background ─────────────────────────────────────────────────
            Color.kataMidnight
                .ignoresSafeArea()

            RadialGradient(
                colors: [Color.kataSapphire.opacity(0.04), Color.clear],
                center: .center,
                startRadius: 60,
                endRadius: 280
            )
            .ignoresSafeArea()

            // ── Central ring group ─────────────────────────────────────────
            VStack(spacing: 36) {
                ZStack {
                    // Backing ring — faint gold hairline
                    Circle()
                        .stroke(Color.kataGold.opacity(0.15), lineWidth: 0.5)
                        .frame(width: 120, height: 120)

                    // Progress arc (indeterminate animation)
                    Circle()
                        .trim(from: 0, to: progressFill)
                        .stroke(Color.kataGold, style: StrokeStyle(lineWidth: 0.5, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: progressFill)

                    // Centre icon
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32, weight: .ultraLight))
                        .foregroundStyle(Color.kataGold)
                        .symbolEffect(.pulse)
                }

                // ── Stage microcopy ───────────────────────────────────────
                Text(stages[stageIndex])
                    .font(.kataMono(13))
                    .foregroundStyle(Color.kataGold.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .id(stageIndex)
                    .animation(.easeInOut(duration: 0.3), value: stageIndex)
                    .padding(.horizontal, 40)
            }
        }
        .onAppear {
            // Kick the indeterminate arc into motion
            progressFill = 0.72
        }
        .onReceive(timer) { _ in
            let next = (stageIndex + 1) % stages.count
            stageIndex = next
            Task { @MainActor in
                KataHaptic.tap.fire()
            }
        }
    }
}
