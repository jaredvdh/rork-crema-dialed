//
//  InsightsView.swift
//  CremaDialed
//

import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query private var brews: [Brew]
    @Query private var beans: [Bean]

    private var sortedByDate: [Brew] { brews.sorted { $0.date < $1.date } }

    var body: some View {
        NavigationStack {
            ZStack {
                CremaColor.background.ignoresSafeArea()
                if brews.isEmpty {
                    EmptyStateView(systemImage: "chart.bar.fill",
                                   title: "No insights yet",
                                   message: "Log a few shots and your coffee trends will appear here.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            statGrid
                            scoreTrendCard
                            extractionCard
                            doseConsistencyCard
                            favouritesCard
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    // MARK: Stats

    private var avgScore: Double {
        guard !brews.isEmpty else { return 0 }
        return Double(brews.map(\.overall).reduce(0, +)) / Double(brews.count)
    }
    private var avgRatio: Double {
        let ratios = brews.map(\.ratio).filter { $0 > 0 }
        guard !ratios.isEmpty else { return 0 }
        return ratios.reduce(0, +) / Double(ratios.count)
    }

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricTile(label: "Avg Score", value: String(format: "%.1f", avgScore), caption: "across \(brews.count) shots")
            MetricTile(label: "Avg Ratio", value: String(format: "1:%.1f", avgRatio), tint: CremaColor.espresso)
            MetricTile(label: "Total Shots", value: "\(brews.count)", tint: CremaColor.caramel)
            MetricTile(label: "Golden Recipes", value: "\(brews.filter(\.isGolden).count)", caption: "dialed in")
        }
    }

    // MARK: Score trend

    private var scoreTrendCard: some View {
        CremaCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Score Trend")
                    .font(.crema(16, .bold))
                    .foregroundStyle(CremaColor.textPrimary)
                Chart(Array(sortedByDate.enumerated()), id: \.offset) { index, brew in
                    LineMark(x: .value("Shot", index), y: .value("Score", brew.overall))
                        .foregroundStyle(CremaColor.crema)
                        .interpolationMethod(.catmullRom)
                    AreaMark(x: .value("Shot", index), y: .value("Score", brew.overall))
                        .foregroundStyle(LinearGradient(colors: [CremaColor.crema.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.catmullRom)
                }
                .chartYScale(domain: 0...10)
                .chartYAxis { AxisMarks(values: [0, 5, 10]) }
                .chartXAxis(.hidden)
                .frame(height: 160)
            }
        }
    }

    // MARK: Extraction (shot time)

    private var extractionCard: some View {
        CremaCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Extraction Time")
                    .font(.crema(16, .bold))
                    .foregroundStyle(CremaColor.textPrimary)
                Chart(Array(sortedByDate.enumerated()), id: \.offset) { index, brew in
                    BarMark(x: .value("Shot", index), y: .value("Seconds", brew.shotTime))
                        .foregroundStyle(brew.shotTime >= 25 && brew.shotTime <= 32 ? CremaColor.positive : CremaColor.caramel)
                }
                .chartXAxis(.hidden)
                .frame(height: 140)
                Text("Sweet spot 25–32s shown in green.")
                    .font(.crema(12, .medium))
                    .foregroundStyle(CremaColor.textSecondary)
            }
        }
    }

    // MARK: Dose consistency

    private var doseConsistencyCard: some View {
        let doses = brews.map(\.dose)
        let spread = (doses.max() ?? 0) - (doses.min() ?? 0)
        return CremaCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Dose Consistency")
                    .font(.crema(16, .bold))
                    .foregroundStyle(CremaColor.textPrimary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(String(format: "±%.1f", spread / 2))
                        .font(.crema(30, .bold))
                        .foregroundStyle(spread <= 1 ? CremaColor.positive : CremaColor.warning)
                    Text("g spread")
                        .font(.crema(14, .medium))
                        .foregroundStyle(CremaColor.textSecondary)
                }
                Text(spread <= 1 ? "Excellent dosing consistency." : "Try to tighten your dose for more repeatable shots.")
                    .font(.crema(13, .medium))
                    .foregroundStyle(CremaColor.textSecondary)
            }
        }
    }

    // MARK: Favourites

    private var favouritesCard: some View {
        CremaCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Favourites")
                    .font(.crema(16, .bold))
                    .foregroundStyle(CremaColor.textPrimary)
                favRow("Best Bean", bestBean, "leaf.fill")
                Divider().overlay(CremaColor.separator)
                favRow("Favourite Roaster", topRoaster, "building.2.fill")
                Divider().overlay(CremaColor.separator)
                favRow("Most-used Machine", topMachine, "cup.and.saucer.fill")
            }
        }
    }

    private func favRow(_ label: String, _ value: String, _ symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.crema(15))
                .foregroundStyle(CremaColor.crema)
                .frame(width: 24)
            Text(label)
                .font(.crema(14, .medium))
                .foregroundStyle(CremaColor.textSecondary)
            Spacer()
            Text(value)
                .font(.crema(15, .semibold))
                .foregroundStyle(CremaColor.textPrimary)
        }
    }

    private var bestBean: String {
        let grouped = Dictionary(grouping: brews.filter { $0.bean != nil }) { $0.bean!.id }
        let best = grouped.max { a, b in
            avg(a.value) < avg(b.value)
        }
        return best?.value.first?.bean?.name ?? "—"
    }
    private func avg(_ list: [Brew]) -> Double {
        guard !list.isEmpty else { return 0 }
        return Double(list.map(\.overall).reduce(0, +)) / Double(list.count)
    }
    private var topRoaster: String {
        let roasters = brews.compactMap { $0.bean?.roaster }.filter { !$0.isEmpty }
        return mostFrequent(roasters) ?? "—"
    }
    private var topMachine: String {
        let names = brews.compactMap { $0.machine?.displayName }
        return mostFrequent(names) ?? "—"
    }
    private func mostFrequent(_ list: [String]) -> String? {
        guard !list.isEmpty else { return nil }
        let counts = Dictionary(grouping: list) { $0 }.mapValues(\.count)
        return counts.max { $0.value < $1.value }?.key
    }
}
