import Foundation

/// Classifies a raw scanned or pasted string into a PayloadType.
struct PayloadClassifier {

    static let knownShorteners: Set<String> = [
        "bit.ly", "tinyurl.com", "t.co", "ow.ly", "is.gd", "buff.ly",
        "short.link", "rb.gy", "cutt.ly", "tiny.cc", "bl.ink", "link.tl"
    ]

    func classify(_ raw: String) -> PayloadType {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("WIFI:") { return .wifi }
        if trimmed.hasPrefix("SMSTO:") || trimmed.hasPrefix("SMS:") { return .sms }
        if trimmed.hasPrefix("mailto:") { return .email }
        if trimmed.hasPrefix("tel:") { return .phone }
        if trimmed.hasPrefix("BEGIN:VCARD") { return .contact }
        if trimmed.hasPrefix("BEGIN:VEVENT") { return .calendar }

        if let url = URL(string: trimmed), url.scheme == "http" || url.scheme == "https" {
            if let host = url.host, Self.knownShorteners.contains(host.lowercased()) {
                return .shortURL
            }
            return .url
        }

        if trimmed.contains(".") && !trimmed.contains(" ") {
            // Bare domain without scheme — treat as URL
            if let url = URL(string: "https://\(trimmed)"), url.host != nil {
                return .url
            }
        }

        return trimmed.isEmpty ? .unknown : .plainText
    }
}
