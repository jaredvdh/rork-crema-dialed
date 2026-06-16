//
//  DialInView.swift
//  CremaDialed
//
//  An elegant coffee journal. Simple by default — bean, dose, yield, timer,
//  a quick star rating and one-tap outcome feedback. Power users can expand
//  "Advanced Parameters" for the full barista workbench.
//

import SwiftUI
import SwiftData

struct DialInView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Bean.createdAt, order: .reverse) private var beans: [Bean]
    @Query(sort: \Machine.createdAt, order: .reverse) private var machines: [Machine]
    @Query(sort: \Grinder.createdAt, order: .reverse) private var grinders: [Grinder]
    @Query private var goldens: [DialedRecipe]

    // Smart defaults — remembered between sessions.
    @AppStorage("lastDose") private var lastDose: Double = 18
    @AppStorage("lastYield") private var lastYield: Double = 36
    @AppStorage("lastTemp") private var lastTemp: Double = 93
    @AppStorage("lastGrind") private var lastGrind: String = ""
    @AppStorage("lastBeanID") private var lastBeanID: String = ""
    @AppStorage("lastBasket") private var lastBasket: String = BasketSize.double.rawValue
    @AppStorage("defaultBasket") private var defaultBasket: String = BasketSize.double.rawValue

    @State private var selectedBean: Bean?
    @State private var selectedMachine: Machine?
    @State private var selectedGrinder: Grinder?

    @State private var dose: Double = 18
    @State private var yield: Double = 36
    @State private var basket: BasketSize = .double
    @State private var shotTime: Double = 28
    @State private var grindSetting: String = ""
    @State private var grindTime: Double = 0
    @State private var waterTemp: Double = 93
    @State private var pressure: Double = 9
    @State private var preInfusion: Double = 0
    @State private var flowRate: Double = 0
    @State private var tds: Double = 0
    @State private var extractionYield: Double = 0
    @State private var machineNotes: String = ""
    @State private var waterRecipe: String = ""

    @State private var flavourScore = 7
    @State private var selectedOutcome: ShotOutcome?

    @State private var acidity = 5
    @State private var sweetness = 5
    @State private var bodyScore = 5
    @State private var bitterness = 5
    @State private var balance = 5
    @State private var aftertaste = 5
    @State private var flavours: [String] = []
    @State private var notes = ""
    @State private var usedDetailedTaste = false

    @State private var showAdvanced = false
    @State private var showTimer = false
    @State private var showEquipment = false
    @State private var showRecipes = false
    @State private var showAddBean = false
    @State private var showEditBean = false
    @State private var showSaved = false
    @State private var markGolden = false
    private let timer = BrewTimer()

    private var ratio: Double { dose > 0 ? yield / dose : 0 }
    private var overall: Int { flavourScore }

    private var golden: DialedRecipe? {
        guard let selectedBean else { return nil }
        return goldens.first { $0.bean?.id == selectedBean.id }
    }

    private var previewBrew: Brew {
        let b = Brew(bean: selectedBean, machine: selectedMachine, grinder: selectedGrinder,
                     dose: dose, yield: yield, shotTime: shotTime, grindSetting: grindSetting,
                     grindTime: grindTime, waterTemp: waterTemp, pressure: pressure, preInfusion: preInfusion,
                     basket: basket)
        b.acidity = acidity; b.sweetness = sweetness; b.body = bodyScore
        b.bitterness = bitterness; b.balance = balance; b.aftertaste = aftertaste; b.overall = overall
        return b
    }

    private var coachTips: [CoachTip] {
        let brew = previewBrew
        if let golden { return DialInCoach.analyze(brew) + DialInCoach.compareToGolden(brew, golden: golden) }
        return DialInCoach.analyze(brew)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CremaColor.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        beanSelector
                        doseYieldHero
                        ratingCard
                        outcomeCard
                        noteCard
                        advancedDisclosure
                        saveSection
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Dial In")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        HapticEngine.light()
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .font(.crema(16, .semibold))
                    .foregroundStyle(CremaColor.espresso)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticEngine.light(); showRecipes = true
                    } label: {
                        Image(systemName: "book.pages.fill").foregroundStyle(CremaColor.espresso)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticEngine.light(); showEquipment = true
                    } label: {
                        Image(systemName: "gearshape.2.fill").foregroundStyle(CremaColor.espresso)
                    }
                }
            }
            .sheet(isPresented: $showRecipes) { RecipesView() }
            .sheet(isPresented: $showEquipment) { EquipmentView() }
            .sheet(isPresented: $showAddBean) {
                AddBeanSheet { bean in
                    modelContext.insert(bean)
                    selectBean(bean)
                    HapticEngine.success()
                }
            }
            .sheet(isPresented: $showEditBean) {
                if let bean = selectedBean {
                    AddBeanSheet(editing: bean) { _ in HapticEngine.success() }
                }
            }
            .fullScreenCover(isPresented: $showTimer) {
                BrewTimerView(timer: timer, dose: dose, yield: yield) { elapsed in
                    shotTime = (elapsed * 10).rounded() / 10
                }
            }
            .onAppear(perform: restoreDefaults)
        }
    }

    // MARK: Bean

    private var availableBeans: [Bean] { beans.filter { !$0.isFinished } }

    @ViewBuilder private var beanSelector: some View {
        Menu {
            Picker("Bean", selection: beanPickerBinding) {
                Text("No bean selected").tag(nil as UUID?)
                ForEach(availableBeans) { bean in
                    Text(bean.name).tag(bean.id as UUID?)
                }
            }
            Divider()
            Button { HapticEngine.tap(); showAddBean = true } label: {
                Label("Add New Bean", systemImage: "plus.circle")
            }
            if selectedBean != nil {
                Button { HapticEngine.tap(); showEditBean = true } label: {
                    Label("Edit Bean", systemImage: "pencil")
                }
            }
        } label: {
            beanCardContent
        }
        .buttonStyle(.plain)
    }

    private var beanPickerBinding: Binding<UUID?> {
        Binding(
            get: { selectedBean?.id },
            set: { id in selectBean(availableBeans.first { $0.id == id }) }
        )
    }

    private var beanCardContent: some View {
        CremaCard {
            HStack(spacing: 14) {
                beanThumbnail
                if let bean = selectedBean {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bean.name)
                            .font(.crema(19, .bold))
                            .foregroundStyle(CremaColor.textPrimary)
                            .lineLimit(1)
                        if !bean.roaster.isEmpty {
                            Text(bean.roaster)
                                .font(.crema(14, .medium))
                                .foregroundStyle(CremaColor.textSecondary)
                                .lineLimit(1)
                        }
                        Text(bean.freshnessLabel)
                            .font(.crema(13, .semibold))
                            .foregroundStyle(freshnessTint(bean))
                        if golden != nil {
                            Label("Golden Recipe Loaded", systemImage: "star.fill")
                                .font(.crema(12, .bold))
                                .foregroundStyle(CremaColor.crema)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(beans.isEmpty ? "Add your first bean" : "Select a bean")
                            .font(.crema(18, .bold))
                            .foregroundStyle(CremaColor.textPrimary)
                        Text(beans.isEmpty ? "Tap to start dialing in." : "Tap to choose, add or edit.")
                            .font(.crema(13, .medium))
                            .foregroundStyle(CremaColor.textSecondary)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.crema(14, .semibold))
                    .foregroundStyle(CremaColor.textTertiary)
            }
        }
    }

    @ViewBuilder private var beanThumbnail: some View {
        let size: CGFloat = 56
        if let data = selectedBean?.photoData, let ui = UIImage(data: data) {
            Color.clear
                .frame(width: size, height: size)
                .overlay {
                    Image(uiImage: ui).resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false)
                }
                .clipShape(.rect(cornerRadius: 14))
        } else {
            RoundedRectangle(cornerRadius: 14)
                .fill(CremaColor.surface)
                .frame(width: size, height: size)
                .overlay {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(CremaColor.crema)
                }
        }
    }

    private func freshnessTint(_ bean: Bean) -> Color {
        guard let days = bean.daysOffRoast else { return CremaColor.textTertiary }
        switch days {
        case ..<4: return CremaColor.caramel
        case 4...18: return CremaColor.positive
        case 19...30: return CremaColor.caramel
        default: return CremaColor.negative
        }
    }

    // MARK: Dose / Yield hero

    private var doseYieldHero: some View {
        VStack(spacing: 16) {
            basketPicker
            HStack(spacing: 12) {
                BigParam(label: "DOSE", unit: "g in", value: $dose, step: 0.1, range: 5...30)
                BigParam(label: "YIELD", unit: "g out", value: $yield, step: 0.5, range: 10...80)
            }
            HStack(spacing: 14) {
                supportingStat(String(format: "%.0fs", shotTime), "TIME", tint: CremaColor.caramel)
                Rectangle().fill(CremaColor.separator).frame(width: 1, height: 28)
                supportingStat(String(format: "1:%.1f", ratio), "RATIO", tint: CremaColor.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            Button {
                HapticEngine.tap()
                timer.configure(targetTime: shotTime)
                timer.reset()
                if let g = golden {
                    timer.loadGolden(time: g.shotTime, yield: g.yield, dose: g.dose,
                                     temp: g.waterTemp, basket: g.basket.rawValue)
                } else {
                    timer.clearGolden()
                }
                showTimer = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "drop.fill")
                    Text("Start Extraction")
                }
                .font(.crema(17, .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .foregroundStyle(CremaColor.background)
                .background(
                    LinearGradient(colors: [CremaColor.caramel, CremaColor.crema],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(.rect(cornerRadius: CremaRadius.field))
                .shadow(color: CremaColor.crema.opacity(0.3), radius: 12, y: 5)
            }
            .buttonStyle(PressableStyle())
        }
        .padding(18)
        .background(CremaColor.card)
        .clipShape(.rect(cornerRadius: CremaRadius.card))
        .overlay(RoundedRectangle(cornerRadius: CremaRadius.card).stroke(CremaColor.separator, lineWidth: 0.5))
    }

    private var basketPicker: some View {
        VStack(spacing: 8) {
            HStack {
                Text("BASKET")
                    .font(.crema(11, .semibold))
                    .foregroundStyle(CremaColor.textTertiary)
                Spacer()
            }
            HStack(spacing: 8) {
                ForEach(BasketSize.allCases) { size in
                    Button {
                        HapticEngine.selection()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { basket = size }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: size.systemImage).font(.crema(13, .semibold))
                            Text(size.rawValue).font(.crema(14, .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .foregroundStyle(basket == size ? CremaColor.background : CremaColor.textSecondary)
                        .background(basket == size ? CremaColor.espresso : CremaColor.surface)
                        .clipShape(.rect(cornerRadius: CremaRadius.field))
                    }
                    .buttonStyle(PressableStyle())
                }
            }
        }
    }

    private func supportingStat(_ value: String, _ label: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Text(value)
                .font(.crema(17, .bold))
                .foregroundStyle(tint)
                .contentTransition(.numericText())
            Text(label)
                .font(.crema(11, .semibold))
                .foregroundStyle(CremaColor.textTertiary)
        }
    }

    // MARK: Quick rating

    private var ratingCard: some View {
        CremaCard {
            VStack(spacing: 14) {
                Text("FLAVOUR SCORE")
                    .font(.crema(11, .semibold))
                    .foregroundStyle(CremaColor.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                FlavourScore(score: $flavourScore)
            }
        }
    }

    // MARK: Quick outcome

    private var outcomeCard: some View {
        CremaCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("QUICK FEEDBACK")
                    .font(.crema(11, .semibold))
                    .foregroundStyle(CremaColor.textTertiary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                    ForEach(ShotOutcome.allCases) { outcome in
                        CremaChip(label: outcome.rawValue, systemImage: outcome.systemImage,
                                  isSelected: selectedOutcome == outcome) {
                            selectedOutcome = (selectedOutcome == outcome) ? nil : outcome
                        }
                    }
                }
                if let selectedOutcome {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: selectedOutcome.isPositive ? "checkmark.seal.fill" : "lightbulb.fill")
                            .font(.crema(15))
                            .foregroundStyle(selectedOutcome.isPositive ? CremaColor.positive : CremaColor.caramel)
                        Text(selectedOutcome.suggestion)
                            .font(.crema(14, .medium))
                            .foregroundStyle(CremaColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(CremaColor.surface)
                    .clipShape(.rect(cornerRadius: CremaRadius.field))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedOutcome)
        }
    }

    private var noteCard: some View {
        CremaCard {
            LabeledField(label: "Tasting Note (optional)", text: $notes,
                         placeholder: "Syrupy, milk chocolate, juicy finish…", axis: .vertical)
        }
    }

    // MARK: Advanced

    private var advancedDisclosure: some View {
        VStack(spacing: 16) {
            Button {
                HapticEngine.light()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { showAdvanced.toggle() }
            } label: {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                    Text(showAdvanced ? "Hide Advanced Parameters" : "Show Advanced Parameters")
                        .font(.crema(15, .semibold))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(showAdvanced ? 180 : 0))
                }
                .font(.crema(15, .semibold))
                .foregroundStyle(CremaColor.espresso)
                .padding(16)
                .background(CremaColor.card)
                .clipShape(.rect(cornerRadius: CremaRadius.field))
                .overlay(RoundedRectangle(cornerRadius: CremaRadius.field).stroke(CremaColor.separator, lineWidth: 0.5))
            }
            .buttonStyle(PressableStyle())

            if showAdvanced {
                VStack(spacing: 16) {
                    equipmentSelector
                    parametersSection
                    grinderAwareSection
                    measurementsSection
                    waterNotesSection
                    detailedTasteSection
                    coachSection
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    @ViewBuilder private var equipmentSelector: some View {
        if !machines.isEmpty || !grinders.isEmpty {
            CremaCard {
                VStack(alignment: .leading, spacing: 12) {
                    if !machines.isEmpty {
                        equipmentRow("MACHINE", items: machines.map { ($0.id, $0.displayName) },
                                     selectedID: selectedMachine?.id) { id in
                            selectedMachine = machines.first { $0.id == id }
                        }
                    }
                    if !grinders.isEmpty {
                        equipmentRow("GRINDER", items: grinders.map { ($0.id, $0.displayName) },
                                     selectedID: selectedGrinder?.id) { id in
                            selectedGrinder = grinders.first { $0.id == id }
                        }
                    }
                }
            }
        }
    }

    private func equipmentRow(_ title: String, items: [(UUID, String)], selectedID: UUID?, onSelect: @escaping (UUID) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.crema(11, .semibold))
                .foregroundStyle(CremaColor.textTertiary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items, id: \.0) { item in
                        CremaChip(label: item.1, isSelected: selectedID == item.0) { onSelect(item.0) }
                    }
                }
            }
        }
    }

    private var parametersSection: some View {
        VStack(spacing: 12) {
            SectionHeader("Brew Parameters")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ParamStepper(label: "Water Temp", unit: "°C", value: $waterTemp, step: 0.5, range: 85...100, format: "%.1f")
                ParamStepper(label: "Pressure", unit: "bar", value: $pressure, step: 0.5, range: 1...12, format: "%.1f")
                ParamStepper(label: "Pre-infusion", unit: "seconds", value: $preInfusion, step: 0.5, range: 0...20, format: "%.1f")
                ParamStepper(label: "Shot Time", unit: "seconds", value: $shotTime, step: 0.5, range: 5...60, format: "%.0f")
            }
        }
    }

    @ViewBuilder private var grinderAwareSection: some View {
        CremaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "dial.high.fill").foregroundStyle(CremaColor.crema)
                    Text(grinderTitle)
                        .font(.crema(15, .bold))
                        .foregroundStyle(CremaColor.textPrimary)
                }
                LabeledField(label: grindSettingLabel, text: $grindSetting, placeholder: grindSettingPlaceholder)
                if let kind = selectedGrinder?.kind, kind == .timeBased {
                    ParamStepper(label: "Grind Time", unit: "seconds", value: $grindTime, step: 0.1, range: 0...30, format: "%.1f")
                }
                if !(selectedGrinder?.referencePoint.isEmpty ?? true) {
                    Text("Reference: \(selectedGrinder?.referencePoint ?? "")")
                        .font(.crema(13, .medium))
                        .foregroundStyle(CremaColor.textSecondary)
                }
            }
        }
    }

    private var measurementsSection: some View {
        VStack(spacing: 12) {
            SectionHeader("Measurements")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ParamStepper(label: "Flow Rate", unit: "ml/s", value: $flowRate, step: 0.1, range: 0...10, format: "%.1f")
                ParamStepper(label: "TDS", unit: "%", value: $tds, step: 0.05, range: 0...15, format: "%.2f")
                ParamStepper(label: "Extraction Yield", unit: "% EY", value: $extractionYield, step: 0.1, range: 0...30, format: "%.1f")
            }
            Text("Leave at zero if you don't measure these — they're ready for future scale and analysis features.")
                .font(.crema(12, .medium))
                .foregroundStyle(CremaColor.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var waterNotesSection: some View {
        CremaCard {
            VStack(alignment: .leading, spacing: 12) {
                LabeledField(label: "Machine Notes", text: $machineNotes, placeholder: "Pressure profile, basket…", axis: .vertical)
                Divider().overlay(CremaColor.separator)
                LabeledField(label: "Water Recipe", text: $waterRecipe, placeholder: "e.g. 2 parts RO + 1 part tap", axis: .vertical)
            }
        }
    }

    private var detailedTasteSection: some View {
        VStack(spacing: 12) {
            SectionHeader("Detailed Tasting")
            CremaCard {
                VStack(spacing: 14) {
                    TasteSlider(label: "Acidity", value: tasteBinding($acidity))
                    TasteSlider(label: "Sweetness", value: tasteBinding($sweetness))
                    TasteSlider(label: "Body", value: tasteBinding($bodyScore))
                    TasteSlider(label: "Bitterness", value: tasteBinding($bitterness))
                    TasteSlider(label: "Balance", value: tasteBinding($balance))
                    TasteSlider(label: "Aftertaste", value: tasteBinding($aftertaste))
                }
            }
            SectionHeader("Flavour Notes")
            CremaCard { FlavourWheelPicker(selected: $flavours) }
        }
    }

    private func tasteBinding(_ source: Binding<Int>) -> Binding<Int> {
        Binding(get: { source.wrappedValue }, set: { usedDetailedTaste = true; source.wrappedValue = $0 })
    }

    private var coachSection: some View {
        VStack(spacing: 12) {
            SectionHeader("Dial-In Coach")
            CremaCard {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(coachTips) { tip in
                        CoachTipRow(tip: tip)
                        if tip.id != coachTips.last?.id { Divider().overlay(CremaColor.separator) }
                    }
                }
            }
        }
    }

    // MARK: Save

    private var saveSection: some View {
        VStack(spacing: 12) {
            Button {
                HapticEngine.selection(); markGolden.toggle()
            } label: {
                HStack {
                    Image(systemName: markGolden ? "star.fill" : "star").foregroundStyle(CremaColor.crema)
                    Text("Save as Golden Recipe")
                        .font(.crema(15, .semibold))
                        .foregroundStyle(CremaColor.textPrimary)
                    Spacer()
                    if markGolden {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(CremaColor.positive)
                    }
                }
                .padding(16)
                .background(CremaColor.card)
                .clipShape(.rect(cornerRadius: CremaRadius.field))
                .overlay(RoundedRectangle(cornerRadius: CremaRadius.field).stroke(markGolden ? CremaColor.crema : CremaColor.separator, lineWidth: markGolden ? 1.5 : 0.5))
            }
            .buttonStyle(PressableStyle())

            PrimaryButton(title: "Log This Shot", systemImage: "checkmark") { saveBrew() }

            if showSaved {
                Text("Shot logged ☕️")
                    .font(.crema(14, .semibold))
                    .foregroundStyle(CremaColor.positive)
                    .transition(.opacity)
            }
        }
    }

    // MARK: Grinder labels

    private var grinderTitle: String {
        guard let g = selectedGrinder else { return "Grind Setting" }
        return "\(g.model) · \(g.kind.rawValue)"
    }
    private var grindSettingLabel: String {
        switch selectedGrinder?.kind {
        case .stepless: return "Dial Position"
        case .weightBased: return "Target Dose"
        case .timeBased: return "Setting"
        default: return "Grind Setting"
        }
    }
    private var grindSettingPlaceholder: String {
        switch selectedGrinder?.kind {
        case .stepless: return "e.g. 2.4"
        case .weightBased: return "e.g. 18g"
        default: return "e.g. 14"
        }
    }

    // MARK: Smart defaults

    private func restoreDefaults() {
        if selectedMachine == nil { selectedMachine = machines.first }
        if selectedGrinder == nil { selectedGrinder = grinders.first(where: { !$0.isIntegrated }) ?? grinders.first }
        // Only seed once per appearance when nothing is selected yet.
        if selectedBean == nil {
            basket = BasketSize(rawValue: lastBasket) ?? BasketSize(rawValue: defaultBasket) ?? .double
            if let saved = beans.first(where: { $0.id.uuidString == lastBeanID && !$0.isFinished }) {
                selectBean(saved)
            } else {
                dose = lastDose; yield = lastYield; waterTemp = lastTemp; grindSetting = lastGrind
            }
        }
    }

    private func selectBean(_ bean: Bean?) {
        selectedBean = bean
        selectedOutcome = nil
        guard let bean else { return }
        if let g = goldens.first(where: { $0.bean?.id == bean.id }) {
            // Preload the last successful recipe for this bean.
            dose = g.dose; yield = g.yield; shotTime = g.shotTime
            grindSetting = g.grindSetting; waterTemp = g.waterTemp; basket = g.basket
        } else {
            dose = lastDose; yield = lastYield; waterTemp = lastTemp; grindSetting = lastGrind
        }
    }

    private func saveBrew() {
        let brew = Brew(bean: selectedBean, machine: selectedMachine, grinder: selectedGrinder,
                        dose: dose, yield: yield, shotTime: shotTime, grindSetting: grindSetting,
                        grindTime: grindTime, waterTemp: waterTemp, pressure: pressure, preInfusion: preInfusion,
                        basket: basket)
        brew.acidity = acidity; brew.sweetness = sweetness; brew.body = bodyScore
        brew.bitterness = bitterness; brew.balance = balance; brew.aftertaste = aftertaste
        brew.overall = overall; brew.flavourNotesRaw = flavours; brew.notes = notes
        brew.outcomeRaw = selectedOutcome?.rawValue ?? ""
        brew.flowRate = flowRate; brew.tds = tds; brew.extractionYield = extractionYield
        brew.machineNotes = machineNotes; brew.waterRecipe = waterRecipe
        brew.isGolden = markGolden
        modelContext.insert(brew)

        if markGolden, let bean = selectedBean {
            for existing in goldens where existing.bean?.id == bean.id {
                modelContext.delete(existing)
            }
            modelContext.insert(DialedRecipe(from: brew))
        }

        // Persist smart defaults.
        lastDose = dose; lastYield = yield; lastTemp = waterTemp; lastGrind = grindSetting
        lastBeanID = selectedBean?.id.uuidString ?? ""
        lastBasket = basket.rawValue

        HapticEngine.success()
        withAnimation { showSaved = true }
        markGolden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSaved = false }
        }
    }
}

