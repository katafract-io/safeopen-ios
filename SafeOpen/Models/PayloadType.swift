import Foundation

enum PayloadType: String, Codable {
    // Web
    case url
    case shortURL   = "short_url"
    case dataURL    = "data_url"
    case deepLink   = "deep_link"

    // Messaging / comms
    case sms
    case email
    case phone

    // Network
    case wifi

    // Identity / scheduling
    case contact            // vCard
    case meCard  = "me_card"
    case calendar           // vEvent

    // Auth / finance
    case otp
    case crypto

    // Location
    case geo

    // Code / data
    case script
    case json

    // Fallback
    case plainText  = "plain_text"
    case unknown
}
