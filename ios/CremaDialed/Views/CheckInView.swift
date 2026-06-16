//
//  CheckInView.swift
//  CremaDialed
//
//  A premium, guided café check-in that captures a coffee memory:
//  confirm café → choose drink → quick rating → optional details → save.
//

import SwiftUI
import SwiftData
import CoreLocation

enum CheckInStep: Int, CaseIterable {
    case confirm, drink, rate, details

    var title: String {
        switch self {
        case .confirm: return "Confirm Café"
        case .drink: return "What did you drink?"
        case .rate: return "Quick rating"
        case .details: return "Optional details"
        }
    }
}

struct CheckInView: View {
    var location: CafeLocationService
    var existingCafes: [Cafe]
    var preselectedResult: CafeResult? = nil
    var preselectedCafe: Cafe? = nil
    var onSave: (Cafe, CafeVisit) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var picked: CafeResult?
    @State private var pickedExisting: Cafe?
    @State private var step: CheckInStep = .confirm

    @State private var drink: CoffeeDrink = .flatWhite
    @State private var galleryPhotos: [GalleryPhoto] = []
    @State private var coffeeScore = 8
    @State private var wouldReturn = false
    @State private var notes = ""

    // Optional detailed review (Coffee Quality / Service / Atmosphere / Value).
    @State private var showDetails = false
    @State private var usedAdvanced = false
    @State private var coffeeQuality = 8
    @State private var service = 8
    @State private var atmosphere = 8
    @State private var value = 7

    @State private var showSuccess = false

    private var hasCafe: Bool { picked != nil || pickedExisting != nil }
    private var cafeName: String { picked?.name ?? pickedExisting?.name ?? "" }
    private var cafeSubtitle: String {
        if let picked { return [picked.address, picked.city].filter { !$0.isEmpty }.joined(separator: ", ") }
        if let pickedExisting { return [pickedExisting.address, pickedExisting.city].filter { !$0.isEmpty }.joined(separator: ", ") }
        return ""
    }
    private var cafeDistance: String? { picked?.distanceLabel }
    private var cafeCover: Data? { (picked != nil ? matchingCafe(for: picked!, in: existingCafes)?.coverPhoto : pickedExisting?.coverPhoto) }

    var body: some View {
        NavigationStack {
            ZStack {
                CremaColor.background.ignoresSafeArea()
                Group {
                    if hasCafe {
                        flowBody
                    } else {
                        CafePicker(location: location, existingCafes: existingCafes,
                                   onPickResult: { picked = $0 },
                                   onPickExisting: { pickedExisting = $0 })
                    }
                }
                if showSuccess { successOverlay }
            }
            .navigationTitle(hasCafe ? "Check In" : "Find a Café")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            if let preselectedResult { picked = preselectedResult }
            else if let preselectedCafe { pickedExisting = preselectedCafe }
        }
    }

    // MARK: Flow

    private var flowBody: some View {
        VStack(spacing: 0) {
            progressBar
                .padding(.horizontal, 20)
                .padding(.top, 12)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(step.title)
                        .font(.crema(28, .bold))
                        .foregroundStyle(CremaColor.textPrimary)
                        .padding(.top, 6)

                    switch step {
                    case .confirm: confirmStep
                    case .drink: drinkStep
                    case .rate: rateStep
                    case .details: detailsStep
                    }
                }
                .padding(20)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            bottomBar
        }
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

