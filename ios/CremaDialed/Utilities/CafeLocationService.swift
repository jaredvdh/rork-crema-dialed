//
//  CafeLocationService.swift
//  CremaDialed
//
//  Wraps Core Location + MapKit to find nearby cafés and search globally.
//

import Foundation
import CoreLocation
import MapKit
import UIKit

/// A lightweight value describing a café found via MapKit search.
struct CafeResult: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let address: String
    let city: String
    let coordinate: CLLocationCoordinate2D
    /// Metres from the user, if a location is available.
    var distance: Double?
    /// MapKit category, used to recognise genuine coffee venues.
    var category: MKPointOfInterestCategory?

    /// Whether this looks like a genuine coffee venue (café, bakery, or a
    /// coffee-named place) rather than fast food or general retail.
    var isCoffeePlace: Bool {
        if category == .cafe || category == .bakery { return true }
        let lower = name.lowercased()
        let keywords = ["coffee", "café", "cafe", "espresso", "roaster", "roastery",
                        "brew", "barista", "latte", "bean"]
        return keywords.contains { lower.contains($0) }
    }

    var distanceLabel: String? {
        guard let distance else { return nil }
        return UnitPreferences.distanceLabel(metres: distance)
    }

    static func == (lhs: CafeResult, rhs: CafeResult) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

