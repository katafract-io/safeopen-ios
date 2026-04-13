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

        let (riskLevel, riskFactors) = scoreLocally(url: normalizedURL, type: type, raw: raw)
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

    private func scoreLocally(url: URL?, type: PayloadType, raw: String = "") -> (RiskLevel, [RiskFactor]) {
        switch type {
        case .wifi, .sms, .email, .phone, .contact, .meCard, .calendar, .otp, .geo, .plainText:
            return (.low, [])
        case .crypto:
            return (.caution, [])
        case .script:
            return (.high, [.executableScript])
        case .dataURL:
            return (.caution, [.dataURLPayload])
        case .deepLink:
            return (.low, [])
        case .json:
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
        case .dataURL:
            return ("Embedded data", "This encodes raw data directly in the payload — no server needed. Review before acting.")
        case .deepLink:
            return ("App deep link", "This opens a specific screen inside an app on your device.")
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
        case .meCard:
            return ("Contact (MECARD)", "This adds a contact to your address book.")
        case .calendar:
            return ("Calendar event", "This adds an event to your calendar.")
        case .otp:
            return ("One-time password", "This is an authenticator setup code. Add it to your authenticator app.")
        case .crypto:
            return ("Crypto payment", "This is a cryptocurrency payment request. Verify the address carefully before sending.")
        case .geo:
            return ("Location", "This encodes a geographic coordinate.")
        case .script:
            return ("Executable script", "This payload contains code. Do not execute it unless you trust the source completely.")
        case .json:
            return ("JSON data", "This is structured data in JSON format.")
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