    private var confirmStep: some View {
        VStack(spacing: 16) {
            Color(.secondarySystemBackground)
                .frame(height: 170)
                .overlay {
                    if let data = cafeCover, let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false)
                    } else {
                        LinearGradient(colors: [CremaColor.espresso, CremaColor.caramel],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                            .overlay {
                                Image(systemName: "cup.and.saucer.fill")
                                    .font(.system(size: 44, weight: .bold))
                                    .foregroundStyle(CremaColor.background.opacity(0.9))
                            }
                    }
                }
                .clipShape(.rect(cornerRadius: CremaRadius.card))

            CremaCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(cafeName)
                        .font(.crema(20, .bold))
                        .foregroundStyle(CremaColor.textPrimary)
                    if !cafeSubtitle.isEmpty {
                        Label(cafeSubtitle, systemImage: "mappin.and.ellipse")
                            .font(.crema(13, .medium))
                            .foregroundStyle(CremaColor.textSecondary)
                    }
                    if let cafeDistance {
                        Label(cafeDistance, systemImage: "location.fill")
                            .font(.crema(13, .semibold))
                            .foregroundStyle(CremaColor.caramel)
                    }
                }
            }

            Button {
                HapticEngine.light()
                picked = nil; pickedExisting = nil; step = .confirm
            } label: {
                Label("Choose a different café", systemImage: "arrow.triangle.2.circlepath")
                    .font(.crema(14, .semibold))
                    .foregroundStyle(CremaColor.espresso)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(CremaColor.surface)
                    .clipShape(.rect(cornerRadius: CremaRadius.field))
            }
            .buttonStyle(PressableStyle())
        }
    }

    private var drinkStep: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(CoffeeDrink.allCases) { d in
                DrinkCard(drink: d, isSelected: drink == d) { drink = d }
            }
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
            Text("Keep it quick — you can add more detail below if you like.")
                .font(.crema(13, .medium))
                .foregroundStyle(CremaColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var detailsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Photo
            VStack(alignment: .leading, spacing: 10) {
                Text("PHOTO")
                    .font(.crema(11, .semibold))
                    .foregroundStyle(CremaColor.textTertiary)
                PhotoGalleryEditor(photos: $galleryPhotos)
            }

            // Expandable rating dimensions
            Button {
                HapticEngine.light()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { showDetails.toggle() }
            } label: {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                    Text(showDetails ? "Hide ratings" : "Rate quality, service, atmosphere & value")
                    Spacer()
                    Image(systemName: "chevron.down").rotationEffect(.degrees(showDetails ? 180 : 0))
                }
                .font(.crema(14, .semibold))
                .foregroundStyle(CremaColor.espresso)
                .padding(16)
                .background(CremaColor.card)
                .clipShape(.rect(cornerRadius: CremaRadius.field))
                .overlay(RoundedRectangle(cornerRadius: CremaRadius.field).stroke(CremaColor.separator, lineWidth: 0.5))
            }
            .buttonStyle(PressableStyle())

            if showDetails {
                CremaCard {
                    VStack(spacing: 14) {
                        TasteSlider(label: "Coffee Quality", value: advBinding($coffeeQuality))
                        TasteSlider(label: "Service", value: advBinding($service))
                        TasteSlider(label: "Atmosphere", value: advBinding($atmosphere))
                        TasteSlider(label: "Value", value: advBinding($value))
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Notes
            VStack(alignment: .leading, spacing: 10) {
                Text("NOTES")
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

    private func advBinding(_ source: Binding<Int>) -> Binding<Int> {
        Binding(get: { max(1, source.wrappedValue) },
                set: { usedAdvanced = true; source.wrappedValue = $0 })
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if step != .confirm {
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
                if step == .details {
                    save()
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { goNext() }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(step == .details ? "Save to Passport" : "Continue")
                    Image(systemName: step == .details ? "checkmark" : "chevron.right")
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

    // MARK: Success overlay

    private var successOverlay: some View {
        ZStack {
            CremaColor.background.opacity(0.96).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("☕")
                    .font(.system(size: 72))
                    .scaleEffect(showSuccess ? 1 : 0.4)
                    .animation(.spring(response: 0.45, dampingFraction: 0.55), value: showSuccess)
                Text("Added to Coffee Passport")
                    .font(.crema(20, .bold))
                    .foregroundStyle(CremaColor.textPrimary)
                Text(cafeName)
                    .font(.crema(14, .medium))
                    .foregroundStyle(CremaColor.textSecondary)
            }
        }
        .transition(.opacity)
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
            coffeeTags: [],
            venueTags: [],
            overallRating: coffeeScore,
            wouldReturn: wouldReturn,
            usedAdvanced: usedAdvanced,
            coffeeQuality: coffeeQuality, milkQuality: 0, extractionQuality: 0,
            temperature: 0, value: value, atmosphere: atmosphere,
            service: service, consistency: 0, foodQuality: 0)
        onSave(cafe, visit)
        HapticEngine.success()
        withAnimation(.easeOut(duration: 0.25)) { showSuccess = true }
        Task {
            try? await Task.sleep(for: .seconds(1.1))
            dismiss()
        }
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
