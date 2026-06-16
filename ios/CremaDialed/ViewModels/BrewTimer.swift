//
//  BrewTimer.swift
//  CremaDialed
//
//  Drives the immersive extraction experience. The official shot time begins
//  at the FIRST DRIP — not pump start or pre-infusion — because pre-infusion
//  behaviour varies wildly between machines.
//

import Foundation
import Combine

@Observable
final class BrewTimer {
    /// Stages of the extraction ritual.
    enum Phase {
        case ready       // armed, waiting for the first visible drip
        case extracting  // counting the official shot time
        case finished    // stopped, results frozen
    }

    /// Educational extraction stages that update automatically as the shot runs.
    /// Time thresholds are relative to first drip.
    enum ExtractionStage: String {
        case preInfusion = "Pre-Infusion"
        case firstDrops = "First Drops"
        case bodyBuilding = "Body Building"
        case sweetSpot = "Sweet Spot"
        case blonding = "Blonding"

        var detail: String {
            switch self {
            case .preInfusion: return "Bed saturating, pressure building"
            case .firstDrops: return "Espresso begins to flow"
            case .bodyBuilding: return "Rich body and sweetness developing"
            case .sweetSpot: return "Balanced extraction — the good stuff"
            case .blonding: return "Flow lightening — consider stopping"
            }
        }
    }

    private(set) var phase: Phase = .ready
    private(set) var elapsed: Double = 0
    private(set) var stage: ExtractionStage = .preInfusion

    /// Target extraction window (inclusive seconds).
    var targetLow: Double = 26
    var targetHigh: Double = 32

    // Optional golden-recipe targets shown on the extraction screen.
    var goldenTime: Double?
    var goldenYield: Double?
    var goldenDose: Double?
    var goldenTemp: Double?
    var goldenBasket: String?
    var hasGolden: Bool { goldenTime != nil }

    private var timer: AnyCancellable?
    private var startReference: Date?
    private var didEnterRange = false
    private var didReachGolden = false

    /// True once the shot time is within the target window.
    var isInTargetRange: Bool {
        elapsed >= targetLow && elapsed <= targetHigh
    }

    /// True once extraction has run past the upper target bound.
    var isOverTarget: Bool { elapsed > targetHigh }

    var targetLabel: String { "\(Int(targetLow))–\(Int(targetHigh))s" }

    /// Normalised progress toward the upper target bound (0...1).
    var progress: Double {
        guard targetHigh > 0 else { return 0 }
        return min(elapsed / targetHigh, 1)
    }

    /// Begin counting the official shot time from the first drip.
    func firstDrip() {
        guard phase == .ready else { return }
        phase = .extracting
        elapsed = 0
        didEnterRange = false
        didReachGolden = false
        stage = .firstDrops
        startReference = Date()
        HapticEngine.success() // milestone: first drops
        timer = Timer.publish(every: 0.03, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let ref = self.startReference else { return }
                self.elapsed = Date().timeIntervalSince(ref)
                self.updateStage()
                if !self.didEnterRange && self.elapsed >= self.targetLow {
                    self.didEnterRange = true
                    HapticEngine.tap() // milestone: entered target range
                }
                if let gt = self.goldenTime, !self.didReachGolden, self.elapsed >= gt {
                    self.didReachGolden = true
                    HapticEngine.success() // milestone: golden target reached
                }
            }
    }

    /// Map elapsed time to an educational extraction stage.
    private func updateStage() {
        let new: ExtractionStage
        switch elapsed {
        case ..<3: new = .firstDrops
        case 3..<targetLow: new = .bodyBuilding
        case targetLow...targetHigh: new = .sweetSpot
        default: new = .blonding
        }
        if new != stage { stage = new }
    }

    /// Freeze the timer and present results.
    func stop() {
        guard phase == .extracting else { return }
        phase = .finished
        startReference = nil
        timer?.cancel()
        HapticEngine.warning()
    }

    /// Re-arm for a fresh shot.
    func reset() {
        phase = .ready
        elapsed = 0
        stage = .preInfusion
        didEnterRange = false
        didReachGolden = false
        startReference = nil
        timer?.cancel()
    }

    /// Load golden-recipe targets to personalise the extraction screen.
    func loadGolden(time: Double?, yield: Double?, dose: Double?, temp: Double?, basket: String?) {
        goldenTime = time
        goldenYield = yield
        goldenDose = dose
        goldenTemp = temp
        goldenBasket = basket
    }

    func clearGolden() {
        goldenTime = nil; goldenYield = nil; goldenDose = nil; goldenTemp = nil; goldenBasket = nil
    }

    /// Configure the target window around a desired shot time.
    func configure(targetTime: Double) {
        targetLow = max(18, (targetTime - 2).rounded())
        targetHigh = (targetTime + 2).rounded()
    }
}
