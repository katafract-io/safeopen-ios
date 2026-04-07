import Foundation

struct URLNormalizationService {

    /// Attempt to produce a canonical URL from raw input.
    func normalize(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }
        // Try prepending https for bare domains
        return URL(string: "https://\(trimmed)")
    }
}
