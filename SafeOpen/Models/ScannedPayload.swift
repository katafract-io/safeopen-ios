import Foundation

struct ScannedPayload: Identifiable, Codable, Hashable {
    let id: UUID
    let rawValue: String
    let type: PayloadType
    let normalizedValue: String?
    let scannedAt: Date
    let source: PayloadSource

    enum PayloadSource: String, Codable, Hashable {
        case camera
        case paste
        case shareExtension
        case imageImport
    }
}
