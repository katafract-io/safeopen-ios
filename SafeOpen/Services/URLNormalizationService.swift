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

    /// Returns a copy of the URL with known tracking/marketing parameters removed,
    /// or nil if nothing was stripped.
    static func stripTrackingParams(from url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems, !items.isEmpty else { return nil }

        let kept = items.filter { !Self.trackingParams.contains($0.name.lowercased()) }
        guard kept.count < items.count else { return nil }

        components.queryItems = kept.isEmpty ? nil : kept
        return components.url
    }

    private static let trackingParams: Set<String> = [
        // UTM
        "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content", "utm_id",
        // Ad click IDs
        "fbclid", "gclid", "gclsrc", "msclkid", "twclid", "ttclid",
        "li_fat_id", "igshid", "yclid", "rb_clickid", "srsltid",
        // Email marketing
        "mc_eid", "_hsenc", "_hsmi", "hsctatracking", "mkt_tok",
        "ml_subscriber", "ml_subscriber_hash", "vero_id", "wickedid",
        // Misc referrers
        "ncid", "oly_anon_id", "oly_enc_id", "ef_id", "s_kwcid",
    ]
}
