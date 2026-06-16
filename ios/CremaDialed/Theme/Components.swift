//
//  Components.swift
//  CremaDialed
//
//  Shared UI building blocks used across the app.
//

import SwiftUI

/// Rounded elevated card container.
struct CremaCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CremaColor.card)
            .clipShape(.rect(cornerRadius: CremaRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: CremaRadius.card)
                    .stroke(CremaColor.separator, lineWidth: 0.5)
            )
    }
}

/// Section heading with optional trailing accessory.
struct SectionHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: Trailing

    init(_ title: String, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
        self.title = title
        self.trailing = trailing()
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.crema(20, .bold))
                .foregroundStyle(CremaColor.textPrimary)
            Spacer()
            trailing
        }
    }
}

/// Primary filled action button.
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            HapticEngine.tap()
            action()
        } label: {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(.crema(17, .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(enabled ? CremaColor.background : CremaColor.textTertiary)
            .background(enabled ? CremaColor.espresso : CremaColor.surface)
            .clipShape(.rect(cornerRadius: CremaRadius.field))
        }
        .disabled(!enabled)
        .buttonStyle(PressableStyle())
    }
}

/// Selectable chip used for tags, flavours and filters.
struct CremaChip: View {
    let label: String
    var systemImage: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            HapticEngine.selection()
            action()
        } label: {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.crema(12, .semibold))
                }
                Text(label)
                    .font(.crema(14, .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .foregroundStyle(isSelected ? CremaColor.background : CremaColor.textPrimary)
            .background(isSelected ? CremaColor.espresso : CremaColor.surface)
            .clipShape(.rect(cornerRadius: CremaRadius.chip))
        }
        .buttonStyle(PressableStyle())
    }
}

/// Subtle scale-on-press style.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Compact metric tile (label + big value).
struct MetricTile: View {
    let label: String
    let value: String
    var caption: String? = nil
    var tint: Color = CremaColor.crema

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.crema(11, .semibold))
                .foregroundStyle(CremaColor.textTertiary)
            Text(value)
                .font(.crema(26, .bold))
                .foregroundStyle(tint)
            if let caption {
                Text(caption)
                    .font(.crema(12, .medium))
                    .foregroundStyle(CremaColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(CremaColor.card)
        .clipShape(.rect(cornerRadius: CremaRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: CremaRadius.card)
                .stroke(CremaColor.separator, lineWidth: 0.5)
        )
    }
}

/// Friendly empty state.
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 46, weight: .regular))
                .foregroundStyle(CremaColor.crema)
            Text(title)
                .font(.crema(20, .bold))
                .foregroundStyle(CremaColor.textPrimary)
            Text(message)
                .font(.crema(15))
                .multilineTextAlignment(.center)
                .foregroundStyle(CremaColor.textSecondary)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}
