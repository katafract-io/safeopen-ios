import SwiftUI

struct ShareInspectView: View {
    let url: URL
    let result: InspectionResult?
    let isLoading: Bool
    let error: String?
    let onOpenInApp: () -> Void

    private let cyan = Color(red: 0, green: 0.83, blue: 1)

    var body: some View {
        VStack(spacing: 12) {
            if isLoading {
                loadingView
            } else if let error = error {
                errorView(error)
            } else if let result = result {
                resultView(result)
            } else {
                emptyView
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(UIColor.systemGroupedBackground))
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Analyzing link…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.orange)
            Text("Inspection failed")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }

    private func resultView(_ result: InspectionResult) -> some View {
        VStack(spacing: 12) {
            // Risk banner
            riskBanner(result)

            // Destination info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Destination")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                if let finalURL = result.finalURL {
                    Text(finalURL.host ?? finalURL.absoluteString)
                        .font(.caption.monospaced())
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                }
            }
            .padding(10)
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

            // Risk summary
            if !result.riskFactors.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Risk Factors")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(result.riskFactors.prefix(2), id: \.self) { factor in
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundStyle(riskColor(result.riskLevel))
                            Text(factor.explanation)
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }
                    }
                    if result.riskFactors.count > 2 {
                        Text("+\(result.riskFactors.count - 2) more")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
            }

            // Open in SafeOpen button
            Button(action: onOpenInApp) {
                Label("Open in SafeOpen", systemImage: "arrow.up.right")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(cyan)
            .controlSize(.regular)

            Text("AI summary costs 1 credit. Basic inspection is free.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func riskBanner(_ result: InspectionResult) -> some View {
        VStack(spacing: 6) {
            Image(systemName: riskIcon(result.riskLevel))
                .font(.headline)
                .foregroundStyle(riskColor(result.riskLevel))
            Text(result.riskLevel.displayTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(riskColor(result.riskLevel).opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Text("Ready to inspect")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func riskIcon(_ level: RiskLevel) -> String {
        switch level {
        case .low:     return "checkmark.shield.fill"
        case .caution: return "exclamationmark.shield.fill"
        case .high:    return "xmark.shield.fill"
        case .unknown: return "questionmark.app.fill"
        }
    }

    private func riskColor(_ level: RiskLevel) -> Color {
        switch level {
        case .low:     return .green
        case .caution: return .orange
        case .high:    return .red
        case .unknown: return .secondary
        }
    }
}
