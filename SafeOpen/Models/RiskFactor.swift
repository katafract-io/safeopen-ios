import Foundation

enum RiskFactor: String, Codable, CaseIterable {
    // URL-specific
    case insecureTransport
    case rawIPAddress
    case suspiciousEncoding
    case trackingParameters
    case unusualPort
    case shortenedLink
    case punycodeHost
    case unknownDestination
    case suspiciousPathKeyword
    case excessiveQueryParams
    case extremelyLongURL
    // Payload-specific
    case executableScript
    case dataURLPayload
    case obfuscatedContent
    case openWifiNetwork
    case weakWifiEncryption
    case cryptoPayload
    case embeddedURL

    var explanation: String {
        switch self {
        case .insecureTransport:
            return "Uses HTTP instead of HTTPS — connection is not encrypted."
        case .rawIPAddress:
            return "Links directly to an IP address instead of a domain name."
        case .suspiciousEncoding:
            return "Contains unusual percent-encoding that may obscure the real destination."
        case .trackingParameters:
            return "Contains known tracking parameters that identify you to the destination."
        case .unusualPort:
            return "Uses a non-standard port, which is uncommon for normal websites."
        case .shortenedLink:
            return "This is a shortened link — the real destination is not yet visible."
        case .punycodeHost:
            return "The domain uses international characters that may look like a known site."
        case .unknownDestination:
            return "The final destination cannot be determined locally."
        case .suspiciousPathKeyword:
            return "The URL path contains keywords associated with login, payment, or reset flows."
        case .excessiveQueryParams:
            return "Contains an unusually large number of query parameters."
        case .extremelyLongURL:
            return "This URL is unusually long, which is sometimes used to obscure the destination."
        case .executableScript:
            return "This payload contains code that could be executed — review carefully before acting."
        case .dataURLPayload:
            return "Embeds raw data directly in the payload, which can hide malicious content."
        case .obfuscatedContent:
            return "Contains obfuscated or encoded content — the real payload is not human-readable."
        case .openWifiNetwork:
            return "This Wi-Fi network has no password. Anyone nearby can monitor your traffic."
        case .weakWifiEncryption:
            return "This Wi-Fi network uses WEP encryption, which is easily cracked."
        case .cryptoPayload:
            return "This is a cryptocurrency payment request. Verify the address independently before sending any funds."
        case .embeddedURL:
            return "This payload contains a URL. Review the destination carefully before proceeding."
        }
    }
}
