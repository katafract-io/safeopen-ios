# SafeOpen IAP Setup — Manual Steps Required

The current ASC API key (`AuthKey_3N7X2443W9`) was generated with read-only IAP scope, so the pivot to consumable credit packs must be done in the App Store Connect UI by hand.

## 1. Retire the old subscriptions

In ASC → My Apps → SafeOpen → In-App Purchases:

| Action | Product | Product ID |
|---|---|---|
| Mark **Removed from Sale** | SafeOpen Pro Monthly | `com.katafract.safeopen.pro_monthly` |
| Mark **Removed from Sale** | SafeOpen Pro Annual | `com.katafract.safeopen.pro_annual` |

The subscription group `SafeOpen Pro` (group ID 22024151) can be left in place — it's empty without products and Apple won't let you delete it anyway.

## 2. Create three consumable credit packs

For each row below, click "Create" → choose **Consumable**:

### Pack 1 — Starter

| Field | Value |
|---|---|
| Reference Name | `Starter Credit Pack` |
| Product ID | `com.katafract.safeopen.credits_starter` |
| Type | Consumable |
| Price | **$0.99** (USD) |
| Display Name | `100 Scan Credits` |
| Description | `100 scan credits for SafeOpen. Each AI summary or Open Safely session costs 1 credit. Credits never expire.` |
| Review Notes | `Consumable. Server validates Apple transaction via App Store Server API and grants 100 credits to the device's anonymous Keychain UUID. Idempotent on transactionId.` |

### Pack 2 — Standard (Best Value)

| Field | Value |
|---|---|
| Reference Name | `Standard Credit Pack` |
| Product ID | `com.katafract.safeopen.credits_standard` |
| Type | Consumable |
| Price | **$3.99** (USD) |
| Display Name | `500 Scan Credits` |
| Description | `500 scan credits for SafeOpen. Each AI summary or Open Safely session costs 1 credit. Credits never expire.` |
| Review Notes | `Consumable. Server validates Apple transaction via App Store Server API and grants 500 credits to the device's anonymous Keychain UUID. Idempotent on transactionId.` |

### Pack 3 — Power

| Field | Value |
|---|---|
| Reference Name | `Power Credit Pack` |
| Product ID | `com.katafract.safeopen.credits_power` |
| Type | Consumable |
| Price | **$9.99** (USD) |
| Display Name | `2,500 Scan Credits` |
| Description | `2,500 scan credits for SafeOpen. Each AI summary or Open Safely session costs 1 credit. Credits never expire.` |
| Review Notes | `Consumable. Server validates Apple transaction via App Store Server API and grants 2,500 credits to the device's anonymous Keychain UUID. Idempotent on transactionId.` |

## 3. Submit each consumable for review with the binary

Apple requires consumables to be submitted alongside the binary for first review. After creating each one, scroll down to **Submission Information** and either:
- Attach a screenshot of the Buy Credits sheet (the `04_account.png` screenshot or a fresh one from the rebuilt app), or
- Wait until you have new screenshots from the credit-balance UI rebuild and attach them then.

## 4. App Privacy nutrition label (also UI-only)

ASC's App Privacy section is not exposed via the public API and must be set in the App Store Connect UI: ASC → SafeOpen → App Privacy → Edit → Get Started.

Apple will walk you through a wizard. Use these answers to match what is documented on https://katafract.com/privacy/safeopen and what the app actually does.

### Question: "Do you or your third-party partners collect data from this app?"
Answer: **Yes**

### Data Types to declare collected:

#### Identifiers — Device ID
- **Used for:** App Functionality
- **Linked to user identity:** No (anonymous Keychain UUID, not tied to Apple ID, name, or email)
- **Used for tracking:** No

#### User Content — Other User Content (the URLs you submit to AI Summary or Open Safely)
- **Used for:** App Functionality
- **Linked to user identity:** No (URL is keyed only to the anonymous device ID; never linked to Apple ID, name, or email; auto-deleted after 30 days)
- **Used for tracking:** No

#### Purchases — Purchase History (handled entirely by Apple StoreKit)
- **Used for:** App Functionality
- **Linked to user identity:** No (we only see the opaque transaction ID Apple gives us for credit redemption)
- **Used for tracking:** No

### Data Types NOT collected (leave unchecked):
- Contact Info (name, email, phone, address)
- Health & Fitness
- Financial Info
- Location
- Sensitive Info
- Contacts
- User Content (Photos/Videos, Audio, Gameplay, Customer Support, Other)
- Browsing History
- Search History
- Identifiers (User ID, Advertising ID)
- Usage Data (Product Interaction, Advertising Data, Other)
- Diagnostics (Crash Data, Performance Data, Other)

### Privacy Policy URL field
Already set to `https://katafract.com/privacy/safeopen`. Verify it points to the new page after the website deploys.

## 5. Optional but recommended

Generate a new ASC API key with **App Manager** role so future automation can manage IAPs without manual steps:
ASC → Users and Access → Integrations → App Store Connect API → Generate API Key
Save the new `.p8` and key ID; update `~/.appstoreconnect/private_keys/` and the references in `/tmp/asc.py`.
