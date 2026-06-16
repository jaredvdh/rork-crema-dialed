//
//  Machine.swift
//  CremaDialed
//

import Foundation
import SwiftData

@Model
final class Machine {
    var id: UUID
    var manufacturer: String
    var model: String
    var boilerTypeRaw: String
    var pumpTypeRaw: String
    var groupHeadRaw: String
    var hasIntegratedGrinder: Bool
    var photoData: Data?
    /// Filenames of attached manuals (PDF / guides) stored conceptually.
    var manualTitles: [String]
    var createdAt: Date

    // Machine-specific maintenance notes.
    var waterHardness: String
    var preferredCleaningProduct: String
    var lastServiceDate: Date?
    var manufacturerRecommendations: String
    var maintenanceNotes: String

    // Explicit inverse relationships to avoid ambiguous SwiftData inference.
    @Relationship(deleteRule: .nullify, inverse: \Brew.machine) var brews: [Brew] = []
    @Relationship(deleteRule: .nullify, inverse: \DialedRecipe.machine) var dialedRecipes: [DialedRecipe] = []
    @Relationship(deleteRule: .cascade, inverse: \MaintenanceLog.machine) var maintenanceLogs: [MaintenanceLog] = []
    @Relationship(deleteRule: .cascade, inverse: \MaintenanceReminder.machine) var maintenanceReminders: [MaintenanceReminder] = []

    init(
        manufacturer: String,
        model: String,
        boilerType: BoilerType = .singleBoiler,
        pumpType: PumpType = .vibratory,
        groupHead: GroupHeadType = .e61,
        hasIntegratedGrinder: Bool = false,
        photoData: Data? = nil
    ) {
        self.id = UUID()
        self.manufacturer = manufacturer
        self.model = model
        self.boilerTypeRaw = boilerType.rawValue
        self.pumpTypeRaw = pumpType.rawValue
        self.groupHeadRaw = groupHead.rawValue
        self.hasIntegratedGrinder = hasIntegratedGrinder
        self.photoData = photoData
        self.manualTitles = []
        self.createdAt = Date()
        self.waterHardness = ""
        self.preferredCleaningProduct = ""
        self.lastServiceDate = nil
        self.manufacturerRecommendations = ""
        self.maintenanceNotes = ""
    }

    var boilerType: BoilerType { BoilerType(rawValue: boilerTypeRaw) ?? .singleBoiler }
    var pumpType: PumpType { PumpType(rawValue: pumpTypeRaw) ?? .vibratory }
    var groupHead: GroupHeadType { GroupHeadType(rawValue: groupHeadRaw) ?? .e61 }
    var displayName: String { "\(manufacturer) \(model)" }
}
