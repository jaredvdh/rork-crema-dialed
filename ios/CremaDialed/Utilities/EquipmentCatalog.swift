//
//  EquipmentCatalog.swift
//  CremaDialed
//
//  Bundled starter database of popular machines and grinders for quick setup.
//

import Foundation

struct MachineTemplate: Identifiable, Hashable {
    let id = UUID()
    let manufacturer: String
    let model: String
    let boiler: BoilerType
    let pump: PumpType
    let group: GroupHeadType
    let integratedGrinder: Bool
    var displayName: String { "\(manufacturer) \(model)" }
}

struct GrinderTemplate: Identifiable, Hashable {
    let id = UUID()
    let manufacturer: String
    let model: String
    let kind: GrinderKind
    let burr: BurrType
    let burrSize: Int
    var displayName: String { "\(manufacturer) \(model)" }
}

enum EquipmentCatalog {
    static let machines: [MachineTemplate] = [
        // De'Longhi
        .init(manufacturer: "De'Longhi", model: "Dedica EC685", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "De'Longhi", model: "La Specialista Arte", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: true),
        .init(manufacturer: "De'Longhi", model: "La Specialista Maestro", boiler: .dualBoiler, pump: .vibratory, group: .proprietary, integratedGrinder: true),
        .init(manufacturer: "De'Longhi", model: "Magnifica Evo", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: true),
        .init(manufacturer: "De'Longhi", model: "Eletta Explore", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: true),
        .init(manufacturer: "De'Longhi", model: "Dinamica Plus", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: true),

        // Breville / Sage (Sage is Breville's EU/UK brand)
        .init(manufacturer: "Breville", model: "Bambino", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "Breville", model: "Bambino Plus", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "Breville", model: "Barista Express", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: true),
        .init(manufacturer: "Breville", model: "Barista Express Impress", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: true),
        .init(manufacturer: "Breville", model: "Barista Pro", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: true),
        .init(manufacturer: "Breville", model: "Barista Touch", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: true),
        .init(manufacturer: "Breville", model: "Barista Touch Impress", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: true),
        .init(manufacturer: "Breville", model: "Dual Boiler", boiler: .dualBoiler, pump: .vibratory, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "Breville", model: "Oracle", boiler: .dualBoiler, pump: .vibratory, group: .proprietary, integratedGrinder: true),
        .init(manufacturer: "Breville", model: "Oracle Touch", boiler: .dualBoiler, pump: .vibratory, group: .proprietary, integratedGrinder: true),
        .init(manufacturer: "Breville", model: "Oracle Jet", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: true),
        .init(manufacturer: "Sage", model: "Bambino", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "Sage", model: "Bambino Plus", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "Sage", model: "Barista Express", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: true),
        .init(manufacturer: "Sage", model: "Barista Express Impress", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: true),
        .init(manufacturer: "Sage", model: "Barista Pro", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: true),
        .init(manufacturer: "Sage", model: "Barista Touch", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: true),
        .init(manufacturer: "Sage", model: "Dual Boiler", boiler: .dualBoiler, pump: .vibratory, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "Sage", model: "Oracle Touch", boiler: .dualBoiler, pump: .vibratory, group: .proprietary, integratedGrinder: true),

        // KitchenAid
        .init(manufacturer: "KitchenAid", model: "Artisan Espresso KES6403", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "KitchenAid", model: "Semi-Automatic KES6551", boiler: .dualBoiler, pump: .vibratory, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "KitchenAid", model: "Metal Espresso KES6404", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: false),

        // Ninja
        .init(manufacturer: "Ninja", model: "Luxe Café", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: true),
        .init(manufacturer: "Ninja", model: "Espresso & Barista", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: false),

        // Sunbeam
        .init(manufacturer: "Sunbeam", model: "Café Series EM7000", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "Sunbeam", model: "Mini Barista EM5000", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: true),
        .init(manufacturer: "Sunbeam", model: "Barista Max", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: true),

        // Smeg
        .init(manufacturer: "Smeg", model: "ECF01", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "Smeg", model: "ECF02", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "Smeg", model: "BCC02 Bean to Cup", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: true),

        // Philips / Saeco
        .init(manufacturer: "Philips", model: "3200 LatteGo", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: true),
        .init(manufacturer: "Philips", model: "5400 LatteGo", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: true),
        .init(manufacturer: "Saeco", model: "Xelsis", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: true),

        // Jura
        .init(manufacturer: "Jura", model: "E8", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: true),
        .init(manufacturer: "Jura", model: "ENA 8", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: true),

        // Italian / prosumer
        .init(manufacturer: "Rancilio", model: "Silvia", boiler: .singleBoiler, pump: .vibratory, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "Rancilio", model: "Silvia Pro X", boiler: .dualBoiler, pump: .vibratory, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "Gaggia", model: "Classic Pro", boiler: .singleBoiler, pump: .vibratory, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "Gaggia", model: "Classic Evo Pro", boiler: .singleBoiler, pump: .vibratory, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "Lelit", model: "Anna", boiler: .singleBoiler, pump: .vibratory, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "Lelit", model: "MaraX", boiler: .heatExchanger, pump: .vibratory, group: .e61, integratedGrinder: false),
        .init(manufacturer: "Lelit", model: "Bianca", boiler: .dualBoiler, pump: .rotary, group: .e61, integratedGrinder: false),
        .init(manufacturer: "Lelit", model: "Elizabeth", boiler: .dualBoiler, pump: .vibratory, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "Profitec", model: "Pro 300", boiler: .dualBoiler, pump: .vibratory, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "Profitec", model: "Pro 600", boiler: .dualBoiler, pump: .vibratory, group: .e61, integratedGrinder: false),
        .init(manufacturer: "Profitec", model: "Pro 700", boiler: .dualBoiler, pump: .rotary, group: .e61, integratedGrinder: false),
        .init(manufacturer: "ECM", model: "Classika", boiler: .heatExchanger, pump: .vibratory, group: .e61, integratedGrinder: false),
        .init(manufacturer: "ECM", model: "Synchronika", boiler: .dualBoiler, pump: .rotary, group: .e61, integratedGrinder: false),
        .init(manufacturer: "Rocket", model: "Appartamento", boiler: .heatExchanger, pump: .vibratory, group: .e61, integratedGrinder: false),
        .init(manufacturer: "Rocket", model: "Mozzafiato", boiler: .heatExchanger, pump: .vibratory, group: .e61, integratedGrinder: false),
        .init(manufacturer: "Rocket", model: "R58", boiler: .dualBoiler, pump: .rotary, group: .e61, integratedGrinder: false),
        .init(manufacturer: "La Marzocco", model: "Linea Mini", boiler: .dualBoiler, pump: .rotary, group: .saturated, integratedGrinder: false),
        .init(manufacturer: "La Marzocco", model: "Linea Micra", boiler: .dualBoiler, pump: .vibratory, group: .saturated, integratedGrinder: false),
        .init(manufacturer: "La Marzocco", model: "GS3", boiler: .dualBoiler, pump: .rotary, group: .saturated, integratedGrinder: false),
        .init(manufacturer: "Ascaso", model: "Steel Duo", boiler: .dualBoiler, pump: .vibratory, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "Bezzera", model: "BZ10", boiler: .heatExchanger, pump: .vibratory, group: .e61, integratedGrinder: false),
        .init(manufacturer: "Quick Mill", model: "Rubino", boiler: .heatExchanger, pump: .vibratory, group: .e61, integratedGrinder: false),
        .init(manufacturer: "Nuova Simonelli", model: "Oscar II", boiler: .heatExchanger, pump: .vibratory, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "Bezzera", model: "Duo DE", boiler: .dualBoiler, pump: .rotary, group: .e61, integratedGrinder: false),

        // Manual / lever / portable
        .init(manufacturer: "Flair", model: "58", boiler: .singleBoiler, pump: .manualLever, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "Flair", model: "Pro 2", boiler: .singleBoiler, pump: .manualLever, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "La Pavoni", model: "Europiccola", boiler: .singleBoiler, pump: .manualLever, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "Cafelat", model: "Robot", boiler: .singleBoiler, pump: .manualLever, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "Wacaco", model: "Nanopresso", boiler: .singleBoiler, pump: .manualLever, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "9Barista", model: "Espresso Machine", boiler: .singleBoiler, pump: .spring, group: .proprietary, integratedGrinder: false)
    ]

