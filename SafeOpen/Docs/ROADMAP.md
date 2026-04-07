# SafeOpen — Roadmap

## Phase A — MVP Stub (current)

Goal: working scanner + local inspection, no backend dependency.

- [ ] QR scanning via native iOS camera APIs
- [ ] Payload classification (url, short_url, wifi, sms, email, phone, contact, calendar, plain_text, unknown)
- [ ] Local URL risk heuristics (http, raw IP, punycode, suspicious params, unusual port, encoding, shorteners)
- [ ] Plain-language explanation for each payload type
- [ ] Result screen: Open / Open Safely (stub) / Copy
- [ ] Scan history (local, on-device)
- [ ] Paste / share-in URL entry

## Phase B — Backend Inspection

- [ ] `POST /v1/inspect/url` — redirect expansion, final destination
- [ ] `POST /v1/inspect/expand` — short URL resolver
- [ ] TLS/domain metadata enrichment
- [ ] Tracker detection
- [ ] Stronger reputation signals

## Phase C — Wraith Entitlement Integration

- [ ] Detect active Wraith/Enclave subscription via Sigil
- [ ] Show "Open Safely with Wraith" CTA when entitled
- [ ] `POST /v1/safe-open/session` — platform issues session token

## Phase D — Protected Open

- [ ] Route open request through Wraith mesh
- [ ] Assign ephemeral IPv6 address from Enclave sandbox pool per session
- [ ] Masked referrer / stripped tracking params
- [ ] Optional isolated browsing context
- [ ] Premium domain intelligence

## Phase E — Broader Inspection Surface

- [ ] Safari share extension
- [ ] Image import → QR extraction
- [ ] DocArmor integration (embedded QR in documents)
- [ ] Saved inspection reports

---

## IPv6 Sandbox Design Note

Each "Open Safely" session will be assigned a randomly generated IPv6 address
from the Enclave sandbox prefix. This ensures:
- no cross-session IP linkability
- the destination server cannot correlate user activity across inspections
- the ephemeral address is discarded after session close

Integration point: `SafeOpenService.requestSafeOpenSession()` → platform API
→ Wraith node assigns sandbox IPv6 → returns session token to app.

Details to be designed in coordination with the Wraith/platform team.
