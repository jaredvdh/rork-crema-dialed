//
//  CremaTheme.swift
//  CremaDialed
//
//  Coffee-inspired design system with automatic light/dark adaptation.
//

import SwiftUI
import UIKit

/// Central palette. Every color is a dynamic UIColor so the whole app adapts
/// to light and dark mode without inverting — dark mode is a bespoke warm
/// espresso theme, not a flipped light theme.
enum CremaColor {
    private static func dynamic(light: UInt, dark: UInt) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }

    // Brand
    /// Espresso brown — primary brand color for emphasis and buttons.
    static let espresso = dynamic(light: 0x4A2C1A, dark: 0xE8C9A0)
    /// Golden crema — the signature accent.
    static let crema = dynamic(light: 0xC68A3E, dark: 0xE0A95C)
    /// Caramel — secondary accent / highlights.
    static let caramel = dynamic(light: 0xB5763B, dark: 0xCE9456)

    // Surfaces
    /// Warm off-white background in light, rich dark espresso in dark.
    static let background = dynamic(light: 0xF7F1E8, dark: 0x17110D)
    /// Elevated card surface.
    static let card = dynamic(light: 0xFFFFFF, dark: 0x241B14)
    /// Slightly raised secondary surface (chips, fields).
    static let surface = dynamic(light: 0xEFE7DA, dark: 0x2E231A)

    // Text
    static let textPrimary = dynamic(light: 0x2A1C12, dark: 0xF4ECE0)
    static let textSecondary = dynamic(light: 0x7A6A58, dark: 0xB6A793)
    static let textTertiary = dynamic(light: 0xA89A88, dark: 0x82715D)

    // Lines
    static let separator = dynamic(light: 0xE4D9C8, dark: 0x352920)

    // Semantic
    static let positive = dynamic(light: 0x5E8C5A, dark: 0x83BE7C)
    static let warning = dynamic(light: 0xC9852F, dark: 0xE0A95C)
    static let negative = dynamic(light: 0xB55438, dark: 0xD9785A)
}

extension UIColor {
    convenience init(hex: UInt) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}

/// Reusable corner radii.
enum CremaRadius {
    static let card: CGFloat = 20
    static let chip: CGFloat = 14
    static let field: CGFloat = 14
}

extension Font {
    static func crema(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
