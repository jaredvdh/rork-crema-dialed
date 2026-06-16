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
        .init(manufacturer: "Breville", model: "Barista Express", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: true),
        .init(manufacturer: "Sage", model: "Barista Touch", boiler: .thermoblock, pump: .vibratory, group: .proprietary, integratedGrinder: true),
        .init(manufacturer: "Breville", model: "Dual Boiler", boiler: .dualBoiler, pump: .vibratory, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "Rancilio", model: "Silvia", boiler: .singleBoiler, pump: .vibratory, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "Gaggia", model: "Classic Pro", boiler: .singleBoiler, pump: .vibratory, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "Lelit", model: "Bianca", boiler: .dualBoiler, pump: .rotary, group: .e61, integratedGrinder: false),
        .init(manufacturer: "Profitec", model: "Pro 600", boiler: .dualBoiler, pump: .vibratory, group: .e61, integratedGrinder: false),
        .init(manufacturer: "ECM", model: "Synchronika", boiler: .dualBoiler, pump: .rotary, group: .e61, integratedGrinder: false),
        .init(manufacturer: "La Marzocco", model: "Linea Mini", boiler: .dualBoiler, pump: .rotary, group: .saturated, integratedGrinder: false),
        .init(manufacturer: "Rocket", model: "Appartamento", boiler: .heatExchanger, pump: .vibratory, group: .e61, integratedGrinder: false),
        .init(manufacturer: "Flair", model: "58", boiler: .singleBoiler, pump: .manualLever, group: .proprietary, integratedGrinder: false),
        .init(manufacturer: "La Pavoni", model: "Europiccola", boiler: .singleBoiler, pump: .manualLever, group: .proprietary, integratedGrinder: false)
    ]

    static let grinders: [GrinderTemplate] = [
        .init(manufacturer: "Niche", model: "Zero", kind: .stepless, burr: .conical, burrSize: 63),
        .init(manufacturer: "Eureka", model: "Mignon Specialita", kind: .stepless, burr: .flat, burrSize: 55),
        .init(manufacturer: "Baratza", model: "Sette 270", kind: .stepped, burr: .conical, burrSize: 40),
        .init(manufacturer: "DF64", model: "Gen 2", kind: .stepless, burr: .flat, burrSize: 64),
        .init(manufacturer: "1Zpresso", model: "J-Max", kind: .stepped, burr: .conical, burrSize: 48),
        .init(manufacturer: "Comandante", model: "C40", kind: .stepped, burr: .conical, burrSize: 39),
        .init(manufacturer: "Mazzer", model: "Mini", kind: .stepless, burr: .flat, burrSize: 64),
        .init(manufacturer: "Fellow", model: "Ode Gen 2", kind: .stepped, burr: .flat, burrSize: 64),
        .init(manufacturer: "Weber", model: "Key", kind: .stepless, burr: .flat, burrSize: 83),
        .init(manufacturer: "Timemore", model: "Sculptor 078", kind: .stepless, burr: .conical, burrSize: 78)
    ]
}
