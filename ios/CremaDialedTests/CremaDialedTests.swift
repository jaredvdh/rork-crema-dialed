//
//  CremaDialedTests.swift
//  CremaDialedTests
//
//  Unit tests for the offline brewing intelligence: DialInCoach recommendations,
//  MaintenanceEngine reminder scheduling, and roast-freshness / golden-recipe math.
//

import Testing
import Foundation
@testable import CremaDialed

// MARK: - DialInCoach recommendation logic

@MainActor
struct DialInCoachTests {

    /// Helper to build a brew with sensible mid-range taste values.
    private func makeBrew(shotTime: Double = 28, dose: Double = 18, yield: Double = 36) -> Brew {
        let brew = Brew(dose: dose, yield: yield, shotTime: shotTime)
        return brew
    }

    @Test func fastShotRecommendsFinerGrind() {
        let brew = makeBrew(shotTime: 18)
        let tips = DialInCoach.analyze(brew)
        let first = try? #require(tips.first)
        #expect(first?.severity == .adjust)
        #expect(first?.text.contains("finer") == true)
        #expect(first?.systemImage == "timer")
    }

    @Test func slowShotRecommendsCoarserGrind() {
        let brew = makeBrew(shotTime: 42)
        let tips = DialInCoach.analyze(brew)
        #expect(tips.first?.severity == .adjust)
        #expect(tips.first?.text.contains("coarser") == true)
    }

    @Test func sweetSpotShotIsMarkedGood() {
        let brew = makeBrew(shotTime: 29)
        let tips = DialInCoach.analyze(brew)
        #expect(tips.first?.severity == .good)
    }

    @Test func highBitternessLowSweetnessFlagsOverExtraction() {
        let brew = makeBrew(shotTime: 29)
        brew.bitterness = 8
        brew.sweetness = 3
        let tips = DialInCoach.analyze(brew)
        #expect(tips.contains { $0.text.contains("over-extraction") })
    }

    @Test func sharpAcidityLowSweetnessFlagsUnderExtraction() {
        let brew = makeBrew(shotTime: 29)
        brew.acidity = 8
        brew.sweetness = 3
        let tips = DialInCoach.analyze(brew)
        #expect(tips.contains { $0.text.contains("under-extraction") })
    }

    @Test func tightRatioRaisesAlert() {
        // dose 20, yield 30 -> ratio 1.5 (< 1.6)
        let brew = makeBrew(shotTime: 29, dose: 20, yield: 30)
        let tips = DialInCoach.analyze(brew)
        #expect(tips.contains { $0.severity == .alert })
    }

    @Test func longRatioSuggestsPullingBack() {
        // dose 18, yield 54 -> ratio 3.0 (> 2.6)
        let brew = makeBrew(shotTime: 29, dose: 18, yield: 54)
        let tips = DialInCoach.analyze(brew)
        #expect(tips.contains { $0.text.contains("long") })
    }

    @Test func missingBeanProducesNoFreshnessTip() {
        // Edge case: no bean attached -> no roast-age advice, but still safe.
        let brew = makeBrew(shotTime: 29)
        #expect(brew.bean == nil)
        let tips = DialInCoach.analyze(brew)
        #expect(tips.contains { $0.text.contains("off roast") } == false)
    }

    @Test func freshBeanWarnsAboutDegassing() {
        let brew = makeBrew(shotTime: 29)
        let bean = Bean(name: "Test", roastDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()))
        brew.bean = bean
        let tips = DialInCoach.analyze(brew)
        #expect(tips.contains { $0.text.contains("degassing") })
    }

    @Test func grindAdviceUsesSteppedGrinderNumbers() {
        let brew = makeBrew(shotTime: 18)
        let grinder = Grinder(manufacturer: "Test", model: "Grinder", kind: .stepped)
        brew.grinder = grinder
        brew.grindSetting = "12"
        let tips = DialInCoach.analyze(brew)
        // Finer on a stepped grinder: 12 -> 10.
        #expect(tips.first?.text.contains("Grinder") == true)
        #expect(tips.first?.text.contains("10") == true)
    }

    @Test func compareToGoldenDetectsSlowerShot() {
        let brew = makeBrew(shotTime: 34, dose: 18, yield: 36)
        let goldenBrew = makeBrew(shotTime: 28, dose: 18, yield: 36)
        let golden = DialedRecipe(from: goldenBrew)
        let tips = DialInCoach.compareToGolden(brew, golden: golden)
        #expect(tips.contains { $0.text.contains("slower") })
    }

    @Test func compareToGoldenWhenOnTargetIsGood() {
        let brew = makeBrew(shotTime: 28, dose: 18, yield: 36)
        let goldenBrew = makeBrew(shotTime: 28, dose: 18, yield: 36)
        let golden = DialedRecipe(from: goldenBrew)
        let tips = DialInCoach.compareToGolden(brew, golden: golden)
        #expect(tips.count == 1)
        #expect(tips.first?.severity == .good)
    }
}

// MARK: - MaintenanceEngine scheduling

@MainActor
struct MaintenanceEngineTests {

