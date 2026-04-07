import Foundation

@MainActor
class PasteLinkViewModel: ObservableObject {
    @Published var input = ""
    @Published var result: InspectionResult?

    private let service = SafeOpenService()

    func inspect() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        result = service.inspect(raw: trimmed, source: .paste)
    }
}
