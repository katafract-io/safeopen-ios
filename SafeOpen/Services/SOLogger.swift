import Foundation

/// Ring-buffer debug logger for SafeOpen. Founder-only — not shipped to general users.
/// Access via SOLogger.shared; log via soLog(_:category:) free function.
@MainActor
final class SOLogger: ObservableObject {

    static let shared = SOLogger()
    private init() {}

    struct Entry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let category: String  // "scene" | "session" | "api" | "attest" | "app"
        let message: String

        var formatted: String {
            let f = DateFormatter()
            f.dateFormat = "HH:mm:ss.SSS"
            return "[\(f.string(from: timestamp))] [\(category)] \(message)"
        }
    }

    @Published private(set) var entries: [Entry] = []
    private let maxEntries = 300

    func log(_ message: String, category: String = "app") {
        let entry = Entry(timestamp: Date(), category: category, message: message)
        entries.append(entry)
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
    }

    func clear() { entries.removeAll() }

    var allText: String { entries.map(\.formatted).joined(separator: "\n") }
}

/// Fire-and-forget logger callable from any context.
func soLog(_ message: String, category: String = "app") {
    Task { @MainActor in SOLogger.shared.log(message, category: category) }
}
