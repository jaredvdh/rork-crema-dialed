//
//  Brew.swift
//  CremaDialed
//
//  A single dialed-in espresso shot with parameters and taste evaluation.
//

import Foundation
import SwiftData

@Model
final class Brew {
    var id: UUID
    var date: Date

    // Relationships
    var bean: Bean?
    var machine: Machine?
    var grinder: Grinder?

    // Brew parameters
    var dose: Double          // grams in
    var yield: Double         // grams out
    var shotTime: Double      // seconds
    var grindSetting: String  // stepped number / stepless dial
    var grindTime: Double     // seconds (time-based grinders)
    var waterTemp: Double     // celsius
    var pressure: Double      // bar
    var preInfusion: Double   // seconds
    var basketSize: Int       // grams basket capacity
    var basketRaw: String     // Single / Double / Triple
    var filterType: String
    var notes: String

    // Taste evaluation (1...10)
    var acidity: Int
    var sweetness: Int
    var body: Int
    var bitterness: Int
    var balance: Int
    var aftertaste: Int
    var overall: Int
    var flavourNotesRaw: [String]

    // Quick one-tap outcome ("" when not set) — stored against the bean to help
    // the recipe converge over time.
    var outcomeRaw: String

    // Future-ready measurement fields (0 / nil when unmeasured). Reserved for
    // crema/extraction analysis, Bluetooth scales and automated dial-in.
    var flowRate: Double          // ml/s
    var tds: Double               // total dissolved solids %
    var extractionYield: Double   // EY %
    var machineNotes: String
    var waterRecipe: String
    var cremaPhotoData: Data?

    var isGolden: Bool

    init(
        bean: Bean? = nil,
        machine: Machine? = nil,
        grinder: Grinder? = nil,
        dose: Double = 18,
        yield: Double = 36,
        shotTime: Double = 28,
        grindSetting: String = "",
        grindTime: Double = 0,
        waterTemp: Double = 93,
        pressure: Double = 9,
        preInfusion: Double = 0,
        basketSize: Int = 18,
        basket: BasketSize = .double,
        filterType: String = "Double"
    ) {
        self.id = UUID()
        self.date = Date()
        self.bean = bean
        self.machine = machine
        self.grinder = grinder
        self.dose = dose
        self.yield = yield
        self.shotTime = shotTime
        self.grindSetting = grindSetting
        self.grindTime = grindTime
        self.waterTemp = waterTemp
        self.pressure = pressure
        self.preInfusion = preInfusion
        self.basketSize = basketSize
        self.basketRaw = basket.rawValue
        self.filterType = filterType
        self.notes = ""
        self.acidity = 5
        self.sweetness = 5
        self.body = 5
        self.bitterness = 5
        self.balance = 5
        self.aftertaste = 5
        self.overall = 5
        self.flavourNotesRaw = []
        self.outcomeRaw = ""
        self.flowRate = 0
        self.tds = 0
        self.extractionYield = 0
        self.machineNotes = ""
        self.waterRecipe = ""
        self.cremaPhotoData = nil
        self.isGolden = false
    }

    var outcome: ShotOutcome? { ShotOutcome(rawValue: outcomeRaw) }
    var basket: BasketSize { BasketSize(rawValue: basketRaw) ?? .double }

    var ratio: Double { dose > 0 ? yield / dose : 0 }
    var ratioLabel: String { String(format: "1:%.1f", ratio) }

    var flavourNotes: [FlavourNote] {
        flavourNotesRaw.compactMap { FlavourNote(rawValue: $0) }
    }
}
