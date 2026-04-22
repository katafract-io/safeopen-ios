import Foundation

struct ScanPreview: Codable {
    let pngData: Data?
    let pageTitle: String
    let summary: String
    let saferSummary: String

    enum CodingKeys: String, CodingKey {
        case pngData = "png_base64"
        case pageTitle = "title"
        case summary = "summary"
        case saferSummary = "safer_summary"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pageTitle = try container.decode(String.self, forKey: .pageTitle)
        summary = try container.decode(String.self, forKey: .summary)
        saferSummary = try container.decode(String.self, forKey: .saferSummary)

        // Decode base64 PNG if present
        if let base64 = try container.decodeIfPresent(String.self, forKey: .pngData) {
            pngData = Data(base64Encoded: base64)
        } else {
            pngData = nil
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pageTitle, forKey: .pageTitle)
        try container.encode(summary, forKey: .summary)
        try container.encode(saferSummary, forKey: .saferSummary)
        if let pngData = pngData {
            try container.encode(pngData.base64EncodedString(), forKey: .pngData)
        }
    }
}

@MainActor
final class SafeOpenScreenshotService {
    static let shared = SafeOpenScreenshotService()

    // Endpoint: hermes Playwright service at safeopen-screenshot:8410
    // Via mesh: http://100.64.0.27:8410 or via external proxy
    private let baseURL: URL

    init() {
        // Default to mesh IP; can be overridden for testing
        self.baseURL = URL(string: "http://100.64.0.27:8410")!
    }

    func fetchPreview(url: URL, userToken: String?) async throws -> ScanPreview {
        var request = URLRequest(url: baseURL.appendingPathComponent("/screenshot"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Include Enclave token if available for server-side plan validation
        if let token = userToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let payload: [String: Any] = ["url": url.absoluteString]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ScreenshotError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            return try decoder.decode(ScanPreview.self, from: data)
        case 401:
            throw ScreenshotError.unauthorized
        case 429:
            throw ScreenshotError.rateLimited
        case 400...499:
            throw ScreenshotError.clientError(httpResponse.statusCode)
        case 500...599:
            throw ScreenshotError.serverError(httpResponse.statusCode)
        default:
            throw ScreenshotError.unknownStatus(httpResponse.statusCode)
        }
    }
}

enum ScreenshotError: Error, LocalizedError {
    case invalidResponse
    case unauthorized
    case rateLimited
    case clientError(Int)
    case serverError(Int)
    case unknownStatus(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from preview service."
        case .unauthorized:
            return "Not authorized to view preview."
        case .rateLimited:
            return "Too many requests. Try again later."
        case .clientError(let code):
            return "Client error (\(code))."
        case .serverError(let code):
            return "Server error (\(code)). Try again later."
        case .unknownStatus(let code):
            return "Unknown status (\(code))."
        case .decodingFailed:
            return "Failed to decode preview data."
        }
    }
}
