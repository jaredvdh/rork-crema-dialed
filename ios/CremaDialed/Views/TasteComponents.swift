//
//  TasteComponents.swift
//  CremaDialed
//

import SwiftUI

/// A 1...10 taste attribute slider with a warm fill.
struct TasteSlider: View {
    let label: String
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.crema(15, .medium))
                    .foregroundStyle(CremaColor.textPrimary)
                Spacer()
                Text("\(value)")
                    .font(.crema(15, .bold))
                    .foregroundStyle(CremaColor.crema)
                    .contentTransition(.numericText())
            }
            Slider(value: Binding(
                get: { Double(value) },
                set: { newValue in
                    let rounded = Int(newValue.rounded())
                    if rounded != value { HapticEngine.selection() }
                    value = rounded
                }
            ), in: 1...10, step: 1)
            .tint(CremaColor.crema)
        }
    }
}

/// A premium 1...10 flavour score control with a Poor / Good / Excellent descriptor.
struct FlavourScore: View {
    @Binding var score: Int

    private var descriptor: String {
        switch score {
        case ..<4: return "Poor"
        case 4...6: return "Okay"
        case 7...8: return "Good"
        default: return "Excellent"
        }
    }

    private var tint: Color {
        switch score {
        case ..<4: return CremaColor.negative
        case 4...6: return CremaColor.caramel
        default: return CremaColor.positive
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(score)")
                    .font(.crema(44, .bold))
                    .foregroundStyle(tint)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text("/10")
                    .font(.crema(18, .semibold))
                    .foregroundStyle(CremaColor.textTertiary)
                Spacer()
                Text(descriptor)
                    .font(.crema(15, .bold))
                    .foregroundStyle(tint)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(tint.opacity(0.14))
                    .clipShape(Capsule())
                    .contentTransition(.opacity)
            }
            HStack(spacing: 6) {
                ForEach(1...10, id: \.self) { n in
                    Capsule()
                        .fill(n <= score ? tint : CremaColor.surface)
                        .frame(height: 26)
                        .overlay {
                            if n <= score {
                                Capsule().stroke(tint.opacity(0.5), lineWidth: 0.5)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            HapticEngine.selection()
                            score = n
                        }
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: score)
        }
    }
}

/// A large, tappable 1...5 star rating control.
struct StarRating: View {
    @Binding var rating: Int
    var size: CGFloat = 34
    var tint: Color = CremaColor.crema

    var body: some View {
        HStack(spacing: 10) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(star <= rating ? tint : CremaColor.textTertiary)
                    .scaleEffect(star <= rating ? 1 : 0.9)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: rating)
                    .onTapGesture {
                        HapticEngine.selection()
                        rating = star
                    }
                    .accessibilityLabel("\(star) star\(star == 1 ? "" : "s")")
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// Interactive flavour wheel — multi-select chips arranged in a wrapping grid.
struct FlavourWheelPicker: View {
    @Binding var selected: [String]

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(FlavourNote.allCases) { note in
                let isOn = selected.contains(note.rawValue)
                Button {
                    HapticEngine.selection()
                    if isOn {
                        selected.removeAll { $0 == note.rawValue }
                    } else {
                        selected.append(note.rawValue)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(note.emoji)
                        Text(note.rawValue)
                            .font(.crema(13, .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .foregroundStyle(isOn ? CremaColor.background : CremaColor.textPrimary)
                    .background(isOn ? CremaColor.caramel : CremaColor.surface)
                    .clipShape(.rect(cornerRadius: CremaRadius.chip))
                }
                .buttonStyle(PressableStyle())
            }
        }
    }
}

/// Coach tip row with color-coded severity.
struct CoachTipRow: View {
    let tip: CoachTip

    private var tint: Color {
        switch tip.severity {
        case .good: return CremaColor.positive
        case .adjust: return CremaColor.warning
        case .alert: return CremaColor.negative
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: tip.systemImage)
                .font(.crema(16, .semibold))
                .foregroundStyle(tint)
                .frame(width: 24)
            Text(tip.text)
                .font(.crema(14))
                .foregroundStyle(CremaColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}
