import Foundation
import KatafractStyle

@MainActor
class PasteLinkViewModel: ObservableObject {
    @Published var input = ""
    @Published var result: InspectionResult?
    @Published var isInspecting = false
    @Published var error: String?

    private let service = SafeOpenService()

    func inspect() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        error = nil
        isInspecting = true
        // Brief artificial delay so the hero seal screen has time to
        // land and animate before the result is pushed.
        Task {
            // One stage cycle (1.2s) so user sees the animation at least once
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            result = service.inspect(raw: trimmed, source: .paste)
            isInspecting = false
        }
    }


}
