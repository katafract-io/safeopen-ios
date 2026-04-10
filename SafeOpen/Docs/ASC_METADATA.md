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

## Promotional Text (157/170 chars — updateable without new build)
```
Every link you open exposes your IP. SafeOpen inspects links before you open them and routes every open through a privacy relay — your device stays anonymous.
```

## Description (≤4000 chars)
```
Most links look harmless. Shortened URLs, QR codes from flyers, links in text messages — any of them could lead somewhere unexpected. And the moment you tap them, the destination sees your device's IP address.

SafeOpen changes that.

Point your camera at any QR code, or paste a URL to get an instant safety inspection before anything loads. SafeOpen analyzes the link and highlights risk signals — shortened URLs, raw IP addresses, punycode domains, unusual ports, suspicious parameters, and more — in plain language you can actually understand.

When you're ready to open, tap "Open Safely." Your request routes through SafeOpen's privacy relay. The destination never sees your real IP address.

─────────────────────────────
FREE
─────────────────────────────
• QR scanner with torch control
• Link inspection — paste or type any URL
• Plain-language risk breakdown for every scan
• Scan history stored on-device
• Open Safely — your IP is always hidden behind our shared relay

─────────────────────────────
SAFEOPEN PRO — $0.99/mo or $4.99/yr
─────────────────────────────
• Disposable IPv6 identity per session — a fresh datacenter address, burned after 10 minutes
• Zero cross-session linkability — no two opens share the same IP
• Everything in Free, with ephemeral identity on every open

─────────────────────────────

No account. No login. Works immediately on install.

Privacy is the default. Pro makes it airtight.
```

## Keywords (97/100 chars — comma-separated, no spaces after commas)
```
QR scanner,link inspector,URL checker,phishing,safe browsing,privacy,IP protection,QR code reader
```

## What's New (v1.0 — Initial Release)
```
SafeOpen is here. Scan QR codes, inspect any link for risk signals, and open URLs safely through our privacy relay — your IP never reaches the destination.
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
SafeOpen is a QR code scanner and link inspection app. It requires no user account — a service-level API token is embedded in the binary for all platform calls.

Camera access is used exclusively for QR code scanning via AVFoundation. No photos are stored.

The "Open Safely" feature routes URL opens through Katafract's privacy relay infrastructure. During review, the reviewer's IP address will not be exposed to any destination URL opened via this button.

In-app purchase (Pro tier) enables ephemeral IPv6 per session. Use a Sandbox Apple ID to test. The free tier is fully functional without any purchase.

To test core flows:
1. Camera tab → point at any QR code
2. Inspect tab → paste a URL (e.g. https://bit.ly/example) → tap Inspect
3. Tap "Open Safely" on any result to test the privacy relay
4. Tap the upgrade prompt to view the Pro paywall (no purchase required to dismiss)

No demo credentials needed.
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
