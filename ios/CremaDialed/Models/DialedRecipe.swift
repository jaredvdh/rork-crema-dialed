//
//  DialedRecipe.swift
//  CremaDialed
//
//  A saved "golden" reference recipe for a bean.
//

import Foundation
import SwiftData

@Model
final class DialedRecipe {
    var id: UUID
    var bean: Bean?
    var machine: Machine?
    var grinder: Grinder?
    var dose: Double
    var yield: Double
    var shotTime: Double
    var grindSetting: String
    var waterTemp: Double
    var basketRaw: String
    var score: Int
    var createdAt: Date

    init(from brew: Brew) {
        self.id = UUID()
        self.bean = brew.bean
        self.machine = brew.machine
        self.grinder = brew.grinder
        self.dose = brew.dose
        self.yield = brew.yield
        self.shotTime = brew.shotTime
        self.grindSetting = brew.grindSetting
        self.waterTemp = brew.waterTemp
        self.basketRaw = brew.basketRaw
        self.score = brew.overall
        self.createdAt = Date()
    }

    var ratio: Double { dose > 0 ? yield / dose : 0 }
    var ratioLabel: String { String(format: "1:%.1f", ratio) }
    var basket: BasketSize { BasketSize(rawValue: basketRaw) ?? .double }
}
