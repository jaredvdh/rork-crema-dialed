//
//  BackupService.swift
//  CremaDialed
//
//  Encodes the user's coffee data into a portable JSON snapshot and restores it
//  by UUID, reconstructing relationships. Photos are intentionally excluded to
//  keep backups small and shareable; everything else round-trips.
//

import Foundation
import SwiftData

// MARK: - Transferable snapshot DTOs (background-safe)

nonisolated struct CremaBackup: Codable {
    var version: Int = 1
    var exportedAt: Date = Date()
    var beans: [BeanDTO] = []
    var machines: [MachineDTO] = []
    var grinders: [GrinderDTO] = []
    var brews: [BrewDTO] = []
    var recipes: [RecipeDTO] = []
    var maintenanceLogs: [MaintenanceLogDTO] = []
    var maintenanceReminders: [MaintenanceReminderDTO] = []
    var cafes: [CafeDTO] = []
    var cafeVisits: [CafeVisitDTO] = []
}

nonisolated struct BeanDTO: Codable {
    var id: UUID
    var name: String
    var roaster: String
    var country: String
    var region: String
    var farm: String
    var variety: String
    var processRaw: String
    var roastLevelRaw: String
    var roastDate: Date?
    var purchaseDate: Date?
    var notes: String
    var isFinished: Bool
    var createdAt: Date
}

nonisolated struct MachineDTO: Codable {
    var id: UUID
    var manufacturer: String
    var model: String
    var boilerTypeRaw: String
    var pumpTypeRaw: String
    var groupHeadRaw: String
    var hasIntegratedGrinder: Bool
    var manualTitles: [String]
    var createdAt: Date
    var waterHardness: String
    var preferredCleaningProduct: String
    var lastServiceDate: Date?
    var manufacturerRecommendations: String
    var maintenanceNotes: String
}

nonisolated struct GrinderDTO: Codable {
    var id: UUID
    var manufacturer: String
    var model: String
    var kindRaw: String
    var burrTypeRaw: String
    var burrSizeMM: Int
    var isIntegrated: Bool
    var referencePoint: String
    var createdAt: Date
}

nonisolated struct BrewDTO: Codable {
    var id: UUID
    var date: Date
    var beanID: UUID?
    var machineID: UUID?
    var grinderID: UUID?
    var dose: Double
    var yield: Double
    var shotTime: Double
    var grindSetting: String
    var grindTime: Double
    var waterTemp: Double
    var pressure: Double
    var preInfusion: Double
    var basketSize: Int
    var basketRaw: String
    var filterType: String
    var notes: String
    var acidity: Int
    var sweetness: Int
    var body: Int
    var bitterness: Int
    var balance: Int
    var aftertaste: Int
    var overall: Int
    var flavourNotesRaw: [String]
    var outcomeRaw: String
    var flowRate: Double
    var tds: Double
    var extractionYield: Double
    var machineNotes: String
    var waterRecipe: String
    var isGolden: Bool
}

nonisolated struct RecipeDTO: Codable {
    var id: UUID
    var beanID: UUID?
    var machineID: UUID?
    var grinderID: UUID?
    var dose: Double
    var yield: Double
    var shotTime: Double
    var grindSetting: String
    var waterTemp: Double
    var basketRaw: String
    var score: Int
    var createdAt: Date
}

nonisolated struct MaintenanceLogDTO: Codable {
    var id: UUID
    var kindRaw: String
    var machineID: UUID?
    var date: Date
    var notes: String
}

nonisolated struct MaintenanceReminderDTO: Codable {
    var id: UUID
    var machineID: UUID?
    var kindRaw: String
    var modeRaw: String
    var intervalDays: Int
    var intervalShots: Int
    var createdAt: Date
}

nonisolated struct CafeDTO: Codable {
    var id: UUID
    var name: String
    var address: String
    var city: String
    var latitude: Double
    var longitude: Double
    var createdAt: Date
    var isFavourite: Bool
    var wantToVisit: Bool
    var personalNotes: String
}