@Observable
final class CafeLocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    private(set) var authorization: CLAuthorizationStatus
    private(set) var userLocation: CLLocationCoordinate2D?
    private(set) var nearby: [CafeResult] = []
    private(set) var isSearching = false
    private(set) var errorMessage: String?

    override init() {
        authorization = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var isDenied: Bool {
        authorization == .denied || authorization == .restricted
    }

    /// The closest discovered café when the user is within check-in range
    /// (≈100m). Drives the contextual "Check In Nearby" prompt so a check-in
    /// button only appears when the user has genuinely arrived somewhere.
    var arrivedCafe: CafeResult? {
        guard userLocation != nil else { return nil }
        guard let closest = nearby.first,
              let distance = closest.distance, distance <= 100 else { return nil }
        return closest
    }

    /// Ask for permission and, once granted, fetch the current location.
    func requestAndLocate() {
        switch authorization {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }

    // MARK: CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorization = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coord = locations.last?.coordinate else { return }
        Task { @MainActor in
            self.userLocation = coord
            await self.searchNearbyCafes()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = "Couldn't determine your location."
        }
    }

    // MARK: Search

    /// Find cafés around the user's current location, sorted by distance.
    ///
    /// A single MapKit POI request filtered to `.cafe` misses a lot of real
    /// coffee shops — many are tagged as bakeries, restaurants, or carry no
    /// category at all, and some only ever surface through a text search. To
    /// make discovery reliable we run several strategies concurrently and merge
    /// the results:
    ///   1. A POI request including café + bakery + restaurant categories.
    ///   2. Natural-language searches for "coffee" and "espresso" near the user.
    /// Everything is de-duplicated and filtered down to genuine coffee venues.
    func searchNearbyCafes() async {
        guard let center = userLocation else { return }
        isSearching = true
        errorMessage = nil

        let radius: CLLocationDistance = 5000
        let region = MKCoordinateRegion(center: center,
                                        latitudinalMeters: radius * 2,
                                        longitudinalMeters: radius * 2)

        async let poiResults = runPOISearch(center: center, radius: radius)
        async let coffeeResults = runQuerySearch("coffee", region: region, from: center)
        async let espressoResults = runQuerySearch("espresso", region: region, from: center)

        let combined = await (poiResults + coffeeResults + espressoResults)
        let coffeeOnly = combined.filter { $0.isCoffeePlace && ($0.distance ?? .greatestFiniteMagnitude) <= radius * 1.5 }
        let merged = deduplicate(coffeeOnly)

        if merged.isEmpty && combined.isEmpty {
            errorMessage = "Couldn't load nearby cafés."
        }
        nearby = merged
        isSearching = false
    }

    /// MapKit points-of-interest request across the categories coffee venues
    /// commonly fall under.
    private func runPOISearch(center: CLLocationCoordinate2D, radius: CLLocationDistance) async -> [CafeResult] {
        let request = MKLocalPointsOfInterestRequest(center: center, radius: radius)
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.cafe, .bakery, .restaurant])
        do {
            let response = try await MKLocalSearch(request: request).start()
            return mapResults(response.mapItems, from: center)
        } catch {
            return []
        }
    }

    /// Natural-language MapKit search constrained to the user's region.
    private func runQuerySearch(_ query: String, region: MKCoordinateRegion, from center: CLLocationCoordinate2D) async -> [CafeResult] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region
        request.resultTypes = .pointOfInterest
        do {
            let response = try await MKLocalSearch(request: request).start()
            return mapResults(response.mapItems, from: center)
        } catch {
            return []
        }
    }

    /// Collapse results that point at the same venue (same name within ~50m),
    /// keeping the closest instance, then sort by distance.
    private func deduplicate(_ results: [CafeResult]) -> [CafeResult] {
        var unique: [CafeResult] = []
        for result in results.sorted(by: { ($0.distance ?? .greatestFiniteMagnitude) < ($1.distance ?? .greatestFiniteMagnitude) }) {
            let key = result.name.lowercased().trimmingCharacters(in: .whitespaces)
            let isDuplicate = unique.contains { existing in
                existing.name.lowercased().trimmingCharacters(in: .whitespaces) == key &&
                Self.metresBetween(existing.coordinate, result.coordinate) < 50
            }
            if !isDuplicate { unique.append(result) }
        }
        return unique
    }

    private static func metresBetween(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
    }

    /// Search any café globally by text query. Coffee venues are surfaced first,
    /// but manual searches can still reach anything the user explicitly types.
    func search(query: String) async -> [CafeResult] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        if let center = userLocation {
            request.region = MKCoordinateRegion(center: center,
                                                latitudinalMeters: 50000,
                                                longitudinalMeters: 50000)
        }
        do {
            let response = try await MKLocalSearch(request: request).start()
            let mapped = mapResults(response.mapItems, from: userLocation)
            // Coffee places first, then everything else (still available on manual search).
            return mapped.sorted { lhs, rhs in
                if lhs.isCoffeePlace != rhs.isCoffeePlace { return lhs.isCoffeePlace }
                return (lhs.distance ?? .greatestFiniteMagnitude) < (rhs.distance ?? .greatestFiniteMagnitude)
            }
        } catch {
            return []
        }
    }

    private func mapResults(_ items: [MKMapItem], from center: CLLocationCoordinate2D?) -> [CafeResult] {
        let origin = center.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }
        let results: [CafeResult] = items.compactMap { item in
            guard let name = item.name else { return nil }
            let placemark = item.placemark
            let coord = placemark.coordinate
            var distance: Double?
            if let origin {
                distance = origin.distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude))
            }
            let street = [placemark.subThoroughfare, placemark.thoroughfare]
                .compactMap { $0 }.joined(separator: " ")
            return CafeResult(
                name: name,
                address: street,
                city: placemark.locality ?? "",
                coordinate: coord,
                distance: distance,
                category: item.pointOfInterestCategory
            )
        }
        return results.sorted { ($0.distance ?? .greatestFiniteMagnitude) < ($1.distance ?? .greatestFiniteMagnitude) }
    }
}

/// Launches Apple Maps with turn-by-turn directions to a coordinate.
enum MapsLauncher {
    static func directions(to coordinate: CLLocationCoordinate2D, name: String) {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        item.name = name.isEmpty ? "Café" : name
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault
        ])
    }
}

/// Finds the saved café that corresponds to a discovered search result, if any
/// (same name within ~120m), so Nearby cards can surface personal ratings.
func matchingCafe(for result: CafeResult, in cafes: [Cafe]) -> Cafe? {
    let key = result.name.lowercased().trimmingCharacters(in: .whitespaces)
    return cafes.first { cafe in
        guard cafe.name.lowercased().trimmingCharacters(in: .whitespaces) == key else { return false }
        let a = CLLocation(latitude: cafe.latitude, longitude: cafe.longitude)
        let b = CLLocation(latitude: result.coordinate.latitude, longitude: result.coordinate.longitude)
        return a.distance(from: b) < 120
    }
}
