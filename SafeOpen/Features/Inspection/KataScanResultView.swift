// SafeOpen/Features/Inspection/KataScanResultView.swift
//
// Sealed verdict report. Opus crit item #2:
//   - No green checkmark SF Symbol, no red danger color
//   - Gold hairline container around screenshot thumbnail + metadata
//   - Serif "stamp" rotated -8° in kataChampagne for all verdict levels
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
    let stampText: String
    let stampAngle: Double
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Gold hairline border container
            RoundedRectangle(cornerRadius: 2)
                .stroke(hairlineColor.opacity(0.5), lineWidth: 0.5)
                .background(
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.kataNavy.opacity(0.05))
                )

            content()
                .padding(20)

            // Serif stamp — top-right corner. Width-constrained + wrapping so a
            // longer label can never render as a diagonal sentence across the card.
            Text(stampText)
                .font(.kataDisplay(14))
                .foregroundStyle(Color.kataChampagne)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 130, alignment: .trailing)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.kataNavy.opacity(0.55))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.kataChampagne.opacity(0.25), lineWidth: 0.5)
                        )
                )
                .rotationEffect(.degrees(stampAngle))
                .padding(.top, 14)
                .padding(.trailing, 18)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Safe result banner

private struct SafeResultBanner: View {
    let urlString: String

    var body: some View {
        SealedContainer(hairlineColor: .kataGold, stampText: "Verified", stampAngle: -8) {
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
        SealedContainer(hairlineColor: .kataChampagne, stampText: "Danger", stampAngle: -8) {
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

                // Reason shown as normal horizontal text (was previously
                // jammed into the rotated corner stamp, which rendered as a
                // long diagonal sentence across the card).
                Text(reason)
                    .font(.kataBody(15))
                    .foregroundStyle(Color.kataIce.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

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
        SealedContainer(hairlineColor: .kataChampagne, stampText: "Caution", stampAngle: -8) {
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
        SealedContainer(hairlineColor: .kataGold, stampText: "Unknown", stampAngle: -8) {
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
