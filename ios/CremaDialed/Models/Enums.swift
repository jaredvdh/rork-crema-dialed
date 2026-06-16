//
//  Enums.swift
//  CremaDialed
//
//  Shared value types describing equipment and coffee characteristics.
//

import Foundation

enum BoilerType: String, CaseIterable, Codable, Identifiable {
    case thermoblock = "Thermoblock"
    case singleBoiler = "Single Boiler"
    case heatExchanger = "Heat Exchanger"
    case dualBoiler = "Dual Boiler"
    var id: String { rawValue }
}

enum PumpType: String, CaseIterable, Codable, Identifiable {
    case vibratory = "Vibratory"
    case rotary = "Rotary"
    case manualLever = "Manual Lever"
    case spring = "Spring Lever"
    var id: String { rawValue }
}

enum GroupHeadType: String, CaseIterable, Codable, Identifiable {
    case e61 = "E61"
    case saturated = "Saturated"
    case semiSaturated = "Semi-Saturated"
    case proprietary = "Proprietary"
    var id: String { rawValue }
}

enum GrinderKind: String, CaseIterable, Codable, Identifiable {
    case stepped = "Stepped"
    case stepless = "Stepless"
    case timeBased = "Time-Based"
    case weightBased = "Weight-Based"
    var id: String { rawValue }

    var detail: String {
        switch self {
        case .stepped: return "Discrete click settings"
        case .stepless: return "Continuous dial position"
        case .timeBased: return "Grind by time"
        case .weightBased: return "Grind by target dose"
        }
    }
}

enum BurrType: String, CaseIterable, Codable, Identifiable {
    case conical = "Conical"
    case flat = "Flat"
    case ghost = "Ghost"
    var id: String { rawValue }
}

enum RoastLevel: String, CaseIterable, Codable, Identifiable {
    case light = "Light"
    case mediumLight = "Medium-Light"
    case medium = "Medium"
    case mediumDark = "Medium-Dark"
    case dark = "Dark"
    var id: String { rawValue }
}

enum ProcessMethod: String, CaseIterable, Codable, Identifiable {
    case washed = "Washed"
    case natural = "Natural"
    case honey = "Honey"
    case anaerobic = "Anaerobic"
    case other = "Other"
    var id: String { rawValue }
}

/// Basket size used for the shot — refers to physical basket capacity, not the drink.
enum BasketSize: String, CaseIterable, Codable, Identifiable {
    case single = "Single"
    case double = "Double"
    case triple = "Triple"
    var id: String { rawValue }

    /// Typical dose range midpoint in grams — a sensible default for the basket.
    var typicalDose: Double {
        switch self {
        case .single: return 9
        case .double: return 18
        case .triple: return 21
        }
    }

    var systemImage: String {
        switch self {
        case .single: return "circle"
        case .double: return "circle.circle"
        case .triple: return "circle.circle.fill"
        }
    }
}

/// One-tap shot outcome used for fast feedback after pulling a shot.
enum ShotOutcome: String, CaseIterable, Codable, Identifiable {
    case tooSour = "Too Sour"
    case tooBitter = "Too Bitter"
    case tooFast = "Too Fast"
    case tooSlow = "Too Slow"
    case perfect = "Perfect"
    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .tooSour: return "bolt.fill"
        case .tooBitter: return "flame.fill"
        case .tooFast: return "hare.fill"
        case .tooSlow: return "tortoise.fill"
        case .perfect: return "checkmark.seal.fill"
        }
    }

    /// Suggested grind adjustment for the next shot.
    var suggestion: String {
        switch self {
        case .tooSour: return "Under-extracted — grind finer to draw out more sweetness."
        case .tooBitter: return "Over-extracted — grind coarser to ease back the bitterness."
        case .tooFast: return "Flow too quick — grind finer to slow the shot down."
        case .tooSlow: return "Flow too slow — grind coarser to open the shot up."
        case .perfect: return "Dialed in — save this as your golden recipe."
        }
    }

    var isPositive: Bool { self == .perfect }
}

/// How a maintenance reminder is scheduled.
enum MaintenanceFrequencyMode: String, CaseIterable, Codable, Identifiable {
    case time = "By Time"
    case shots = "By Coffees"
    case off = "No Reminder"
    var id: String { rawValue }
}

enum MaintenanceKind: String, CaseIterable, Codable, Identifiable {
    case clean = "Clean & Wipe Down"
    case backflush = "Backflush"
    case groupHead = "Group Head & Screen"
    case descale = "Descale"
    case waterFilter = "Water Filter"
    case grinderClean = "Grinder Clean"
    case burrReplacement = "Burr Replacement"
    case groupGasket = "Group Gasket"
    case servicing = "General Service"
    var id: String { rawValue }

    /// Tasks that only make sense when a grinder is attached or integrated.
    var isGrinderTask: Bool {
        switch self {
        case .grinderClean, .burrReplacement: return true
        default: return false
        }
    }

    var systemImage: String {
        switch self {
        case .clean: return "sparkles"
        case .backflush: return "arrow.triangle.2.circlepath"
        case .groupHead: return "shower.fill"
        case .descale: return "drop.triangle"
        case .waterFilter: return "line.3.horizontal.decrease.circle"
        case .grinderClean: return "dial.high.fill"
        case .burrReplacement: return "gearshape.2"
        case .groupGasket: return "circle.circle"
        case .servicing: return "wrench.and.screwdriver"
        }
    }

