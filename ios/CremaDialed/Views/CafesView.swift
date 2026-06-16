//
//  CafesView.swift
//  CremaDialed
//
//  The coffee passport: a personal map of every café, favourites, a wishlist
//  and discovery sections that make returning to great coffee feel rewarding.
//

import SwiftUI
import SwiftData
import MapKit

/// Lenses for browsing the café collection.
enum PassportFilter: String, CaseIterable, Identifiable {
    case recent = "Recent"
    case topRated = "Top Rated"
    case mostVisited = "Most Visited"
    case wishlist = "Wishlist"
    var id: String { rawValue }
}

struct CafesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Cafe.createdAt, order: .reverse) private var cafes: [Cafe]
    @Query(sort: \Brew.date, order: .reverse) private var brews: [Brew]

    @State private var location = CafeLocationService()
    @State private var showCheckIn = false
    @State private var showWishlist = false
    @State private var filter: PassportFilter = .recent
    @State private var mapPosition: MapCameraPosition = .automatic

    private var visitedCafes: [Cafe] { cafes.filter { $0.hasVisited } }
    private var favourites: [Cafe] { cafes.filter { $0.isFavourite } }

    var body: some View {
        NavigationStack {
            ZStack {
                CremaColor.background.ignoresSafeArea()
                if cafes.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            mapCard
                            passportSummary
                            if !favourites.isEmpty { favouritesCarousel }
                            collectionSection
                            recommendationsCard
                        }
                        .padding(16)
                        .padding(.bottom, 90)
                    }
                    .navigationDestination(for: UUID.self) { id in
                        if let cafe = cafes.first(where: { $0.id == id }) {
                            CafeDetailView(cafe: cafe)
                        }
                    }
                }

                if !cafes.isEmpty { checkInButton }
            }
            .navigationTitle("Coffee Passport")
            .toolbar {
                if !cafes.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { HapticEngine.tap(); showWishlist = true } label: {
                            Image(systemName: "bookmark")
                        }
                    }
                }
            }
            .sheet(isPresented: $showCheckIn) {
                CheckInView(location: location, existingCafes: cafes) { cafe, visit in
                    if cafe.modelContext == nil { modelContext.insert(cafe) }
                    modelContext.insert(visit)
                }
            }
            .sheet(isPresented: $showWishlist) {
                WishlistSearchSheet(location: location, existingCafes: cafes) { result in
                    let cafe = Cafe(name: result.name, address: result.address, city: result.city,
                                    latitude: result.coordinate.latitude, longitude: result.coordinate.longitude,
                                    wantToVisit: true)
                    modelContext.insert(cafe)
                }
            }
        }
    }

    // MARK: Map

    private var mapCard: some View {
        Map(position: $mapPosition) {
            ForEach(cafes) { cafe in
                Annotation(cafe.name, coordinate: cafe.coordinate) {
                    NavigationLink(value: cafe.id) {
                        ZStack {
                            Circle().fill(cafe.wantToVisit && !cafe.hasVisited ? CremaColor.caramel : CremaColor.espresso)
                                .frame(width: 34, height: 34)
                                .shadow(radius: 3)
                            Image(systemName: cafe.isFavourite ? "heart.fill" : "cup.and.saucer.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(CremaColor.background)
                        }
                    }
                }
            }
        }
        .frame(height: 220)
        .clipShape(.rect(cornerRadius: CremaRadius.card))
        .overlay(RoundedRectangle(cornerRadius: CremaRadius.card).stroke(CremaColor.separator, lineWidth: 0.5))
    }

    // MARK: Passport summary

    private var allVisits: [CafeVisit] { cafes.flatMap(\.visits) }

    private var passportSummary: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricTile(label: "Cafés", value: "\(visitedCafes.count)", tint: CremaColor.espresso)
            MetricTile(label: "Check-ins", value: "\(allVisits.count)", tint: CremaColor.caramel)
            MetricTile(label: "Favourites", value: "\(favourites.count)", tint: CremaColor.negative)
        }
    }

    // MARK: Favourites carousel

    private var favouritesCarousel: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Favourites")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(favourites) { cafe in
                        NavigationLink(value: cafe.id) {
                            CafeFeatureCard(cafe: cafe)
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
            }
            .contentMargins(.horizontal, 2)
        }
    }

    // MARK: Collection section with filter

    private var filteredCafes: [Cafe] {
        switch filter {
        case .recent:
            return visitedCafes.sorted { ($0.lastVisit ?? .distantPast) > ($1.lastVisit ?? .distantPast) }
        case .topRated:
            return visitedCafes.sorted { $0.averageRating > $1.averageRating }
        case .mostVisited:
            return visitedCafes.sorted { $0.visits.count > $1.visits.count }
        case .wishlist:
            return cafes.filter { $0.wantToVisit && !$0.hasVisited }
        }
    }

    private var collectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Your Collection")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PassportFilter.allCases) { f in
                        CremaChip(label: f.rawValue, isSelected: filter == f) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { filter = f }
                        }
                    }
                }
                .padding(.horizontal, 2)
            }

            if filteredCafes.isEmpty {
                CremaCard {
                    Text(filter == .wishlist
                         ? "Your wishlist is empty. Tap the bookmark to add cafés you want to visit."
                         : "No cafés here yet.")
                        .font(.crema(14, .medium))
                        .foregroundStyle(CremaColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(filteredCafes) { cafe in
                    NavigationLink(value: cafe.id) { CafeListRow(cafe: cafe) }
                        .buttonStyle(PressableStyle())
                }
            }
        }
    }

    // MARK: Recommendations

    private var recommendationsCard: some View {
        let tips = recommendations
        return Group {
            if !tips.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader("Coffee Notes")
                    CremaCard {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(tips.enumerated()), id: \.offset) { idx, tip in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "sparkles")
                                        .font(.crema(15))
                                        .foregroundStyle(CremaColor.caramel)
                                        .frame(width: 22)
                                    Text(tip)
                                        .font(.crema(14))
                                        .foregroundStyle(CremaColor.textPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 0)
                                }
                                if idx != tips.count - 1 { Divider().overlay(CremaColor.separator) }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: Check-in button

    private var checkInButton: some View {
        VStack {
            Spacer()
            Button {
                HapticEngine.tap()
                showCheckIn = true
            } label: {
                Label("Check In", systemImage: "camera.fill")
                    .font(.crema(18, .bold))
                    .foregroundStyle(CremaColor.background)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [CremaColor.espresso, CremaColor.caramel],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
                    .shadow(color: CremaColor.espresso.opacity(0.35), radius: 12, y: 5)
            }
            .buttonStyle(PressableStyle())
            .padding(.bottom, 18)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            EmptyStateView(systemImage: "map.fill",
                           title: "Start your coffee passport",
                           message: "Check into cafés to capture coffee memories, build a personal map, and remember where you've had the best cup.")
            Button {
                HapticEngine.tap()
                showCheckIn = true
            } label: {
                Label("Check In", systemImage: "camera.fill")
                    .font(.crema(17, .bold))
                    .foregroundStyle(CremaColor.background)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 15)
                    .background(CremaColor.espresso)
                    .clipShape(Capsule())
            }
            .buttonStyle(PressableStyle())
        }
        .padding(24)
    }

    // MARK: Insight helpers

    private var topCity: String {
        let cities = visitedCafes.map(\.city).filter { !$0.isEmpty }
        guard !cities.isEmpty else { return "—" }
        let counts = Dictionary(grouping: cities) { $0 }.mapValues(\.count)
        return counts.max { $0.value < $1.value }?.key ?? "—"
    }

    /// Pattern-spotting recommendations that grow with history.
    private var recommendations: [String] {
        var tips: [String] = []
        let visits = allVisits
        guard visits.count >= 3 else { return tips }

        if let best = visitedCafes.filter({ $0.hasVisited }).max(by: { $0.averageRating < $1.averageRating }) {
            tips.append("\(best.name) is your highest-rated café at \(String(format: "%.1f", best.averageRating))/10.")
        }

        let drinkCounts = Dictionary(grouping: visits) { $0.drink }.mapValues(\.count)
        if let fav = drinkCounts.max(by: { $0.value < $1.value }), fav.value >= 3 {
            tips.append("Your go-to order is the \(fav.key.rawValue.lowercased()) — \(fav.value) check-ins so far.")
        }

        if topCity != "—" {
            tips.append("\(topCity) is your most-explored coffee city. Keep hunting for hidden gems there.")
        }

        let wishlistCount = cafes.filter { $0.wantToVisit && !$0.hasVisited }.count
        if wishlistCount > 0 {
            tips.append("You have \(wishlistCount) café\(wishlistCount == 1 ? "" : "s") on your wishlist. Time for a coffee adventure?")
        }
        return Array(tips.prefix(4))
    }
}

