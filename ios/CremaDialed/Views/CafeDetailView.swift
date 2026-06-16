//
//  CafeDetailView.swift
//  CremaDialed
//
//  A café profile: cover hero, passport stats, photo gallery, personal notes
//  and a scrollable journal of coffee memories.
//

import SwiftUI
import MapKit
import UIKit

struct CafeDetailView: View {
    @Bindable var cafe: Cafe
    /// Begin a check-in for this café.
    var onCheckIn: () -> Void = {}

    @State private var viewerPhoto: PhotoItem?

    private var visits: [CafeVisit] { cafe.sortedVisits }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                hero
                actionRow
                if cafe.hasVisited { historyCard }
                if !cafe.allPhotos.isEmpty { photoGallery }
                notesCard
                mapCard
                journalSection
            }
            .padding(.bottom, 24)
        }
        .background(CremaColor.background)
        .navigationTitle(cafe.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !cafe.hasVisited {
                    Button {
                        HapticEngine.selection()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { cafe.wantToVisit.toggle() }
                    } label: {
                        Image(systemName: cafe.wantToVisit ? "bookmark.fill" : "bookmark")
                            .foregroundStyle(cafe.wantToVisit ? CremaColor.caramel : CremaColor.espresso)
                    }
                }
                Button {
                    HapticEngine.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { cafe.isFavourite.toggle() }
                } label: {
                    Image(systemName: cafe.isFavourite ? "heart.fill" : "heart")
                        .foregroundStyle(cafe.isFavourite ? CremaColor.negative : CremaColor.espresso)
                }
            }
        }
        .fullScreenCover(item: $viewerPhoto) { item in
            PhotoViewer(data: item.data) { viewerPhoto = nil }
        }
    }

    // MARK: Hero

    private var hero: some View {
        Color(.secondarySystemBackground)
            .frame(height: 240)
            .overlay {
                if let data = cafe.coverPhoto, let image = UIImage(data: data) {
                    Image(uiImage: image).resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false)
                } else {
                    LinearGradient(colors: [CremaColor.espresso, CremaColor.caramel],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            }
            .overlay {
                LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom)
                    .allowsHitTesting(false)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 5) {
                    if cafe.isFavourite {
                        Label("Favourite", systemImage: "heart.fill")
                            .font(.crema(11, .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 9).padding(.vertical, 5)
                            .background(CremaColor.negative)
                            .clipShape(Capsule())
                    }
                    Text(cafe.name)
                        .font(.crema(28, .bold))
                        .foregroundStyle(.white)
                    HStack(spacing: 12) {
                        if !cafe.city.isEmpty {
                            Label(cafe.city, systemImage: "mappin.and.ellipse")
                                .font(.crema(13, .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        if cafe.hasVisited {
                            Label(String(format: "%.1f", cafe.averageRating), systemImage: "cup.and.saucer.fill")
                                .font(.crema(13, .bold))
                                .foregroundStyle(CremaColor.background)
                                .padding(.horizontal, 9).padding(.vertical, 4)
                                .background(CremaColorTintForScore(cafe.averageRating))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(20)
            }
            .ignoresSafeArea(edges: .top)
    }

    // MARK: Actions

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button {
                HapticEngine.tap()
                MapsLauncher.directions(to: cafe.coordinate, name: cafe.name)
            } label: {
                Label("Directions", systemImage: "location.north.line.fill")
                    .font(.crema(15, .bold))
                    .foregroundStyle(CremaColor.espresso)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(CremaColor.espresso.opacity(0.12))
                    .clipShape(.rect(cornerRadius: CremaRadius.field))
            }
            .buttonStyle(PressableStyle())

            Button {
                HapticEngine.tap()
                onCheckIn()
            } label: {
                Label("Check In", systemImage: "cup.and.saucer.fill")
                    .font(.crema(15, .bold))
                    .foregroundStyle(CremaColor.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [CremaColor.espresso, CremaColor.caramel],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(.rect(cornerRadius: CremaRadius.field))
            }
            .buttonStyle(PressableStyle())
        }
        .padding(.horizontal, 16)
    }

    // MARK: Your history

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Your History")
            CremaCard {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    historyStat("\(cafe.visits.count)", "Total Visits", "arrow.triangle.2.circlepath", CremaColor.espresso)
                    historyStat(String(format: "%.1f", cafe.averageRating), "Average Rating", "cup.and.saucer.fill", CremaColor.crema)
                    historyStat(cafe.favouriteDrink?.rawValue ?? "—", "Favourite Drink", "heart.fill", CremaColor.caramel)
                    historyStat(lastVisitLabel, "Last Visit", "calendar", CremaColor.positive)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var lastVisitLabel: String {
        guard let last = cafe.lastVisit else { return "—" }
        return last.formatted(.relative(presentation: .named))
    }

    private func historyStat(_ value: String, _ label: String, _ icon: String, _ tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.crema(15, .semibold))
                .foregroundStyle(tint)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.crema(16, .bold))
                    .foregroundStyle(CremaColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(.crema(11, .medium))
                    .foregroundStyle(CremaColor.textTertiary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: Photo gallery

    private var photoGallery: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Gallery")
                .padding(.horizontal, 16)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(cafe.allPhotos.enumerated()), id: \.offset) { _, data in
                        if let image = UIImage(data: data) {
                            Color(.secondarySystemBackground)
                                .frame(width: 150, height: 150)
                                .overlay { Image(uiImage: image).resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false) }
                                .clipShape(.rect(cornerRadius: 14))
                                .onTapGesture { HapticEngine.tap(); viewerPhoto = PhotoItem(data: data) }
                        }
                    }
                }
            }
            .contentMargins(.horizontal, 16)
        }
    }

    // MARK: Notes

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Personal Notes")
            CremaCard {
                TextField("Order the single origin pour over, sit by the window…",
                          text: $cafe.personalNotes, axis: .vertical)
                    .font(.crema(15, .medium))
                    .foregroundStyle(CremaColor.textPrimary)
                    .tint(CremaColor.crema)
                    .lineLimit(2...6)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: Map

    private var mapCard: some View {
        VStack(spacing: 12) {
            Map(initialPosition: .region(MKCoordinateRegion(
                center: cafe.coordinate,
                latitudinalMeters: 600, longitudinalMeters: 600
            ))) {
                Marker(cafe.name, systemImage: "cup.and.saucer.fill", coordinate: cafe.coordinate)
                    .tint(CremaColor.espresso)
            }
            .frame(height: 160)
            .clipShape(.rect(cornerRadius: CremaRadius.card))
            .allowsHitTesting(false)

            Button {
                HapticEngine.tap()
                openInMaps()
            } label: {
                Label("Directions", systemImage: "location.north.line.fill")
                    .font(.crema(15, .bold))
                    .foregroundStyle(CremaColor.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(CremaColor.espresso)
                    .clipShape(.rect(cornerRadius: CremaRadius.field))
            }
            .buttonStyle(PressableStyle())
        }
        .padding(.horizontal, 16)
    }

    /// Opens Apple Maps with directions to this café from the user's current location.
    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: cafe.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = cafe.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault
        ])
    }

    // MARK: Journal

    private var journalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !visits.isEmpty {
                SectionHeader("Recent Check-Ins")
                ForEach(visits) { visit in
                    MemoryCard(visit: visit) { data in viewerPhoto = PhotoItem(data: data) }
                }
            } else {
                CremaCard {
                    Text("No check-ins yet. Tap Check In to start your coffee journal here.")
                        .font(.crema(14, .medium))
                        .foregroundStyle(CremaColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

/// Tint for a café's average score badge.
private func CremaColorTintForScore(_ score: Double) -> Color {
    CoffeeScoreStyle.tint(Int(score.rounded()))
}

/// A journal-style memory card for a single visit.
private struct MemoryCard: View {
    let visit: CafeVisit
    let onTapPhoto: (Data) -> Void

    private var photos: [Data] { visit.orderedPhotos }

    var body: some View {
        CremaCard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                if let cover = visit.coverPhoto, let image = UIImage(data: cover) {
                    Color(.secondarySystemBackground)
                        .frame(height: 200)
                        .overlay { Image(uiImage: image).resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false) }
                        .overlay(alignment: .topTrailing) {
                            CoffeeScoreBadge(score: Double(visit.coffeeScore))
                                .padding(12)
                        }
                        .clipShape(.rect(topLeadingRadius: CremaRadius.card, topTrailingRadius: CremaRadius.card))
                        .onTapGesture { HapticEngine.tap(); onTapPhoto(cover) }
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label(visit.drink.rawValue, systemImage: visit.drink.systemImage)
                            .font(.crema(17, .bold))
                            .foregroundStyle(CremaColor.textPrimary)
                        Spacer()
                        if visit.coverPhoto == nil {
                            CoffeeScoreBadge(score: Double(visit.coffeeScore))
                        }
                    }
                    Text(visit.date.formatted(date: .complete, time: .shortened))
                        .font(.crema(12, .medium))
                        .foregroundStyle(CremaColor.textSecondary)

                    if photos.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(photos.dropFirst().enumerated()), id: \.offset) { _, data in
                                    if let image = UIImage(data: data) {
                                        Color(.secondarySystemBackground)
                                            .frame(width: 90, height: 90)
                                            .overlay { Image(uiImage: image).resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false) }
                                            .clipShape(.rect(cornerRadius: 10))
                                            .onTapGesture { HapticEngine.tap(); onTapPhoto(data) }
                                    }
                                }
                            }
                        }
                    }

                    let tags = visit.coffeeTags + visit.venueTags
                    if !tags.isEmpty {
                        TagChipsRow(tags: tags, tint: CremaColor.surface)
                    }

                    if visit.wouldReturn {
                        Label("Would return", systemImage: "heart.fill")
                            .font(.crema(12, .semibold))
                            .foregroundStyle(CremaColor.negative)
                    }

                    if visit.usedAdvanced {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            if visit.coffeeQuality > 0 { ratingPill("Coffee", visit.coffeeQuality) }
                            if visit.milkQuality > 0 { ratingPill("Milk", visit.milkQuality) }
                            if visit.extractionQuality > 0 { ratingPill("Espresso", visit.extractionQuality) }
                            if visit.temperature > 0 { ratingPill("Temp", visit.temperature) }
                            if visit.service > 0 { ratingPill("Service", visit.service) }
                            if visit.atmosphere > 0 { ratingPill("Atmos", visit.atmosphere) }
                            if visit.value > 0 { ratingPill("Value", visit.value) }
                            if visit.consistency > 0 { ratingPill("Consist", visit.consistency) }
                            if visit.foodQuality > 0 { ratingPill("Food", visit.foodQuality) }
                        }
                    }

                    if !visit.notes.isEmpty {
                        Text(visit.notes)
                            .font(.crema(15))
                            .italic()
                            .foregroundStyle(CremaColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
            }
        }
    }

    private func ratingPill(_ label: String, _ value: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.crema(18, .bold))
                .foregroundStyle(value >= 8 ? CremaColor.positive : (value >= 5 ? CremaColor.caramel : CremaColor.negative))
            Text(label.uppercased())
                .font(.crema(9, .semibold))
                .foregroundStyle(CremaColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(CremaColor.surface)
        .clipShape(.rect(cornerRadius: 10))
    }
}

/// Identifiable wrapper so a photo can drive a full-screen viewer.
private struct PhotoItem: Identifiable {
    let id = UUID()
    let data: Data
}

/// A simple full-screen, zoomable photo viewer.
private struct PhotoViewer: View {
    let data: Data
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .ignoresSafeArea()
            }
            VStack {
                HStack {
                    Spacer()
                    Button { HapticEngine.light(); onClose() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white, .black.opacity(0.4))
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}
