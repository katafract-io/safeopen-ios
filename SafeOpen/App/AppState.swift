import Foundation
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var inspectionHistory: [InspectionResult] = []

    func record(_ result: InspectionResult) {
        inspectionHistory.insert(result, at: 0)
    }
}
