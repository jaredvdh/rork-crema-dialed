//
//  InterfaceStyle+Modifier.swift
//  CremaDialed
//
//  Forces the active window's `overrideUserInterfaceStyle` to match the chosen
//  appearance. SwiftUI's `.preferredColorScheme` updates the environment but
//  does not reliably re-resolve dynamic `UIColor`s (the whole CremaColor
//  palette), so we drive the window trait collection directly to repaint.
//

import SwiftUI
import UIKit

private struct InterfaceStyleModifier: ViewModifier {
    let style: UIUserInterfaceStyle

    func body(content: Content) -> some View {
        content
            .onAppear { apply(style) }
            .onChange(of: style) { _, newStyle in apply(newStyle) }
    }

    private func apply(_ style: UIUserInterfaceStyle) {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
        for window in windows {
            window.overrideUserInterfaceStyle = style
        }
    }
}

extension View {
    /// Forces every active window to the given interface style.
    func applyInterfaceStyle(_ style: UIUserInterfaceStyle) -> some View {
        modifier(InterfaceStyleModifier(style: style))
    }
}
