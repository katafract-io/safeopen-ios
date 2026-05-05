import Foundation
import DeviceCheck

/// Checks whether this Apple device has previously claimed SafeOpen's welcome
/// credits. Uses Apple's DeviceCheck API (2 persistent bits per device that
/// survive reinstalls), so reinstall-farming is blocked even if App Attest
/// ever fails open.
///
/// The backend calls Apple's DeviceCheck directly via its REST API — the client
/// only has to hand the server an opaque `DCDevice.current.generateToken()`
/// result, which Apple signs with the device attestation key.
///
/// During dark launch the backend logs but doesn't reject; this class runs
/// unconditionally so the server builds a full picture of device history from
/// day one, then flips enforcement on in a later release.
struct DeviceCheckClient {

    /// Opportunistically claim the welcome credits once per device. Safe to call
    /// on every launch — backend idempotency prevents double-claims.
    static func claimWelcomeOnce() async {
        guard DCDevice.current.isSupported else { return }
        do {
            let tokenData = try await withCheckedThrowingContinuation { (cc: CheckedContinuation<Data, Error>) in
                DCDevice.current.generateToken { data, error in
                    if let error = error { cc.resume(throwing: error); return }
                    guard let data = data else {
                        cc.resume(throwing: DeviceCheckError.noToken); return
                    }
                    cc.resume(returning: data)
                }
            }
            var req = URLRequest(url: URL(string: "\(InspectionAPIClient.baseURL)/v1/safeopen/device-check/claim-welcome")!)
            req.httpMethod = "POST"
            let assertion = await AppAttestClient.shared.assertionHeader()
            req.setValue(assertion, forHTTPHeaderField: "X-App-Attest-Assertion")
            req.setValue(InspectionAPIClient.deviceID, forHTTPHeaderField: "X-Device-ID")
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body: [String: Any] = ["device_token": tokenData.base64EncodedString()]
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            _ = try await URLSession.shared.data(for: req)
        } catch {
            // Fail silently — dark launch posture, welcome grant still happens
            // via the normal /credits path regardless.
            print("DeviceCheckClient.claimWelcomeOnce failed: \(error.localizedDescription)")
        }
    }
}

enum DeviceCheckError: Error {
    case noToken
}
