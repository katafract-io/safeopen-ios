import Foundation
import DeviceCheck
import CryptoKit

/// Wraps Apple's App Attest to prove to the SafeOpen backend that a request came
/// from a genuine, unmodified SafeOpen binary running on a real Apple device.
///
/// - On first launch, calls ``bootstrapIfNeeded()``: generates a Secure Enclave key,
///   pairs it with a server-issued nonce, and POSTs the attestation to the backend.
///   The returned keyId is persisted in the Keychain forever.
/// - On every credit-consuming API call, ``getAttestHeaders()`` requests a fresh
///   server challenge, signs it with the persisted key, and returns the headers to
///   attach to the request.
///
/// If App Attest is not supported (simulator, older device), every call no-ops and
/// returns nil. The backend accepts nil during dark-launch and enforces after roll-out.
actor AppAttestClient {
    static let shared = AppAttestClient()

    private let service = DCAppAttestService.shared
    private let keychainService = "com.katafract.safeopen"
    private let keychainAccount = "app_attest_key_id"

    private init() {}

    var isAvailable: Bool {
        service.isSupported
    }

    // MARK: - Bootstrap (first launch only)

    /// Generate a key + attest it to the server, if we don't already have one.
    /// Safe to call every launch — no-ops if a key is already stored.
    func bootstrapIfNeeded() async {
        guard service.isSupported else { return }
        if loadKeyId() != nil { return }
        do {
            let challengeResponse = try await requestChallenge()
            guard let challengeData = Data(base64URLEncoded: challengeResponse.challenge) else {
                return
            }
            let keyId = try await generateKey()
            let clientDataHash = Data(SHA256.hash(data: challengeData))
            let attestation = try await attest(keyId: keyId, clientDataHash: clientDataHash)
            try await submitAttestation(
                keyId: keyId,
                attestation: attestation,
                challenge: challengeResponse.challenge
            )
            saveKeyId(keyId)
        } catch {
            // Any failure → leave no key stored. Dark-launch on the backend allows
            // requests without attestation. Next launch will retry bootstrap.
            print("AppAttestClient.bootstrap failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Per-request assertion

    struct AttestHeaders {
        let keyId:     String  // base64url
        let assertion: String  // base64url
        let challenge: String  // base64url (as issued by server)
    }

    /// Get the headers to attach to a single credit-consuming request.
    /// Returns nil if App Attest isn't supported or no key is stored.
    func getAttestHeaders() async -> AttestHeaders? {
        guard service.isSupported else { return nil }
        guard let keyId = loadKeyId() else { return nil }
        do {
            let challengeResponse = try await requestChallenge()
            guard let challengeData = Data(base64URLEncoded: challengeResponse.challenge) else {
                return nil
            }
            let clientDataHash = Data(SHA256.hash(data: challengeData))
            let assertion = try await generateAssertion(
                keyId: keyId,
                clientDataHash: clientDataHash
            )
            return AttestHeaders(
                keyId:     keyId.asBase64URL(),
                assertion: assertion.base64URLEncodedString(),
                challenge: challengeResponse.challenge
            )
        } catch {
            print("AppAttestClient.getAttestHeaders failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Get a single assertion header value for X-App-Attest-Assertion.
    /// Returns a base64url-encoded assertion string, or an empty string if unavailable.
    func assertionHeader() async -> String {
        guard let headers = await getAttestHeaders() else { return "" }
        return headers.assertion
    }

    // MARK: - DeviceCheck bridging

    private func generateKey() async throws -> String {
        try await withCheckedThrowingContinuation { (cc: CheckedContinuation<String, Error>) in
            service.generateKey { keyId, error in
                if let error = error { cc.resume(throwing: error); return }
                guard let keyId = keyId else {
                    cc.resume(throwing: AppAttestError.noKeyId); return
                }
                cc.resume(returning: keyId)
            }
        }
    }

    private func attest(keyId: String, clientDataHash: Data) async throws -> Data {
        try await withCheckedThrowingContinuation { (cc: CheckedContinuation<Data, Error>) in
            service.attestKey(keyId, clientDataHash: clientDataHash) { attestation, error in
                if let error = error { cc.resume(throwing: error); return }
                guard let attestation = attestation else {
                    cc.resume(throwing: AppAttestError.noAttestation); return
                }
                cc.resume(returning: attestation)
            }
        }
    }

    private func generateAssertion(keyId: String, clientDataHash: Data) async throws -> Data {
        try await withCheckedThrowingContinuation { (cc: CheckedContinuation<Data, Error>) in
            service.generateAssertion(keyId, clientDataHash: clientDataHash) { assertion, error in
                if let error = error { cc.resume(throwing: error); return }
                guard let assertion = assertion else {
                    cc.resume(throwing: AppAttestError.noAssertion); return
                }
                cc.resume(returning: assertion)
            }
        }
    }

    // MARK: - Backend calls

    private func requestChallenge() async throws -> ChallengeResponse {
        var req = URLRequest(url: URL(string: "\(InspectionAPIClient.baseURL)/v1/safeopen/attest/challenge")!)
        req.httpMethod = "GET"
        req.setValue(InspectionAPIClient.deviceID, forHTTPHeaderField: "X-Device-ID")
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(ChallengeResponse.self, from: data)
    }

    private func submitAttestation(keyId: String, attestation: Data, challenge: String) async throws {
        var req = URLRequest(url: URL(string: "\(InspectionAPIClient.baseURL)/v1/safeopen/attest")!)
        req.httpMethod = "POST"
        req.setValue(InspectionAPIClient.deviceID, forHTTPHeaderField: "X-Device-ID")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "key_id":      keyId.asBase64URL(),
            "attestation": attestation.base64URLEncodedString(),
            "challenge":   challenge,
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        _ = try await URLSession.shared.data(for: req)
    }

    // MARK: - Keychain storage

    private func loadKeyId() -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: keychainAccount,
            kSecReturnData:  true,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let str = String(data: data, encoding: .utf8) else {
            return nil
        }
        return str
    }

    private func saveKeyId(_ keyId: String) {
        let delete: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: keychainAccount,
        ]
        SecItemDelete(delete as CFDictionary)
        let add: [CFString: Any] = [
            kSecClass:          kSecClassGenericPassword,
            kSecAttrService:    keychainService,
            kSecAttrAccount:    keychainAccount,
            kSecValueData:      Data(keyId.utf8),
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemAdd(add as CFDictionary, nil)
    }
}

enum AppAttestError: Error {
    case noKeyId
    case noAttestation
    case noAssertion
}

private struct ChallengeResponse: Decodable {
    let challenge: String
    let ttl:       Int
}

// MARK: - base64url helpers

extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    init?(base64URLEncoded: String) {
        var str = base64URLEncoded
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while str.count % 4 != 0 { str += "=" }
        self.init(base64Encoded: str)
    }
}

extension String {
    /// Convert a standard-base64 Apple keyId into base64url for the backend.
    func asBase64URL() -> String {
        replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
