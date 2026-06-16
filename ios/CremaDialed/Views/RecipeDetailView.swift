//
//  RecipeDetailView.swift
//  CremaDialed
//
//  Full recipe: base shot, ingredients and step-by-step method.
//

import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe

    var body: some View {
        ZStack {
            CremaColor.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if let base = recipe.espressoBase {
                        baseCard(base)
                    }
                    ingredientsCard
                    stepsCard
                    if let tip = recipe.tip {
                        tipCard(tip)
                    }
                }
                .padding(16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: CremaRadius.card)
                    .fill(
                        LinearGradient(colors: [CremaColor.espresso, CremaColor.caramel],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(height: 130)
                Image(systemName: recipe.systemImage)
                    .font(.system(size: 50, weight: .bold))
                    .foregroundStyle(CremaColor.background.opacity(0.9))
            }
            Text(recipe.tagline)
                .font(.crema(16, .medium))
                .foregroundStyle(CremaColor.textSecondary)
            HStack(spacing: 10) {
                pill("clock", "\(recipe.minutes) min")
                pill("chart.bar.fill", recipe.difficulty.rawValue)
                pill(recipe.category.systemImage, recipe.category.rawValue)
            }
        }
    }

    private func pill(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.crema(11, .semibold))
            Text(text)
                .font(.crema(12, .semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .foregroundStyle(CremaColor.textPrimary)
        .background(CremaColor.surface)
        .clipShape(Capsule())
    }

    private func baseCard(_ base: String) -> some View {
        CremaCard {
            HStack(spacing: 12) {
                Image(systemName: "dial.medium.fill")
                    .font(.crema(20))
                    .foregroundStyle(CremaColor.crema)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text("ESPRESSO BASE")
                        .font(.crema(11, .semibold))
                        .foregroundStyle(CremaColor.textTertiary)
                    Text(base)
                        .font(.crema(16, .bold))
                        .foregroundStyle(CremaColor.textPrimary)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var ingredientsCard: some View {
        CremaCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Ingredients")
                    .font(.crema(18, .bold))
                    .foregroundStyle(CremaColor.textPrimary)
                ForEach(recipe.ingredients, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(CremaColor.crema)
                            .padding(.top, 7)
                        Text(item)
                            .font(.crema(15, .medium))
                            .foregroundStyle(CremaColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var stepsCard: some View {
        CremaCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Method")
                    .font(.crema(18, .bold))
                    .foregroundStyle(CremaColor.textPrimary)
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { idx, step in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(CremaColor.espresso)
                                .frame(width: 26, height: 26)
                            Text("\(idx + 1)")
                                .font(.crema(13, .bold))
                                .foregroundStyle(CremaColor.background)
                        }
                        Text(step)
                            .font(.crema(15))
                            .foregroundStyle(CremaColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private func tipCard(_ tip: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.crema(16))
                .foregroundStyle(CremaColor.caramel)
            VStack(alignment: .leading, spacing: 3) {
                Text("Barista Tip")
                    .font(.crema(13, .bold))
                    .foregroundStyle(CremaColor.caramel)
                Text(tip)
                    .font(.crema(14, .medium))
                    .foregroundStyle(CremaColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(CremaColor.caramel.opacity(0.12))
        .clipShape(.rect(cornerRadius: CremaRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: CremaRadius.card)
                .stroke(CremaColor.caramel.opacity(0.3), lineWidth: 0.5)
        )
    }
}