nonisolated struct CafeVisitDTO: Codable {
    var id: UUID
    var date: Date
    var cafeID: UUID?
    var drinkRaw: String
    var notes: String
    var beanID: UUID?
    var coffeeScore: Int
    var overallRating: Int
    var wouldReturn: Bool
    var usedAdvanced: Bool
    var coffeeTags: [String]
    var venueTags: [String]
    var coffeeQuality: Int
    var milkQuality: Int
    var extractionQuality: Int
    var temperature: Int
    var value: Int
    var atmosphere: Int
    var service: Int
    var consistency: Int
    var foodQuality: Int
}

/// Summary of a completed import, used to inform the user.
struct ImportSummary {
    var beans = 0
    var machines = 0
    var grinders = 0
    var brews = 0
    var recipes = 0
    var cafes = 0
    var visits = 0

    var total: Int { beans + machines + grinders + brews + recipes + cafes + visits }
}

@MainActor
enum BackupService {
    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    /// Build a snapshot of everything currently stored.
    static func makeBackup(context: ModelContext) -> CremaBackup {
        var backup = CremaBackup()

        backup.beans = ((try? context.fetch(FetchDescriptor<Bean>())) ?? []).map { b in
            BeanDTO(id: b.id, name: b.name, roaster: b.roaster, country: b.country,
                    region: b.region, farm: b.farm, variety: b.variety,
                    processRaw: b.processRaw, roastLevelRaw: b.roastLevelRaw,
                    roastDate: b.roastDate, purchaseDate: b.purchaseDate, notes: b.notes,
                    isFinished: b.isFinished, createdAt: b.createdAt)
        }
        backup.machines = ((try? context.fetch(FetchDescriptor<Machine>())) ?? []).map { m in
            MachineDTO(id: m.id, manufacturer: m.manufacturer, model: m.model,
                       boilerTypeRaw: m.boilerTypeRaw, pumpTypeRaw: m.pumpTypeRaw,
                       groupHeadRaw: m.groupHeadRaw, hasIntegratedGrinder: m.hasIntegratedGrinder,
                       manualTitles: m.manualTitles, createdAt: m.createdAt,
                       waterHardness: m.waterHardness, preferredCleaningProduct: m.preferredCleaningProduct,
                       lastServiceDate: m.lastServiceDate,
                       manufacturerRecommendations: m.manufacturerRecommendations,
                       maintenanceNotes: m.maintenanceNotes)
        }
        backup.grinders = ((try? context.fetch(FetchDescriptor<Grinder>())) ?? []).map { g in
            GrinderDTO(id: g.id, manufacturer: g.manufacturer, model: g.model,
                       kindRaw: g.kindRaw, burrTypeRaw: g.burrTypeRaw, burrSizeMM: g.burrSizeMM,
                       isIntegrated: g.isIntegrated, referencePoint: g.referencePoint,
                       createdAt: g.createdAt)
        }
        backup.brews = ((try? context.fetch(FetchDescriptor<Brew>())) ?? []).map { b in
            BrewDTO(id: b.id, date: b.date, beanID: b.bean?.id, machineID: b.machine?.id,
                    grinderID: b.grinder?.id, dose: b.dose, yield: b.yield, shotTime: b.shotTime,
                    grindSetting: b.grindSetting, grindTime: b.grindTime, waterTemp: b.waterTemp,
                    pressure: b.pressure, preInfusion: b.preInfusion, basketSize: b.basketSize,
                    basketRaw: b.basketRaw, filterType: b.filterType, notes: b.notes,
                    acidity: b.acidity, sweetness: b.sweetness, body: b.body, bitterness: b.bitterness,
                    balance: b.balance, aftertaste: b.aftertaste, overall: b.overall,
                    flavourNotesRaw: b.flavourNotesRaw, outcomeRaw: b.outcomeRaw, flowRate: b.flowRate,
                    tds: b.tds, extractionYield: b.extractionYield, machineNotes: b.machineNotes,
                    waterRecipe: b.waterRecipe, isGolden: b.isGolden)
        }
        backup.recipes = ((try? context.fetch(FetchDescriptor<DialedRecipe>())) ?? []).map { r in
            RecipeDTO(id: r.id, beanID: r.bean?.id, machineID: r.machine?.id, grinderID: r.grinder?.id,
                      dose: r.dose, yield: r.yield, shotTime: r.shotTime, grindSetting: r.grindSetting,
                      waterTemp: r.waterTemp, basketRaw: r.basketRaw, score: r.score, createdAt: r.createdAt)
        }
        backup.maintenanceLogs = ((try? context.fetch(FetchDescriptor<MaintenanceLog>())) ?? []).map { l in
            MaintenanceLogDTO(id: l.id, kindRaw: l.kindRaw, machineID: l.machine?.id,
                              date: l.date, notes: l.notes)
        }
        backup.maintenanceReminders = ((try? context.fetch(FetchDescriptor<MaintenanceReminder>())) ?? []).map { r in
            MaintenanceReminderDTO(id: r.id, machineID: r.machine?.id, kindRaw: r.kindRaw,
                                   modeRaw: r.modeRaw, intervalDays: r.intervalDays,
                                   intervalShots: r.intervalShots, createdAt: r.createdAt)
        }
        backup.cafes = ((try? context.fetch(FetchDescriptor<Cafe>())) ?? []).map { c in
            CafeDTO(id: c.id, name: c.name, address: c.address, city: c.city,
                    latitude: c.latitude, longitude: c.longitude, createdAt: c.createdAt,
                    isFavourite: c.isFavourite, wantToVisit: c.wantToVisit, personalNotes: c.personalNotes)
        }
        backup.cafeVisits = ((try? context.fetch(FetchDescriptor<CafeVisit>())) ?? []).map { v in
            CafeVisitDTO(id: v.id, date: v.date, cafeID: v.cafe?.id, drinkRaw: v.drinkRaw,
                         notes: v.notes, beanID: v.beanID, coffeeScore: v.coffeeScore,
                         overallRating: v.overallRating, wouldReturn: v.wouldReturn,
                         usedAdvanced: v.usedAdvanced, coffeeTags: v.coffeeTags, venueTags: v.venueTags,
                         coffeeQuality: v.coffeeQuality, milkQuality: v.milkQuality,
                         extractionQuality: v.extractionQuality, temperature: v.temperature,
                         value: v.value, atmosphere: v.atmosphere, service: v.service,
                         consistency: v.consistency, foodQuality: v.foodQuality)
        }

        return backup
    }

