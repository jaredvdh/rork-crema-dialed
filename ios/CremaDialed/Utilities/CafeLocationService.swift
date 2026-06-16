//
//  CafeLocationService.swift
//  CremaDialed
//
//  Wraps Core Location + MapKit to find nearby cafés and search globally.
//

import Foundation
import CoreLocation
import MapKit

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
        if distance < 1000 { return "\(Int(distance))m away" }
        return String(format: "%.1fkm away", distance / 1000)
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
    /// Strictly limited to coffee points of interest so fast food and general
    /// retail never break the experience.
    func searchNearbyCafes() async {
        guard let center = userLocation else { return }
        isSearching = true
        errorMessage = nil
        let request = MKLocalPointsOfInterestRequest(center: center, radius: 4000)
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.cafe])
        do {
            let response = try await MKLocalSearch(request: request).start()
            let mapped = mapResults(response.mapItems, from: center)
            nearby = mapped.filter { $0.isCoffeePlace }
        } catch {
            errorMessage = "Couldn't load nearby cafés."
        }
        isSearching = false
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
