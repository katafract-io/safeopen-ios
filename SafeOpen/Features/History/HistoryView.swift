import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            if appState.inspectionHistory.isEmpty {
                ContentUnavailableView("No history yet", systemImage: "clock")
            } else {
                List(appState.inspectionHistory) { result in
                    NavigationLink(value: result) {
                        HStack {
                            Image(systemName: riskIcon(result.riskLevel))
                                .foregroundStyle(riskColor(result.riskLevel))
                            VStack(alignment: .leading) {
                                Text(result.title).font(.headline)
                                Text(result.payload.rawValue)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .navigationDestination(for: InspectionResult.self) { result in
                    InspectionResultView(result: result)
                }
            }
        }
        .navigationTitle("History")
    }

    private func riskIcon(_ level: RiskLevel) -> String {
        switch level {
        case .low:     return "checkmark.circle"
        case .caution: return "exclamationmark.triangle"
        case .high:    return "xmark.octagon"
        case .unknown: return "questionmark.circle"
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
