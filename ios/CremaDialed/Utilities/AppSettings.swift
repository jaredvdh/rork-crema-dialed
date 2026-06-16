//
//  AppSettings.swift
//  CremaDialed
//
//  Central keys and value types for app-wide behaviour preferences that live in
//  the consolidated Settings area (appearance, haptics, notifications, location,
//  iCloud sync). Measurement units live in `UnitPreferences`.
//

import SwiftUI

/// How the app chooses its colour scheme.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var symbol: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    /// The scheme to apply, or `nil` to follow the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Storage keys + lightweight accessors for app behaviour preferences. Keys are
/// shared with the `@AppStorage` declarations in the Settings views.
enum AppSettings {
    static let appearanceKey = "appearanceMode"
    static let hapticsKey = "hapticsEnabled"
    static let notificationsKey = "notificationsEnabled"
    static let locationKey = "locationServicesEnabled"
    static let iCloudSyncKey = "iCloudSyncEnabled"

    /// Whether haptic feedback should fire. Defaults to on when unset.
    static var hapticsEnabled: Bool {
        UserDefaults.standard.object(forKey: hapticsKey) as? Bool ?? true
    }

    /// Whether the user has opted in to location-based café discovery. Defaults
    /// to on when unset (existing behaviour), so the toggle never silently
    /// disables a feature people already rely on.
    static var locationEnabled: Bool {
        UserDefaults.standard.object(forKey: locationKey) as? Bool ?? true
    }

    static var appearance: AppearanceMode {
        AppearanceMode(rawValue: UserDefaults.standard.string(forKey: appearanceKey) ?? "") ?? .system
    }
}