/// A large, journal-style numeric parameter (dose / yield) with tap +/- and a big value.
private struct BigParam: View {
    let label: String
    let unit: String
    @Binding var value: Double
    var step: Double
    var range: ClosedRange<Double>

    var body: some View {
        VStack(spacing: 10) {
            Text(label)
                .font(.crema(11, .semibold))
                .foregroundStyle(CremaColor.textTertiary)
            Text(String(format: "%.1f", value))
                .font(.crema(40, .bold))
                .foregroundStyle(CremaColor.textPrimary)
                .monospacedDigit()
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(unit)
                .font(.crema(11, .medium))
                .foregroundStyle(CremaColor.textTertiary)
            HStack(spacing: 10) {
                roundButton("minus") { value = max(range.lowerBound, value - step) }
                roundButton("plus") { value = min(range.upperBound, value + step) }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(CremaColor.surface)
        .clipShape(.rect(cornerRadius: CremaRadius.field))
    }

    private func roundButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticEngine.light(); action()
        } label: {
            Image(systemName: symbol)
                .font(.crema(16, .bold))
                .foregroundStyle(CremaColor.espresso)
                .frame(width: 40, height: 40)
                .background(CremaColor.card)
                .clipShape(Circle())
        }
        .buttonStyle(PressableStyle())
    }
}
