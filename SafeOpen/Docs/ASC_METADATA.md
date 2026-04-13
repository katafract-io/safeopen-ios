# SafeOpen — App Store Connect Metadata
# Version 1.0.0 | Bundle ID: com.katafract.safeopen | App ID: 6761782681

---

## App Name
```
SafeOpen
```

## Subtitle (28/30 chars)
```
Link inspector & safe opener
```

## Promotional Text (160/170 chars, updateable without new build)
```
Every link you open exposes your IP. SafeOpen inspects links before you open them and routes every open through a privacy relay, so your device stays anonymous.
```

## Description (≤4000 chars)
```
Most links look harmless. Shortened URLs, QR codes from flyers, links in text messages. Any of them can lead somewhere unexpected, and the moment you tap, the destination already knows your device's IP address.

SafeOpen changes that.

Point your camera at any QR code, or paste a URL to get a safety inspection before anything loads. SafeOpen analyzes the link and flags risk signals: shortened URLs, raw IP addresses, punycode domains, unusual ports, suspicious tracking parameters, and more.

When you're ready to open, tap "Open Safely". Your request routes through SafeOpen's privacy relay, so the destination never sees your real IP address.

FREE
- QR scanner with torch control
- Link inspection for any URL you paste or type
- Plain risk breakdown for every scan
- Scan history stored on device
- Open Safely with a shared relay so your IP stays hidden

SAFEOPEN PRO ($0.99/mo or $4.99/yr)
- Disposable IPv6 identity per session: a fresh datacenter address that expires after 10 minutes
- No two opens share the same IP
- Everything in Free, with ephemeral identity on every open

No account. No login. Works the moment you install it.
```

## Keywords (97/100 chars — comma-separated, no spaces after commas)
```
QR scanner,link inspector,URL checker,phishing,safe browsing,privacy,IP protection,QR code reader
```

## What's New
v1.0 is the initial release; Apple hides the "What's New" field on first submissions and rejects writes to it. Use this copy on the next version bump:
```
First release. Scan QR codes, inspect any link for risk signals, and open URLs through SafeOpen's privacy relay so your IP never reaches the destination.
```

---

## URLs

| Field | Value |
|---|---|
| Support URL | https://katafract.com/safeopen |
| Marketing URL | https://katafract.com/safeopen |
| Privacy Policy URL | https://katafract.com/privacy |

---

## Categories

| Field | Value |
|---|---|
| Primary | Utilities |
| Secondary | Productivity |

---

## Age Rating

**4+** — no objectionable content, no user-generated content, no unrestricted web access (all browsing is initiated intentionally by the user).

---

## App Review Notes

```
SafeOpen is a QR code scanner and link inspection app. No user account is required. A service-level API token is embedded in the binary for all platform calls.

Camera access is used exclusively for QR scanning via AVFoundation. No photos are stored.

"Open Safely" routes URL opens through Katafract's privacy relay. The reviewer's IP will not be exposed to any destination URL opened via this button.

In-app purchase (Pro) enables ephemeral IPv6 per session. Test with a Sandbox Apple ID. The free tier is fully functional without any purchase.

To test:
1. Camera tab: point at any QR code
2. Inspect tab: paste a URL (e.g. https://example.com) and tap Inspect
3. Tap "Open Safely" on any result to test the relay
4. Tap the upgrade prompt to view the Pro paywall (no purchase needed to dismiss)

No demo credentials required.
```

---

## In-App Purchases (already created in ASC)

| Product ID | Name | Price | Billing |
|---|---|---|---|
| com.katafract.safeopen.pro_monthly | SafeOpen Pro Monthly | $0.99 | Monthly auto-renewing |
| com.katafract.safeopen.pro_annual | SafeOpen Pro Annual | $4.99 | Annual auto-renewing |

Subscription group: **SafeOpen Pro** (ID: 22024151)

IAP display name/description for each:

**Pro Monthly**
- Display Name: `SafeOpen Pro`
- Description: `Disposable IPv6 identity per session. Fresh address, burned after 10 minutes.`

**Pro Annual**
- Display Name: `SafeOpen Pro Annual`
- Description: `Disposable IPv6 identity per session. Fresh address per open, burned after 10 minutes. Best value.`
