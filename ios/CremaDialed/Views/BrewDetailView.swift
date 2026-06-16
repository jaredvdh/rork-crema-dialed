//
//  BrewDetailView.swift
//  CremaDialed
//

import SwiftUI
import SwiftData

struct BrewDetailView: View {
    @Bindable var brew: Brew
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var goldens: [DialedRecipe]

    private var golden: DialedRecipe? {
        guard let bean = brew.bean else { return nil }
        return goldens.first { $0.bean?.id == bean.id }
    }

    private var tips: [CoachTip] {
        if let golden { return DialInCoach.analyze(brew) + DialInCoach.compareToGolden(brew, golden: golden) }
        return DialInCoach.analyze(brew)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                scoreHeader

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    MetricTile(label: "Dose", value: String(format: "%.1fg", brew.dose))
                    MetricTile(label: "Yield", value: String(format: "%.1fg", brew.yield))
                    MetricTile(label: "Ratio", value: brew.ratioLabel, tint: CremaColor.espresso)
                    MetricTile(label: "Shot Time", value: "\(Int(brew.shotTime))s", tint: CremaColor.caramel)
                    MetricTile(label: "Water Temp", value: String(format: "%.1f°C", brew.waterTemp))
                    MetricTile(label: "Pressure", value: String(format: "%.0f bar", brew.pressure))
                }

                if !brew.grindSetting.isEmpty || brew.grinder != nil {
                    CremaCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("EQUIPMENT")
                                .font(.crema(11, .semibold))
                                .foregroundStyle(CremaColor.textTertiary)
                            if let m = brew.machine { infoRow("Machine", m.displayName) }
                            if let g = brew.grinder { infoRow("Grinder", g.displayName) }
                            if !brew.grindSetting.isEmpty { infoRow("Grind", brew.grindSetting) }
                        }
                    }
                }

                SectionHeader("Taste Profile")
                CremaCard {
                    VStack(spacing: 10) {
                        tasteBar("Acidity", brew.acidity)
                        tasteBar("Sweetness", brew.sweetness)
                        tasteBar("Body", brew.body)
                        tasteBar("Bitterness", brew.bitterness)
                        tasteBar("Balance", brew.balance)
                        tasteBar("Aftertaste", brew.aftertaste)
                    }
                }

                if !brew.flavourNotes.isEmpty {
                    CremaCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("FLAVOURS")
                                .font(.crema(11, .semibold))
                                .foregroundStyle(CremaColor.textTertiary)
                            FlowChips(items: brew.flavourNotes.map { "\($0.emoji) \($0.rawValue)" })
                        }
                    }
                }

                if !brew.notes.isEmpty {
                    CremaCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("NOTES")
                                .font(.crema(11, .semibold))
                                .foregroundStyle(CremaColor.textTertiary)
                            Text(brew.notes)
                                .font(.crema(15))
                                .foregroundStyle(CremaColor.textPrimary)
                        }
                    }
                }

                SectionHeader("Coach Review")
                CremaCard {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(tips) { tip in
                            CoachTipRow(tip: tip)
                            if tip.id != tips.last?.id { Divider().overlay(CremaColor.separator) }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(CremaColor.background)
        .navigationTitle(brew.bean?.name ?? "Shot")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        toggleGolden()
                    } label: {
                        Label(brew.isGolden ? "Unmark golden" : "Mark as golden",
                              systemImage: brew.isGolden ? "star.slash" : "star.fill")
                    }
                    Button(role: .destructive) {
                        modelContext.delete(brew)
                        HapticEngine.warning()
                        dismiss()
                    } label: { Label("Delete shot", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
    }

    private var scoreHeader: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().stroke(CremaColor.surface, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: CGFloat(brew.overall) / 10)
                    .stroke(CremaColor.crema, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(brew.overall)")
                    .font(.crema(40, .bold))
                    .foregroundStyle(CremaColor.textPrimary)
            }
            .frame(width: 120, height: 120)
            if brew.isGolden {
                Label("Golden Recipe", systemImage: "star.fill")
                    .font(.crema(14, .semibold))
                    .foregroundStyle(CremaColor.crema)
            }
            Text(brew.date.formatted(date: .complete, time: .shortened))
                .font(.crema(13, .medium))
                .foregroundStyle(CremaColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.crema(15, .medium)).foregroundStyle(CremaColor.textSecondary)
            Spacer()
            Text(value).font(.crema(15, .semibold)).foregroundStyle(CremaColor.textPrimary)
        }
    }

    private func tasteBar(_ label: String, _ value: Int) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.crema(14, .medium))
                .foregroundStyle(CremaColor.textPrimary)
                .frame(width: 92, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(CremaColor.surface)
                    Capsule().fill(CremaColor.caramel)
                        .frame(width: geo.size.width * CGFloat(value) / 10)
                }
            }
            .frame(height: 8)
            Text("\(value)")
                .font(.crema(14, .bold))
                .foregroundStyle(CremaColor.textSecondary)
                .frame(width: 20)
        }
    }

    private func toggleGolden() {
        brew.isGolden.toggle()
        guard let bean = brew.bean else { return }
        for existing in goldens where existing.bean?.id == bean.id {
            modelContext.delete(existing)
        }
        if brew.isGolden {
            modelContext.insert(DialedRecipe(from: brew))
        }
        HapticEngine.success()
    }
}

/// Simple wrapping chip layout.
struct FlowChips: View {
    let items: [String]
    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.crema(13, .medium))
                    .foregroundStyle(CremaColor.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(CremaColor.surface)
                    .clipShape(.rect(cornerRadius: CremaRadius.chip))
            }
        }
    }
}
