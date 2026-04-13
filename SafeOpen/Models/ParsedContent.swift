import Foundation

// MARK: - Parsed structured content for rich display

enum ParsedContent {
    case contact(ContactContent)
    case event(EventContent)
    case otp(OTPContent)
    case geo(GeoContent)
    case crypto(CryptoContent)
    case script(ScriptContent)
    case wifi(WiFiContent)
    case deepLink(DeepLinkContent)
    case json(String)       // pretty-printed
    case dataURL(DataURLContent)
    case none
}

struct ContactContent {
    var fullName:     String?
    var firstName:    String?
    var lastName:     String?
    var phones:       [String]  = []
    var emails:       [String]  = []
    var org:          String?
    var title:        String?
    var address:      String?
    var url:          String?
    var note:         String?
    var format:       String    = "vCard"   // "vCard" or "MECARD"
}

struct EventContent {
    var summary:     String?
    var startDate:   String?
    var endDate:     String?
    var location:    String?
    var description: String?
    var organizer:   String?
    var url:         String?
}

struct OTPContent {
    var type:    String   // "totp" or "hotp"
    var issuer:  String?
    var account: String?
    var secret:  String?
    var digits:  String?
    var period:  String?
}

struct GeoContent {
    var latitude:  Double
    var longitude: Double
    var altitude:  Double?
    var query:     String?   // optional place name from geo:?q= or geo:lat,lon?q=
}

struct CryptoContent {
    var currency: String   // "Bitcoin", "Ethereum", etc.
    var address:  String
    var amount:   String?
    var label:    String?
    var message:  String?
}

struct ScriptContent {
    var language: String   // "JavaScript", "Bash", "Python", "PowerShell", "HTML"
    var snippet:  String   // first 400 chars
}

struct WiFiContent {
    var ssid:     String
    var password: String
    var security: String   // WPA, WEP, nopass
    var hidden:   Bool
}

struct DeepLinkContent {
    var scheme: String
    var host:   String?
    var path:   String?
    var url:    URL
}

struct DataURLContent {
    var mimeType: String
    var encoding: String?  // "base64" or nil
    var dataSize: Int      // byte count of payload
}
