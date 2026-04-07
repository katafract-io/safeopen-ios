# SafeOpen — Agent Instructions

## Roles

**Claude Code (architect/planner)**
- Architecture decisions
- Repo structure and docs
- Domain model design
- Feature sequencing
- Integration planning (Wraith, platform, Sigil)
- Code review

**Codex (implementer)**
- SwiftUI scaffolding
- Camera scanning implementation
- Local parser / classifier
- Risk scoring service
- Models and view models
- Result screen flows
- Service stubs
- Compile-focused iteration

---

## First Codex Tasks

### Task 1 — Repo scaffold
Create app scaffold: SafeOpenApp.swift, AppCoordinator, AppState.
Placeholder screens for Scanner, History, Paste entry.

### Task 2 — QR scanning
Native iOS camera scanning via AVFoundation.
`CameraScannerService` wraps AVCaptureSession, emits decoded strings.

### Task 3 — Payload classification
`PayloadClassifier.classify(_ raw: String) -> PayloadType`
Handle all types: url, short_url, wifi, sms, email, phone, contact, calendar, plain_text, unknown.

### Task 4 — Local risk scoring
`RiskScoringService.score(_ url: URL) -> InspectionResult`
Deterministic, explainable rules only. See RiskFactor enum.

### Task 5 — Result UI
`InspectionResultView` — calm, practical design.
Top-level: Likely safe / Use caution / High risk / Unknown.
Then: destination/action, why it scored that way, action buttons.

### Task 6 — Safe-open stubs
`SafeOpenService` and `InspectionAPIClient` as empty stubs.
`canOpenSafely` flag on InspectionResult.
"Open Safely" button shows placeholder sheet in MVP.

---

## Do Not Build (MVP)

- Full backend dependency
- Browser engine
- Phishing intelligence overreach
- Complicated user accounts
- Aggressive analytics
- Cloud sync
- Wraith-specific runtime coupling
- Broad admin infrastructure

---

## Success Criteria (MVP)

- QR can be scanned
- Payload type correctly recognized
- Result screen appears reliably
- URL-like payloads get basic explainable risk score
- User understands what will happen before opening
- Architecture clearly leaves room for Wraith integration
- Product is understandable as SafeOpen, not a VPN add-on
