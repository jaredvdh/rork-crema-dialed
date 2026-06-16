//
//  CheckInView.swift
//  CremaDialed
//
//  A premium, step-based café check-in that captures a coffee memory:
//  choose café → select drink → capture photos → rate → quick impressions → save.
//

import SwiftUI
import SwiftData
import CoreLocation

enum CheckInStep: Int, CaseIterable {
    case drink, photos, rate, impressions

    var title: String {
        switch self {
        case .drink: return "What did you drink?"
        case .photos: return "Capture the moment"
        case .rate: return "How was it?"
        case .impressions: return "Quick impressions"
        }
    }
}

struct CheckInView: View {
    var location: CafeLocationService
    var existingCafes: [Cafe]
    var onSave: (Cafe, CafeVisit) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var picked: CafeResult?
    @State private var pickedExisting: Cafe?
    @State private var step: CheckInStep = .drink

    @State private var drink: CoffeeDrink = .flatWhite
    @State private var galleryPhotos: [GalleryPhoto] = []
    @State private var coffeeScore = 8
    @State private var wouldReturn = false
    @State private var coffeeTags: [String] = []
    @State private var venueTags: [String] = []
    @State private var notes = ""

    // Optional detailed review.
    @State private var showAdvanced = false
    @State private var usedAdvanced = false
    @State private var coffee = 8
    @State private var milk = 7
    @State private var extraction = 8
    @State private var temperature = 7
    @State private var value = 7
    @State private var atmosphere = 8
    @State private var service = 8
    @State private var consistency = 7
    @State private var food = 0

    private var hasCafe: Bool { picked != nil || pickedExisting != nil }
    private var cafeName: String { picked?.name ?? pickedExisting?.name ?? "" }
    private var cafeSubtitle: String {
        picked.map { [$0.address, $0.city].filter { !$0.isEmpty }.joined(separator: ", ") }
            ?? pickedExisting?.city ?? ""
    }

    var body: some View {
        NavigationStack {
            Group {
                if hasCafe {
                    flowBody
                } else {
                    CafePicker(location: location, existingCafes: existingCafes,
                               onPickResult: { picked = $0 },
                               onPickExisting: { pickedExisting = $0 })
                }
            }
            .background(CremaColor.background)
            .navigationTitle(hasCafe ? "Check In" : "Find a Café")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: Flow

    private var flowBody: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(step.title)
                        .font(.crema(28, .bold))
                        .foregroundStyle(CremaColor.textPrimary)
                        .padding(.top, 4)

                    switch step {
                    case .drink: drinkStep
                    case .photos: photoStep
                    case .rate: rateStep
                    case .impressions: impressionStep
                    }
                }
                .padding(20)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            bottomBar
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                CafeCover(data: (pickedExisting?.coverPhoto) ?? nil, size: 40, corner: 11)
                VStack(alignment: .leading, spacing: 1) {
                    Text(cafeName)
                        .font(.crema(16, .bold))
                        .foregroundStyle(CremaColor.textPrimary)
                        .lineLimit(1)
                    if !cafeSubtitle.isEmpty {
                        Text(cafeSubtitle)
                            .font(.crema(12, .medium))
                            .foregroundStyle(CremaColor.textSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Button {
                    HapticEngine.light()
                    picked = nil; pickedExisting = nil; step = .drink
                } label: {
                    Text("Change")
                        .font(.crema(13, .semibold))
                        .foregroundStyle(CremaColor.espresso)
                }
            }
            progressBar
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(CheckInStep.allCases, id: \.rawValue) { s in
                Capsule()
                    .fill(s.rawValue <= step.rawValue ? CremaColor.crema : CremaColor.surface)
                    .frame(height: 5)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: step)
    }

    // MARK: Steps

    private var drinkStep: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(CoffeeDrink.allCases) { d in
                DrinkCard(drink: d, isSelected: drink == d) { drink = d }
            }
        }
    }

