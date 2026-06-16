//
//  HapticEngine.swift
//  CremaDialed
//
//  Lightweight haptic feedback wrappers. All feedback respects the user's
//  Haptics preference in Settings → App Preferences.
//

import UIKit

enum HapticEngine {
    /// Honours the user's Haptics toggle (defaults to on when never set).
    private static var isEnabled: Bool { AppSettings.hapticsEnabled }

    static func tap() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func light() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func selection() {
        guard isEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func success() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
