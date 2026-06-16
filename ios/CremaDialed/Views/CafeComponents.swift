//
//  CafeComponents.swift
//  CremaDialed
//
//  Reusable building blocks for the café passport: visual drink cards, tag
//  clouds, coffee score badges, cover thumbnails and rich café cards.
//

import SwiftUI
import UIKit

// MARK: - Coffee score

/// Descriptor + tint for a 1...10 coffee score.
enum CoffeeScoreStyle {
    static func descriptor(_ score: Int) -> String {
        switch score {
        case ..<4: return "Poor"
        case 4...6: return "Good"
        case 7...8: return "Great"
        default: return "Exceptional"
        }
    }
    static func tint(_ score: Int) -> Color {
        switch score {
        case ..<4: return CremaColor.negative
        case 4...6: return CremaColor.caramel
        case 7...8: return CremaColor.crema
        default: return CremaColor.positive
        }
    }
}

/// Compact pill showing a coffee score out of 10.
struct CoffeeScoreBadge: View {
    let score: Double
    var size: CGFloat = 17

    private var rounded: Int { Int(score.rounded()) }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.crema(size * 0.62, .bold))
            Text(score.truncatingRemainder(dividingBy: 1) == 0
                 ? "\(rounded)" : String(format: "%.1f", score))
                .font(.crema(size, .bold))
                .monospacedDigit()
        }
        .foregroundStyle(CremaColor.background)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(CoffeeScoreStyle.tint(rounded))
        .clipShape(Capsule())
    }
}

// MARK: - Visual drink card

/// A large, tappable drink card with icon, name and descriptor.
struct DrinkCard: View {
    let drink: CoffeeDrink
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            HapticEngine.selection()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: drink.systemImage)
                    .font(.crema(26, .semibold))
                    .foregroundStyle(isSelected ? CremaColor.background : CremaColor.crema)
                Spacer(minLength: 0)
                Text(drink.rawValue)
                    .font(.crema(16, .bold))
                    .foregroundStyle(isSelected ? CremaColor.background : CremaColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(drink.blurb)
                    .font(.crema(12, .medium))
                    .foregroundStyle(isSelected ? CremaColor.background.opacity(0.85) : CremaColor.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 112)
            .padding(14)
            .background(
                ZStack {
                    if isSelected {
                        LinearGradient(colors: [CremaColor.espresso, CremaColor.caramel],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    } else {
                        CremaColor.card
                    }
                }
            )
            .clipShape(.rect(cornerRadius: CremaRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: CremaRadius.card)
                    .stroke(isSelected ? Color.clear : CremaColor.separator, lineWidth: 0.5)
            )
            .shadow(color: isSelected ? CremaColor.espresso.opacity(0.3) : .clear, radius: 10, y: 4)
        }
        .buttonStyle(PressableStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
    }
}

// MARK: - Tag cloud

/// A wrapping multi-select tag cloud backed by an array of raw string values.
struct TagCloud: View {
    let options: [String]
    @Binding var selected: [String]
    var tint: Color = CremaColor.espresso

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 8, alignment: .leading)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(options, id: \.self) { option in
                let isOn = selected.contains(option)
                Button {
                    HapticEngine.selection()
                    if isOn { selected.removeAll { $0 == option } }
                    else { selected.append(option) }
                } label: {
                    Text(option)
                        .font(.crema(13, .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 6)
                        .foregroundStyle(isOn ? CremaColor.background : CremaColor.textPrimary)
                        .background(isOn ? tint : CremaColor.surface)
                        .clipShape(.rect(cornerRadius: CremaRadius.chip))
                }
                .buttonStyle(PressableStyle())
            }
        }
    }
}

/// Read-only tag chips used on memory cards and profiles.
struct TagChipsRow: View {
    let tags: [String]
    var tint: Color = CremaColor.surface

    private let columns = [GridItem(.adaptive(minimum: 80), spacing: 6, alignment: .leading)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.crema(11, .semibold))
                    .foregroundStyle(CremaColor.textSecondary)
                    .lineLimit(1)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(tint)
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Cover thumbnail

/// A rounded cover image that falls back to a tinted coffee glyph.
struct CafeCover: View {
    let data: Data?
    var size: CGFloat
    var corner: CGFloat = 14

