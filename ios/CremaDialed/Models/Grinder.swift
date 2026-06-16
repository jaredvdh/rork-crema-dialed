//
//  Grinder.swift
//  CremaDialed
//

import Foundation
import SwiftData

@Model
final class Grinder {
    var id: UUID
    var manufacturer: String
    var model: String
    var kindRaw: String
    var burrTypeRaw: String
    var burrSizeMM: Int
    /// True when this represents a machine's built-in grinder.
    var isIntegrated: Bool
    /// Reference point for stepless grinders (e.g. "zero chirp").
    var referencePoint: String
    var createdAt: Date

    // Explicit inverse relationships to avoid ambiguous SwiftData inference.
    @Relationship(deleteRule: .nullify, inverse: \Brew.grinder) var brews: [Brew] = []
    @Relationship(deleteRule: .nullify, inverse: \DialedRecipe.grinder) var dialedRecipes: [DialedRecipe] = []

    init(
        manufacturer: String,
        model: String,
        kind: GrinderKind = .stepped,
        burrType: BurrType = .conical,
        burrSizeMM: Int = 54,
        isIntegrated: Bool = false,
        referencePoint: String = ""
    ) {
        self.id = UUID()
        self.manufacturer = manufacturer
        self.model = model
        self.kindRaw = kind.rawValue
        self.burrTypeRaw = burrType.rawValue
        self.burrSizeMM = burrSizeMM
        self.isIntegrated = isIntegrated
        self.referencePoint = referencePoint
        self.createdAt = Date()
    }

    var kind: GrinderKind { GrinderKind(rawValue: kindRaw) ?? .stepped }
    var burrType: BurrType { BurrType(rawValue: burrTypeRaw) ?? .conical }
    var displayName: String { "\(manufacturer) \(model)" }
}
