//
//  Cafe.swift
//  CremaDialed
//
//  A coffee location the user has discovered, anchored to a map coordinate.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class Cafe {
    var id: UUID
    var name: String
    var address: String
    var city: String
    var latitude: Double
    var longitude: Double
    var createdAt: Date

    /// Marked as a favourite coffee destination.
    var isFavourite: Bool
    /// On the personal "want to visit" wishlist (no visits required).
    var wantToVisit: Bool
    /// Personal notes about this café that persist across visits.
    var personalNotes: String

    @Relationship(deleteRule: .cascade, inverse: \CafeVisit.cafe) var visits: [CafeVisit] = []

    init(name: String, address: String = "", city: String = "", latitude: Double, longitude: Double,
         isFavourite: Bool = false, wantToVisit: Bool = false, personalNotes: String = "") {
        self.id = UUID()
        self.name = name
        self.address = address
        self.city = city
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = Date()
        self.isFavourite = isFavourite
        self.wantToVisit = wantToVisit
        self.personalNotes = personalNotes
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Average overall rating across all visits (0 when none).
    var averageRating: Double {
        guard !visits.isEmpty else { return 0 }
        return visits.map(\.averageScore).reduce(0, +) / Double(visits.count)
    }

    var lastVisit: Date? { visits.map(\.date).max() }

    /// Visits newest-first.
    var sortedVisits: [CafeVisit] {
        visits.sorted { $0.date > $1.date }
    }

    /// Cover image for the café — the cover photo of the most recent visit that has one.
    var coverPhoto: Data? {
        for visit in sortedVisits {
            if let cover = visit.coverPhoto { return cover }
        }
        return nil
    }

    /// Every photo across all visits, newest visit first.
    var allPhotos: [Data] {
        sortedVisits.flatMap(\.orderedPhotos)
    }

    /// The most frequently ordered drink across all visits.
    var favouriteDrink: CoffeeDrink? {
        guard !visits.isEmpty else { return nil }
        let counts = Dictionary(grouping: visits) { $0.drink }.mapValues(\.count)
        return counts.max { $0.value < $1.value }?.key
    }

    var hasVisited: Bool { !visits.isEmpty }
}
