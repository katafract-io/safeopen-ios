import Foundation

struct InspectionResult: Identifiable, Codable {
    let id: UUID
    let payload: ScannedPayload
    let title: String
    let summary: String
    let riskLevel: RiskLevel
    let riskFactors: [RiskFactor]
    let recommendedAction: RecommendedAction
    let finalURL: URL?
    let redirectHops: [RedirectHop]
    let canOpenSafely: Bool

    enum RecommendedAction: String, Codable {
        case open
        case openSafely
        case caution
        case block
    }
}
