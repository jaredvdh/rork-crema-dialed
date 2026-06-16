//
//  UnitPreferences.swift
//  CremaDialed
//
//  Central place for the user's measurement preferences (distance system and
//  temperature unit). Values are always stored internally in metric / Celsius;
//  these helpers convert for display only.
//

import Foundation

enum MeasurementSystem: String, CaseIterable, Identifiable {
    case metric
    case imperial

    var id: String { rawValue }
    var label: String { self == .metric ? "Metric" : "Imperial" }
    var caption: String { self == .metric ? "km · metres" : "miles · feet" }
}

enum TemperatureUnit: String, CaseIterable, Identifiable {
    case celsius
    case fahrenheit

    var id: String { rawValue }
    var label: String { self == .celsius ? "Celsius" : "Fahrenheit" }
    var symbol: String { self == .celsius ? "°C" : "°F" }
}

/// Reads the user's stored preferences and converts/format values for display.
/// Keys match the `@AppStorage` keys used by `SettingsView`.
enum UnitPreferences {
    static let systemKey = "measurementSystem"
    static let temperatureKey = "temperatureUnit"

    static var system: MeasurementSystem {
        MeasurementSystem(rawValue: UserDefaults.standard.string(forKey: systemKey) ?? "") ?? .metric
    }

    static var temperatureUnit: TemperatureUnit {
        TemperatureUnit(rawValue: UserDefaults.standard.string(forKey: temperatureKey) ?? "") ?? .celsius
    }

    // MARK: Temperature

    static func celsiusToFahrenheit(_ c: Double) -> Double { c * 9 / 5 + 32 }
    static func fahrenheitToCelsius(_ f: Double) -> Double { (f - 32) * 5 / 9 }

    /// A Celsius-stored temperature formatted in the user's preferred unit.
    static func temperatureLabel(celsius: Double) -> String {
        switch temperatureUnit {
        case .celsius: return String(format: "%.1f°C", celsius)
        case .fahrenheit: return String(format: "%.0f°F", celsiusToFahrenheit(celsius))
        }
    }

    // MARK: Distance

    /// A distance in metres formatted in the user's preferred system.
    static func distanceLabel(metres: Double) -> String {
        switch system {
        case .metric:
            if metres < 1000 { return "\(Int(metres))m away" }
            return String(format: "%.1fkm away", metres / 1000)
        case .imperial:
            let feet = metres * 3.28084
            if feet < 1000 { return "\(Int(feet))ft away" }
            return String(format: "%.1fmi away", metres / 1609.344)
        }
    }
}
