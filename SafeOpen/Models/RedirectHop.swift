import Foundation

struct RedirectHop: Identifiable, Codable {
    let id: UUID
    let url: URL
    let statusCode: Int?
    let resolvedLocally: Bool
}
