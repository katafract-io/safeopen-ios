import Foundation

enum PayloadType: String, Codable {
    case url
    case shortURL = "short_url"
    case wifi
    case sms
    case email
    case phone
    case contact
    case calendar
    case plainText = "plain_text"
    case unknown
}
