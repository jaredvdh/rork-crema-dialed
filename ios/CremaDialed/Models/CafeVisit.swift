//
//  CafeVisit.swift
//  CremaDialed
//
//  A single check-in at a café — the drink, six rating dimensions, notes and photos.
//

import Foundation
import SwiftData

@Model
final class CafeVisit {
    var id: UUID
    var date: Date
    var cafe: Cafe?

    var drinkRaw: String
    var notes: String
    var photosData: [Data]
    /// Optional caption per photo, parallel to `photosData`.
    var photoCaptions: [String]
    /// Index of the cover photo within `photosData`.
    var coverIndex: Int

    // Quick rating (always set): a 1...10 coffee score plus a would-return flag.
    /// The primary 1...10 coffee score for this visit.
    var coffeeScore: Int
    var overallRating: Int
    var wouldReturn: Bool
    /// True once the user has expanded and edited the detailed ratings.
    var usedAdvanced: Bool

    // One-tap impressions (stored as raw values for forward compatibility).
    var coffeeTags: [String]
    var venueTags: [String]

    // Detailed ratings (1...10). 0 means "not rated".
    var coffeeQuality: Int
    var milkQuality: Int
    var extractionQuality: Int
    var temperature: Int
    var value: Int
    var atmosphere: Int
    var service: Int
    var consistency: Int
    var foodQuality: Int

    init(
        cafe: Cafe? = nil,
        drink: CoffeeDrink = .flatWhite,
        notes: String = "",
        photosData: [Data] = [],
        photoCaptions: [String] = [],
        coverIndex: Int = 0,
        coffeeScore: Int = 8,
        coffeeTags: [String] = [],
        venueTags: [String] = [],
        overallRating: Int = 8,
        wouldReturn: Bool = false,
        usedAdvanced: Bool = false,
        coffeeQuality: Int = 7,
        milkQuality: Int = 7,
        extractionQuality: Int = 7,
        temperature: Int = 7,
        value: Int = 7,
        atmosphere: Int = 7,
        service: Int = 7,
        consistency: Int = 7,
        foodQuality: Int = 0
    ) {
        self.id = UUID()
        self.date = Date()
        self.cafe = cafe
        self.drinkRaw = drink.rawValue
        self.notes = notes
        self.photosData = photosData
        self.photoCaptions = photoCaptions
        self.coverIndex = coverIndex
        self.coffeeScore = coffeeScore
        self.coffeeTags = coffeeTags
        self.venueTags = venueTags
        self.overallRating = overallRating
        self.wouldReturn = wouldReturn
        self.usedAdvanced = usedAdvanced
        self.coffeeQuality = coffeeQuality
        self.milkQuality = milkQuality
        self.extractionQuality = extractionQuality
        self.temperature = temperature
        self.value = value
        self.atmosphere = atmosphere
        self.service = service
        self.consistency = consistency
        self.foodQuality = foodQuality
    }

    var drink: CoffeeDrink { CoffeeDrink(rawValue: drinkRaw) ?? .flatWhite }

    /// Photos ordered with the chosen cover image first.
    var orderedPhotos: [Data] {
        guard photosData.indices.contains(coverIndex), coverIndex != 0 else { return photosData }
        var ordered = photosData
        let cover = ordered.remove(at: coverIndex)
        ordered.insert(cover, at: 0)
        return ordered
    }

    /// The cover image for this visit (chosen cover, else first photo).
    var coverPhoto: Data? {
        if photosData.indices.contains(coverIndex) { return photosData[coverIndex] }
        return photosData.first
    }

    var coffeeTagValues: [CoffeeTag] { coffeeTags.compactMap { CoffeeTag(rawValue: $0) } }
    var venueTagValues: [VenueTag] { venueTags.compactMap { VenueTag(rawValue: $0) } }

    /// Overall score for dashboards. Uses the coffee score unless the user
    /// filled in the detailed dimensions, in which case they are averaged.
    var averageScore: Double {
        guard usedAdvanced else { return Double(coffeeScore) }
        let dims = [coffeeQuality, milkQuality, extractionQuality, temperature,
                    value, atmosphere, service, consistency].filter { $0 > 0 }
        guard !dims.isEmpty else { return Double(coffeeScore) }
        return Double(dims.reduce(0, +)) / Double(dims.count)
    }
}
