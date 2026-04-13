import Foundation

/// Parses structured content out of a raw QR/paste payload.
struct PayloadParser {

    func parse(raw: String, type: PayloadType) -> ParsedContent {
        switch type {
        case .contact:   return parseVCard(raw)
        case .meCard:    return parseMECard(raw)
        case .calendar:  return parseVEvent(raw)
        case .otp:       return parseOTP(raw)
        case .geo:       return parseGeo(raw)
        case .crypto:    return parseCrypto(raw)
        case .script:    return parseScript(raw)
        case .json:      return parseJSON(raw)
        case .wifi:      return parseWifi(raw)
        case .dataURL:   return parseDataURL(raw)
        case .deepLink:
            if let url = URL(string: raw) { return parseDeepLink(url) }
            return .none
        default:
            return .none
        }
    }

    // MARK: - vCard

    private func parseVCard(_ raw: String) -> ParsedContent {
        var c = ContactContent()
        c.format = "vCard"
        for line in raw.components(separatedBy: .newlines) {
            let parts = line.components(separatedBy: ":"); guard parts.count >= 2 else { continue }
            let key = parts[0].uppercased()
            let val = parts[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces)
            if key.hasPrefix("FN")          { c.fullName  = val }
            else if key.hasPrefix("N;") || key == "N" {
                // Last;First;Middle;Prefix;Suffix
                let ns = val.components(separatedBy: ";")
                c.lastName  = ns.count > 0 ? ns[0] : nil
                c.firstName = ns.count > 1 ? ns[1] : nil
            }
            else if key.hasPrefix("TEL")    { if !val.isEmpty { c.phones.append(val) } }
            else if key.hasPrefix("EMAIL")  { if !val.isEmpty { c.emails.append(val) } }
            else if key.hasPrefix("ORG")    { c.org     = val }
            else if key.hasPrefix("TITLE")  { c.title   = val }
            else if key.hasPrefix("ADR")    { c.address = val.replacingOccurrences(of: ";", with: " ").trimmingCharacters(in: .whitespaces) }
            else if key.hasPrefix("URL")    { c.url     = val }
            else if key.hasPrefix("NOTE")   { c.note    = val }
        }
        return .contact(c)
    }

    // MARK: - MECARD

    private func parseMECard(_ raw: String) -> ParsedContent {
        var c = ContactContent()
        c.format = "MECARD"
        let body = raw.replacingOccurrences(of: "MECARD:", with: "", options: .caseInsensitive)
        for field in body.components(separatedBy: ";") {
            let parts = field.components(separatedBy: ":"); guard parts.count >= 2 else { continue }
            let key = parts[0].uppercased()
            let val = parts[1...].joined(separator: ":")
            switch key {
            case "N":     let ns = val.components(separatedBy: ","); c.lastName = ns.first; c.firstName = ns.count > 1 ? ns[1] : nil
            case "TEL":   c.phones.append(val)
            case "EMAIL": c.emails.append(val)
            case "ORG":   c.org  = val
            case "URL":   c.url  = val
            case "NOTE":  c.note = val
            default: break
            }
        }
        return .contact(c)
    }

    // MARK: - vEvent

    private func parseVEvent(_ raw: String) -> ParsedContent {
        var e = EventContent()
        var inEvent = false
        for line in raw.components(separatedBy: .newlines) {
            if line.uppercased().hasPrefix("BEGIN:VEVENT") { inEvent = true; continue }
            if line.uppercased().hasPrefix("END:VEVENT")   { break }
            guard inEvent else { continue }
            let parts = line.components(separatedBy: ":"); guard parts.count >= 2 else { continue }
            let key = parts[0].uppercased().components(separatedBy: ";")[0]
            let val = parts[1...].joined(separator: ":")
            switch key {
            case "SUMMARY":     e.summary     = val
            case "DTSTART":     e.startDate   = formatICSDate(val)
            case "DTEND":       e.endDate     = formatICSDate(val)
            case "LOCATION":    e.location    = val
            case "DESCRIPTION": e.description = val
            case "ORGANIZER":   e.organizer   = val.replacingOccurrences(of: "mailto:", with: "")
            case "URL":         e.url         = val
            default: break
            }
        }
        return .event(e)
    }

    private func formatICSDate(_ raw: String) -> String {
        // 20261225T090000Z or 20261225
        var s = raw.replacingOccurrences(of: "Z", with: "")
        if s.count >= 8 {
            let y = String(s.prefix(4)); s = String(s.dropFirst(4))
            let mo = String(s.prefix(2)); s = String(s.dropFirst(2))
            let d  = String(s.prefix(2)); s = String(s.dropFirst(2))
            if s.hasPrefix("T") && s.count >= 7 {
                s = String(s.dropFirst())
                let h = String(s.prefix(2)); s = String(s.dropFirst(2))
                let mi = String(s.dropFirst(2).prefix(2))
                return "\(y)-\(mo)-\(d) \(h):\(mi)"
            }
            return "\(y)-\(mo)-\(d)"
        }
        return raw
    }

    // MARK: - OTP

