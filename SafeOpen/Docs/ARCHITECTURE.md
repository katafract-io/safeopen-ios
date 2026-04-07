# SafeOpen — Architecture

SafeOpen is a privacy-first QR and link inspection app in the Katafract family.

## Product Position

- **ExifArmor** → protect what you share
- **DocArmor** → protect what you store
- **Wraith** → protect how you connect
- **SafeOpen** → protect what you open

SafeOpen is a standalone product. It does not require Wraith to function.
Long-term, Wraith provides protected routing for the "Open Safely" workflow.

---

## App Structure

```
SafeOpen/
├── App/
│   ├── SafeOpenApp.swift
│   ├── AppCoordinator.swift
│   └── AppState.swift
├── Features/
│   ├── Scanner/
│   ├── Inspection/
│   ├── Paste/
│   └── History/
├── Models/
├── Services/
├── Helpers/
└── Docs/
```

---

## Data Flow

1. User scans QR or pastes link
2. `CameraScannerService` / paste entry decodes raw payload
3. `PayloadClassifier` maps to `PayloadType`
4. `URLNormalizationService` normalizes URL-like payloads
5. `RiskScoringService` runs deterministic local heuristics → `[RiskFactor]` + `RiskLevel`
6. `InspectionResultView` renders explanation + actions
7. User chooses: Open / Open Safely / Copy

---

## Local vs Backend

MVP operates entirely on-device. No backend calls required for core value.

Future backend endpoints (Phase 2+):
- `POST /v1/inspect/url`
- `POST /v1/inspect/qr`
- `POST /v1/inspect/expand`
- `POST /v1/safe-open/session`

---

## Wraith Integration Trajectory

| Phase | Description |
|-------|-------------|
| A | SafeOpen standalone, no Wraith dependency |
| B | Entitlement awareness — show "Open Safely with Wraith" if user has Wraith/Enclave |
| C | API-backed handoff — platform issues a safe-open session token |
| D | Premium flow — masked network path, safe relay, redirect tracing |

---

## IPv6 Sandbox (Future)

SafeOpen will support routing inspected URLs through an isolated IPv6 address
generated from the Enclave sandbox pool. Each inspection session gets a unique
ephemeral IPv6 address, preventing cross-session linkability.
Details TBD — see ROADMAP.md.