    /// Encode a snapshot to a temporary `.cremabackup` file for sharing.
    static func writeBackupFile(_ backup: CremaBackup) throws -> URL {
        let data = try encoder().encode(backup)
        let name = "CremaDialed-\(Self.fileStamp()).cremabackup"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func fileStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        return formatter.string(from: Date())
    }

    /// Merge a snapshot into the store, skipping records whose id already
    /// exists so re-importing never duplicates data.
    @discardableResult
    static func restore(_ backup: CremaBackup, into context: ModelContext) -> ImportSummary {
        var summary = ImportSummary()

        let existingBeans = Set(((try? context.fetch(FetchDescriptor<Bean>())) ?? []).map(\.id))
        let existingMachines = Set(((try? context.fetch(FetchDescriptor<Machine>())) ?? []).map(\.id))
        let existingGrinders = Set(((try? context.fetch(FetchDescriptor<Grinder>())) ?? []).map(\.id))
        let existingBrews = Set(((try? context.fetch(FetchDescriptor<Brew>())) ?? []).map(\.id))
        let existingRecipes = Set(((try? context.fetch(FetchDescriptor<DialedRecipe>())) ?? []).map(\.id))
        let existingLogs = Set(((try? context.fetch(FetchDescriptor<MaintenanceLog>())) ?? []).map(\.id))
        let existingReminders = Set(((try? context.fetch(FetchDescriptor<MaintenanceReminder>())) ?? []).map(\.id))
        let existingCafes = Set(((try? context.fetch(FetchDescriptor<Cafe>())) ?? []).map(\.id))
        let existingVisits = Set(((try? context.fetch(FetchDescriptor<CafeVisit>())) ?? []).map(\.id))

        var beanByID: [UUID: Bean] = [:]
        for bean in (try? context.fetch(FetchDescriptor<Bean>())) ?? [] {
            beanByID[bean.id] = bean
        }
        var machineByID: [UUID: Machine] = [:]
        for machine in (try? context.fetch(FetchDescriptor<Machine>())) ?? [] {
            machineByID[machine.id] = machine
        }
        var grinderByID: [UUID: Grinder] = [:]
        for grinder in (try? context.fetch(FetchDescriptor<Grinder>())) ?? [] {
            grinderByID[grinder.id] = grinder
        }
        var cafeByID: [UUID: Cafe] = [:]
        for cafe in (try? context.fetch(FetchDescriptor<Cafe>())) ?? [] {
            cafeByID[cafe.id] = cafe
        }

        for dto in backup.beans where !existingBeans.contains(dto.id) {
            let bean = Bean(name: dto.name)
            bean.id = dto.id
            bean.roaster = dto.roaster
            bean.country = dto.country
            bean.region = dto.region
            bean.farm = dto.farm
            bean.variety = dto.variety
            bean.processRaw = dto.processRaw
            bean.roastLevelRaw = dto.roastLevelRaw
            bean.roastDate = dto.roastDate
            bean.purchaseDate = dto.purchaseDate
            bean.notes = dto.notes
            bean.isFinished = dto.isFinished
            bean.createdAt = dto.createdAt
            context.insert(bean)
            beanByID[dto.id] = bean
            summary.beans += 1
        }

        for dto in backup.machines where !existingMachines.contains(dto.id) {
            let machine = Machine(manufacturer: dto.manufacturer, model: dto.model)
            machine.id = dto.id
            machine.boilerTypeRaw = dto.boilerTypeRaw
            machine.pumpTypeRaw = dto.pumpTypeRaw
            machine.groupHeadRaw = dto.groupHeadRaw
            machine.hasIntegratedGrinder = dto.hasIntegratedGrinder
            machine.manualTitles = dto.manualTitles
            machine.createdAt = dto.createdAt
            machine.waterHardness = dto.waterHardness
            machine.preferredCleaningProduct = dto.preferredCleaningProduct
            machine.lastServiceDate = dto.lastServiceDate
            machine.manufacturerRecommendations = dto.manufacturerRecommendations
            machine.maintenanceNotes = dto.maintenanceNotes
            context.insert(machine)
            machineByID[dto.id] = machine
            summary.machines += 1
        }

        for dto in backup.grinders where !existingGrinders.contains(dto.id) {
            let grinder = Grinder(manufacturer: dto.manufacturer, model: dto.model)
            grinder.id = dto.id
            grinder.kindRaw = dto.kindRaw
            grinder.burrTypeRaw = dto.burrTypeRaw
            grinder.burrSizeMM = dto.burrSizeMM
            grinder.isIntegrated = dto.isIntegrated
            grinder.referencePoint = dto.referencePoint
            grinder.createdAt = dto.createdAt
            context.insert(grinder)
            grinderByID[dto.id] = grinder
            summary.grinders += 1
        }

        for dto in backup.cafes where !existingCafes.contains(dto.id) {
            let cafe = Cafe(name: dto.name, latitude: dto.latitude, longitude: dto.longitude)
            cafe.id = dto.id
            cafe.address = dto.address
            cafe.city = dto.city
            cafe.createdAt = dto.createdAt
            cafe.isFavourite = dto.isFavourite
            cafe.wantToVisit = dto.wantToVisit
            cafe.personalNotes = dto.personalNotes
            context.insert(cafe)
            cafeByID[dto.id] = cafe
            summary.cafes += 1
        }

        for dto in backup.brews where !existingBrews.contains(dto.id) {
            let brew = Brew()
            brew.id = dto.id
            brew.date = dto.date
            brew.bean = dto.beanID.flatMap { beanByID[$0] }
            brew.machine = dto.machineID.flatMap { machineByID[$0] }
            brew.grinder = dto.grinderID.flatMap { grinderByID[$0] }
            brew.dose = dto.dose
            brew.yield = dto.yield
            brew.shotTime = dto.shotTime
            brew.grindSetting = dto.grindSetting
            brew.grindTime = dto.grindTime
            brew.waterTemp = dto.waterTemp
            brew.pressure = dto.pressure
            brew.preInfusion = dto.preInfusion
            brew.basketSize = dto.basketSize
            brew.basketRaw = dto.basketRaw
            brew.filterType = dto.filterType
            brew.notes = dto.notes
            brew.acidity = dto.acidity
            brew.sweetness = dto.sweetness
            brew.body = dto.body
            brew.bitterness = dto.bitterness
            brew.balance = dto.balance
            brew.aftertaste = dto.aftertaste
            brew.overall = dto.overall
            brew.flavourNotesRaw = dto.flavourNotesRaw
            brew.outcomeRaw = dto.outcomeRaw
            brew.flowRate = dto.flowRate
            brew.tds = dto.tds
            brew.extractionYield = dto.extractionYield
            brew.machineNotes = dto.machineNotes
            brew.waterRecipe = dto.waterRecipe
            brew.isGolden = dto.isGolden
            context.insert(brew)
            summary.brews += 1
        }

        for dto in backup.recipes where !existingRecipes.contains(dto.id) {
            let recipe = DialedRecipe(from: Brew())
            recipe.id = dto.id
            recipe.bean = dto.beanID.flatMap { beanByID[$0] }
            recipe.machine = dto.machineID.flatMap { machineByID[$0] }
            recipe.grinder = dto.grinderID.flatMap { grinderByID[$0] }
            recipe.dose = dto.dose
            recipe.yield = dto.yield
            recipe.shotTime = dto.shotTime
            recipe.grindSetting = dto.grindSetting
            recipe.waterTemp = dto.waterTemp
            recipe.basketRaw = dto.basketRaw
            recipe.score = dto.score
            recipe.createdAt = dto.createdAt
            context.insert(recipe)
            summary.recipes += 1
        }

        for dto in backup.maintenanceLogs where !existingLogs.contains(dto.id) {
            let kind = MaintenanceKind(rawValue: dto.kindRaw) ?? .backflush
            let log = MaintenanceLog(kind: kind,
                                     machine: dto.machineID.flatMap { machineByID[$0] },
                                     date: dto.date, notes: dto.notes)
            log.id = dto.id
            context.insert(log)
        }

        for dto in backup.maintenanceReminders where !existingReminders.contains(dto.id) {
            let kind = MaintenanceKind(rawValue: dto.kindRaw) ?? .backflush
            let reminder = MaintenanceReminder(machine: dto.machineID.flatMap { machineByID[$0] }, kind: kind)
            reminder.id = dto.id
            reminder.modeRaw = dto.modeRaw
            reminder.intervalDays = dto.intervalDays
            reminder.intervalShots = dto.intervalShots
            reminder.createdAt = dto.createdAt
            context.insert(reminder)
        }

        for dto in backup.cafeVisits where !existingVisits.contains(dto.id) {
            let visit = CafeVisit()
            visit.id = dto.id
            visit.date = dto.date
            visit.cafe = dto.cafeID.flatMap { cafeByID[$0] }
            visit.drinkRaw = dto.drinkRaw
            visit.notes = dto.notes
            visit.beanID = dto.beanID
            visit.coffeeScore = dto.coffeeScore
            visit.overallRating = dto.overallRating
            visit.wouldReturn = dto.wouldReturn
            visit.usedAdvanced = dto.usedAdvanced
            visit.coffeeTags = dto.coffeeTags
            visit.venueTags = dto.venueTags
            visit.coffeeQuality = dto.coffeeQuality
            visit.milkQuality = dto.milkQuality
            visit.extractionQuality = dto.extractionQuality
            visit.temperature = dto.temperature
            visit.value = dto.value
            visit.atmosphere = dto.atmosphere
            visit.service = dto.service
            visit.consistency = dto.consistency
            visit.foodQuality = dto.foodQuality
            context.insert(visit)
            summary.visits += 1
        }

        return summary
    }
}
