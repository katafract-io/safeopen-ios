import SwiftUI

struct OnboardingView: View {
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("How SafeOpen works", systemImage: "shield.lefthalf.filled")
                            .font(.title2.weight(.bold))
                        Text("When you inspect a link, SafeOpen sends the URL to our servers to analyze it for phishing, malware, and risky redirects.")
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("About scan credits", systemImage: "creditcard")
                            .font(.title3.weight(.semibold))
                        Text("You start with free scan credits. Each AI summary or 'Open Safely' session uses 1 credit. QR scanning and local risk checks are always free.")
                            .foregroundStyle(.secondary)
                        Text("Credits never expire. More credits are available as one-time purchases — no subscription required.")
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Your privacy", systemImage: "eye.slash")
                            .font(.title3.weight(.semibold))
                        Text("URLs are sent to SafeOpen's servers for inspection only. We don't store them after analysis. No account required — you're identified only by an anonymous install ID.")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(24)
            }
            .navigationTitle("Welcome to SafeOpen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Got it") { onDismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
