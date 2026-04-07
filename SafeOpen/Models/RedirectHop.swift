import Foundation

struct RedirectHop: Identifiable, Codable, Hashable {
    let id: UUID
    let url: URL
    let statusCode: Int?
    let resolvedLocally: Bool
}
