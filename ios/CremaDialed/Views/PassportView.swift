//
//  PassportView.swift
//  CremaDialed
//
//  Your personal coffee journal: lifetime statistics, a map of every café
//  you've visited, browsable collections, and a passport summary of your
//  coffee story. Everything is stored locally on this device.
//

import SwiftUI
import MapKit

/// Lenses for browsing the visited-café collection.
enum PassportFilter: String, CaseIterable, Identifiable {
    case recent = "Recent"
    case topRated = "Top Rated"
    case mostVisited = "Most Visited"
    case favourites = "Favourites"
    case wishlist = "Wishlist"
    var id: String { rawValue }
}

struct PassportView: View {
    var cafes: [Cafe]
    var onCheckIn: () -> Void
    var onDelete: (Cafe) -> Void

    @State private var filter: PassportFilter = .recent
    @State private var mapPosition: MapCameraPosition = .automatic

    private var visitedCafes: [Cafe] { cafes.filter { $0.hasVisited } }
    private var favourites: [Cafe] { cafes.filter { $0.isFavourite } }
    private var wishlist: [Cafe] { cafes.filter { $0.wantToVisit && !$0.hasVisited } }
    private var allVisits: [CafeVisit] { cafes.flatMap(\.visits) }

    var body: some View {
        if visitedCafes.isEmpty && wishlist.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(spacing: 22) {
                    statistics
                    if !visitedCafes.isEmpty { coffeeMap }
                    collectionSection
                    passportSummary
                }
                .padding(16)
                .padding(.bottom, 90)
            }
        }
    }

    // MARK: Statistics

    private var statistics: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricTile(label: "Cafés Visited", value: "\(visitedCafes.count)", tint: CremaColor.espresso)
            MetricTile(label: "Total Check-Ins", value: "\(allVisits.count)", tint: CremaColor.caramel)
            MetricTile(label: "Favourites", value: "\(favourites.count)", tint: CremaColor.negative)
            MetricTile(label: "Average Rating",
                       value: averageRating > 0 ? String(format: "%.1f", averageRating) : "—",
                       tint: CremaColor.crema)
        }
    }

    private var averageRating: Double {
        guard !visitedCafes.isEmpty else { return 0 }
        return visitedCafes.map(\.averageRating).reduce(0, +) / Double(visitedCafes.count)
    }

    // MARK: Coffee map

    private var coffeeMap: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Your Coffee Map")
            Map(position: $mapPosition) {
                ForEach(visitedCafes) { cafe in
                    Annotation(cafe.name, coordinate: cafe.coordinate) {
                        NavigationLink(value: cafe.id) {
                            ZStack {
                                Circle()
                                    .fill(cafe.isFavourite ? CremaColor.negative : CremaColor.espresso)
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
    }

    // MARK: Collections

    private var filteredCafes: [Cafe] {
        switch filter {
        case .recent:
            return visitedCafes.sorted { ($0.lastVisit ?? .distantPast) > ($1.lastVisit ?? .distantPast) }
        case .topRated:
            return visitedCafes.sorted { $0.averageRating > $1.averageRating }
        case .mostVisited:
            return visitedCafes.sorted { $0.visits.count > $1.visits.count }
        case .favourites:
            return favourites.sorted { ($0.lastVisit ?? .distantPast) > ($1.lastVisit ?? .distantPast) }
        case .wishlist:
            return wishlist
        }
    }

    private var collectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Collections")
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
                    Text(emptyCollectionMessage)
                        .font(.crema(14, .medium))
                        .foregroundStyle(CremaColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(filteredCafes) { cafe in
                    SwipeToDelete(onDelete: { onDelete(cafe) }) {
                        NavigationLink(value: cafe.id) { CafeListRow(cafe: cafe) }
                            .buttonStyle(PressableStyle())
                    }
                }
            }
        }
    }

    private var emptyCollectionMessage: String {
        switch filter {
        case .favourites: return "No favourites yet. Tap the heart on a café you love."
        case .wishlist: return "Your wishlist is empty. Save coffee houses you'd like to try."
        default: return "No cafés here yet — check in to start your journal."
        }
    }

    // MARK: Passport summary

    private var passportSummary: some View {
        let rows = summaryRows
        return Group {
            if !rows.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader("Passport Summary")
                    CremaCard {
                        VStack(spacing: 0) {
                            ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                                HStack(spacing: 12) {
                                    Image(systemName: row.icon)
                                        .font(.crema(15, .semibold))
                                        .foregroundStyle(row.tint)
                                        .frame(width: 26)
                                    Text(row.label)
                                        .font(.crema(14, .medium))
                                        .foregroundStyle(CremaColor.textSecondary)
                                    Spacer(minLength: 12)
                                    Text(row.value)
                                        .font(.crema(15, .bold))
                                        .foregroundStyle(CremaColor.textPrimary)
                                        .lineLimit(1)
                                        .multilineTextAlignment(.trailing)
                                }
                                .padding(.vertical, 11)
                                if idx != rows.count - 1 { Divider().overlay(CremaColor.separator) }
                            }
                        }
                    }
                }
            }
        }
    }

    private struct SummaryRow { let icon: String; let label: String; let value: String; let tint: Color }

    private var summaryRows: [SummaryRow] {
        guard !visitedCafes.isEmpty else { return [] }
        var rows: [SummaryRow] = []

        if let favourite = favourites.sorted(by: { $0.averageRating > $1.averageRating }).first
            ?? visitedCafes.max(by: { $0.averageRating < $1.averageRating }) {
            rows.append(SummaryRow(icon: "heart.fill", label: "Favourite Café",
                                   value: favourite.name, tint: CremaColor.negative))
        }
        if let mostVisited = visitedCafes.max(by: { $0.visits.count < $1.visits.count }) {
            rows.append(SummaryRow(icon: "arrow.triangle.2.circlepath", label: "Most Visited",
                                   value: "\(mostVisited.name) · \(mostVisited.visits.count)", tint: CremaColor.espresso))
        }
        if let topRated = visitedCafes.max(by: { $0.averageRating < $1.averageRating }) {
            rows.append(SummaryRow(icon: "star.fill", label: "Highest Rated",
                                   value: "\(topRated.name) · \(String(format: "%.1f", topRated.averageRating))",
                                   tint: CremaColor.crema))
        }
        let drinkCounts = Dictionary(grouping: allVisits) { $0.drink }.mapValues(\.count)
        if let favDrink = drinkCounts.max(by: { $0.value < $1.value })?.key {
            rows.append(SummaryRow(icon: "cup.and.saucer.fill", label: "Favourite Drink",
                                   value: favDrink.rawValue, tint: CremaColor.caramel))
        }
        rows.append(SummaryRow(icon: "checklist", label: "Total Coffees Logged",
                               value: "\(allVisits.count)", tint: CremaColor.positive))
        return rows
    }

    // MARK: Empty

    private var emptyState: some View {
        VStack(spacing: 20) {
            EmptyStateView(systemImage: "book.closed.fill",
                           title: "Your passport is empty",
                           message: "Check into cafés to capture coffee memories, build a personal map and remember where you've had the best cup.")
            Button {
                HapticEngine.tap()
                onCheckIn()
            } label: {
                Label("Check In", systemImage: "cup.and.saucer.fill")
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
        .frame(maxHeight: .infinity)
    }
}
