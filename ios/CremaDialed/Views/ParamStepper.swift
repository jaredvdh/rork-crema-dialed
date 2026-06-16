//
//  ParamStepper.swift
//  CremaDialed
//

import SwiftUI

/// A labelled numeric parameter with - / + controls and a centered value.
struct ParamStepper: View {
    let label: String
    let unit: String
    @Binding var value: Double
    var step: Double = 0.5
    var range: ClosedRange<Double> = 0...999
    var format: String = "%.1f"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.crema(11, .semibold))
                .foregroundStyle(CremaColor.textTertiary)
            HStack(spacing: 8) {
                stepButton("minus") {
                    value = max(range.lowerBound, value - step)
                }
                VStack(spacing: 0) {
                    Text(String(format: format, value))
                        .font(.crema(22, .bold))
                        .foregroundStyle(CremaColor.textPrimary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(unit)
                        .font(.crema(11, .medium))
                        .foregroundStyle(CremaColor.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                stepButton("plus") {
                    value = min(range.upperBound, value + step)
                }
            }
        }
        .padding(12)
        .background(CremaColor.surface)
        .clipShape(.rect(cornerRadius: CremaRadius.field))
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticEngine.light()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.crema(16, .bold))
                .foregroundStyle(CremaColor.espresso)
                .frame(width: 36, height: 36)
                .background(CremaColor.card)
                .clipShape(Circle())
        }
        .buttonStyle(PressableStyle())
    }
}
