import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var showClearConfirm = false

    var body: some View {
        NavigationStack {
            Group {
                if appState.inspectionHistory.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !appState.inspectionHistory.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(role: .destructive) {
                            showClearConfirm = true
                        } label: {
                            Label("Clear", systemImage: "trash")
                        }
                    }
                }
            }
            .confirmationDialog("Clear all history?", isPresented: $showClearConfirm, titleVisibility: .visible) {
                Button("Clear History", role: .destructive) { appState.clearHistory() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No inspections yet")
                .font(.title3.bold())
            Text("Scanned links and QR codes will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var historyList: some View {
        List {
            ForEach(appState.inspectionHistory) { result in
                NavigationLink(value: result) {
                    HistoryRow(result: result)
                }
            }
            .onDelete { offsets in
                appState.inspectionHistory.remove(atOffsets: offsets)
            }
        }
        .navigationDestination(for: InspectionResult.self) { result in
            InspectionResultView(result: result)
        }
    }
}

// MARK: - Row

struct HistoryRow: View {
    let result: InspectionResult

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(riskColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: riskIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(riskColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(result.title)
                    .font(.subheadline.weight(.semibold))

                Text(result.payload.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(result.payload.scannedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private var riskIcon: String {
        switch result.riskLevel {
        case .low:     return "checkmark.shield.fill"
        case .caution: return "exclamationmark.shield.fill"
        case .high:    return "xmark.shield.fill"
        case .unknown: return "questionmark.app.fill"
        }
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
