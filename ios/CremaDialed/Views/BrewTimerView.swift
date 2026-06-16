//
//  BrewTimerView.swift
//  CremaDialed
//
//  The immersive espresso extraction ritual: a full-screen cinematic backdrop,
//  a giant readable timer that starts on the FIRST DRIP, a wet-hand-friendly
//  stop control, and a results summary that flows into the brew log.
//

import SwiftUI

struct BrewTimerView: View {
    @Bindable var timer: BrewTimer
    let dose: Double
    let yield: Double
    /// Called with the final shot time when the user keeps the result.
    var onFinish: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false

    init(timer: BrewTimer, dose: Double, yield: Double, onFinish: @escaping (Double) -> Void) {
        self._timer = Bindable(timer)
        self.dose = dose
        self.yield = yield
        self.onFinish = onFinish
    }

    private var ratio: Double { dose > 0 ? yield / dose : 0 }

    var body: some View {
        ZStack {
            ExtractionVideoView(isFlowing: timer.phase == .extracting)

            switch timer.phase {
            case .ready: readyOverlay
            case .extracting: extractingOverlay
            case .finished: resultsOverlay
            }
        }
        .statusBarHidden(true)
        .preferredColorScheme(.dark)
        .onAppear { withAnimation(.easeOut(duration: 0.6)) { appeared = true } }
    }

    // MARK: Ready — wait for first drip

    private var readyOverlay: some View {
        VStack {
            topBar(showClose: true)
            Spacer()

            VStack(spacing: 14) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(warmGold)
                    .symbolEffect(.pulse, options: .repeating)
                Text("Watch the spout")
                    .font(.crema(26, .bold))
                    .foregroundStyle(.white)
                Text("Tap the moment the first drop of\nespresso falls into the cup.")
                    .font(.crema(16, .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()
            targetPill
                .padding(.bottom, 18)

            bigButton(title: "First Drip", systemImage: "drop.fill", tint: warmGold) {
                timer.firstDrip()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .opacity(appeared ? 1 : 0)
    }

    // MARK: Extracting — live timer

    private var extractingOverlay: some View {
        VStack {
            topBar(showClose: false)
            Spacer()

            VStack(spacing: 6) {
                Text(String(format: "%05.2f", timer.elapsed))
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(statusTint)
                    .shadow(color: .black.opacity(0.4), radius: 12)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.4), value: statusTint)
                Text("SECONDS")
                    .font(.crema(15, .semibold))
                    .tracking(4)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .scaleEffect(timer.isInTargetRange ? 1.04 : 1)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: timer.isInTargetRange)

            stagePill
                .padding(.top, 18)

            Spacer()
            if timer.hasGolden { goldenTargetCard.padding(.bottom, 16) }
            targetPill
                .padding(.bottom, 28)

            stopButton
                .padding(.bottom, 44)
        }
    }

    // MARK: Finished — results summary

    private var resultsOverlay: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 22) {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(warmGold)
                    Text("Shot complete")
                        .font(.crema(24, .bold))
                        .foregroundStyle(.white)
                }

                HStack(spacing: 0) {
                    resultStat("TIME", String(format: "%.1fs", timer.elapsed),
                               tint: timer.isInTargetRange ? Color(red: 0.55, green: 0.78, blue: 0.5) : warmGold)
                    divider
                    resultStat("RATIO", String(format: "1:%.1f", ratio), tint: .white)
                }
                HStack(spacing: 0) {
                    resultStat("DOSE", UnitPreferences.weightLabel(grams: dose), tint: .white.opacity(0.9))
                    divider
                    resultStat("YIELD", UnitPreferences.weightLabel(grams: yield), tint: .white.opacity(0.9))
                }

                Text(timer.isInTargetRange
                     ? "Right in your target window — nice."
                     : "Outside your \(timer.targetLabel) window. The coach can help.")
                    .font(.crema(14, .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.65))
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .clipShape(.rect(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.12), lineWidth: 1))
            .padding(.horizontal, 20)

