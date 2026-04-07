import SwiftUI

struct InspectionResultView: View {
    let result: InspectionResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Risk level header
                Text(result.riskLevel.displayTitle)
                    .font(.title.bold())
                    .foregroundStyle(riskColor)

                // Summary
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title).font(.headline)
                    Text(result.summary).foregroundStyle(.secondary)
                }

                // Destination
                if let url = result.finalURL {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Destination").font(.caption).foregroundStyle(.secondary)
                        Text(url.absoluteString)
                            .font(.caption.monospaced())
                            .lineLimit(3)
                    }
                }

                // Risk factors
                if !result.riskFactors.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Risk factors").font(.caption).foregroundStyle(.secondary)
                        ForEach(result.riskFactors, id: \.self) { factor in
                            Label(factor.explanation, systemImage: "exclamationmark.triangle")
                                .font(.caption)
                        }
                    }
                }

                Divider()

                // Actions
                VStack(spacing: 12) {
                    if let url = result.finalURL {
                        Button("Open") {
                            UIApplication.shared.open(url)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(riskColor)
                    }

                    Button("Open Safely") {
                        // TODO: Phase C — Wraith safe-open session
                    }
                    .buttonStyle(.bordered)

                    if let raw = result.payload.normalizedValue ?? Optional(result.payload.rawValue) {
                        Button("Copy") {
                            UIPasteboard.general.string = raw
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Inspection")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var riskColor: Color {
        switch result.riskLevel {
        case .low:     return .green
        case .caution: return .orange
        case .high:    return .red
        case .unknown: return .secondary
        }
    }
}
