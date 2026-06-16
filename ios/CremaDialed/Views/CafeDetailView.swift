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

    @State private var viewerPhoto: PhotoItem?

    private var visits: [CafeVisit] { cafe.sortedVisits }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                hero
                statRow
                actionRow
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
                VStack(alignment: .leading, spacing: 4) {
                    if cafe.isFavourite {
                        Label("Favourite", systemImage: "heart.fill")
                            .font(.crema(11, .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 9).padding(.vertical, 5)
                            .background(CremaColor.negative)
                            .clipShape(Capsule())
                    }
                    Text(cafe.name)
                        .font(.crema(26, .bold))
                        .foregroundStyle(.white)
                    if !cafe.city.isEmpty {
                        Label(cafe.city, systemImage: "mappin.and.ellipse")
                            .font(.crema(13, .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .padding(20)
            }
            .ignoresSafeArea(edges: .top)
    }

    // MARK: Stats

    private var statRow: some View {
        CremaCard {
            HStack(spacing: 0) {
                stat(cafe.hasVisited ? String(format: "%.1f", cafe.averageRating) : "—", "RATING", CremaColor.crema)
                divider
                stat("\(cafe.visits.count)", "VISITS", CremaColor.espresso)
                divider
                stat(cafe.favouriteDrink?.rawValue ?? "—", "FAVOURITE", CremaColor.caramel, small: true)
            }
        }
        .padding(.horizontal, 16)
    }

    private func stat(_ value: String, _ label: String, _ tint: Color, small: Bool = false) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.crema(small ? 16 : 26, .bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.crema(10, .semibold))
                .foregroundStyle(CremaColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 40)
    }

    private var divider: some View {
        Rectangle().fill(CremaColor.separator).frame(width: 1, height: 36)
    }

    // MARK: Actions

    private var actionRow: some View {
        HStack(spacing: 12) {
            toggleButton(title: cafe.isFavourite ? "Favourited" : "Favourite",
                         symbol: cafe.isFavourite ? "heart.fill" : "heart",
                         active: cafe.isFavourite, tint: CremaColor.negative) {
                cafe.isFavourite.toggle()
            }
            toggleButton(title: cafe.wantToVisit ? "On Wishlist" : "Want to Visit",
                         symbol: cafe.wantToVisit ? "bookmark.fill" : "bookmark",
                         active: cafe.wantToVisit, tint: CremaColor.caramel) {
                cafe.wantToVisit.toggle()
            }
        }
        .padding(.horizontal, 16)
    }

    private func toggleButton(title: String, symbol: String, active: Bool, tint: Color, action: @escaping () -> Void) -> some View {
        Button {
            HapticEngine.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { action() }
        } label: {
            Label(title, systemImage: symbol)
                .font(.crema(14, .bold))
                .foregroundStyle(active ? CremaColor.background : tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(active ? tint : tint.opacity(0.12))
                .clipShape(.rect(cornerRadius: CremaRadius.field))
        }
        .buttonStyle(PressableStyle())
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
                SectionHeader("Coffee Journal")
                ForEach(visits) { visit in
                    MemoryCard(visit: visit) { data in viewerPhoto = PhotoItem(data: data) }
                }
            } else {
                CremaCard {
                    Text("No check-ins yet — this café is on your wishlist. Check in to start your journal here.")
                        .font(.crema(14, .medium))
                        .foregroundStyle(CremaColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, 16)
    }
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
                            ratingPill("Coffee", visit.coffeeQuality)
                            ratingPill("Milk", visit.milkQuality)
                            ratingPill("Espresso", visit.extractionQuality)
                            ratingPill("Temp", visit.temperature)
                            ratingPill("Service", visit.service)
                            ratingPill("Atmos", visit.atmosphere)
                            ratingPill("Value", visit.value)
                            ratingPill("Consist", visit.consistency)
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
