import Foundation

enum RiskLevel: String, Codable {
    case low
    case caution
    case high
    case unknown

    var displayTitle: String {
        switch self {
        case .low:     return "Likely safe"
        case .caution: return "Use caution"
        case .high:    return "High risk"
        case .unknown: return "Unknown"
        }
    }
}