    private func parseOTP(_ raw: String) -> ParsedContent {
        // otpauth://totp/Issuer:account?secret=XXX&digits=6&period=30
        guard let url = URL(string: raw), let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return .none
        }
        var otp = OTPContent(type: url.host ?? "totp")
        let pathParts = url.path.trimmingCharacters(in: .init(charactersIn: "/")).components(separatedBy: ":")
        otp.issuer  = pathParts.count > 1 ? pathParts[0] : comps.queryItems?.first(where: { $0.name == "issuer" })?.value
        otp.account = pathParts.last
        for item in comps.queryItems ?? [] {
            switch item.name {
            case "secret": otp.secret = item.value
            case "digits": otp.digits = item.value
            case "period": otp.period = item.value
            case "issuer": if otp.issuer == nil { otp.issuer = item.value }
            default: break
            }
        }
        return .otp(otp)
    }

    // MARK: - Geo

    private func parseGeo(_ raw: String) -> ParsedContent {
        // geo:lat,lon or geo:lat,lon,alt?q=place
        let body = raw.replacingOccurrences(of: "geo:", with: "", options: .caseInsensitive)
        let qSplit = body.components(separatedBy: "?")
        let coords = qSplit[0].components(separatedBy: ",")
        guard coords.count >= 2,
              let lat = Double(coords[0]), let lon = Double(coords[1]) else { return .none }
        let alt = coords.count >= 3 ? Double(coords[2]) : nil
        var query: String? = nil
        if qSplit.count > 1, let q = URLComponents(string: "?" + qSplit[1])?.queryItems?.first(where: { $0.name == "q" })?.value {
            query = q
        }
        return .geo(GeoContent(latitude: lat, longitude: lon, altitude: alt, query: query))
    }

    // MARK: - Crypto

    private func parseCrypto(_ raw: String) -> ParsedContent {
        let lower = raw.lowercased()
        let (currency, scheme): (String, String)
        if lower.hasPrefix("bitcoin:")       { currency = "Bitcoin";  scheme = "bitcoin:" }
        else if lower.hasPrefix("ethereum:") { currency = "Ethereum"; scheme = "ethereum:" }
        else if lower.hasPrefix("eth:")      { currency = "Ethereum"; scheme = "eth:" }
        else if lower.hasPrefix("litecoin:") { currency = "Litecoin"; scheme = "litecoin:" }
        else if lower.hasPrefix("monero:")   { currency = "Monero";   scheme = "monero:" }
        else { return .none }

        let body = String(raw.dropFirst(scheme.count))
        let qSplit = body.components(separatedBy: "?")
        let address = qSplit[0]
        var amount: String? = nil; var label: String? = nil; var message: String? = nil
        if qSplit.count > 1, let items = URLComponents(string: "?" + qSplit[1])?.queryItems {
            amount  = items.first(where: { $0.name == "amount" })?.value
            label   = items.first(where: { $0.name == "label" })?.value
            message = items.first(where: { $0.name == "message" })?.value
        }
        return .crypto(CryptoContent(currency: currency, address: address, amount: amount, label: label, message: message))
    }

    // MARK: - Script

    private func parseScript(_ raw: String) -> ParsedContent {
        let language: String
        let lower = raw.lowercased()
        if lower.hasPrefix("#!/bin/bash") || lower.hasPrefix("#!/bin/sh") { language = "Bash" }
        else if lower.hasPrefix("#!/usr/bin/env python") || lower.hasPrefix("#!/usr/bin/python") { language = "Python" }
        else if lower.hasPrefix("#!/usr/bin/env node") || lower.hasPrefix("#!/usr/bin/node") { language = "JavaScript" }
        else if lower.hasPrefix("#!/usr/bin/env ruby") { language = "Ruby" }
        else if lower.contains("<script") || lower.contains("</script>") { language = "JavaScript (HTML)" }
        else if lower.contains("get-") || lower.contains("invoke-") || lower.contains("new-object") { language = "PowerShell" }
        else if lower.contains("import os") || lower.contains("import sys") || lower.contains("def ") { language = "Python" }
        else { language = "Script" }
        return .script(ScriptContent(language: language, snippet: String(raw.prefix(400))))
    }

    // MARK: - JSON

    private func parseJSON(_ raw: String) -> ParsedContent {
        guard let data = raw.data(using: .utf8),
              let obj  = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
              let str  = String(data: pretty, encoding: .utf8) else {
            return .json(raw)
        }
        return .json(str)
    }

    // MARK: - WiFi

    private func parseWifi(_ raw: String) -> ParsedContent {
        // WIFI:T:WPA;S:SSID;P:pass;H:false;;
        var ssid = "", password = "", security = "Unknown"; var hidden = false
        let body = raw.replacingOccurrences(of: "WIFI:", with: "", options: .caseInsensitive)
        for field in body.components(separatedBy: ";") {
            let kv = field.split(separator: ":", maxSplits: 1).map(String.init)
            guard kv.count == 2 else { continue }
            switch kv[0].uppercased() {
            case "S": ssid     = kv[1]
            case "P": password = kv[1]
            case "T": security = kv[1].uppercased() == "NOPASS" ? "Open" : kv[1].uppercased()
            case "H": hidden   = kv[1].lowercased() == "true"
            default:  break
            }
        }
        return .wifi(WiFiContent(ssid: ssid, password: password, security: security, hidden: hidden))
    }

    // MARK: - Data URL

    private func parseDataURL(_ raw: String) -> ParsedContent {
        // data:[<mediatype>][;base64],<data>
        let body = raw.dropFirst("data:".count)
        let headerData = body.components(separatedBy: ",")
        let meta = headerData[0].components(separatedBy: ";")
        let mimeType = meta[0].isEmpty ? "text/plain" : meta[0]
        let encoding = meta.count > 1 ? meta[1] : nil
        let payload  = headerData.count > 1 ? headerData[1...].joined(separator: ",") : ""
        let bytes    = encoding == "base64" ? (Data(base64Encoded: payload)?.count ?? payload.count) : payload.count
        return .dataURL(DataURLContent(mimeType: mimeType, encoding: encoding, dataSize: bytes))
    }

    // MARK: - Deep link

    private func parseDeepLink(_ url: URL) -> ParsedContent {
        return .deepLink(DeepLinkContent(scheme: url.scheme ?? "", host: url.host, path: url.path.isEmpty ? nil : url.path, url: url))
    }
}
