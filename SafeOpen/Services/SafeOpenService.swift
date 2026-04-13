import Foundation

/// Orchestrates inspection: local scoring + optional backend enrichment.
/// MVP: local only. Phase 2+: backend-assisted.
@MainActor
class SafeOpenService: ObservableObject {

    private let classifier = PayloadClassifier()
    private let normalizer = URLNormalizationService()
    private let riskScorer = RiskScoringService()
    private let apiClient = InspectionAPIClient()

    func inspect(raw: String, source: ScannedPayload.PayloadSource) -> InspectionResult {
        let type = classifier.classify(raw)
        let normalizedURL = normalizer.normalize(raw)

        let payload = ScannedPayload(
            id: UUID(),
            rawValue: raw,
            type: type,
            normalizedValue: normalizedURL?.absoluteString,
            scannedAt: Date(),
            source: source
        )

        let (riskLevel, riskFactors) = scoreLocally(url: normalizedURL, type: type)
        let (title, summary) = explain(payload: payload, riskLevel: riskLevel)

        return InspectionResult(
            id: UUID(),
            payload: payload,
            title: title,
            summary: summary,
            riskLevel: riskLevel,
            riskFactors: riskFactors,
            recommendedAction: recommendedAction(riskLevel: riskLevel),
            finalURL: normalizedURL,
            redirectHops: [],
            canOpenSafely: riskLevel != .high && type != .unknown
        )
    }

    // MARK: - Private

    private func scoreLocally(url: URL?, type: PayloadType) -> (RiskLevel, [RiskFactor]) {
        // Known non-URL types are inherently classifiable — not "unknown"
        switch type {
        case .wifi, .sms, .email, .phone, .contact, .calendar, .plainText:
            return (.low, [])
        case .unknown:
            return (.unknown, [.unknownDestination])
        case .url, .shortURL:
            guard let url else { return (.unknown, [.unknownDestination]) }
            return riskScorer.score(url: url, type: type)
        }
    }

    private func explain(payload: ScannedPayload, riskLevel: RiskLevel) -> (title: String, summary: String) {
        switch payload.type {
        case .url:
            return ("Website link", "This opens a website in your browser.")
        case .shortURL:
            return ("Shortened link", "The real destination is hidden. Use Inspect & Open to reveal it before your device connects.")
        case .wifi:
            return ("Wi-Fi network", "This will join a Wi-Fi network. Review the credentials before connecting.")
        case .sms:
            return ("Text message", "This starts a text message.")
        case .email:
            return ("Email", "This opens a new email.")
        case .phone:
            return ("Phone call", "This starts a phone call.")
        case .contact:
            return ("Contact card", "This adds a contact to your address book.")
        case .calendar:
            return ("Calendar event", "This adds an event to your calendar.")
        case .plainText:
            return ("Plain text", "This is a plain text string with no action.")
        case .unknown:
            return ("Unknown", "This payload type was not recognized.")
        }
    }

    private func recommendedAction(riskLevel: RiskLevel) -> InspectionResult.RecommendedAction {
        switch riskLevel {
        case .low:     return .open
        case .caution: return .caution
        case .high:    return .block
        case .unknown: return .caution
        }
    }
}
