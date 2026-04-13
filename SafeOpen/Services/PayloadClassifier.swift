import Foundation

/// Classifies a raw scanned or pasted string into a PayloadType.
struct PayloadClassifier {

    static let knownShorteners: Set<String> = [
        "bit.ly", "tinyurl.com", "t.co", "ow.ly", "is.gd", "buff.ly",
        "short.link", "rb.gy", "cutt.ly", "tiny.cc", "bl.ink", "link.tl",
        "shorturl.at", "clck.ru", "yourls.org", "v.gd", "qr.io", "goo.gl"
    ]

    // URL schemes that indicate app deep links (not web URLs)
    private static let knownDeepLinkSchemes: Set<String> = [
        "fb", "twitter", "instagram", "snapchat", "tiktok",
        "spotify", "youtube", "maps", "googlemaps", "comgooglemaps",
        "whatsapp", "telegram", "signal", "skype", "zoom",
        "slack", "notion", "linear", "figma", "github",
        "venmo", "paypal", "cashapp", "coinbase",
        "uber", "lyft", "doordash"
    ]

    // Schemes that are inherently script/exec risks
    private static let scriptSchemes: Set<String> = [
        "javascript", "vbscript"
    ]

    func classify(_ raw: String) -> PayloadType {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .unknown }

        // --- Exact prefix matches (order matters) ---

        // Auth / OTP
        if trimmed.lowercased().hasPrefix("otpauth://") { return .otp }

        // WiFi
        if trimmed.uppercased().hasPrefix("WIFI:") { return .wifi }

        // Messaging
        if trimmed.uppercased().hasPrefix("SMSTO:") || trimmed.lowercased().hasPrefix("sms:") { return .sms }
        if trimmed.lowercased().hasPrefix("mailto:") { return .email }
        if trimmed.lowercased().hasPrefix("tel:") { return .phone }
        if trimmed.lowercased().hasPrefix("facetime:") || trimmed.lowercased().hasPrefix("facetime-audio:") { return .phone }

        // Contact / calendar
        if trimmed.uppercased().hasPrefix("BEGIN:VCARD") { return .contact }
        if trimmed.uppercased().hasPrefix("MECARD:") { return .meCard }
        if trimmed.uppercased().hasPrefix("BEGIN:VCALENDAR") || trimmed.uppercased().hasPrefix("BEGIN:VEVENT") { return .calendar }

        // Crypto
        let lower = trimmed.lowercased()
        if lower.hasPrefix("bitcoin:") || lower.hasPrefix("ethereum:") ||
           lower.hasPrefix("eth:") || lower.hasPrefix("litecoin:") || lower.hasPrefix("monero:") {
            return .crypto
        }

        // Geo
        if lower.hasPrefix("geo:") { return .geo }

        // Data URL
        if lower.hasPrefix("data:") { return .dataURL }

        // Script schemes
        if let colonIdx = trimmed.firstIndex(of: ":") {
            let scheme = String(trimmed[trimmed.startIndex..<colonIdx]).lowercased()
            if Self.scriptSchemes.contains(scheme) { return .script }
        }

        // Script content heuristics (before URL check)
        if looksLikeScript(trimmed) { return .script }

        // JSON
        if looksLikeJSON(trimmed) { return .json }

        // HTTP/HTTPS URLs
        if let url = URL(string: trimmed), (url.scheme == "http" || url.scheme == "https"), url.host != nil {
            if let host = url.host, Self.knownShorteners.contains(host.lowercased()) {
                return .shortURL
            }
            return .url
        }

        // App deep links (known schemes)
        if let colonIdx = trimmed.firstIndex(of: ":") {
            let scheme = String(trimmed[trimmed.startIndex..<colonIdx]).lowercased()
            if Self.knownDeepLinkSchemes.contains(scheme) { return .deepLink }
            // Generic deep link: scheme://something
            if let url = URL(string: trimmed), url.host != nil || !url.path.isEmpty,
               scheme.count >= 2 && !scheme.contains(" ") { return .deepLink }
        }

        // Bare domain without scheme
        if trimmed.contains(".") && !trimmed.contains(" ") {
            if let url = URL(string: "https://\(trimmed)"), url.host != nil {
                return .url
            }
        }

        return .plainText
    }

    // MARK: - Heuristics

    private func looksLikeScript(_ s: String) -> Bool {
        let lower = s.lowercased()
        let scriptMarkers = [
            "#!/bin/", "#!/usr/bin/env",
            "<script", "</script>",
            "get-executionpolicy", "invoke-webrequest", "invoke-expression",
            "powershell -", "cmd /c", "curl | bash", "wget -o- |",
            "import os\n", "import sys\n", "def main(", "if __name__"
        ]
        return scriptMarkers.contains(where: { lower.contains($0) })
    }

    private func looksLikeJSON(_ s: String) -> Bool {
        let t = s.trimmingCharacters(in: .whitespaces)
        guard (t.hasPrefix("{") && t.hasSuffix("}")) ||
              (t.hasPrefix("[") && t.hasSuffix("]")) else { return false }
        guard let data = t.data(using: .utf8),
              (try? JSONSerialization.jsonObject(with: data)) != nil else { return false }
        return true
    }
}
