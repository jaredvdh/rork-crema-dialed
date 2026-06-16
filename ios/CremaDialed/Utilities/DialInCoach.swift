//
//  DialInCoach.swift
//  CremaDialed
//
//  Offline heuristic engine that analyses brew parameters and taste to give
//  barista-style recommendations. Equipment-aware when a grinder is known.
//

import Foundation

struct CoachTip: Identifiable {
    enum Severity {
        case good, adjust, alert
    }
    let id = UUID()
    let severity: Severity
    let text: String
    let systemImage: String
}

enum DialInCoach {
    /// Produce ordered tips for a brew. Most important first.
    static func analyze(_ brew: Brew) -> [CoachTip] {
        var tips: [CoachTip] = []
        let ratio = brew.ratio

        // Shot time analysis
        if brew.shotTime < 22 {
            tips.append(.init(
                severity: .adjust,
                text: grindAdvice(brew, finer: true, reason: "Extraction is running fast (\(Int(brew.shotTime))s). Grind finer to slow the flow."),
                systemImage: "timer"
            ))
        } else if brew.shotTime > 36 {
            tips.append(.init(
                severity: .adjust,
                text: grindAdvice(brew, finer: false, reason: "Extraction is slow (\(Int(brew.shotTime))s). Grind coarser to open up the flow."),
                systemImage: "timer"
            ))
        } else {
            tips.append(.init(
                severity: .good,
                text: "Shot time of \(Int(brew.shotTime))s sits in the sweet spot for this ratio.",
                systemImage: "checkmark.seal.fill"
            ))
        }

        // Taste-led diagnosis
        if brew.bitterness >= 7 && brew.sweetness <= 4 {
            tips.append(.init(
                severity: .adjust,
                text: "High bitterness with low sweetness points to over-extraction. Try a coarser grind or drop water temp by 1°C.",
                systemImage: "drop.degreesign"
            ))
        }
        if brew.acidity >= 7 && brew.sweetness <= 4 {
            tips.append(.init(
                severity: .adjust,
                text: "Sharp acidity and thin sweetness suggest under-extraction. Grind finer or extend yield slightly.",
                systemImage: "bolt.fill"
            ))
        }
        if brew.balance <= 4 {
            tips.append(.init(
                severity: .adjust,
                text: "Balance is low — nudge yield by +2g to round out the cup, then retaste.",
                systemImage: "scalemass"
            ))
        }

        // Ratio guidance
        if ratio < 1.6 {
            tips.append(.init(
                severity: .alert,
                text: String(format: "Ratio of %@ is quite tight — expect intensity. Open to 1:2 for clarity.", brew.ratioLabel),
                systemImage: "arrow.left.and.right"
            ))
        } else if ratio > 2.6 {
            tips.append(.init(
                severity: .adjust,
                text: String(format: "Ratio of %@ is long — flavours may thin out. Pull back toward 1:2.", brew.ratioLabel),
                systemImage: "arrow.left.and.right"
            ))
        }

        // Bean age awareness
        if let days = brew.bean?.daysOffRoast {
            if days < 4 {
                tips.append(.init(
                    severity: .adjust,
                    text: "Beans are only \(days)d off roast and still degassing — gushing and uneven shots are normal. Let them rest.",
                    systemImage: "calendar"
                ))
            } else if days > 25 {
                tips.append(.init(
                    severity: .adjust,
                    text: "At \(days)d off roast these beans are fading. Go a touch finer to keep extraction lively.",
                    systemImage: "calendar"
                ))
            }
        }

        if tips.contains(where: { $0.severity == .good }) && tips.count == 1 && brew.overall >= 8 {
            tips.append(.init(
                severity: .good,
                text: "This is dialed in beautifully — consider saving it as your golden recipe.",
                systemImage: "star.fill"
            ))
        }

        return tips
    }

    /// Build equipment-aware grind advice using the grinder type when available.
    private static func grindAdvice(_ brew: Brew, finer: Bool, reason: String) -> String {
        guard let grinder = brew.grinder, !brew.grindSetting.isEmpty else {
            return reason
        }
        let direction = finer ? "finer" : "coarser"
        switch grinder.kind {
        case .stepped, .stepless:
            if let current = Double(brew.grindSetting) {
                let target = finer ? current - 2 : current + 2
                let fmt = grinder.kind == .stepped ? "%.0f" : "%.1f"
                return reason + String(format: " On your \(grinder.model), move from \(fmt) to \(fmt).", current, target)
            }
            return reason + " Move 2 clicks \(direction) on your \(grinder.model)."
        case .timeBased:
            let target = finer ? brew.grindTime + 0.8 : max(0, brew.grindTime - 0.8)
            return reason + String(format: " Adjust grind time from %.1fs to %.1fs.", brew.grindTime, target)
        case .weightBased:
            return reason + " Step the burr \(direction) one increment and keep your target dose steady."
        }
    }

    /// Compare a brew against a saved golden recipe.
    static func compareToGolden(_ brew: Brew, golden: DialedRecipe) -> [CoachTip] {
        var tips: [CoachTip] = []
        let timeDelta = brew.shotTime - golden.shotTime
        if abs(timeDelta) >= 3 {
            let dir = timeDelta > 0 ? "slower" : "faster"
            tips.append(.init(
                severity: .adjust,
                text: String(format: "This shot ran %.0fs %@ than your golden recipe (%.0fs).", abs(timeDelta), dir, golden.shotTime),
                systemImage: "timer"
            ))
        }
        if abs(brew.ratio - golden.ratio) >= 0.2 {
            tips.append(.init(
                severity: .adjust,
                text: "Ratio drifted from your golden \(golden.ratioLabel) to \(brew.ratioLabel).",
                systemImage: "arrow.left.and.right"
            ))
        }
        if tips.isEmpty {
            tips.append(.init(
                severity: .good,
                text: "Right on your golden recipe — nicely repeatable.",
                systemImage: "star.fill"
            ))
        }
        return tips
    }
}