    @Test func shotModeBecomesDueAtInterval() {
        let status = MaintenanceEngine.status(
            kind: .backflush, mode: .shots, intervalDays: 0, intervalShots: 50,
            lastDone: Date(), shotsSince: 50
        )
        #expect(status.isDue)
        #expect(status.progress >= 1.0)
    }

    @Test func shotModeNotDueBelowInterval() {
        let status = MaintenanceEngine.status(
            kind: .backflush, mode: .shots, intervalDays: 0, intervalShots: 50,
            lastDone: Date(), shotsSince: 10
        )
        #expect(status.isDue == false)
        #expect(status.summary.contains("40"))
    }

    @Test func shotModeWithZeroShotsIsNotDue() {
        // Edge case: nothing pulled yet.
        let status = MaintenanceEngine.status(
            kind: .clean, mode: .shots, intervalDays: 0, intervalShots: 15,
            lastDone: nil, shotsSince: 0
        )
        #expect(status.isDue == false)
        #expect(status.progress == 0)
    }

    @Test func shotModeGuardsAgainstZeroInterval() {
        // Edge case: a zero interval must not divide-by-zero; engine clamps to 1.
        let status = MaintenanceEngine.status(
            kind: .clean, mode: .shots, intervalDays: 0, intervalShots: 0,
            lastDone: nil, shotsSince: 1
        )
        #expect(status.progress.isFinite)
        #expect(status.isDue)
    }

    @Test func timeModeNeverLoggedIsDue() {
        // Edge case: missing lastDone in time mode -> always due.
        let status = MaintenanceEngine.status(
            kind: .descale, mode: .time, intervalDays: 90, intervalShots: 0,
            lastDone: nil, shotsSince: 0
        )
        #expect(status.isDue)
        #expect(status.summary == "Never logged")
    }

    @Test func timeModeNotYetDue() {
        let lastDone = Calendar.current.date(byAdding: .day, value: -10, to: Date())
        let status = MaintenanceEngine.status(
            kind: .descale, mode: .time, intervalDays: 90, intervalShots: 0,
            lastDone: lastDone, shotsSince: 0
        )
        #expect(status.isDue == false)
        #expect(status.progress < 1.0)
    }

    @Test func timeModeOverdue() {
        let lastDone = Calendar.current.date(byAdding: .day, value: -120, to: Date())
        let status = MaintenanceEngine.status(
            kind: .descale, mode: .time, intervalDays: 90, intervalShots: 0,
            lastDone: lastDone, shotsSince: 0
        )
        #expect(status.isDue)
        #expect(status.summary.contains("Overdue"))
    }

    @Test func offModeIsNeverDue() {
        let status = MaintenanceEngine.status(
            kind: .servicing, mode: .off, intervalDays: 180, intervalShots: 0,
            lastDone: nil, shotsSince: 0
        )
        #expect(status.isDue == false)
        #expect(status.summary == "Not tracked")
    }

    @Test func applicableKindsExcludeGrinderTasksWithoutGrinder() {
        let withoutGrinder = MaintenanceEngine.applicableKinds(hasGrinder: false)
        #expect(withoutGrinder.contains(.grinderClean) == false)
        #expect(withoutGrinder.contains(.burrReplacement) == false)
        let withGrinder = MaintenanceEngine.applicableKinds(hasGrinder: true)
        #expect(withGrinder.contains(.grinderClean))
    }
}

// MARK: - Roast freshness & Golden Recipe calculations

@MainActor
struct FreshnessAndRatioTests {

    @Test func daysOffRoastNilWhenNoRoastDate() {
        // Edge case: missing optional roast date.
        let bean = Bean(name: "Mystery")
        #expect(bean.daysOffRoast == nil)
        #expect(bean.freshnessLabel == "Roast date unknown")
    }

    @Test func freshnessLabelRestingWindow() {
        let bean = Bean(name: "Fresh", roastDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()))
        #expect(bean.freshnessLabel.contains("Resting"))
    }

    @Test func freshnessLabelPeakWindow() {
        let bean = Bean(name: "Peak", roastDate: Calendar.current.date(byAdding: .day, value: -10, to: Date()))
        #expect(bean.freshnessLabel.contains("Peak window"))
    }

    @Test func freshnessLabelPastPeak() {
        let bean = Bean(name: "Old", roastDate: Calendar.current.date(byAdding: .day, value: -45, to: Date()))
        #expect(bean.freshnessLabel.contains("Past peak"))
    }

    @Test func brewRatioComputesCorrectly() {
        let brew = Brew(dose: 18, yield: 36)
        #expect(abs(brew.ratio - 2.0) < 0.0001)
        #expect(brew.ratioLabel == "1:2.0")
    }

    @Test func brewRatioGuardsAgainstZeroDose() {
        // Edge case: zero dose must not divide-by-zero.
        let brew = Brew(dose: 0, yield: 36)
        #expect(brew.ratio == 0)
    }

    @Test func dialedRecipeCarriesOverScoreAndRatio() {
        let brew = Brew(dose: 20, yield: 40)
        brew.overall = 9
        let recipe = DialedRecipe(from: brew)
        #expect(recipe.score == 9)
        #expect(abs(recipe.ratio - 2.0) < 0.0001)
        #expect(recipe.ratioLabel == "1:2.0")
    }
}