            VStack(spacing: 12) {
                bigButton(title: "Save Shot Time", systemImage: "checkmark", tint: warmGold) {
                    onFinish((timer.elapsed * 10).rounded() / 10)
                    dismiss()
                }
                Button {
                    HapticEngine.light()
                    timer.reset()
                } label: {
                    Text("Pull Again")
                        .font(.crema(16, .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: Building blocks

    private var warmGold: Color { Color(red: 0.88, green: 0.66, blue: 0.36) }

    // MARK: Extraction stage

    private var stagePill: some View {
        VStack(spacing: 4) {
            Text(timer.stage.rawValue.uppercased())
                .font(.crema(16, .bold))
                .tracking(2)
                .foregroundStyle(statusTint)
                .contentTransition(.opacity)
            Text(timer.stage.detail)
                .font(.crema(13, .medium))
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(statusTint.opacity(0.4), lineWidth: 1))
        .animation(.easeInOut(duration: 0.35), value: timer.stage)
    }

    // MARK: Golden recipe targets

    private var goldenTargetCard: some View {
        VStack(spacing: 10) {
            Label("GOLDEN RECIPE", systemImage: "star.fill")
                .font(.crema(11, .bold)).tracking(2)
                .foregroundStyle(warmGold)
            HStack(spacing: 0) {
                goldenStat("TIME", timer.goldenTime.map { String(format: "%.0fs", $0) })
                goldenDivider
                goldenStat("YIELD", timer.goldenYield.map { UnitPreferences.weightLabel(grams: $0) })
                goldenDivider
                goldenStat("DOSE", timer.goldenDose.map { UnitPreferences.weightLabel(grams: $0) })
                goldenDivider
                goldenStat("TEMP", timer.goldenTemp.map { String(format: "%.0f°", $0) })
                if let b = timer.goldenBasket, !b.isEmpty {
                    goldenDivider
                    goldenStat("BASKET", b)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(warmGold.opacity(0.3), lineWidth: 1))
        .padding(.horizontal, 24)
    }

    private func goldenStat(_ label: String, _ value: String?) -> some View {
        VStack(spacing: 3) {
            Text(value ?? "—")
                .font(.crema(17, .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.crema(9, .semibold)).tracking(1)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    private var goldenDivider: some View {
        Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 26)
    }

    private func topBar(showClose: Bool) -> some View {
        HStack {
            if showClose {
                Button {
                    HapticEngine.light()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.crema(16, .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var targetPill: some View {
        HStack(spacing: 16) {
            VStack(spacing: 2) {
                Text("TARGET")
                    .font(.crema(10, .semibold)).tracking(2)
                    .foregroundStyle(.white.opacity(0.5))
                Text(timer.targetLabel)
                    .font(.crema(18, .bold))
                    .foregroundStyle(.white)
            }
            Rectangle().fill(.white.opacity(0.2)).frame(width: 1, height: 28)
            VStack(spacing: 2) {
                Text("STATUS")
                    .font(.crema(10, .semibold)).tracking(2)
                    .foregroundStyle(.white.opacity(0.5))
                Text(statusText)
                    .font(.crema(18, .bold))
                    .foregroundStyle(statusTint)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(statusTint.opacity(timer.isInTargetRange ? 0.7 : 0.15), lineWidth: 1.5))
        .animation(.easeInOut(duration: 0.3), value: timer.isInTargetRange)
    }

    private var statusText: String {
        switch timer.phase {
        case .ready: return "Ready"
        case .extracting:
            if timer.isOverTarget { return "Over" }
            return timer.isInTargetRange ? "Sweet Spot" : "Building"
        case .finished: return "Done"
        }
    }

    private var statusTint: Color {
        if timer.isInTargetRange { return Color(red: 0.6, green: 0.85, blue: 0.55) }
        if timer.isOverTarget { return Color(red: 0.9, green: 0.5, blue: 0.38) }
        return warmGold
    }

    private var stopButton: some View {
        Button {
            timer.stop()
        } label: {
            ZStack {
                Circle()
                    .fill(Color(red: 0.86, green: 0.3, blue: 0.24))
                    .frame(width: 96, height: 96)
                    .shadow(color: .black.opacity(0.4), radius: 16, y: 6)
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white)
                    .frame(width: 30, height: 30)
            }
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("Stop extraction")
    }

    private func bigButton(title: String, systemImage: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button {
            HapticEngine.tap()
            action()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.crema(19, .bold))
            }
            .foregroundStyle(Color(red: 0.12, green: 0.07, blue: 0.04))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(tint)
            .clipShape(.rect(cornerRadius: 22))
            .shadow(color: tint.opacity(0.4), radius: 14, y: 6)
        }
        .buttonStyle(PressableStyle())
    }

    private func resultStat(_ label: String, _ value: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.crema(11, .semibold)).tracking(2)
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.crema(28, .bold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 40)
    }
}