/// A lightweight search sheet for adding "want to visit" cafés to the wishlist.
private struct WishlistSearchSheet: View {
    var location: CafeLocationService
    var existingCafes: [Cafe]
    var onAdd: (CafeResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [CafeResult] = []
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").foregroundStyle(CremaColor.textTertiary)
                        TextField("Search a café to save", text: $query)
                            .font(.crema(16, .medium))
                            .foregroundStyle(CremaColor.textPrimary)
                            .tint(CremaColor.crema)
                            .autocorrectionDisabled()
                    }
                    .padding(14)
                    .background(CremaColor.surface)
                    .clipShape(.rect(cornerRadius: CremaRadius.field))

                    if results.isEmpty && !query.isEmpty && !isSearching {
                        Text("No cafés found.")
                            .font(.crema(14, .medium))
                            .foregroundStyle(CremaColor.textSecondary)
                    }
                    ForEach(results) { r in
                        Button {
                            HapticEngine.success()
                            onAdd(r)
                            dismiss()
                        } label: {
                            CremaCard(padding: 12) {
                                HStack(spacing: 12) {
                                    Image(systemName: "bookmark.fill")
                                        .font(.crema(16))
                                        .foregroundStyle(CremaColor.caramel)
                                        .frame(width: 44, height: 44)
                                        .background(CremaColor.surface)
                                        .clipShape(.rect(cornerRadius: 12))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(r.name).font(.crema(15, .bold)).foregroundStyle(CremaColor.textPrimary).lineLimit(1)
                                        let sub = [r.address, r.city].filter { !$0.isEmpty }.joined(separator: ", ")
                                        if !sub.isEmpty {
                                            Text(sub).font(.crema(12, .medium)).foregroundStyle(CremaColor.textSecondary).lineLimit(1)
                                        }
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: "plus.circle.fill").foregroundStyle(CremaColor.espresso)
                                }
                            }
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(CremaColor.background)
            .navigationTitle("Add to Wishlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
            .onChange(of: query) { _, q in
                Task {
                    isSearching = true
                    results = await location.search(query: q)
                    isSearching = false
                }
            }
        }
    }
}
