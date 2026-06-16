//
//  ExtractionBackground.swift
//  CremaDialed
//
//  A cinematic, fully procedural espresso-extraction backdrop — warm, premium
//  and calming. A naked-portafilter pour of caramel espresso falls into a cup,
//  crema swirls below, steam drifts up and a soft glow breathes. No video files,
//  so it works offline and never looks like stock footage.
//

import SwiftUI

struct ExtractionBackground: View {
    /// Whether espresso is actively flowing (drives the pour + intensity).
    var isFlowing: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                drawAtmosphere(context: context, size: size, t: t)
                drawSteam(context: context, size: size, t: t)
                drawPour(context: context, size: size, t: t)
                drawCremaPool(context: context, size: size, t: t)
                drawVignette(context: context, size: size)
            }
        }
        .ignoresSafeArea()
        .background(Color(red: 0.06, green: 0.04, blue: 0.03).ignoresSafeArea())
    }

    // MARK: Palette (fixed warm espresso tones — this scene is always "dark")

    private let espressoDark = Color(red: 0.09, green: 0.05, blue: 0.03)
    private let caramel = Color(red: 0.62, green: 0.36, blue: 0.16)
    private let cremaGold = Color(red: 0.80, green: 0.55, blue: 0.27)
    private let cremaLight = Color(red: 0.88, green: 0.68, blue: 0.40)

    // MARK: Layers

    private func drawAtmosphere(context: GraphicsContext, size: CGSize, t: Double) {
        let breathe = 0.5 + 0.5 * sin(t * 0.6)
        let glowOpacity = isFlowing ? 0.32 + 0.12 * breathe : 0.14 + 0.06 * breathe
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.34)
        let radius = max(size.width, size.height) * 0.9
        let gradient = Gradient(stops: [
            .init(color: cremaGold.opacity(glowOpacity), location: 0),
            .init(color: caramel.opacity(glowOpacity * 0.4), location: 0.4),
            .init(color: .clear, location: 1),
        ])
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .radialGradient(gradient, center: center, startRadius: 0, endRadius: radius)
        )
    }

    private func drawPour(context: GraphicsContext, size: CGSize, t: Double) {
        let cx = size.width * 0.5
        let topY = size.height * 0.16
        let cupY = size.height * 0.62

        if isFlowing {
            // Twin syrupy streams that braid together as they fall.
            for side in [-1.0, 1.0] {
                var path = Path()
                path.move(to: CGPoint(x: cx + side * 5, y: topY))
                let steps = 28
                for i in 0...steps {
                    let p = Double(i) / Double(steps)
                    let y = topY + (cupY - topY) * p
                    let braid = sin(t * 3 + p * 7 + side) * (1 - p) * 6 * side
                    let converge = side * 5 * (1 - p)
                    path.addLine(to: CGPoint(x: cx + converge + braid, y: y))
                }
                context.stroke(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [cremaLight, caramel]),
                        startPoint: CGPoint(x: cx, y: topY),
                        endPoint: CGPoint(x: cx, y: cupY)
                    ),
                    style: StrokeStyle(lineWidth: 2.4, lineCap: .round)
                )
            }
            // Falling droplets / splash sparkle.
            for i in 0..<6 {
                let phase = (t * 1.1 + Double(i) / 6).truncatingRemainder(dividingBy: 1)
                let y = topY + (cupY - topY) * phase
                let x = cx + sin(t * 4 + Double(i)) * 4
                let r = 1.4 + 1.2 * (1 - phase)
                context.fill(
                    Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                    with: .color(cremaLight.opacity(0.8 * (1 - phase) + 0.2))
                )
            }
        } else {
            // A single trembling drip hanging at the spout, ready to fall.
            let dripY = topY + 6 + sin(t * 2) * 3
            context.fill(
                Path(ellipseIn: CGRect(x: cx - 4, y: dripY - 5, width: 8, height: 11)),
                with: .color(caramel.opacity(0.9))
            )
        }
    }

    private func drawCremaPool(context: GraphicsContext, size: CGSize, t: Double) {
        let cx = size.width * 0.5
        let poolY = size.height * 0.66
        let poolW = size.width * 0.34

        // Cup rim / pool base.
        let base = Path(ellipseIn: CGRect(x: cx - poolW / 2, y: poolY - 14, width: poolW, height: 30))
        context.fill(base, with: .color(espressoDark.opacity(0.9)))

        // Swirling crema highlights.
        let swirls = isFlowing ? 5 : 3
        for i in 0..<swirls {
            let a = t * (isFlowing ? 1.4 : 0.6) + Double(i) * (.pi * 2 / Double(swirls))
            let rx = poolW * 0.28 * (0.5 + 0.5 * sin(t + Double(i)))
            let x = cx + cos(a) * rx
            let y = poolY + sin(a) * 6
            let r = 8.0 + 4 * sin(t * 2 + Double(i))
            context.fill(
                Path(ellipseIn: CGRect(x: x - r, y: y - r / 2, width: r * 2, height: r)),
                with: .color(cremaGold.opacity(isFlowing ? 0.5 : 0.32))
            )
        }
        // Bright meniscus glint.
        context.fill(
            Path(ellipseIn: CGRect(x: cx - poolW * 0.18, y: poolY - 6, width: poolW * 0.36, height: 8)),
            with: .color(cremaLight.opacity(0.35))
        )
    }

    private func drawSteam(context: GraphicsContext, size: CGSize, t: Double) {
        let cx = size.width * 0.5
        let baseY = size.height * 0.6
        for i in 0..<3 {
            var path = Path()
            let offset = Double(i - 1) * 26
            path.move(to: CGPoint(x: cx + offset, y: baseY))
            let steps = 16
            for s in 0...steps {
                let p = Double(s) / Double(steps)
                let y = baseY - p * size.height * 0.28
                let x = cx + offset + sin(t * 1.2 + p * 5 + Double(i)) * 16 * p
                path.addLine(to: CGPoint(x: x, y: y))
            }
            context.stroke(
                path,
                with: .color(.white.opacity((isFlowing ? 0.06 : 0.035))),
                style: StrokeStyle(lineWidth: 14, lineCap: .round)
            )
        }
    }

    private func drawVignette(context: GraphicsContext, size: CGSize) {
        let gradient = Gradient(stops: [
            .init(color: .clear, location: 0.5),
            .init(color: .black.opacity(0.55), location: 1),
        ])
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .radialGradient(
                gradient,
                center: CGPoint(x: size.width / 2, y: size.height / 2),
                startRadius: size.width * 0.3,
                endRadius: max(size.width, size.height) * 0.75
            )
        )
    }
}
