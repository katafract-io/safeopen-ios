// SafeOpen/Features/Inspection/KataScanResultView.swift
//
// Polished hero result card used as the top-of-scroll focal point for
// Screenshots 2 (safe) and 3 (dangerous). Replaces the stock RiskBanner
// with a KatafractStyle-branded layout.
//
// The existing InspectionResultView is not removed — it still handles all
// detail content below the fold. KataScanResultBanner is injected at the
// top of InspectionResultView's body in place of RiskBanner.

import SwiftUI

// MARK: - KataScanResultBanner (replaces RiskBanner in InspectionResultView)

struct KataScanResultBanner: View {
    let result: InspectionResult

    var body: some View {
        switch result.riskLevel {
        case .low:     SafeResultBanner(urlString: result.finalURL?.absoluteString ?? result.payload.rawValue)
        case .high:    DangerResultBanner(urlString: result.finalURL?.absoluteString ?? result.payload.rawValue,
                                          reason: result.riskFactors.first?.explanation ?? "Threat indicators detected")
        case .caution: CautionResultBanner(result: result)
        case .unknown: UnknownResultBanner(result: result)
        }
    }
}

// MARK: - Safe result banner

private struct SafeResultBanner: View {
    let urlString: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 80, weight: .regular))
                .foregroundStyle(Color.kataChampagne)
                .padding(.top, 32)

            Text("This link is safe.")
                .font(.kataDisplay(24))
                .foregroundStyle(Color.kataMidnight)
                .multilineTextAlignment(.center)

            // URL pill
            Text(urlString)
                .font(.kataMono(14))
                .foregroundStyle(Color.kataMidnight.opacity(0.7))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.kataIce.opacity(0.55))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.kataGold.opacity(0.5), lineWidth: 0.75)
                        )
                )
                .padding(.horizontal, 24)

            // Metadata chips row
            HStack(spacing: 12) {
                metaChip(icon: "globe", text: domain(from: urlString))
                metaChip(icon: "clock", text: "Just now")
            }
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity)
        .background(Color.kataChampagne.opacity(0.06))
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
    private let crimson = Color.kataCrimson

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 72, weight: .regular))
                .foregroundStyle(crimson)
                .padding(.top, 32)

            Text("Do not open.")
                .font(.kataDisplay(24))
                .foregroundStyle(crimson)
                .multilineTextAlignment(.center)

            // Reason chip
            Text(reason)
                .font(.kataBody(14))
                .foregroundStyle(crimson.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.kataIce.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(crimson.opacity(0.5), lineWidth: 0.5)
                        )
                )
                .padding(.horizontal, 24)

            // Struck-through URL
            Text(urlString)
                .font(.kataMono(14))
                .foregroundStyle(Color.kataMidnight.opacity(0.5))
                .strikethrough(true, color: Color.kataMidnight.opacity(0.35))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity)
        .background(crimson.opacity(0.04))
    }
}

// MARK: - Caution banner (unchanged functional, styled)

private struct CautionResultBanner: View {
    let result: InspectionResult

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.shield")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(Color.kataGold)
                .padding(.top, 28)

            Text(result.riskLevel.displayTitle)
                .font(.kataHeadline(20))
                .foregroundStyle(Color.kataMidnight)

            Text(result.summary)
                .font(.kataBody(15))
                .foregroundStyle(Color.kataMidnight.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(Color.kataGold.opacity(0.07))
    }
}

// MARK: - Unknown banner

private struct UnknownResultBanner: View {
    let result: InspectionResult

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.app")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(Color.kataMidnight.opacity(0.4))
                .padding(.top, 28)

            Text(result.riskLevel.displayTitle)
                .font(.kataHeadline(20))
                .foregroundStyle(Color.kataMidnight)

            Text(result.summary)
                .font(.kataBody(15))
                .foregroundStyle(Color.kataMidnight.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(Color.kataMidnight.opacity(0.04))
    }
}

// MARK: - Screenshot mode preview helpers (used by UITests when ScreenshotMode is set)
// TODO: Sprint 10 — wire ScreenshotMode environment flag in SafeOpen-UITests target
// so fastlane capture_ios_screenshots walks:
//   1. PasteLinkView with example URL pre-filled (hero input state)
//   2. InspectionResultView with mock safe InspectionResult
//   3. InspectionResultView with mock dangerous InspectionResult
// See project_screenshot_pipeline_canonical.md for the ScreenshotMode pattern.