    var detail: String {
        switch self {
        case .clean: return "Wipe the group, wand and drip tray."
        case .backflush: return "Flush the group with water or detergent."
        case .groupHead: return "Remove and clean the shower screen."
        case .descale: return "Clear scale from the boiler and lines."
        case .waterFilter: return "Swap the in-tank water filter."
        case .grinderClean: return "Brush out retained grounds and fines."
        case .burrReplacement: return "Fit fresh burrs for clean cutting."
        case .groupGasket: return "Replace the worn group gasket."
        case .servicing: return "Full descale, gasket and seal service."
        }
    }

    /// Default reminder mode for this task.
    var defaultMode: MaintenanceFrequencyMode {
        switch self {
        case .clean, .backflush, .groupHead, .grinderClean: return .shots
        default: return .time
        }
    }

    /// Recommended interval in days for time-based reminders.
    var intervalDays: Int {
        switch self {
        case .clean: return 1
        case .backflush: return 7
        case .groupHead: return 14
        case .descale: return 90
        case .waterFilter: return 60
        case .grinderClean: return 30
        case .burrReplacement: return 365
        case .groupGasket: return 365
        case .servicing: return 180
        }
    }

    /// Recommended interval in number of coffees for shot-based reminders.
    var intervalShots: Int {
        switch self {
        case .clean: return 15
        case .backflush: return 50
        case .groupHead: return 100
        case .descale: return 600
        case .waterFilter: return 400
        case .grinderClean: return 250
        case .burrReplacement: return 4000
        case .groupGasket: return 3000
        case .servicing: return 1200
        }
    }
}

/// Drinks orderable at a café check-in.
enum CoffeeDrink: String, CaseIterable, Codable, Identifiable {
    case espresso = "Espresso"
    case ristretto = "Ristretto"
    case flatWhite = "Flat White"
    case cappuccino = "Cappuccino"
    case latte = "Latte"
    case cortado = "Cortado"
    case macchiato = "Macchiato"
    case mocha = "Mocha"
    case longBlack = "Long Black"
    case americano = "Americano"
    case pourOver = "Pour Over"
    case filter = "Filter Coffee"
    case coldBrew = "Cold Brew"
    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .espresso, .ristretto, .longBlack, .americano: return "cup.and.saucer.fill"
        case .flatWhite, .cappuccino, .latte, .cortado, .macchiato, .mocha: return "cup.and.heat.waves.fill"
        case .pourOver, .filter: return "drop.fill"
        case .coldBrew: return "snowflake"
        }
    }

    /// A short descriptor shown on the visual drink card.
    var blurb: String {
        switch self {
        case .espresso: return "Pure shot"
        case .ristretto: return "Short & sweet"
        case .flatWhite: return "Silky microfoam"
        case .cappuccino: return "Foamy classic"
        case .latte: return "Milky & smooth"
        case .cortado: return "Balanced & small"
        case .macchiato: return "Marked shot"
        case .mocha: return "Chocolate twist"
        case .longBlack: return "Bold & black"
        case .americano: return "Diluted shot"
        case .pourOver: return "Bright filter"
        case .filter: return "Batch brew"
        case .coldBrew: return "Slow & cold"
        }
    }

    /// Whether this drink contains milk (used to weight milk-quality insights).
    var hasMilk: Bool {
        switch self {
        case .flatWhite, .cappuccino, .latte, .cortado, .macchiato, .mocha: return true
        default: return false
        }
    }
}

/// One-tap coffee impressions captured during a café check-in.
enum CoffeeTag: String, CaseIterable, Codable, Identifiable {
    case balanced = "Balanced"
    case fruity = "Fruity"
    case chocolatey = "Chocolatey"
    case sweet = "Sweet"
    case nutty = "Nutty"
    case bright = "Bright"
    case complex = "Complex"
    case smooth = "Smooth"
    case bitter = "Bitter"
    case sour = "Sour"
    case greatMilk = "Excellent Milk Texture"
    case greatEspresso = "Great Espresso"
    case greatLatteArt = "Great Latte Art"
    var id: String { rawValue }
}

/// One-tap venue impressions captured during a café check-in.
enum VenueTag: String, CaseIterable, Codable, Identifiable {
    case friendlyStaff = "Friendly Staff"
    case beautifulSpace = "Beautiful Space"
    case quiet = "Quiet"
    case busy = "Busy"
    case workSpot = "Great Work Spot"
    case fastService = "Fast Service"
    case goodFood = "Good Food"
    case greatAtmosphere = "Great Atmosphere"
    var id: String { rawValue }
}

/// Curated flavour wheel categories used in taste evaluation.
enum FlavourNote: String, CaseIterable, Codable, Identifiable {
    case chocolate = "Chocolate"
    case caramel = "Caramel"
    case nutty = "Nutty"
    case berry = "Berry"
    case citrus = "Citrus"
    case stoneFruit = "Stone Fruit"
    case floral = "Floral"
    case spice = "Spice"
    case vanilla = "Vanilla"
    case honey = "Honey"
    case wine = "Wine"
    case earthy = "Earthy"
    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .chocolate: return "🍫"
        case .caramel: return "🍯"
        case .nutty: return "🥜"
        case .berry: return "🫐"
        case .citrus: return "🍋"
        case .stoneFruit: return "🍑"
        case .floral: return "🌸"
        case .spice: return "🌶️"
        case .vanilla: return "🍦"
        case .honey: return "🐝"
        case .wine: return "🍷"
        case .earthy: return "🍂"
        }
    }
}
