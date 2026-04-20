import Foundation

// MARK: - Inspection Result

struct InspectionResult: Identifiable, Codable, Hashable {
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

    enum RecommendedAction: String, Codable, Hashable {
        case open
        case openSafely
        case caution
        case block
    }
}

// MARK: - Scanned Payload

struct ScannedPayload: Codable, Hashable {
    let rawValue: String
    let type: PayloadType

    var normalizedValue: String? {
        guard type == .url || type == .shortURL else { return nil }
        return rawValue.hasPrefix("http") ? rawValue : "https://\(rawValue)"
    }
}

// MARK: - Payload Type

enum PayloadType: String, Codable, Hashable {
    case url
    case shortURL = "short_url"
    case dataURL = "data_url"
    case deepLink = "deep_link"
    case wifi
    case sms
    case email
    case phone
    case contact
    case meCard = "mecard"
    case calendar
    case otp
    case crypto
    case geo
    case script
    case json
    case plainText = "plain_text"
    case unknown
}

// MARK: - Risk Level

enum RiskLevel: String, Codable, Hashable {
    case low
    case caution
    case high
    case unknown

    var displayTitle: String {
        switch self {
        case .low:     return "Safe"
        case .caution: return "Caution"
        case .high:    return "High Risk"
        case .unknown: return "Unknown"
        }
    }
}

// MARK: - Risk Factor

struct RiskFactor: Codable, Hashable {
    let category: String
    let severity: Severity
    let explanation: String

    enum Severity: String, Codable, Hashable {
        case low
        case medium
        case high
    }

    static func == (lhs: RiskFactor, rhs: RiskFactor) -> Bool {
        lhs.category == rhs.category && lhs.severity == rhs.severity
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(category)
        hasher.combine(severity)
    }
}

// MARK: - Redirect Hop

struct RedirectHop: Codable, Hashable {
    let url: String
    let statusCode: Int
    let timestamp: Date?
}

// MARK: - Parsed Content (stub)

enum ParsedContent: Hashable {
    case none
    case contact(ContactContent)
    case event(EventContent)
    case otp(OTPContent)
    case geo(GeoContent)
    case crypto(CryptoContent)
    case script(ScriptContent)
    case json(String)
    case dataURL(DataURLContent)
    case deepLink(DeepLinkContent)
    case wifi
}

struct ContactContent: Hashable {
    let format: String
    let fullName: String?
    let firstName: String?
    let lastName: String?
    let org: String?
    let title: String?
    let phones: [String]
    let emails: [String]
    let address: String?
    let url: String?
    let note: String?
}

struct EventContent: Hashable {
    let summary: String?
    let startDate: String?
    let endDate: String?
    let location: String?
    let description: String?
    let organizer: String?
}

struct OTPContent: Hashable {
    let type: String
    let issuer: String?
    let account: String?
    let digits: Int?
    let period: Int?
}

struct GeoContent: Hashable {
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    let query: String?
}

struct CryptoContent: Hashable {
    let currency: String
    let address: String
    let amount: String?
    let label: String?
    let message: String?
}

struct ScriptContent: Hashable {
    let language: String
    let snippet: String
}

struct DataURLContent: Hashable {
    let mimeType: String
    let encoding: String?
    let dataSize: Int
}

struct DeepLinkContent: Hashable {
    let scheme: String
    let host: String?
    let path: String?
}
