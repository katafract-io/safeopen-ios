// SafeOpen/Design/KataStyle.swift
// Inline copy of KatafractStyle tokens — avoids SPM integration friction.
// Source of truth: katafract-io/KatafractStyle. Keep in sync manually.
// Last synced: 2026-04-21

import SwiftUI

// MARK: - Color palette

extension Color {
    /// Deep cobalt background. #0F2652
    static let kataNavy        = Color(red: 0.059, green: 0.149, blue: 0.322)
    /// Near-black for gradient bottoms. #020610
    static let kataMidnight    = Color(red: 0.008, green: 0.024, blue: 0.063)
    /// Sapphire-blue CTA accent. #1F5FAE
    static let kataSapphire    = Color(red: 0.122, green: 0.373, blue: 0.682)
    /// Pale sky-blue highlight. #B8DFFF
    static let kataIce         = Color(red: 0.722, green: 0.875, blue: 1.000)
    /// Warm champagne gold. #C69838
    static let kataGold        = Color(red: 0.776, green: 0.596, blue: 0.220)
    /// Bright champagne highlight. #FFE89A
    static let kataChampagne   = Color(red: 1.000, green: 0.910, blue: 0.604)
    /// Deep bronze shadow. #6E4E15
    static let kataBronze      = Color(red: 0.431, green: 0.306, blue: 0.082)
    /// Deep crimson for hard danger states — NOT bright UIKit red.
    static let kataCrimson     = Color(red: 0.670, green: 0.130, blue: 0.130)

    // Semantic aliases
    static let kataSurface     = Color.kataNavy
    static let kataAction      = Color.kataSapphire
}

// MARK: - Typography

extension Font {
    /// Serif display — hero / paywall headlines.
    static func kataDisplay(_ size: CGFloat = 40, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    /// Section headings.
    static func kataHeadline(_ size: CGFloat = 24, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    /// Body copy.
    static func kataBody(_ size: CGFloat = 16, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    /// Captions and footers.
    static func kataCaption(_ size: CGFloat = 12, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    /// Monospace for URLs, keys, technical content.
    static func kataMono(_ size: CGFloat = 14, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Haptics

enum KataHaptic {
    /// Scan complete — safe result.
    case unlocked
    /// Scan complete — dangerous result.
    case denied
    /// Subtle tap — tab switch, list selection.
    case tap
    /// Action committed.
    case saved
    /// Destructive confirmation.
    case destructive

    @MainActor
    func fire() {
#if canImport(UIKit)
        switch self {
        case .unlocked:
            let g = UINotificationFeedbackGenerator(); g.prepare(); g.notificationOccurred(.success)
        case .denied:
            let g = UINotificationFeedbackGenerator(); g.prepare(); g.notificationOccurred(.error)
        case .tap:
            let g = UIImpactFeedbackGenerator(style: .light); g.prepare(); g.impactOccurred()
        case .saved:
            let g = UIImpactFeedbackGenerator(style: .medium); g.prepare(); g.impactOccurred()
        case .destructive:
            let g = UINotificationFeedbackGenerator(); g.prepare(); g.notificationOccurred(.warning)
        }
#endif
    }
}
