//
//  HistoryView.swift
//  CremaDialed
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Brew.date, order: .reverse) private var brews: [Brew]
    @State private var search = ""
    @State private var minRating = 0
    @State private var goldenOnly = false
    @State private var showInsights = false

    private var filtered: [Brew] {
        brews.filter { brew in
            (minRating == 0 || brew.overall >= minRating) &&
            (!goldenOnly || brew.isGolden) &&
            (search.isEmpty ||
                (brew.bean?.name.localizedStandardContains(search) ?? false) ||
                (brew.bean?.roaster.localizedStandardContains(search) ?? false) ||
                (brew.machine?.displayName.localizedStandardContains(search) ?? false))
        }
    }

    private var grouped: [(String, [Brew])] {
        let dict = Dictionary(grouping: filtered) { brew in
            brew.date.formatted(.dateTime.month(.wide).year())
        }
        return dict.sorted { ($0.value.first?.date ?? .distantPast) > ($1.value.first?.date ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CremaColor.background.ignoresSafeArea()
                if brews.isEmpty {
                    EmptyStateView(systemImage: "book.closed.fill",
                                   title: "Your journal is empty",
                                   message: "Every shot you log lands here — your personal coffee journal.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            filterBar
                            ForEach(grouped, id: \.0) { month, items in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(month)
                                        .font(.crema(14, .bold))
                                        .foregroundStyle(CremaColor.textSecondary)
                                    ForEach(items) { brew in
                                        SwipeToDelete(
                                            onDelete: { deleteBrew(brew) },
                                            confirmTitle: "Delete Journal Entry?",
                                            confirmMessage: "This action cannot be undone."
                                        ) {
                                            NavigationLink(value: brew) { BrewRow(brew: brew) }
                                                .buttonStyle(PressableStyle())
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Journal")
            .searchable(text: $search, prompt: "Search beans, roasters, machines")
            .navigationDestination(for: Brew.self) { BrewDetailView(brew: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticEngine.light(); showInsights = true
                    } label: {
                        Image(systemName: "chart.bar.fill").foregroundStyle(CremaColor.espresso)
                    }
                }
            }
            .sheet(isPresented: $showInsights) { InsightsView() }
        }
    }

    private func deleteBrew(_ brew: Brew) {
        // Deleting the shot removes it everywhere it appears (journal, insights,
        // bean history, recent activity) because those surfaces all read from
        // the same live SwiftData store. Relationships are nullified, so the
        // bean / machine / grinder it referenced are preserved.
        modelContext.delete(brew)
        HapticEngine.warning()
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CremaChip(label: "Golden", systemImage: "star.fill", isSelected: goldenOnly) {
                    goldenOnly.toggle()
                }
                ForEach([8, 6], id: \.self) { rating in
                    CremaChip(label: "\(rating)+", systemImage: "star", isSelected: minRating == rating) {
                        minRating = minRating == rating ? 0 : rating
                    }
                }
            }
        }
    }
}

struct BrewRow: View {
    let brew: Brew

    var body: some View {
        CremaCard {
            HStack(spacing: 14) {
                VStack(spacing: 2) {
                    Text("\(brew.overall)")
                        .font(.crema(22, .bold))
                        .foregroundStyle(scoreTint)
                    Text("/10")
                        .font(.crema(10, .semibold))
                        .foregroundStyle(CremaColor.textTertiary)
                }
                .frame(width: 48)
                .padding(.vertical, 8)
                .background(CremaColor.surface)
                .clipShape(.rect(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(brew.bean?.name ?? "Unknown bean")
                            .font(.crema(16, .bold))
                            .foregroundStyle(CremaColor.textPrimary)
                            .lineLimit(1)
                        if brew.isGolden {
                            Image(systemName: "star.fill")
                                .font(.crema(11))
                                .foregroundStyle(CremaColor.crema)
                        }
                    }
                    Text("\(brew.basket.rawValue) · \(UnitPreferences.weightLabel(grams: brew.dose)) → \(UnitPreferences.weightLabel(grams: brew.yield))")
                        .font(.crema(13, .medium))
                        .foregroundStyle(CremaColor.textSecondary)
                    Text("\(brew.ratioLabel) · \(Int(brew.shotTime))s")
                        .font(.crema(12, .medium))
                        .foregroundStyle(CremaColor.textTertiary)
                    Text(brew.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.crema(12))
                        .foregroundStyle(CremaColor.textTertiary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.crema(13, .semibold))
                    .foregroundStyle(CremaColor.textTertiary)
            }
        }
    }

    private var scoreTint: Color {
        switch brew.overall {
        case 8...10: return CremaColor.positive
        case 5...7: return CremaColor.caramel
        default: return CremaColor.negative
        }
    }
}
