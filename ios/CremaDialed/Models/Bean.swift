//
//  Bean.swift
//  CremaDialed
//

import Foundation
import SwiftData

@Model
final class Bean {
    var id: UUID
    var name: String
    var roaster: String
    var country: String
    var region: String
    var farm: String
    var variety: String
    var processRaw: String
    var roastLevelRaw: String
    var roastDate: Date?
    var purchaseDate: Date?
    var notes: String
    var photoData: Data?
    var isFinished: Bool
    var createdAt: Date

    // Inverse relationships — declared explicitly so SwiftData does not have to
    // infer inverses (ambiguous when multiple models reference Bean).
    @Relationship(deleteRule: .nullify, inverse: \Brew.bean) var brews: [Brew] = []
    @Relationship(deleteRule: .nullify, inverse: \DialedRecipe.bean) var dialedRecipes: [DialedRecipe] = []

    init(
        name: String,
        roaster: String = "",
        country: String = "",
        region: String = "",
        farm: String = "",
        variety: String = "",
        process: ProcessMethod = .washed,
        roastLevel: RoastLevel = .medium,
        roastDate: Date? = nil,
        purchaseDate: Date? = nil,
        notes: String = "",
        photoData: Data? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.roaster = roaster
        self.country = country
        self.region = region
        self.farm = farm
        self.variety = variety
        self.processRaw = process.rawValue
        self.roastLevelRaw = roastLevel.rawValue
        self.roastDate = roastDate
        self.purchaseDate = purchaseDate
        self.notes = notes
        self.photoData = photoData
        self.isFinished = false
        self.createdAt = Date()
    }

    var process: ProcessMethod { ProcessMethod(rawValue: processRaw) ?? .washed }
    var roastLevel: RoastLevel { RoastLevel(rawValue: roastLevelRaw) ?? .medium }

    /// Days elapsed since the roast date, if known.
    var daysOffRoast: Int? {
        guard let roastDate else { return nil }
        return Calendar.current.dateComponents([.day], from: roastDate, to: Date()).day
    }

    /// Human-readable freshness window guidance.
    var freshnessLabel: String {
        guard let days = daysOffRoast else { return "Roast date unknown" }
        switch days {
        case ..<4: return "Resting — \(days)d off roast"
        case 4...18: return "Peak window — \(days)d off roast"
        case 19...30: return "Mature — \(days)d off roast"
        default: return "Past peak — \(days)d off roast"
        }
    }

    var originLine: String {
        [region, country].filter { !$0.isEmpty }.joined(separator: ", ")
    }
}