    static let grinders: [GrinderTemplate] = [
        // Breville / Sage
        .init(manufacturer: "Breville", model: "Smart Grinder Pro", kind: .stepped, burr: .conical, burrSize: 40),
        .init(manufacturer: "Breville", model: "Dose Control Pro", kind: .stepped, burr: .conical, burrSize: 40),
        .init(manufacturer: "Sage", model: "Smart Grinder Pro", kind: .stepped, burr: .conical, burrSize: 40),
        .init(manufacturer: "Sage", model: "Dose Control Pro", kind: .stepped, burr: .conical, burrSize: 40),

        // De'Longhi / Eureka / Italian
        .init(manufacturer: "De'Longhi", model: "Dedica Grinder KG521", kind: .stepped, burr: .conical, burrSize: 40),
        .init(manufacturer: "Eureka", model: "Mignon Specialita", kind: .stepless, burr: .flat, burrSize: 55),
        .init(manufacturer: "Eureka", model: "Mignon Silenzio", kind: .stepless, burr: .flat, burrSize: 50),
        .init(manufacturer: "Eureka", model: "Mignon XL", kind: .stepless, burr: .flat, burrSize: 65),
        .init(manufacturer: "Eureka", model: "Atom 75", kind: .stepless, burr: .flat, burrSize: 75),
        .init(manufacturer: "Mazzer", model: "Mini", kind: .stepless, burr: .flat, burrSize: 64),
        .init(manufacturer: "Mazzer", model: "Super Jolly", kind: .stepless, burr: .flat, burrSize: 64),
        .init(manufacturer: "Mazzer", model: "Philos", kind: .stepless, burr: .conical, burrSize: 71),
        .init(manufacturer: "Ceado", model: "E37S", kind: .stepless, burr: .flat, burrSize: 83),

        // Niche / Baratza / DF
        .init(manufacturer: "Niche", model: "Zero", kind: .stepless, burr: .conical, burrSize: 63),
        .init(manufacturer: "Niche", model: "Duo", kind: .stepless, burr: .conical, burrSize: 83),
        .init(manufacturer: "Baratza", model: "Encore ESP", kind: .stepped, burr: .conical, burrSize: 40),
        .init(manufacturer: "Baratza", model: "Sette 270", kind: .stepped, burr: .conical, burrSize: 40),
        .init(manufacturer: "Baratza", model: "Vario+", kind: .stepped, burr: .flat, burrSize: 54),
        .init(manufacturer: "DF64", model: "Gen 2", kind: .stepless, burr: .flat, burrSize: 64),
        .init(manufacturer: "DF64", model: "V", kind: .stepless, burr: .flat, burrSize: 64),
        .init(manufacturer: "Turin", model: "DF83", kind: .stepless, burr: .flat, burrSize: 83),

        // Fellow / Weber / Timemore / Wilfa
        .init(manufacturer: "Fellow", model: "Ode Gen 2", kind: .stepped, burr: .flat, burrSize: 64),
        .init(manufacturer: "Fellow", model: "Opus", kind: .stepped, burr: .conical, burrSize: 40),
        .init(manufacturer: "Weber", model: "Key", kind: .stepless, burr: .flat, burrSize: 83),
        .init(manufacturer: "Weber", model: "EG-1", kind: .stepless, burr: .flat, burrSize: 80),
        .init(manufacturer: "Timemore", model: "Sculptor 078", kind: .stepless, burr: .conical, burrSize: 78),
        .init(manufacturer: "Wilfa", model: "Uniform", kind: .stepped, burr: .flat, burrSize: 58),

        // Hand grinders
        .init(manufacturer: "1Zpresso", model: "J-Max", kind: .stepped, burr: .conical, burrSize: 48),
        .init(manufacturer: "1Zpresso", model: "K-Ultra", kind: .stepped, burr: .conical, burrSize: 48),
        .init(manufacturer: "1Zpresso", model: "ZP6", kind: .stepped, burr: .conical, burrSize: 47),
        .init(manufacturer: "Comandante", model: "C40", kind: .stepped, burr: .conical, burrSize: 39),
        .init(manufacturer: "Kingrinder", model: "K6", kind: .stepped, burr: .conical, burrSize: 48),
        .init(manufacturer: "Timemore", model: "Chestnut C3", kind: .stepped, burr: .conical, burrSize: 38)
    ]
}