    var body: some View {
        Color(.secondarySystemBackground)
            .frame(width: size, height: size)
            .overlay {
                if let data, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .allowsHitTesting(false)
                } else {
                    LinearGradient(colors: [CremaColor.espresso.opacity(0.85), CremaColor.caramel.opacity(0.7)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                        .overlay {
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.crema(size * 0.34, .bold))
                                .foregroundStyle(CremaColor.background.opacity(0.9))
                        }
                }
            }
            .clipShape(.rect(cornerRadius: corner))
    }
}

// MARK: - Café cards

/// A rich café row used in the passport lists.
struct CafeListRow: View {
    let cafe: Cafe

    var body: some View {
        CremaCard(padding: 12) {
            HStack(spacing: 12) {
                CafeCover(data: cafe.coverPhoto, size: 60, corner: 14)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(cafe.name)
                            .font(.crema(16, .bold))
                            .foregroundStyle(CremaColor.textPrimary)
                            .lineLimit(1)
                        if cafe.isFavourite {
                            Image(systemName: "heart.fill")
                                .font(.crema(11))
                                .foregroundStyle(CremaColor.negative)
                        }
                    }
                    Text(subtitle)
                        .font(.crema(12, .medium))
                        .foregroundStyle(CremaColor.textSecondary)
                        .lineLimit(1)
                    if let drink = cafe.favouriteDrink {
                        Text("Loves the \(drink.rawValue.lowercased())")
                            .font(.crema(11, .medium))
                            .foregroundStyle(CremaColor.caramel)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                if cafe.hasVisited {
                    CoffeeScoreBadge(score: cafe.averageRating)
                } else {
                    Text("Wishlist")
                        .font(.crema(11, .bold))
                        .foregroundStyle(CremaColor.caramel)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(CremaColor.caramel.opacity(0.16))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var subtitle: String {
        var parts: [String] = []
        if cafe.hasVisited {
            parts.append("\(cafe.visits.count) visit\(cafe.visits.count == 1 ? "" : "s")")
        }
        if !cafe.city.isEmpty { parts.append(cafe.city) }
        if let last = cafe.lastVisit {
            parts.append(last.formatted(.relative(presentation: .named)))
        }
        return parts.joined(separator: " · ")
    }
}

/// A large carousel card showing a café cover with overlaid name + score.
struct CafeFeatureCard: View {
    let cafe: Cafe
    var width: CGFloat = 220

    var body: some View {
        Color(.secondarySystemBackground)
            .frame(width: width, height: 150)
            .overlay {
                if let data = cafe.coverPhoto, let image = UIImage(data: data) {
                    Image(uiImage: image).resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false)
                } else {
                    LinearGradient(colors: [CremaColor.espresso, CremaColor.caramel],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            }
            .overlay {
                LinearGradient(colors: [.clear, .black.opacity(0.65)],
                               startPoint: .center, endPoint: .bottom)
                    .allowsHitTesting(false)
            }
            .overlay(alignment: .topTrailing) {
                if cafe.isFavourite {
                    Image(systemName: "heart.fill")
                        .font(.crema(13, .bold))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.black.opacity(0.3), in: Circle())
                        .padding(10)
                }
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(cafe.name)
                        .font(.crema(17, .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        if cafe.hasVisited {
                            Text(String(format: "%.1f", cafe.averageRating))
                                .font(.crema(13, .bold))
                                .foregroundStyle(CremaColor.crema)
                            Text("· \(cafe.visits.count) visit\(cafe.visits.count == 1 ? "" : "s")")
                                .font(.crema(12, .medium))
                                .foregroundStyle(.white.opacity(0.85))
                        } else {
                            Text("Want to visit")
                                .font(.crema(12, .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                }
                .padding(14)
            }
            .clipShape(.rect(cornerRadius: CremaRadius.card))
            .overlay(RoundedRectangle(cornerRadius: CremaRadius.card).stroke(CremaColor.separator, lineWidth: 0.5))
    }
}
