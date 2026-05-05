# SafeOpen — App Store Connect Metadata
# Version 1.0.1 | Bundle ID: com.katafract.safeopen | App ID: 6761782681

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

Point your camera at any QR code, or paste a URL to get a safety inspection before anything loads. SafeOpen analyzes the link and flags risk signals: shortened URLs, raw IP addresses, punycode domains, unusual ports, suspicious tracking parameters, and more. All of this runs entirely on your device — offline, instant, free.

When you're ready to open, tap "Inspect & Open Safely". Your request routes through SafeOpen's privacy relay, where it gets a disposable IPv6 address that the destination sees instead of your real IP. The address is released after 10 minutes. Your cookies and browsing history are destroyed when the session ends.

FREE — NO ACCOUNT REQUIRED
- QR scanner with torch control
- Decodes URLs, Wi-Fi credentials, contacts, calendar events, SMS, email, phone numbers, geo, crypto, and plain text
- Local risk scoring: raw IPs, punycode domains, URL shorteners, suspicious paths, unusual ports, executable scripts, and more
- Tracking-parameter stripping: removes 38+ known tracking params (UTM, fbclid, gclid, msclkid) and shows you the clean URL
- Plain-language explanation for every risk flag
- Scan history stored on-device only, never synced

SCAN CREDITS (optional, one-time purchases)
Two features require a connection to Katafract's servers and cost 1 scan credit each:
- AI Summary: a plain-English summary of what the destination page actually contains
- Open Safely: view the page through a privacy relay in an isolated session — the destination sees a disposable IPv6 address, not your real IP

Every install starts with 10 free credits. We add 10 more every 30 days.
If you need more, credits are available as one-time in-app purchases. They never expire and there is no subscription.

No account. No login. No subscription. Works the moment you install it.
```

## Keywords (97/100 chars — comma-separated, no spaces after commas)
```
QR scanner,link inspector,URL checker,phishing,safe browsing,privacy,IP protection,QR code reader
```

## What's New (use on v1.0.1 and beyond — Apple hides this field on 1.0)
```
Improved link preview — the inspection sheet now opens immediately so you can see analysis results as they arrive instead of waiting for the full load.
```

---

## URLs

| Field | Value |
|---|---|
| Support URL | https://katafract.com/support/safeopen |
| Marketing URL | https://katafract.com/apps/safeopen |
| Privacy Policy URL | https://katafract.com/privacy/safeopen |

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
SafeOpen is a QR code scanner and link inspection app. No user account is required.

No static service credentials are embedded in the binary. Authentication uses per-install device ID + App Attest assertions.

Camera access is used exclusively for QR scanning via AVFoundation. No photos are stored.

"Inspect & Open Safely" opens the link in an isolated in-app browser through Katafract's privacy relay. The reviewer's real IP will not be exposed to any destination URL opened via this button.

In-app purchases are consumable scan-credit packs (not subscriptions). Purchasing is not required — the app is fully functional with the free credits included on install. Test with a Sandbox Apple ID.

To test:
1. Camera tab: point at any QR code
2. Inspect tab: paste a URL (e.g. https://example.com) and tap Inspect
3. Tap "Inspect & Open Safely" on any result — sheet opens immediately with a loading indicator, then shows the full preview
4. Tap the Buy Credits button to view the paywall (no purchase needed to dismiss)

No demo credentials required.
```

---

## In-App Purchases (consumable credit packs — no subscription)

| Product ID | Name | Price | Type |
|---|---|---|---|
| com.katafract.safeopen.credits_starter | SafeOpen Credits — Starter | $0.99 | Consumable |
| com.katafract.safeopen.credits_standard | SafeOpen Credits — Standard | $2.99 | Consumable |
| com.katafract.safeopen.credits_power | SafeOpen Credits — Power | $9.99 | Consumable |

ASC Internal IDs: starter `6762161470`, standard `6762160344`, power `6762157575`

IAP display name/description for each:

**Starter (100 credits)**
- Display Name: `100 Scan Credits`
- Description: `100 scan credits for AI summaries and privacy-relay opens. Credits never expire.`

**Standard (500 credits)**
- Display Name: `500 Scan Credits`
- Description: `500 scan credits for AI summaries and privacy-relay opens. Credits never expire. Best value for regular use.`

**Power (2,500 credits)**
- Display Name: `2,500 Scan Credits`
- Description: `2,500 scan credits for AI summaries and privacy-relay opens. Credits never expire. Best value per credit.`

---

## Old IAPs — mark Removed from Sale in ASC
- `com.katafract.safeopen.pro_monthly` (ID: 6761950941)
- `com.katafract.safeopen.pro_annual` (ID: 6761951070)
