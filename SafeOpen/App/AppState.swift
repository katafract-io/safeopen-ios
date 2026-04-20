import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    private static let historyKey = "com.katafract.safeopen.history"
    private static let maxHistory = 500

    @Published var inspectionHistory: [InspectionResult] = []
    @Published var selectedTab: Int = 0
    @Published var pendingURLToInspect: URL?

    init() {
        load()
    }

    func record(_ result: InspectionResult) {
        // Deduplicate by raw value within 3 seconds
        if let last = inspectionHistory.first,
           last.payload.rawValue == result.payload.rawValue,
           abs(last.payload.scannedAt.timeIntervalSince(result.payload.scannedAt)) < 3 {
            return
        }

        inspectionHistory.insert(result, at: 0)
        if inspectionHistory.count > Self.maxHistory {
            inspectionHistory = Array(inspectionHistory.prefix(Self.maxHistory))
        }
        save()
    }

    func clearHistory() {
        inspectionHistory = []
        UserDefaults.standard.removeObject(forKey: Self.historyKey)
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(inspectionHistory) else { return }
        UserDefaults.standard.set(data, forKey: Self.historyKey)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: Self.historyKey),
            let history = try? JSONDecoder().decode([InspectionResult].self, from: data)
        else { return }
        inspectionHistory = history
    }
}