    private var photoStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photos are the heart of every memory. Add up to 10 — the first becomes your cover.")
                .font(.crema(14, .medium))
                .foregroundStyle(CremaColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            PhotoGalleryEditor(photos: $galleryPhotos)
        }
    }

    private var rateStep: some View {
        VStack(spacing: 18) {
            CremaCard {
                VStack(spacing: 16) {
                    FlavourScore(score: $coffeeScore)
                    Divider().overlay(CremaColor.separator)
                    Button {
                        HapticEngine.selection(); wouldReturn.toggle()
                    } label: {
                        HStack {
                            Image(systemName: wouldReturn ? "heart.fill" : "heart")
                                .foregroundStyle(wouldReturn ? CremaColor.negative : CremaColor.textTertiary)
                            Text("Favourite · I'd come back")
                                .font(.crema(15, .semibold))
                                .foregroundStyle(CremaColor.textPrimary)
                            Spacer()
                            if wouldReturn {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(CremaColor.positive)
                            }
                        }
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            advancedRatingSection
        }
    }

    private var impressionStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("COFFEE")
                    .font(.crema(11, .semibold))
                    .foregroundStyle(CremaColor.textTertiary)
                TagCloud(options: CoffeeTag.allCases.map(\.rawValue), selected: $coffeeTags,
                         tint: CremaColor.espresso)
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("THE VENUE")
                    .font(.crema(11, .semibold))
                    .foregroundStyle(CremaColor.textTertiary)
                TagCloud(options: VenueTag.allCases.map(\.rawValue), selected: $venueTags,
                         tint: CremaColor.caramel)
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("NOTES (OPTIONAL)")
                    .font(.crema(11, .semibold))
                    .foregroundStyle(CremaColor.textTertiary)
                TextField("Best flat white I've had in months…", text: $notes, axis: .vertical)
                    .font(.crema(16, .medium))
                    .foregroundStyle(CremaColor.textPrimary)
                    .tint(CremaColor.crema)
                    .lineLimit(3, reservesSpace: true)
                    .padding(14)
                    .background(CremaColor.surface)
                    .clipShape(.rect(cornerRadius: CremaRadius.field))
            }
        }
    }

    private var advancedRatingSection: some View {
        VStack(spacing: 16) {
            Button {
                HapticEngine.light()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { showAdvanced.toggle() }
            } label: {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                    Text(showAdvanced ? "Hide Detailed Review" : "Show Detailed Review")
                    Spacer()
                    Image(systemName: "chevron.down").rotationEffect(.degrees(showAdvanced ? 180 : 0))
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
                CremaCard {
                    VStack(spacing: 14) {
                        TasteSlider(label: "Coffee Flavour", value: advBinding($coffee))
                        TasteSlider(label: "Milk Texture", value: advBinding($milk))
                        TasteSlider(label: "Espresso Quality", value: advBinding($extraction))
                        TasteSlider(label: "Temperature", value: advBinding($temperature))
                        TasteSlider(label: "Service", value: advBinding($service))
                        TasteSlider(label: "Atmosphere", value: advBinding($atmosphere))
                        TasteSlider(label: "Value", value: advBinding($value))
                        TasteSlider(label: "Consistency", value: advBinding($consistency))
                        TasteSlider(label: "Food / Pastry", value: advBinding($food))
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func advBinding(_ source: Binding<Int>) -> Binding<Int> {
        Binding(get: { max(1, source.wrappedValue) },
                set: { usedAdvanced = true; source.wrappedValue = $0 })
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if step != .drink {
                Button {
                    HapticEngine.light()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { goBack() }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.crema(17, .bold))
                        .foregroundStyle(CremaColor.espresso)
                        .frame(width: 54, height: 54)
                        .background(CremaColor.surface)
                        .clipShape(.rect(cornerRadius: CremaRadius.field))
                }
                .buttonStyle(PressableStyle())
            }
            Button {
                HapticEngine.tap()
                if step == .impressions {
                    save()
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { goNext() }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(step == .impressions ? "Save Memory" : "Continue")
                    Image(systemName: step == .impressions ? "checkmark" : "chevron.right")
                }
                .font(.crema(17, .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .foregroundStyle(CremaColor.background)
                .background(
                    LinearGradient(colors: [CremaColor.espresso, CremaColor.caramel],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(.rect(cornerRadius: CremaRadius.field))
            }
            .buttonStyle(PressableStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(CremaColor.background)
    }

    private func goNext() {
        if let next = CheckInStep(rawValue: step.rawValue + 1) { step = next }
    }
    private func goBack() {
        if let prev = CheckInStep(rawValue: step.rawValue - 1) { step = prev }
    }

    // MARK: Save

    private func save() {
        let cafe: Cafe
        if let pickedExisting {
            cafe = pickedExisting
        } else if let picked {
            cafe = Cafe(name: picked.name, address: picked.address, city: picked.city,
                        latitude: picked.coordinate.latitude, longitude: picked.coordinate.longitude)
        } else {
            return
        }
        if wouldReturn { cafe.isFavourite = true }
        cafe.wantToVisit = false

        let visit = CafeVisit(
            cafe: cafe,
            drink: drink,
            notes: notes,
            photosData: galleryPhotos.map(\.data),
            photoCaptions: galleryPhotos.map(\.caption),
            coverIndex: 0,
            coffeeScore: coffeeScore,
            coffeeTags: coffeeTags,
            venueTags: venueTags,
            overallRating: coffeeScore,
            wouldReturn: wouldReturn,
            usedAdvanced: usedAdvanced,
            coffeeQuality: coffee, milkQuality: milk, extractionQuality: extraction,
            temperature: temperature, value: value, atmosphere: atmosphere,
            service: service, consistency: consistency, foodQuality: food)
        onSave(cafe, visit)
        HapticEngine.success()
        dismiss()
    }
}

/// Nearby + manual café search picker with rich, coffee-first results.
private struct CafePicker: View {
    var location: CafeLocationService
    var existingCafes: [Cafe]
    var onPickResult: (CafeResult) -> Void
    var onPickExisting: (Cafe) -> Void

    @State private var query = ""
    @State private var searchResults: [CafeResult] = []
    @State private var isSearching = false

    private var wishlist: [Cafe] { existingCafes.filter { $0.wantToVisit && !$0.hasVisited } }
    private var visited: [Cafe] { existingCafes.filter { $0.hasVisited } }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                searchField

                if location.authorization == .notDetermined {
                    permissionCard
                } else if location.isDenied {
                    deniedCard
                }

                if !query.isEmpty {
                    resultsSection("Search Results", results: searchResults, loading: isSearching)
                } else {
                    if !wishlist.isEmpty { savedSection("Want to Visit", cafes: wishlist) }
                    if !visited.isEmpty { savedSection("Your Cafés", cafes: visited) }
                    resultsSection("Coffee Nearby", results: location.nearby, loading: location.isSearching)
                }
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear { location.requestAndLocate() }
        .onChange(of: query) { _, q in
            Task {
                isSearching = true
                searchResults = await location.search(query: q)
                isSearching = false
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(CremaColor.textTertiary)
            TextField("Search any café", text: $query)
                .font(.crema(16, .medium))
                .foregroundStyle(CremaColor.textPrimary)
                .tint(CremaColor.crema)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(CremaColor.textTertiary)
                }
            }
        }
        .padding(14)
        .background(CremaColor.surface)
        .clipShape(.rect(cornerRadius: CremaRadius.field))
    }

    private var permissionCard: some View {
        CremaCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("Find coffee around you", systemImage: "location.fill")
                    .font(.crema(15, .bold))
                    .foregroundStyle(CremaColor.textPrimary)
                Text("Allow location access to discover the closest specialty cafés, sorted by distance.")
                    .font(.crema(13, .medium))
                    .foregroundStyle(CremaColor.textSecondary)
                PrimaryButton(title: "Enable Location", systemImage: "location") {
                    location.requestAndLocate()
                }
            }
        }
    }

    private var deniedCard: some View {
        CremaCard {
            VStack(alignment: .leading, spacing: 6) {
                Label("Location is off", systemImage: "location.slash.fill")
                    .font(.crema(15, .bold))
                    .foregroundStyle(CremaColor.textPrimary)
                Text("Enable location in Settings, or search for a café by name above.")
                    .font(.crema(13, .medium))
                    .foregroundStyle(CremaColor.textSecondary)
            }
        }
    }

    private func savedSection(_ title: String, cafes: [Cafe]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.crema(11, .semibold))
                .foregroundStyle(CremaColor.textTertiary)
            ForEach(cafes) { cafe in
                Button { HapticEngine.tap(); onPickExisting(cafe) } label: {
                    CafeListRow(cafe: cafe)
                }
                .buttonStyle(PressableStyle())
            }
        }
    }

    private func resultsSection(_ title: String, results: [CafeResult], loading: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title.uppercased())
                    .font(.crema(11, .semibold))
                    .foregroundStyle(CremaColor.textTertiary)
                if loading { ProgressView().scaleEffect(0.7) }
            }
            if results.isEmpty && !loading {
                Text("No cafés found.")
                    .font(.crema(14, .medium))
                    .foregroundStyle(CremaColor.textSecondary)
            }
            ForEach(results) { r in
                Button { HapticEngine.tap(); onPickResult(r) } label: {
                    resultRow(r)
                }
                .buttonStyle(PressableStyle())
            }
        }
    }

    private func resultRow(_ r: CafeResult) -> some View {
        CremaCard(padding: 12) {
            HStack(spacing: 12) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.crema(18))
                    .foregroundStyle(CremaColor.crema)
                    .frame(width: 44, height: 44)
                    .background(CremaColor.surface)
                    .clipShape(.rect(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text(r.name)
                        .font(.crema(15, .bold))
                        .foregroundStyle(CremaColor.textPrimary)
                        .lineLimit(1)
                    let sub = [r.address, r.city].filter { !$0.isEmpty }.joined(separator: ", ")
                    if !sub.isEmpty {
                        Text(sub)
                            .font(.crema(12, .medium))
                            .foregroundStyle(CremaColor.textSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                if let trailing = r.distanceLabel {
                    Text(trailing)
                        .font(.crema(12, .semibold))
                        .foregroundStyle(CremaColor.caramel)
                }
            }
        }
    }
}
