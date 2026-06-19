// SafeOpen/Features/Inspection/KataScanResultView.swift
//
// Sealed verdict report. Opus crit item #2:
//   - No green checkmark SF Symbol, no red danger color
//   - Gold hairline container around screenshot thumbnail + metadata
//   - Verdict + reason shown as clean horizontal text/banner (no rotated stamp)
//   - Differentiates from every scam-warning screen the user has ever seen

import SwiftUI
import KatafractStyle

// MARK: - KataScanResultBanner (replaces RiskBanner in InspectionResultView)

struct KataScanResultBanner: View {
    let result: InspectionResult

    var body: some View {
        switch result.riskLevel {
        case .low:     SafeResultBanner(urlString: result.finalURL?.absoluteString ?? result.payload.rawValue)
        case .high:    DangerResultBanner(
                           urlString: result.finalURL?.absoluteString ?? result.payload.rawValue,
                           reason: result.riskFactors.first?.explanation ?? "Threat indicators detected"
                       )
        case .caution: CautionResultBanner(result: result)
        case .unknown: UnknownResultBanner(result: result)
        }
    }
}

// MARK: - Shared sealed container chrome

private struct SealedContainer<Content: View>: View {
    let hairlineColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        // Hairline border container. (Removed the rotated corner "stamp" — it
        // read as childish and a longer label rendered as a stretched diagonal.)
        // Content is the sizing view; the border is its background so the card
        // height wraps the content instead of expanding to fill.
        content()
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.kataNavy.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(hairlineColor.opacity(0.5), lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - Safe result banner

private struct SafeResultBanner: View {
    let urlString: String

    var body: some View {
        SealedContainer(hairlineColor: .kataGold) {
            VStack(spacing: 20) {
                // Sealed ring icon instead of green checkmark
                ZStack {
                    Circle()
                        .stroke(Color.kataGold.opacity(0.35), lineWidth: 0.5)
                        .frame(width: 72, height: 72)
                    Image(systemName: "seal")
                        .font(.system(size: 40, weight: .ultraLight))
                        .foregroundStyle(Color.kataGold)
                }
                .padding(.top, 20)

                Text("This link is safe.")
                    .font(.kataDisplay(24))
                    .foregroundStyle(Color.kataIce)
                    .multilineTextAlignment(.center)

                // URL pill
                Text(urlString)
                    .font(.kataMono(13))
                    .foregroundStyle(Color.kataIce.opacity(0.65))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.kataNavy.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.kataGold.opacity(0.4), lineWidth: 0.5)
                            )
                    )
                    .padding(.horizontal, 8)

                // Metadata chips
                HStack(spacing: 12) {
                    metaChip(icon: "globe", text: domain(from: urlString))
                    metaChip(icon: "clock", text: "Just now")
                }
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color.kataGold.opacity(0.04))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func domain(from urlString: String) -> String {
        URL(string: urlString)?.host ?? urlString
    }

    private func metaChip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.kataMono(10))
            Text(text)
                .font(.kataMono(11))
        }
        .foregroundStyle(Color.kataSapphire)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.kataSapphire.opacity(0.08), in: Capsule())
    }
}

// MARK: - Dangerous result banner

private struct DangerResultBanner: View {
    let urlString: String
    let reason: String

    var body: some View {
        SealedContainer(hairlineColor: .kataChampagne) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.kataGold.opacity(0.9).opacity(0.35), lineWidth: 0.5)
                        .frame(width: 72, height: 72)
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 36, weight: .ultraLight))
                        .foregroundStyle(Color.kataGold.opacity(0.9))
                }
                .padding(.top, 20)

                Text("Do not open.")
                    .font(.kataDisplay(24))
                    .foregroundStyle(Color.kataIce)
                    .multilineTextAlignment(.center)

                // Reason as a clean horizontal banner (full-width tinted bar,
                // no rotation) — the background-banner treatment belongs here,
                // on the horizontal text, not on a rotated corner stamp.
                Text(reason)
                    .font(.kataBody(15))
                    .foregroundStyle(Color.kataIce.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.kataChampagne.opacity(0.10))
                    )
                    .padding(.horizontal, 12)

                // Struck-through URL
                Text(urlString)
                    .font(.kataMono(13))
                    .foregroundStyle(Color.kataIce.opacity(0.65))
                    .strikethrough(true, color: Color.kataIce.opacity(0.45))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color.kataChampagne.opacity(0.03))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Caution banner

private struct CautionResultBanner: View {
    let result: InspectionResult

    var body: some View {
        SealedContainer(hairlineColor: .kataChampagne) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(Color.kataGold.opacity(0.35), lineWidth: 0.5)
                        .frame(width: 60, height: 60)
                    Image(systemName: "exclamationmark.shield")
                        .font(.system(size: 32, weight: .ultraLight))
                        .foregroundStyle(Color.kataGold)
                }
                .padding(.top, 20)

                Text(result.riskLevel.displayTitle)
                    .font(.kataHeadline(20))
                    .foregroundStyle(Color.kataIce)

                Text(result.summary)
                    .font(.kataBody(15))
                    .foregroundStyle(Color.kataIce.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color.kataGold.opacity(0.04))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Unknown banner

private struct UnknownResultBanner: View {
    let result: InspectionResult

    var body: some View {
        SealedContainer(hairlineColor: .kataGold) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(Color.kataIce.opacity(0.45), lineWidth: 0.5)
                        .frame(width: 60, height: 60)
                    Image(systemName: "questionmark")
                        .font(.system(size: 28, weight: .ultraLight))
                        .foregroundStyle(Color.kataIce.opacity(0.8))
                }
                .padding(.top, 20)

                Text(result.riskLevel.displayTitle)
                    .font(.kataHeadline(20))
                    .foregroundStyle(Color.kataIce)

                Text(result.summary)
                    .font(.kataBody(15))
                    .foregroundStyle(Color.kataIce.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color.kataNavy.opacity(0.04))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Screenshot mode preview helpers (used by UITests when ScreenshotMode is set)
// TODO: Sprint 10 — wire ScreenshotMode environment flag in SafeOpen-UITests target
// so fastlane capture_ios_screenshots walks:
//   1. PasteLinkView with example URL pre-filled (hero input state)
//   2. InspectionResultView with mock safe InspectionResult
//   3. InspectionResultView with mock dangerous InspectionResult
// See project_screenshot_pipeline_canonical.md for the ScreenshotMode pattern.
