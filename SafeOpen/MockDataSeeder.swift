import Foundation

/// Mock data seeder for screenshot mode (--screenshots launch argument).
/// Provides sample suspicious URLs for link safety scanning.
struct MockDataSeeder {
    static func seedDataIfNeeded() {
        guard CommandLine.arguments.contains("--screenshots") else { return }
        
        // TODO: Tek wires this to real model.
        // Minimal fixture: seed sample URL inspection results + tracker data.
        // Current: placeholder print.
        print("MockDataSeeder: TODO — wire to real SafeOpen URL inspection model")
    }
}
